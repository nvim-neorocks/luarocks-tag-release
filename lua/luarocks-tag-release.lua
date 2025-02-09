#!/usr/bin/env lua

---@alias github_ref_type 'tag' | 'branch'

---@class (exact) Args
---@field repo_name string The repository name.
---@field github_repo string The github repository (owner/repo_name).
---@field git_server_url string The github server's URL.
---@field git_ref string E.g. a tag or a commit sha.
---@field ref_type github_ref_type
---@field dependencies string[] List of LuaRocks package dependencies.
---@field test_dependencies string[] List of test suite dependencies.
---@field labels string[] List of labels to add to the rockspec.
---@field copy_directories string[] List of directories to add to the rockspec's copy_directories.
---@field summary string Package summary.
---@field detailed_description_lines string[] Detailed description (list of lines).
---@field rockspec_template_file_path string File path to the rockspec template (relative to repo's root).
---@field upload boolean Whether to upload to LuaRocks.
---@field license string|nil License SPDX ID (optional).
---@field extra_luarocks_args string[]
---@field github_event_path string|nil The path to the file on the runner that contains the full event webhook payload. For example, /github/workflow/event.json.
---@field is_debug boolean Whether to enable debug logging
---@field fail_on_duplicate boolean Whether to fail if the rock version has already been uploaded.

---@param package_name string The name of the LuaRocks package.
---@param package_version string | nil The version of the LuaRocks package.
---@param specrev string the version of the rockspec
---@param args Args
local function luarocks_tag_release(package_name, package_version, specrev, args)
  package_name = package_name:lower()
  -- version in format 3.0 must follow the format '[%w.]+-[%d]+' or be 'dev' or 'scm'
  local modrev = package_version and package_version ~= 'dev' and string.gsub(package_version, 'v', '') or 'scm'

  local rockspec_file_path = package_name .. '-' .. modrev .. '-' .. specrev .. '.rockspec'

  local luarocks_extra_flags_and_args = ' '
    .. table.concat(args.extra_luarocks_args, ' ')
    .. (args.is_debug and ' --verbose ' or '')

  print('Luarocks flags and args: ' .. luarocks_extra_flags_and_args)

  local OS = require('ltr.os')

  ---@return string tmp_dir The temp directory in which to install the package
  ---@return string luarocks_install_cmd The luarocks install command for installing in tmp_dir
  local function mk_luarocks_install_cmd()
    local tmp_dir = OS.execute('mktemp -d', error, args.is_debug):gsub('\n', '')
    local luarocks_install_cmd = 'luarocks install --tree ' .. tmp_dir
    return tmp_dir, luarocks_install_cmd
  end

  ---Creates a rockspec and performs a local test install
  ---@param rockspec_content string
  ---@return string rockspec_file_path
  local function create_rockspec(rockspec_content)
    local outfile = assert(io.open(rockspec_file_path, 'w'), 'Could not create ' .. rockspec_file_path .. '.')
    outfile:write(rockspec_content)
    outfile:close()
    return rockspec_file_path
  end

  local function setup_luarocks_paths()
    print('Getting luarocks path info')
    local luarocks_path_output, _ = OS.execute('luarocks path', error, args.is_debug)
    print('Setting up luarocks paths')
    OS.execute(luarocks_path_output, error, args.is_debug)
  end

  local function test_install_rockspec()
    local tmp_dir, luarocks_install_cmd = mk_luarocks_install_cmd()
    local cmd = luarocks_install_cmd .. ' ' .. rockspec_file_path .. luarocks_extra_flags_and_args
    print('TEST: ' .. cmd)
    local stdout, _ = OS.execute(cmd, error, args.is_debug)
    print(stdout)
    cmd = 'luarocks remove --tree ' .. tmp_dir .. ' ' .. package_name .. luarocks_extra_flags_and_args
    print('TEST: ' .. cmd)
    stdout, _ = OS.execute(cmd, error, args.is_debug)
    print(stdout)
  end

  ---@param target_rockspec_path string
  ---@return nil
  local function luarocks_upload(target_rockspec_path)
    local cmd = 'luarocks upload '
      .. target_rockspec_path
      .. ' --api-key $LUAROCKS_API_KEY'
      .. luarocks_extra_flags_and_args
    print('UPLOAD: ' .. cmd)
    local stdout, _ = OS.execute(cmd, function(message)
      if message:find('already exists on the server') and not args.fail_on_duplicate then
        print(
          string.format(
            '%s already exists with version %s on the remote. Doing nothing (`fail_on_duplicate` is false).',
            package_name,
            package_version
          )
        )
      else
        error(message)
      end
    end, args.is_debug)
    print(stdout)
  end

  local function test_install_package()
    local _, luarocks_install_cmd = mk_luarocks_install_cmd()
    local cmd = luarocks_install_cmd .. ' ' .. package_name .. ' ' .. modrev .. luarocks_extra_flags_and_args
    print('TEST: ' .. cmd)
    local stdout, _ = OS.execute(cmd, print, args.is_debug)
    print(stdout)
  end

  print('Using template: ' .. args.rockspec_template_file_path)
  local rockspec_template_file =
    assert(io.open(args.rockspec_template_file_path, 'r'), 'Could not open ' .. args.rockspec_template_file_path)
  local rockspec_template = rockspec_template_file:read('*a')
  rockspec_template_file:close()

  print(
    'Generating Luarocks release '
      .. modrev
      .. ' for: '
      .. package_name
      .. ' version '
      .. package_version
      .. ' from ref '
      .. args.git_ref
      .. '.'
  )

  local github_event_data = args.github_event_path and OS.read_file(args.github_event_path)
  local json = require('dkjson')

  local github_event_tbl = github_event_data and json.decode(github_event_data)
  local rockspec = require('ltr.rockspec').generate(package_name, modrev, specrev, rockspec_template, {
    ref_type = args.ref_type,
    git_server_url = args.git_server_url,
    github_repo = args.github_repo,
    license = args.license,
    git_ref = args.git_ref,
    summary = args.summary,
    detailed_description_lines = args.detailed_description_lines,
    dependencies = args.dependencies,
    test_dependencies = args.test_dependencies,
    labels = args.labels,
    copy_directories = args.copy_directories,
    repo_name = args.repo_name,
    github_event_tbl = github_event_tbl,
  })

  print('')
  print('Generated ' .. rockspec_file_path .. ':')
  print('========================================================================================')
  print(rockspec)
  print('========================================================================================')

  OS.write_file(rockspec_file_path, rockspec)
  local target_rockspec_path = create_rockspec(rockspec)
  setup_luarocks_paths()
  test_install_rockspec()
  if args.upload then
    luarocks_upload(target_rockspec_path)
    test_install_package()
  else
    print('LuaRocks upload disabled. Skipping...')
  end

  print('')
  print('Done.')
end

return luarocks_tag_release

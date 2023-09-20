#!/usr/bin/env lua

---@alias github_ref_type 'tag' | 'branch'
---@alias lua_interpreter 'neolua' | 'neolua-nightly' | 'lua'

---@class (exact) Args
---@field repo_name string The repository name.
---@field github_repo string The github repository (owner/repo_name).
---@field github_server_url string The github server's URL.
---@field git_ref string E.g. a tag or a commit sha.
---@field ref_type github_ref_type
---@field dependencies string[] List of LuaRocks package dependencies.
---@field labels string[] List of labels to add to the rockspec.
---@field copy_directories string[] List of directories to add to the rockspec's copy_directories.
---@field summary string Package summary.
---@field detailed_description_lines string[] Detailed description (list of lines).
---@field rockspec_template_file_path string File path to the rockspec template (relative to repo's root).
---@field upload boolean Whether to upload to LuaRocks.
---@field license string|nil License SPDX ID (optional).
---@field luarocks_test_interpreters lua_interpreter[]
---@field github_event_path string|nil The path to the file on the runner that contains the full event webhook payload. For example, /github/workflow/event.json.
---@field is_debug boolean Whether to enable debug logging

---@param package_name string The name of the LuaRocks package.
---@param package_version string The version of the LuaRocks package.
---@param specrev string the version of the rockspec
---@param args Args
local function luarocks_tag_release(package_name, package_version, specrev, args)
  -- version in format 3.0 must follow the format '[%w.]+-[%d]+'
  local modrev = string.gsub(package_version, 'v', '')

  local rockspec_file_path = package_name .. '-' .. modrev .. '-' .. specrev .. '.rockspec'

  local luarocks_extra_flags = args.is_debug and ' --verbose ' or ''

  local OS = require('ltr.os')

  ---@param interpreter lua_interpreter
  ---@return nil
  local function luarocks_test(interpreter)
    print('Initialising luarocks project...')
    OS.execute('luarocks init' .. luarocks_extra_flags, print)
    print('Done.')
    print('Configuring luarocks to use interpreter ' .. interpreter .. '...')
    OS.execute('luarocks config --scope project lua_interpreter ' .. interpreter .. luarocks_extra_flags)
    print('Done.')
    print('Running tests...')
    OS.execute('luarocks test' .. luarocks_extra_flags, error, true)
    OS.execute('rm -r .luarocks luarocks', print, args.is_debug)
  end

  ---@return string tmp_dir The temp directory in which to install the package
  ---@return string luarocks_install_cmd The luarocks install command for installing in tmp_dir
  local function mk_luarocks_install_cmd()
    local tmp_dir = OS.execute('mktemp -d', error, args.is_debug):gsub('\n', '')
    local luarocks_install_cmd = 'luarocks install --tree ' .. tmp_dir .. luarocks_extra_flags
    return tmp_dir, luarocks_install_cmd
  end

  ---Creates a rockspec and performs a local test install
  ---@param rockspec_content string
  ---@return string rockspec_file_path
  local function create_rockspec(rockspec_content)
    local outfile = assert(io.open(rockspec_file_path, 'w'), 'Could not create ' .. rockspec_file_path .. '.')
    outfile:write(rockspec_content)
    outfile:close()
    local tmp_dir, luarocks_install_cmd = mk_luarocks_install_cmd()
    local cmd = luarocks_install_cmd .. ' ' .. rockspec_file_path
    print('TEST: ' .. cmd)
    local stdout, _ = OS.execute(cmd, error, args.is_debug)
    print(stdout)
    cmd = 'luarocks remove --tree ' .. tmp_dir .. ' ' .. package_name .. luarocks_extra_flags
    print('TEST: ' .. cmd)
    stdout, _ = OS.execute(cmd, error, args.is_debug)
    print(stdout)
    return rockspec_file_path
  end

  ---@param target_rockspec_path string
  ---@return nil
  local function luarocks_upload(target_rockspec_path)
    local _, luarocks_install_cmd = mk_luarocks_install_cmd()
    local cmd = 'luarocks upload ' .. target_rockspec_path .. ' --api-key $LUAROCKS_API_KEY' .. luarocks_extra_flags
    print('UPLOAD: ' .. cmd)
    local stdout, _ = OS.execute(cmd, error, args.is_debug)
    print(stdout)
    cmd = luarocks_install_cmd .. ' ' .. package_name .. ' ' .. modrev .. luarocks_extra_flags
    print('TEST: ' .. cmd)
    stdout, _ = OS.execute(cmd, print, args.is_debug)
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
    github_server_url = args.github_server_url,
    github_repo = args.github_repo,
    license = args.license,
    git_ref = args.git_ref,
    summary = args.summary,
    detailed_description_lines = args.detailed_description_lines,
    dependencies = args.dependencies,
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
  if OS.file_exists('.busted') then
    for _, interpreter in pairs(args.luarocks_test_interpreters) do
      luarocks_test(interpreter)
    end
  end
  local target_rockspec_path = create_rockspec(rockspec)
  if args.upload then
    luarocks_upload(target_rockspec_path)
  else
    print('LuaRocks upload disabled. Skipping...')
  end

  print('')
  print('Done.')
end

return luarocks_tag_release

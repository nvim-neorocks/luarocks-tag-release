#!/usr/bin/env lua

---@alias github_ref_type 'tag' | 'branch'
---@alias lua_interpreter 'neolua' | 'neolua-nightly' | 'lua'

---@class Args
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

---@param package_name string The name of the LuaRocks package.
---@param package_version string The version of the LuaRocks package.
---@param specrev string the version of the rockspec
---@param args Args
local function luarocks_tag_release(package_name, package_version, specrev, args)
  -- version in format 3.0 must follow the format '[%w.]+-[%d]+'
  local modrev = string.gsub(package_version, 'v', '')

  local archive_dir_suffix = args.ref_type == 'tag' and modrev or args.git_ref

  local rockspec_file_path = package_name .. '-' .. modrev .. '-' .. specrev .. '.rockspec'

  ---@param filename string
  ---@return string? content
  local function read_file(filename)
    local content
    local f = io.open(filename, 'r')
    if f then
      content = f:read('*a')
      f:close()
    end
    return content
  end

  ---@param filename string
  ---@return boolean file_exists
  local function file_exists(filename)
    local f = io.open(filename, 'r')
    if f then
      f:close()
      return true
    end
    return false
  end

  ---@param filename string
  ---@param content string
  ---@return nil
  local function write_file(filename, content)
    local outfile = assert(io.open(filename, 'w'), 'Could not create ' .. filename .. '.')
    outfile:write(content)
    outfile:close()
  end

  ---@param cmd string
  ---@param on_failure fun(error_msg:string)?
  ---@return string stdout, string stderr
  local function execute(cmd, on_failure)
    on_failure = on_failure or error
    local exec_out = 'exec_out.txt'
    local exec_err = 'exec_err.txt'
    local to_exec_out = ' >' .. exec_out .. ' 2>' .. exec_err
    local exit_code = os.execute(cmd .. to_exec_out)
    local stdout = read_file(exec_out) or ''
    local stderr = read_file(exec_err) or ''
    if exit_code ~= 0 then
      on_failure(cmd .. ' FAILED\nexit code: ' .. exit_code .. '\nstdout: ' .. stdout .. '\nstderr: ' .. stderr)
    end
    return stdout, stderr
  end

  ---@param interpreter lua_interpreter
  ---@return nil
  local function luarocks_test(interpreter)
    print('Initialising luarocks project...')
    execute('luarocks init', print)
    print('Done.')
    print('Configuring luarocks to use interpreter ' .. interpreter .. '...')
    execute('luarocks config --scope project lua_interpreter ' .. interpreter)
    print('Done.')
    print('Running tests...')
    execute('luarocks test')
    execute('rm -r .luarocks luarocks', print)
  end

  ---@return string tmp_dir The temp directory in which to install the package
  ---@return string luarocks_install_cmd The luarocks install command for installing in tmp_dir
  local function mk_luarocks_install_cmd()
    local tmp_dir = execute('mktemp -d', error):gsub('\n', '')
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
    local tmp_dir, luarocks_install_cmd = mk_luarocks_install_cmd()
    local cmd = luarocks_install_cmd .. ' ' .. rockspec_file_path
    print('TEST: ' .. cmd)
    local stdout, _ = execute(cmd)
    print(stdout)
    cmd = 'luarocks remove --tree ' .. tmp_dir .. ' ' .. package_name
    print('TEST: ' .. cmd)
    stdout, _ = execute(cmd, error)
    print(stdout)
    return rockspec_file_path
  end

  ---@param target_rockspec_path string
  ---@return nil
  local function luarocks_upload(target_rockspec_path)
    local _, luarocks_install_cmd = mk_luarocks_install_cmd()
    local cmd = 'luarocks upload ' .. target_rockspec_path .. ' --api-key $LUAROCKS_API_KEY'
    print('UPLOAD: ' .. cmd)
    local stdout, _ = execute(cmd)
    print(stdout)
    cmd = luarocks_install_cmd .. ' ' .. package_name .. ' ' .. modrev
    print('TEST: ' .. cmd)
    stdout, _ = execute(cmd, print)
    print(stdout)
  end

  ---@param xs string[]?
  ---@return string lua_list_string
  local function mk_lua_list_string(xs)
    if not xs or #xs == 0 then
      return '{ }'
    end
    return "{ '" .. table.concat(xs, "', '") .. "' } "
  end

  ---@param xs string[]?
  ---@return string lua_multiline_string
  local function mk_lua_multiline_str(xs)
    if not xs or #xs == 0 then
      return "''"
    end
    return '[[\n    ' .. table.concat(xs, '\n    ') .. '  \n]]'
  end

  print('Using template: ' .. args.rockspec_template_file_path)
  local rockspec_template_file =
    assert(io.open(args.rockspec_template_file_path, 'r'), 'Could not open ' .. args.rockspec_template_file_path)
  local content = rockspec_template_file:read('*a')
  rockspec_template_file:close()
  local repo_url = args.github_server_url .. '/' .. args.github_repo
  local homepage = repo_url
  local license
  local github_event_data = args.github_event_path and read_file(args.github_event_path)
  local json = require('dkjson')
  local github_event_tbl = github_event_data and json.decode(github_event_data)
  local repo_meta = github_event_tbl
    and (
      github_event_tbl.pull_request and github_event_tbl.pull_request.head and github_event_tbl.pull_request.head.repo
      or github_event_tbl.repository
    )
  if repo_meta then
    local repo_license = repo_meta.license or repo_meta.source and repo_meta.source.license
    if args.license then
      license = "license = '" .. args.license .. "'"
    elseif repo_license and repo_license.spdx_id ~= '' and repo_license.spdx_id ~= 'NOASSERTION' then
      license = "license = '" .. repo_license.spdx_id .. "'"
    else
      error([[
    Could not get the license SPDX ID from the GitHub API.
    Please add a license file that GitHub can recognise or add a `license` input.
    See: https://github.com/nvim-neorocks/luarocks-tag-release#license
    ]])
    end
    if not args.summary or args.summary == '' then
      args.summary = repo_meta.description and repo_meta.description or ''
    end
    if not args.labels or #args.labels == 0 then
      args.labels = repo_meta.topics and repo_meta.topics or {}
    end
    if repo_meta.homepage and repo_meta.homepage ~= '' then
      homepage = repo_meta.homepage
    end
  end

  ---@param str string
  ---@return string
  local function escape_quotes(str)
    local escaped = str:gsub("'", "\\'")
    return escaped
  end

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
  local rockspec = content
    :gsub('$git_ref', args.git_ref)
    :gsub('$modrev', modrev)
    :gsub('$specrev', specrev)
    :gsub('$repo_url', repo_url)
    :gsub('$archive_dir_suffix', archive_dir_suffix)
    :gsub('$package', package_name)
    :gsub('$summary', escape_quotes(args.summary))
    :gsub('$detailed_description', mk_lua_multiline_str(args.detailed_description_lines))
    :gsub('$dependencies', mk_lua_list_string(args.dependencies))
    :gsub('$labels', mk_lua_list_string(args.labels))
    :gsub('$homepage', homepage)
    :gsub('$license', license)
    :gsub('$copy_directories', mk_lua_list_string(args.copy_directories))
    :gsub('$repo_name', args.repo_name)

  print('')
  print('Generated ' .. rockspec_file_path .. ':')
  print('========================================================================================')
  print(rockspec)
  print('========================================================================================')

  write_file(rockspec_file_path, rockspec)
  if file_exists('.busted') then
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

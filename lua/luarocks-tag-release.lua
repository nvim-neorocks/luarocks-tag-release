#!/usr/bin/env lua

---@class Args
---@field repo_name string
---@field github_repo string
---@field github_server_url string
---@field package_name string
---@field package_version string
---@field dependencies string[]
---@field labels string[]
---@field copy_directories string[]
---@field summary string
---@field detailed_description_lines string[]
---@field rockspec_template_file_path string
---@field upload boolean
---@field license string|nil

---@param args Args
local function luarocks_tag_release(args)
  local modrev = string.gsub(args.package_version, 'v', '')

  local is_tag = os.getenv('GITHUB_REF_TYPE') == 'tag'
  local git_ref = assert(os.getenv('GITHUB_REF_NAME'), 'GITHUB_REF_NAME not set')
  local archive_dir_suffix = modrev
  if not is_tag then
    print('Publishing an untagged release.')
    git_ref = assert(os.getenv('GITHUB_SHA'), 'GITHUB_SHA not set')
    archive_dir_suffix = git_ref
  end

  local target_rockspec_file = args.package_name .. '-' .. modrev .. '-1.rockspec'

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

  ---@param cmd string
  ---@param on_failure fun(error_msg:string)
  ---@return string stdout, string stderr
  local function execute(cmd, on_failure)
    local exec_out = 'exec_out.txt'
    local exec_err = 'exec_err.txt'
    local to_exec_out = ' >' .. exec_out .. ' 2>' .. exec_err
    local exit_code = os.execute(cmd .. to_exec_out)
    local stdout = read_file(exec_out) or ''
    local stderr = read_file(exec_err) or ''
    if exit_code ~= 0 then
      on_failure('FAILED (exit code ' .. exit_code .. '): ' .. cmd .. ' ' .. stderr)
    end
    return stdout, stderr
  end

  ---@param rockspec_content string
  ---@return nil
  local function luarocks_upload(rockspec_content)
    local outfile = assert(io.open(target_rockspec_file, 'w'), 'Could not create ' .. target_rockspec_file .. '.')
    outfile:write(rockspec_content)
    outfile:close()
    local tmp_dir = execute('mktemp -d', error):gsub('\n', '')
    local luarocks_install_cmd = 'luarocks install --tree ' .. tmp_dir

    local cmd = luarocks_install_cmd .. ' ' .. target_rockspec_file
    print('TEST: ' .. cmd)
    local stdout, _ = execute(cmd, error)
    print(stdout)
    cmd = 'luarocks remove --tree ' .. tmp_dir .. ' ' .. args.package_name
    print('TEST: ' .. cmd)
    stdout, _ = execute(cmd, error)
    if not args.upload then
      print('LuaRocks upload disabled. Skipping...')
      return
    end
    print(stdout)
    cmd = 'luarocks upload ' .. target_rockspec_file .. ' --api-key $LUAROCKS_API_KEY'
    print('UPLOAD: ' .. cmd)
    stdout, _ = execute(cmd, error)
    print(stdout)
    cmd = luarocks_install_cmd .. ' ' .. args.package_name .. ' ' .. modrev
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
  local repo_info_str, _ =
    execute('curl -H "Accept: application/vnd.github+json" https://api.github.com/repos/' .. args.github_repo, print)
  if repo_info_str and repo_info_str ~= '' then
    local json = require('dkjson')
    local repo_meta = json.decode(repo_info_str)
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
      .. args.package_name
      .. ' version '
      .. args.package_version
      .. ' from ref '
      .. git_ref
      .. '.'
  )
  local rockspec = content
    :gsub('$git_ref', git_ref)
    :gsub('$modrev', modrev)
    :gsub('$repo_url', repo_url)
    :gsub('$archive_dir_suffix', archive_dir_suffix)
    :gsub('$package', args.package_name)
    :gsub('$summary', escape_quotes(args.summary))
    :gsub('$detailed_description', mk_lua_multiline_str(args.detailed_description_lines))
    :gsub('$dependencies', mk_lua_list_string(args.dependencies))
    :gsub('$labels', mk_lua_list_string(args.labels))
    :gsub('$homepage', homepage)
    :gsub('$license', license)
    :gsub('$copy_directories', mk_lua_list_string(args.copy_directories))
    :gsub('$repo_name', args.repo_name)

  print('')
  print('Generated rockspec:')
  print('========================================================================================')
  print(rockspec)
  print('========================================================================================')

  luarocks_upload(rockspec)

  print('')
  print('Done.')
end

return luarocks_tag_release

#!/usr/bin/env lua

---@class Args
---@field package_name string
---@field dependencies string[]
---@field labels string[]
---@field copy_directories string[]
---@field summary string
---@field detailed_description_lines string[]
---@field build_type string
---@field rockspec_template_file_path string
---@field license string|nil

---@type string[]
local arg_list = { ... }

local ref_type = os.getenv('GITHUB_REF_TYPE')
if not ref_type or ref_type ~= 'tag' then
  error('This GitHub workflow is designed to be run on tagged releases only.')
end

if not os.getenv('LUAROCKS_API_KEY') then
  error('LUAROCKS_API_KEY secret not set')
end

---@param str string
---@return string[] list_arg
local function parse_list_args(str)
  local tbl = {}
  for arg in string.gmatch(str, '[^\r\n]+') do
    table.insert(tbl, arg)
  end
  return tbl
end

local git_tag = os.getenv('GITHUB_REF_NAME') or 'scm'
local github_repo = os.getenv('GITHUB_REPOSITORY')
if not github_repo then
  error('GITHUB_REPOSITORY not set')
end

local repo_name = string.match(github_repo, '/(.+)')
if not repo_name then
  error([[
    Could not determine repo name from GITHUB_REPOSITORY.
    If you see this, please report this as a bug.
  ]])
end

local github_server_url = os.getenv('GITHUB_SERVER_URL')
if not github_server_url then
  error('GITHUB_SERVER_URL not set')
end

---@type Args
local args = {
  package_name = arg_list[1],
  dependencies = parse_list_args(arg_list[2]),
  labels = parse_list_args(arg_list[3]),
  copy_directories = parse_list_args(arg_list[4]),
  summary = arg_list[5],
  detailed_description_lines = parse_list_args(arg_list[6]),
  build_type = arg_list[7],
  rockspec_template_file_path = arg_list[8],
  license = #arg_list > 8 and arg_list[9] ~= '' and arg_list[9] or nil,
}
table.insert(args.dependencies, 1, 'lua >= 5.1')

local modrev = string.gsub(git_tag, 'v', '')

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
  local outfile = io.open(target_rockspec_file, 'w')
  if not outfile then
    error('Could not create ' .. target_rockspec_file .. '.')
  end
  outfile:write(rockspec_content)
  outfile:close()
  local cmd = 'luarocks install ' .. target_rockspec_file
  print('TEST: ' .. cmd)
  local stdout, _ = execute(cmd, error)
  print(stdout)
  cmd = 'luarocks upload ' .. target_rockspec_file .. ' --api-key $LUAROCKS_API_KEY'
  print('UPLOAD: ' .. cmd)
  stdout, _ = execute(cmd, error)
  print(stdout)
  cmd = 'luarocks install ' .. args.package_name .. ' ' .. modrev
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
local rockspec_template_file = io.open(args.rockspec_template_file_path, 'r')
if not rockspec_template_file then
  error('Could not open ' .. args.rockspec_template_file_path)
end
local content = rockspec_template_file:read('*a')
rockspec_template_file:close()
local repo_url = github_server_url .. '/' .. github_repo
local homepage = repo_url
local license
local repo_info_str, _ =
  execute('curl -H "Accept: application/vnd.github+json" https://api.github.com/repos/' .. github_repo, print)
if repo_info_str and repo_info_str ~= '' then
  local json = require('dkjson')
  local repo_meta = json.decode(repo_info_str)
  local repo_license = repo_meta.license
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

print('Generating Luarocks release ' .. modrev .. ' for: ' .. args.package_name .. ' ' .. git_tag .. '.')
local rockspec = content
  :gsub('$git_tag', git_tag)
  :gsub('$modrev', modrev)
  :gsub('$repo_url', repo_url)
  :gsub('$package', args.package_name)
  :gsub('$summary', escape_quotes(args.summary))
  :gsub('$detailed_description', mk_lua_multiline_str(args.detailed_description_lines))
  :gsub('$dependencies', mk_lua_list_string(args.dependencies))
  :gsub('$labels', mk_lua_list_string(args.labels))
  :gsub('$homepage', homepage)
  :gsub('$license', license)
  :gsub('$copy_directories', mk_lua_list_string(args.copy_directories))
  :gsub('$build_type', args.build_type)
  :gsub('$repo_name', repo_name)

print('')
print('Generated rockspec:')
print('========================================================================================')
print(rockspec)
print('========================================================================================')

luarocks_upload(rockspec)

print('')
print('Done.')

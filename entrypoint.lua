#!/usr/bin/env lua

local args = { ... }

local ref_type = os.getenv('GITHUB_REF_TYPE')
if not ref_type or ref_type ~= 'tag' then
  error('This GitHub workflow is designed to be run on tagged releases only.')
end

if not os.getenv('LUAROCKS_API_KEY') then
  error('LUAROCKS_API_KEY secret not set')
end

local function parse_list_args(str)
  local tbl = {}
  for arg in str:gmatch('[^\r\n]+') do
    table.insert(tbl, arg)
  end
  return tbl
end

local git_tag = os.getenv('GITHUB_REF_NAME') or 'scm'
local github_repo = os.getenv('GITHUB_REPOSITORY')
if not github_repo then
  error('GITHUB_REPOSITORY not set')
end
local repo_name = github_repo:match('/(.+)')

local github_server_url = os.getenv('GITHUB_SERVER_URL')
if not github_server_url then
  error('GITHUB_SERVER_URL not set')
end

local package = args[1]
local dependencies = parse_list_args(args[2])
table.insert(dependencies, 1, 'lua >= 5.1')
local labels = parse_list_args(args[3])
local copy_directories = parse_list_args(args[4])
local summary = args[5]
local detailed_description_lines = parse_list_args(args[6])
local build_type = args[7]

local modrev = git_tag:gsub('v', '')

local target_rockspec_file = package .. '-' .. modrev .. '-1.rockspec'

local function read_file(fname)
  local content = ''
  local f = io.open(fname, 'r')
  if f then
    content = f:read('*a')
    f:close()
  end
  return content
end

local function execute(cmd, on_failure)
  local exec_out = 'exec_out.txt'
  local exec_err = 'exec_err.txt'
  local to_exec_out = ' >' .. exec_out .. ' 2>' .. exec_err
  local exit_code = os.execute(cmd .. to_exec_out)
  local stdout = read_file(exec_out)
  local stderr = read_file(exec_err)
  if exit_code ~= 0 then
    on_failure('FAILED (exit code ' .. exit_code .. '): ' .. cmd .. ' ' .. stderr)
  end
  return stdout, stderr
end

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
  cmd = 'luarocks install ' .. package .. ' ' .. modrev
  print('TEST: ' .. cmd)
  stdout, _ = execute(cmd, print)
  print(stdout)
end

local function mk_table_str(tbl)
  if #tbl == 0 then
    return '{ }'
  end
  return "{ '" .. table.concat(tbl, "', '") .. "' } "
end

local function mk_lua_multiline_str(tbl)
  if #tbl == 0 then
    return "''"
  end
  return '[[\n    ' .. table.concat(tbl, '\n    ') .. '  \n]]'
end

local rockspec_template_file = io.open(package .. '.rockspec.template', 'r')
if rockspec_template_file then
  print('Found rockspec template file.')
else
  rockspec_template_file = io.open('rockspec.template', 'r')
end

if not rockspec_template_file then
  error('Could not open rockspec.template. Please report this as a bug.')
end
local content = rockspec_template_file:read('*a')
rockspec_template_file:close()
local repo_url = github_server_url .. '/' .. github_repo
local homepage = repo_url
local license = ''
local repo_info_str, _ =
  execute('curl -H "Accept: application/vnd.github+json" https://api.github.com/repos/' .. github_repo, print)
if repo_info_str and repo_info_str ~= '' then
  local json = require('dkjson')
  local repo_meta = json.decode(repo_info_str)
  license = repo_meta.license and "license = '" .. repo_meta.license.spdx_id .. "'"
  if not summary or summary == '' then
    summary = repo_meta.description and repo_meta.description or ''
  end
  if not labels or #labels == 0 then
    labels = repo_meta.topics and repo_meta.topics or {}
  end
  if repo_meta.homepage and repo_meta.homepage ~= '' then
    homepage = repo_meta.homepage
  end
end

print('Generating Luarocks release ' .. modrev .. ' for: ' .. package .. ' ' .. git_tag .. '.')
local rockspec = content
  :gsub('$git_tag', git_tag)
  :gsub('$modrev', modrev)
  :gsub('$repo_url', repo_url)
  :gsub('$package', package)
  :gsub('$summary', summary)
  :gsub('$detailed', mk_lua_multiline_str(detailed_description_lines))
  :gsub('$dependencies', mk_table_str(dependencies))
  :gsub('$labels', mk_table_str(labels))
  :gsub('$homepage', homepage)
  :gsub('$license', license)
  :gsub('$copy_directories', mk_table_str(copy_directories))
  :gsub('$build_type', build_type)
  :gsub('$repo_name', repo_name)

print('')
print('Generated rockspec:')
print('========================================================================================')
print(rockspec)
print('========================================================================================')

luarocks_upload(rockspec)

print('')
print('Done.')
return true

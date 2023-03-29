assert(os.getenv('LUAROCKS_API_KEY'), 'LUAROCKS_API_KEY secret not set')

local function getenv_or_err(env_var)
  return assert(os.getenv(env_var), env_var .. ' not set.')
end

local function getenv_or_empty(env_var)
  return os.getenv(env_var) or ''
end

local action_path = getenv_or_err('GITHUB_ACTION_PATH')

local github_repo = getenv_or_err('GITHUB_REPOSITORY')

local repo_name = assert(
  string.match(github_repo, '/(.+)'),
  [[
    Could not determine repository name from GITHUB_REPOSITORY.
    If you see this, please report this as a bug.
  ]]
)

local github_server_url = getenv_or_err('GITHUB_SERVER_URL')

---@param str string
---@return string[] list_arg
local function parse_list_args(str)
  local tbl = {}
  for arg in string.gmatch(str, '[^\r\n]+') do
    table.insert(tbl, arg)
  end
  return tbl
end

---Filter out directories that don't exist.
---@param directories string[] List of directories.
---@return string[] existing_directories
local function filter_existing_directories(directories)
  local existing_directories = {}
  for _, dir in pairs(directories) do
    if require('lfs').attributes(dir, 'mode') == 'directory' then
      existing_directories[#existing_directories + 1] = dir
    end
  end
  return existing_directories
end

---Insert Neovim plugin directories into the `copy_directories` list
---@param copy_directories string[] List of directories
local function insert_neovim_plugin_dirs(copy_directories)
  local neovim_plugin_dirs = {
    'autoload',
    'colors',
    'compiler',
    'doc',
    'filetype.lua',
    'ftplugin',
    'indent',
    'keymap',
    'lang',
    'menu.vim',
    'parser',
    'plugin',
    'queries',
    'query',
    'rplugin',
    'spell',
    'syntax',
  }
  for _, dir in neovim_plugin_dirs do
    table.insert(copy_directories, dir)
  end
end

---@param str_args string The arguments to parse
---@return string[] copy_directories The directories to copy
local function parse_copy_directory_args(str_args)
  local args = parse_list_args(str_args)
  local copy_directories = {}
  for _, arg in pairs(args) do
    if string.match(arg, '{{ neovim.plugin.dirs }}') then
      insert_neovim_plugin_dirs(copy_directories)
    else
      copy_directories[#copy_directories + 1] = arg
    end
  end
  return filter_existing_directories(copy_directories)
end

local license_input = os.getenv('INPUT_LICENSE')
local template_input = os.getenv('INPUT_TEMPLATE')

---@type Args
local args = {
  github_repo = github_repo,
  repo_name = repo_name,
  github_server_url = github_server_url,
  package_name = getenv_or_err('INPUT_NAME'),
  package_version = getenv_or_err('INPUT_VERSION'),
  dependencies = parse_list_args(getenv_or_empty('INPUT_DEPENDENCIES')),
  labels = parse_list_args(getenv_or_empty('INPUT_LABELS')),
  copy_directories = parse_copy_directory_args(getenv_or_err('INPUT_COPY_DIRECTORIES')),
  summary = getenv_or_empty('INPUT_SUMMARY'),
  detailed_description_lines = parse_list_args(getenv_or_empty('INPUT_DETAILED_DESCRIPTION')),
  rockspec_template_file_path = template_input ~= '' and template_input
    or action_path .. '/resources/rockspec.template',
  upload = getenv_or_err('INPUT_UPLOAD') == 'true',
  license = license_input ~= '' and license_input or nil,
}
table.insert(args.dependencies, 1, 'lua >= 5.1')

args.ref_type = getenv_or_err('GITHUB_REF_TYPE')
print('Workflow has been triggered by: ' .. args.ref_type)
args.git_ref = getenv_or_err('GITHUB_REF_NAME')
if args.ref_type ~= 'tag' then
  args.git_ref = getenv_or_err('GITHUB_SHA')
end

local luarocks_tag_release = require('luarocks-tag-release')

luarocks_tag_release(args)

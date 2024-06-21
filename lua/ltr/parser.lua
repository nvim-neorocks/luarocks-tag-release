local Parser = {}

---@param str string
---@return string[] list_arg
function Parser.parse_list_args(str)
  local tbl = {}
  for arg in string.gmatch(str, '[^%s*][^\r\n]+') do
    table.insert(tbl, arg)
  end
  return tbl
end

---Insert Neovim plugin directories into the `copy_directories` list
---@param copy_directories string[] List of directories
local function insert_neovim_plugin_dirs(copy_directories)
  local neovim_plugin_dirs = {
    'after',
    'autoload',
    'colors',
    'compiler',
    'doc',
    'filetype.lua',
    'ftplugin',
    'ftdetect',
    'indent',
    'keymap',
    'lang',
    'menu.vim',
    'parser',
    'parser-info',
    'plugin',
    'queries',
    'query',
    'rplugin',
    'spell',
    'syntax',
  }
  for _, dir in pairs(neovim_plugin_dirs) do
    table.insert(copy_directories, dir)
  end
end

---@param str_args string The arguments to parse
---@return string[] copy_directories The directories to copy
function Parser.parse_copy_directory_args(str_args)
  local args = Parser.parse_list_args(str_args)
  local copy_directories = {}
  for _, arg in pairs(args) do
    if string.match(arg, '{{ neovim%.plugin%.dirs }}') ~= nil then
      insert_neovim_plugin_dirs(copy_directories)
    else
      copy_directories[#copy_directories + 1] = arg
    end
  end
  return copy_directories
end

return Parser

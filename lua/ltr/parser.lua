local Parser = {}

---@param str string
---@return string[] list_arg
function Parser.parse_list_args(str)
  local tbl = {}
  for arg in string.gmatch(str, '[^\r\n]+') do
    table.insert(tbl, arg)
  end
  return tbl
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
  for _, dir in pairs(neovim_plugin_dirs) do
    table.insert(copy_directories, dir)
  end
end

---@param input string GitHub action input
---@return boolean
function Parser.is_neovim_plugin_dir_wildcard(input)
  return string.match(input, '{{ neovim%.plugin%.dirs }}')
end

---@param str_args string The arguments to parse
---@return string[] copy_directories The directories to copy
function Parser.parse_copy_directory_args(str_args)
  local args = Parser.parse_list_args(str_args)
  local copy_directories = {}
  for _, arg in pairs(args) do
    if Parser.is_neovim_plugin_dir_wildcard(arg) then
      insert_neovim_plugin_dirs(copy_directories)
    else
      copy_directories[#copy_directories + 1] = arg
    end
  end
  return copy_directories
end

---@param interpreters_input string|nil
---@return lua_interpreter[]
function Parser.parse_interpreter_input(interpreters_input)
  local test_interpreters = {}
  if interpreters_input then
    for _, input in pairs(Parser.parse_list_args(interpreters_input)) do
      if input == 'neovim-stable' then
        table.insert(test_interpreters, 'neolua')
      elseif input == 'neovim-nightly' then
        table.insert(test_interpreters, 'neolua-nightly')
      elseif input == 'lua' then
        table.insert(test_interpreters, 'lua')
      else
        error('Test interpreter ' .. input .. ' not supported.')
      end
    end
  end
  return test_interpreters
end

return Parser

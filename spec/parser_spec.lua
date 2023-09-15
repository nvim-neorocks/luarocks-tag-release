describe('Parser', function()
  local Parser = require('ltr.parser')
  it('Parse list args', function()
    local args = [[
      first
      second
      third
      fourth fith
    ]]
    local result = Parser.parse_list_args(args)
    assert.same({ 'first', 'second', 'third', 'fourth fith' }, result)
  end)
  it('Parse copy_directory args', function()
    assert.same(
      { 'first', 'second', 'third' },
      Parser.parse_copy_directory_args([[
      first
      second
      third
    ]])
    )
  end)
  it('Parse copy_directory args with {{ neovim.plugin.dirs }}', function()
    assert.same(
      {
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
        'first',
        'second',
        'third',
      },
      Parser.parse_copy_directory_args([[
      {{ neovim.plugin.dirs }}
      first
      second
      third
    ]])
    )
  end)
  it('Parse interpreter input', function()
    assert.same({ 'neolua' }, Parser.parse_interpreter_input('neovim-stable'))
    assert.same({ 'neolua-nightly' }, Parser.parse_interpreter_input('neovim-nightly'))
    assert.same({ 'lua' }, Parser.parse_interpreter_input('lua'))
    assert.same(
      { 'neolua', 'neolua-nightly' },
      Parser.parse_interpreter_input([[
      neovim-stable
      neovim-nightly
    ]])
    )
  end)
end)

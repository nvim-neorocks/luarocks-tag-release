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
    assert.same(result, { 'first', 'second', 'third', 'fourth fith' })
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
    local result = Parser.parse_copy_directory_args([[
      {{ neovim.plugin.dirs }}
      first
      second
      third
    ]])
    assert.same(result, {
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
      'parser-info',
      'plugin',
      'queries',
      'query',
      'rplugin',
      'spell',
      'syntax',
      'first',
      'second',
      'third',
    })
  end)
  it('Parse interpreter input', function()
    assert.same(Parser.parse_interpreter_input('neovim-stable'), { 'neolua' })
    assert.same(Parser.parse_interpreter_input('neovim-nightly'), { 'neolua-nightly' })
    assert.same(Parser.parse_interpreter_input('lua'), { 'lua' })
    assert.same(
      Parser.parse_interpreter_input([[
        neovim-stable
        neovim-nightly
      ]]),
      { 'neolua', 'neolua-nightly' }
    )
  end)
end)

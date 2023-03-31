---@diagnostic disable-next-line undefined-global
describe('Test example', function()
  ---@diagnostic disable-next-line undefined-global
  it('Test can access vim namespace', function()
    ---@diagnostic disable-next-line undefined-global
    assert.are.same(vim.trim('  a '), 'a')
  end)
  ---@diagnostic disable-next-line undefined-global
  it('Test can access plenary.nvim dependency', function()
    ---@diagnostic disable-next-line undefined-global
    assert(require('plenary'), 'Could not access plenary')
  end)
end)

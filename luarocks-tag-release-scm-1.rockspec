local _MODREV, _SPECREV = 'scm', '-1'
rockspec_format = '3.0'
package = 'luarocks-tag-release'
version = _MODREV .. _SPECREV

description = {
  summary = 'Build and upload LuaRocks packages from Git tags',
  homepage = 'http://github.com/mrcjkb/' .. package,
  license = 'MIT',
}

dependencies = {
  'lua >= 5.1',
  'argparse',
  'dkjson',
  'luafilesystem',
}

test_dependencies = {
  'dkjson',
  'luafilesystem',
  'nlua',
}

source = {
  url = 'git://github.com/mrcjkb/' .. package,
}

build = {
  type = 'builtin',
}

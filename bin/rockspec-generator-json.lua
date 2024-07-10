#!/usr/bin/env lua
local json = require('dkjson')

local input = io.stdin:read('*all')
-- print('You entered: ' .. input)

meta = json.decode(input)

-- split after the
package_name = meta.shorthand
dependencies = meta.dependencies
license = meta.license
summary = meta.summary
-- server_url =
meta.repo_name = package_name
meta.github_repo = meta.name
meta.git_ref = 'main' -- TODO adjust
meta.detailed_description_lines = ''
meta.copy_directories = meta.extra_directories
meta.labels = { 'neovim' }
meta.test_dependencies = {}

-- TODO split
-- meta.dependencies = meta.dependencies
meta.git_server_url = 'https://github.com'
-- meta["github_repo"] = "lol"
-- print(meta.github_repo)

local result = {}
-- if dependencies is empty then we
-- for line in string.gmatch(meta.dependencies .. "\n", "(.-)\n") do
--     table.insert(result, line);
-- end

meta.dependencies = result
-- print(meta.dependencies)

local rockspec_template_file_path = './resources/rockspec.template'
-- rockspec_template_file_path
local rockspec_template_fd =
  assert(io.open(rockspec_template_file_path, 'r'), 'Could not open ' .. rockspec_template_file_path)
local rockspec_template = rockspec_template_fd:read('*a')

local specrev = 1
local modrev = 1
local rockspec = require('ltr.rockspec').generate(
  package_name,
  modrev,
  specrev,
  rockspec_template,
  meta
  --   {
  --   -- ref_type = args.ref_type,
  --   -- git_server_url = args.git_server_url,
  --   -- github_repo = args.github_repo,
  --   license = license,
  --   -- git_ref = args.git_ref,
  --   summary = summary,
  --   -- detailed_description_lines = args.detailed_description_lines,
  --   -- dependencies = args.dependencies,
  --   -- test_dependencies = args.test_dependencies,
  --   -- labels = args.labels,
  --   -- copy_directories = args.copy_directories,
  --   -- repo_name = args.repo_name,
  --   github_event_tbl = meta,
  -- }
)

print(rockspec)

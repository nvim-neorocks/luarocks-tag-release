local json = require('dkjson')

local basename = 'toto'
local version = '0.1'
local argparse = require('argparse')
local parser = argparse([[rockspec-generator", "LuaRocks "..version..", the Lua package manager\n\n
      ' without any arguments to see the configuration.]])
  :help_max_width(80)
  :add_help_command()
  :add_complete_command({
    help_max_width = 100,
    summary = 'Output a shell completion script.',
    description = [[
Output a shell completion script.

Enabling completions for Bash:

   Add the following line to your ~/.bashrc:
      source <(]] .. basename .. [[ completion bash)
   or save the completion script to the local completion directory:
      ]] .. basename .. [[ completion bash > ~/.local/share/bash-completion/completions/]] .. basename .. [[
]],
  })
  :command_target('command')
  :require_command(false)

parser:flag('--version', 'Show version info and exit.'):action(function()
  print('Program version:', version)
  os.exit(0)
end)
parser:flag('--dev', 'Enable the sub-repositories in rocks servers for ' .. 'rockspecs of in-development versions.')
parser:option('--template', 'Rockspec-template'):argname('<template>'):hidden_name('--only-sources-from')
-- :handle_options(false)
parser:argument('package_name')
-- :args("*")

args = parser:parse(args)

package_name = arg[0]
dependencies = arg[1]
rockspect_template = args.template
-- json.decode(github_event_data)

local rockspec = require('ltr.rockspec').generate(package_name, modrev, specrev, rockspec_template, {
  ref_type = args.ref_type,
  git_server_url = args.git_server_url,
  github_repo = args.github_repo,
  license = args.license,
  git_ref = args.git_ref,
  summary = args.summary,
  detailed_description_lines = args.detailed_description_lines,
  dependencies = args.dependencies,
  test_dependencies = args.test_dependencies,
  labels = args.labels,
  copy_directories = args.copy_directories,
  repo_name = args.repo_name,
  github_event_tbl = github_event_tbl,
})

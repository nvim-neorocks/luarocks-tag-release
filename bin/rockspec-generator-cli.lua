local json = require('dkjson')

json.decode(github_event_data)

package_name = arg[0]
dependencies = arg[1]
rockspect_template = arg[1]

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


local M = {}

function M.generate_rockspec()
  local rockspec = rockspec_template
    :gsub('$git_ref', meta.git_ref)
    :gsub('$modrev', modrev)
    :gsub('$specrev', specrev)
    :gsub('$repo_url', repo_url)
    :gsub('$archive_dir_suffix', archive_dir_suffix)
    :gsub('$package', package_name)
    :gsub('$summary', escape_quotes(meta.summary))
    :gsub('$detailed_description', mk_lua_multiline_str(meta.detailed_description_lines))
    :gsub('$dependencies', mk_lua_list_string(meta.dependencies))
    :gsub('$test_dependencies', mk_lua_list_string(meta.test_dependencies))
    :gsub('$labels', mk_lua_list_string(meta.labels))
    :gsub('$homepage', homepage)
    :gsub('$license', license)
    :gsub('$copy_directories', mk_lua_list_string(meta.copy_directories))
    :gsub('$repo_name', meta.repo_name)
end

return M

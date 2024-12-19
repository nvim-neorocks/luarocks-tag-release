assert(os.getenv('LUAROCKS_API_KEY'), 'LUAROCKS_API_KEY secret not set')

local Parser = require('ltr.parser')
local OS = require('ltr.os')

local function getenv_or_err(env_var)
  return assert(os.getenv(env_var), env_var .. ' not set.')
end

local function getenv_or_empty(env_var)
  return os.getenv(env_var) or ''
end

local action_path = getenv_or_err('GITHUB_ACTION_PATH')

local github_repo = os.getenv('GITHUB_REPOSITORY_OVERRIDE') or getenv_or_err('GITHUB_REPOSITORY')

local repo_name = assert(
  string.match(github_repo, '/(.+)'),
  [[
    Could not determine repository name from GITHUB_REPOSITORY.
    If you see this, please report this as a bug.
  ]]
)

local git_server_url = getenv_or_err('INPUT_REPOSITORY')

local is_pull_request = getenv_or_empty('GITHUB_EVENT_NAME') == 'pull_request'

local license_input = os.getenv('INPUT_LICENSE')
local template_input = os.getenv('INPUT_TEMPLATE')
local package_name = getenv_or_err('INPUT_NAME')
---@type string | nil
local package_version = is_pull_request and '0.0.0' or os.getenv('INPUT_VERSION')

---@type Args
local args = {
  github_repo = github_repo,
  repo_name = repo_name,
  git_server_url = git_server_url,
  dependencies = Parser.parse_list_args(getenv_or_empty('INPUT_DEPENDENCIES')),
  test_dependencies = Parser.parse_list_args(getenv_or_empty('INPUT_TEST_DEPENDENCIES')),
  labels = Parser.parse_list_args(getenv_or_empty('INPUT_LABELS')),
  copy_directories = OS.filter_existing_directories(
    Parser.parse_copy_directory_args(getenv_or_err('INPUT_COPY_DIRECTORIES'))
  ),
  summary = getenv_or_empty('INPUT_SUMMARY'),
  detailed_description_lines = Parser.parse_list_args(getenv_or_empty('INPUT_DETAILED_DESCRIPTION')),
  rockspec_template_file_path = template_input ~= '' and template_input
    or action_path .. '/resources/rockspec.template',
  upload = not is_pull_request,
  license = license_input ~= '' and license_input or nil,
  extra_luarocks_args = Parser.parse_list_args(getenv_or_empty('INPUT_EXTRA_LUAROCKS_ARGS')),
  github_event_path = getenv_or_err('GITHUB_EVENT_PATH'),
  ref_type = os.getenv('GITHUB_REF_TYPE_OVERRIDE') or getenv_or_err('GITHUB_REF_TYPE'),
  git_ref = os.getenv('GITHUB_REF_NAME_OVERRIDE') or getenv_or_err('GITHUB_REF_NAME'),
  is_debug = os.getenv('RUNNER_DEBUG') == '1',
  fail_on_duplicate = getenv_or_empty('INPUT_FAIL_ON_DUPLICATE') == 'true',
}

local function get_github_sha()
  return os.getenv('GITHUB_SHA_OVERRIDE') or getenv_or_err('GITHUB_SHA')
end

print('Workflow has been triggered by: ' .. args.ref_type)
local is_tag = args.ref_type == 'tag'
if not is_tag then
  print('Publishing an untagged release.')
  args.git_ref = get_github_sha()
end

local luarocks_tag_release = require('luarocks-tag-release')

local specrev
if is_pull_request then
  print('Running in a pull request.')
  specrev = assert(os.getenv('GITHUB_RUN_ATTEMPT'), 'GITHUB_RUN_ATTEMPT not set')
  args.git_ref = get_github_sha()
else
  specrev = os.getenv('INPUT_SPECREV') or '1'
end

luarocks_tag_release(package_name, package_version, specrev, args)

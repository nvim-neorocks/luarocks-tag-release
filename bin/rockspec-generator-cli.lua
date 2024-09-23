#!/usr/bin/env lua
--[[
This script can generate a rockspec from arguments passed on the command line
using argparse

]]

local json = require('dkjson')
local argparse = require('argparse')

local parser = argparse('rockspec-generator-cli', 'Generate a rockspec file')
parser:option('--package_name', 'The name of the package')
parser:option('--modrev', 'Module revision')
parser:option('--specrev', 'Spec revision')
parser:option('--rockspec_template', 'Rockspec template')
parser:option('--ref_type', 'Reference type')
parser:option('--git_server_url', 'Git server URL')
parser:option('--github_repo', 'GitHub repository')
parser:option('--license', 'License')
parser:option('--git_ref', 'Git reference')
parser:option('--summary', 'Summary')
parser:option('--detailed_description_lines', 'Detailed description lines')
parser:option('--dependencies', 'Dependencies')
parser:option('--test_dependencies', 'Test dependencies')
parser:option('--labels', 'Labels')
parser:option('--copy_directories', 'Copy directories')
parser:option('--repo_name', 'Repository name')
parser:option('--github_event_data', 'GitHub event data'):default {}

local args = parser:parse()

local github_event_tbl = json.decode(args.github_event_data)

local rockspec =
  require('ltr.rockspec').generate(args.package_name, args.modrev, args.specrev, args.rockspec_template, {
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

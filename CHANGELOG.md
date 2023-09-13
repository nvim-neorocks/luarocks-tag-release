<!-- markdownlint-disable MD024 -->

# Changelog

## [5.1.7](https://github.com/nvim-neorocks/luarocks-tag-release/compare/v5.1.6...v5.1.7) (2023-09-13)


### Dependencies

* update flake.lock ([#107](https://github.com/nvim-neorocks/luarocks-tag-release/issues/107)) ([11f3a86](https://github.com/nvim-neorocks/luarocks-tag-release/commit/11f3a8648eb5b4ed5c0e33523eea409ef4b69165))

## [5.1.6](https://github.com/nvim-neorocks/luarocks-tag-release/compare/v5.1.5...v5.1.6) (2023-09-12)


### Bug Fixes

* auto-tag releases ([a3b23d3](https://github.com/nvim-neorocks/luarocks-tag-release/commit/a3b23d3bfae9bc2eb10efe789da2294f17027e06))
* **dependencies:** update flake.lock ([#105](https://github.com/nvim-neorocks/luarocks-tag-release/issues/105)) ([a29081d](https://github.com/nvim-neorocks/luarocks-tag-release/commit/a29081d5e1a7fda19feee925be53b7556b366e04))


### Reverts

* add workflow_dispatch to actions-tagger ([38705c8](https://github.com/nvim-neorocks/luarocks-tag-release/commit/38705c88e9b177dba09cd0fc8ef4b15e1b9b749d))

## [5.1.5](https://github.com/nvim-neorocks/luarocks-tag-release/compare/v5.1.4...v5.1.5) (2023-09-11)


### Bug Fixes

* **dependencies:** update flake.lock ([#98](https://github.com/nvim-neorocks/luarocks-tag-release/issues/98)) ([c3119ad](https://github.com/nvim-neorocks/luarocks-tag-release/commit/c3119adf5d1b990ee9aa6d177bcac4518d529784))
* **dependencies:** update flake.lock ([#99](https://github.com/nvim-neorocks/luarocks-tag-release/issues/99)) ([0672f79](https://github.com/nvim-neorocks/luarocks-tag-release/commit/0672f7915dd98c32c3020e067a133387409d5abd))

## [v5.1.4] - 2023-08-06
### Fixed
- Broken `{{ neovim.plugin.dirs }}` variable detection.

## [v5.1.3] - 2023-07-28
### Fixed
- Include stdout + stderr in error messages.

## [v5.1.2] - 2023-07-28
### Fixed
- Avoid duplicate `lua` dependencies in rockspec
  if specified in dependencies input.
### Changed
- Print generated rockspec's filename in workflow log.

## [v5.1.1] - 2023-07-17
### Fixed
- Use `GITHUB_EVENT_PATH` to get extra repo info
  (instead of GitHub REST API, which is flaky).

## [v5.1.0] - 2023-07-13
### Added
- Ability to test a local `luarocks install`, without uploading to luarocks.org
  on `pull_request`.

## [v5.0.1] - 2023-07-06
### Fixed
- Run `luarocks test` only if a `.busted` file exists in the project root.

## [v5.0.0] - 2023-06-04
### Added
- Ability to run `luarocks test` with Neovim as an interpreter.
  POTENIALLY BREAKING: Packages that have [busted](https://lunarmodules.github.io/busted/#usage)
  tests will fail to release if the test suite fails.

## [v4.0.1] - 2023-03-29
### Changed
- Change license to AGPLv3.0.
  Note: This does not affect the permission to use this action with a package that has a different license.
### Fixed
- Add `ftplugin` to `{{ neovim.plugin.dirs }}`.

## [v4.0.0] - 2023-03-19
- POTENIALLY BREAKING: Convert to composite action.
- POTENTIALLY BREAKING: Remove redundant `build_type` input.
  Use `template` input for non-builtin build types instead.
- Remove `gnumake` from shell wrapper (no longer needed in a composite action).

## [v3.0.0] - 2023-03-08
### Added
- Add directories from Neovim's `runtimepath` and some common plugin directories
  as the default for the `copy_directories` input.
  BREAKING CHANGE: This could potentially add new directories to LuaRocks packages,
  if the `copy_directories` input is not explicity specified, and one of the new default directories exists.
### Changed
- Only add directories that exist to the rockspec's `copy_directories`.

## [v2.3.0] - 2023-03-01
### Added
- Maintain `vX` and `vX.X` tags for the latest non-breaking releases.
### Fixed
- Only install packages locally when running as non-root.
  Fixes build failure in docker container.
### Changed
- Remove ShellCheck and transitive GHC dependency.

## [v2.2.0] - 2023-02-24
### Added
- Added 'make' to build environment to fix the support for rockspecs of build type 'make'.

## [v2.1.0] - 2023-02-17
### Added
- Optional `version` input to support basic git workflows (#11).

## [v2.0.0] - 2023-02-10
### Added
- Optional `license` input.
### Changed
- BREAKING: The action will fail if no `license` input is set and GitHub cannot determine the license automatically.

## [v1.0.2] - 2023-02-06
### Fixed
- Escape quotes in summary

## [v1.0.1] - 2023-02-03
### Fixed
- Used wrong entrypoint.sh

## [v1.0.0] - 2023-02-03
### Added
- First release.

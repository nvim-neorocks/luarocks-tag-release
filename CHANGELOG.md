<!-- markdownlint-disable MD024 -->

# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

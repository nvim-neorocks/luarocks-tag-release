<!-- markdownlint-disable MD024 -->

# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- Support for `latest` tag

## [v2.2.0] - 2023-02-24
### Added
- Added 'make' to build environment to fix the support for rockspecs of build type 'make'

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

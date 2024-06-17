<!-- markdownlint-disable -->
<br />
<div align="center">
  <a href="https://github.com/nvim-neorocks/luarocks-tag-release">
    <img src="https://avatars.githubusercontent.com/u/124081866?s=400&u=0da379a468d46456477a1f68048b020cf7a99f34&v=4" alt="neorocks">
  </a>
  <p align="center">
    <a href="https://github.com/nvim-neorocks/luarocks-tag-release/issues">Report Bug</a>
  </p>
  <p>
    <strong>
      luarocks-tag-release
      <br />
      Automatically publish <a href="https://luarocks.org/">luarocks</a> packages from git tags.
      <br />
      Designed to work with <a href="https://neovim.io/">Neovim</a> plugins.
    </strong>
  </p>
  <p>🏷️🚀🌒</p>
</div>
<!-- markdownlint-restore -->

[![Neovim][neovim-shield]][neovim-url]
[![Lua][lua-shield]][lua-url]
[![AGPL3 License][license-shield]][license-url]
[![Issues][issues-shield]][issues-url]
[![Luarocks release][ci-shield]][ci-url]

Publishes packages to [LuaRocks](https://luarocks.org/) when a git tag is pushed.
No need to add a rockspec to your repository for each release (or at all).

## Quick links

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Usage](#usage)
- [Inputs](#inputs)
- [Example configurations](https://github.com/nvim-neorocks/luarocks-tag-release/wiki/Example-configurations)
- [Limitations](#limitations)
- [Related](#related)
- [Acknowledgements](#acknowledgements)

## Features

- Can generate a [rockspec](https://github.com/luarocks/luarocks/wiki/Rockspec-format)
  based on repository metadata and information provided to the action.
- Tests a local installation from the rockspec file before uploading.
- Uploads the package to LuaRocks.
- Tests the installation of the uploaded package.
- Runs [`luarocks test`](https://github.com/luarocks/luarocks/wiki/test)
  with lua, neovim 0.9 and/or neovim-nightly as the interpreter.

## Prerequisites

- A LuaRocks account and an [API key](https://luarocks.org/settings/api-keys).
- Add the API key to your [repository's GitHub Actions secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets#creating-encrypted-secrets-for-a-repository).

## Usage

Create `.github/workflows/release.yml` in your repository with the following contents:

```yaml
name: LuaRocks release
on:
  push:
    tags: # Will upload to luarocks.org when a tag is pushed
      - "*"
  pull_request: # Will test a local install without uploading to luarocks.org

jobs:
  luarocks-release:
    runs-on: ubuntu-latest
    name: LuaRocks upload
    steps:
      - name: Checkout
        uses: actions/checkout@v3
      - name: LuaRocks Upload
        uses: nvim-neorocks/luarocks-tag-release@v5
        env:
          LUAROCKS_API_KEY: ${{ secrets.LUAROCKS_API_KEY }}
```

> [!NOTE]
>
> Use the `v5` tag to keep up with the latest releases, without breaking changes.

## Inputs

The following optional inputs can be specified using `with:`

### `name`

The name of the the luarocks package.

- Defaults to the repository name.

### `dependencies`

Lua dependencies.
Any dependencies specified here must be available on LuaRocks.

Example:

```yaml
- name: LuaRocks Upload
  uses: nvim-neorocks/luarocks-tag-release@v5
  with:
    dependencies: |
      plenary.nvim
      telescope.nvim
```

### `test_dependencies`

Lua dependencies of the test suite.
Any dependencies specified here must be available on LuaRocks.

Example:

```yaml
- name: LuaRocks Upload
  uses: nvim-neorocks/luarocks-tag-release@v5
  with:
    test_dependencies: |
      luaunit
```

### `labels`

Labels to add to the rockspec.
If none are specified, this action will use the repository's GitHub topics.

Example:

```yaml
- name: LuaRocks Upload
  uses: nvim-neorocks/luarocks-tag-release@v5
  with:
    labels: |
      neovim
```

### `test_interpreters`

Lua interpreters to run `luarocks test` with.
If no interpreter is set, or no [.busted file](https://lunarmodules.github.io/busted/#usage)
is present, no tests will be run.

Supported interpreters:

- `neovim-stable` - With access to the [Neovim 0.9 Lua API](https://neovim.io/doc/user/lua.html).
- `neovim-nightly` - With access to the Neovim nightly Lua API.
- `lua` - Plain luajit

Example:

```yaml
- name: LuaRocks Test and Upload
  uses: nvim-neorocks/luarocks-tag-release@v5
  with:
    test_interpreters: |
      neovim-stable
      neovim-nightly
```

> [!NOTE]
>
> For reproducible builds with recent versions of Neovim,
> we recommend **not** to use the latest stable tag,
> but instead to use [Dependabot](https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/configuring-dependabot-version-updates#enabling-github-dependabot-version-updates)
> to manage version updates.
> For convenience, you can [auto-approve](https://docs.github.com/en/code-security/dependabot/working-with-dependabot/automating-dependabot-with-github-actions#approve-a-pull-request)
> the pull request.

### `copy_directories`

Directories in the source directory to be copied to the rock installation
prefix as-is.
Useful for installing documentation and other files such as samples and tests.

Example:

```yaml
- name: LuaRocks Upload
  uses: nvim-neorocks/luarocks-tag-release@v5
  with:
    copy_directories: |
      {{ neovim.plugin.dirs }}
      src
      examples
```

>[!NOTE]
>
> The value `{{ neovim.plugin.dirs }}` (set by default)
> expands to common Neovim plugin directories (see also `:help runtimepath`):
>
> - autoload
> - colors
> - compiler
> - doc
> - filetype.lua
> - ftplugin
> - ftdetect
> - indent
> - keymap
> - lang
> - menu.vim
> - parser
> - plugin
> - queries
> - query
> - rplugin
> - spell
> - syntax

<!-- markdownlint-disable -->
>[!WARNING]
>
> Do not use the following directory names: `lua`, `lib`, `rock_manifest`
> or the name of your rockspec; those names are used by the .rock format
> internally, and attempting to copy directories with those names using
> the build.copy_directories directive will cause a clash.
<!-- markdownlint-enable -->

### `summary`

A short description of the package (one line).
If excluded, this action will fetch it from your repository's about section.

### `detailed_description`

A more detailed description of the package. Can be multiple lines.

Example:

```yaml
- name: LuaRocks Upload
  uses: nvim-neorocks/luarocks-tag-release@v5
  with:
    detailed_description: |
      Publishes packages to LuaRocks when a git tag is pushed.
      Automatically generates a rockspec from repository metadata
      and tests the installation before releasing.
```

### `template`

By default, this workflow will generate a rockspec based on a [predefined template](./rockspec.template).

You can also add a modified template to your repository and specify the path
to it with the `template` variable.

Example:

```yaml
- name: LuaRocks Upload
  uses: nvim-neorocks/luarocks-tag-release@v5
  with:
    template: "/path/to/my/template.rockspec"
```

### `license` (optional)

The license used by this package.
If not set (by default), this workflow will fetch the license SPDX ID from GitHub.
If GitHub cannot detect the license automatically, you can set it here.

Example:

```yaml
- name: LuaRocks Upload
  uses: nvim-neorocks/luarocks-tag-release@v5
  with:
    license: "MIT"
```

> [!NOTE]
>
> If GitHub can detect the license automatically,
> it will be displayed in your repository's About section.
>
> ![about](https://user-images.githubusercontent.com/12857160/218101570-b0605716-0457-47c1-ab2e-91d48a48881c.png)

### `version` (optional)

The package version to release to LuaRocks (without the rockspec revision).
By default, this workflow will use `github.ref_name` (the git tag or branch name)
to determine the LuaRocks package version.
If you do not have a workflow that releases based on tags,
you can manually set the version input.

Setting this input to either `null`, `"scm"` or `"dev"` will result in a
scm release, where the generated rockspec's source URL
is the repository's URL.

The following is an example for a basic workflow that runs daily at 00:00,
sets the package version to `0.0.<number_of_commits>`, and publishes to LuaRocks
if there have been any commits in the last 24 hours:

<!-- markdownlint-disable -->
```yaml
name: "release"
on:
  workflow_dispatch: # allows manual triggering
  schedule:
    - cron: '0 0 * * *' # runs daily at 00:00
  pull_request: # Will test a local install without uploading to luarocks.org

jobs:
  luarocks-upload:
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0 # Required to count the commits
      - name: Set luarocks version
        run: echo "LUAROCKS_VERSION=0.0.$(git log --oneline | wc -l)" >> $GITHUB_ENV
      - name: Get new commits
        run: echo "NEW_COMMIT_COUNT=$(git log --oneline --since '24 hours ago' | wc -l)" >> $GITHUB_ENV
      - name: LuaRocks Upload
        uses: nvim-neorocks/luarocks-tag-release@v5
        if: ${{ env.NEW_COMMIT_COUNT > 0 }}
        env:
          LUAROCKS_API_KEY: ${{ secrets.LUAROCKS_API_KEY }}
        with:
          version: ${{ env.LUAROCKS_VERSION }}
```
<!-- markdownlint-restore -->

> [!NOTE]
>
> A `v` prefix (e.g. git tags such as `v1.0.0`) is also supported.
> It will be removed from the LuaRocks version.

### `specrev` (optional)

The specrev (revision) of the generated rockspec. Defaults to `'1'`.

> [!TIP]
>
> When publishing `scm` or `dev` rockspecs, it can be useful to set
> point the source to a commit hash, and increment the `specrev` with every
> new push.
> This allows consumers to roll back or pin dev versions.

Example:

```yaml
- name: LuaRocks Upload
  uses: nvim-neorocks/luarocks-tag-release@v5
  with:
    version: "scm"
    # Add logic or determining if the specrev needs to be incremented
    specrev: "${{ env.SPECREV }}"
```

### `fail_on_duplicate` (optional)

When set to `true` will cause the workflow to fail with an error if the rock already exists on the server.
By default, if the rock already exists with a given version, the workflow will do nothing and fall back to other tasks
instead (e.g. running tests).

### `extra_luarocks_args`

Extra args to pass to the luarocks command.
This is useful if luarocks cannot find headers needed for the installation.

Example:

```yaml
- run: |
    sudo apt-get install -y libcurl4-openssl-dev
- name: LuaRocks Upload
  uses: nvim-neorocks/luarocks-tag-release@v5
  with:
    extra_luarocks_args: |
      CURL_INCDIR=/usr/include/x86_64-linux-gnu
```

> [!TIP]
>
> To find out where `apt` installs headers
> (assuming you are have set `runs-on: ubuntu-xyz`),
> you can run `dpkg -L <package-name>`.

## Example configurations

See the [Example configurations wiki page](https://github.com/nvim-neorocks/luarocks-tag-release/wiki/Example-configurations).

## Limitations

- This workflow only works on public repositories.
- It was designed with Neovim plugins in mind. It should work with any LuaRocks package
  (lua >= 5.1), but this has not been tested.
- This action uses lua 5.1. So any packages that depend on lua > 5.1
  will fail to install.

## Related

- [`rocks.nvim`](https://github.com/nvim-neorocks/rocks.nvim):
  A modern approach to Neovim plugin management, which uses
  luarocks.
- [Luarocks :purple_heart: Neovim](https://github.com/nvim-neorocks/sample-luarocks-plugin):
  A simple sample repository showing how to push your Neovim plugins to luarocks.

## Acknowledgements

Thanks to:

- [@Conni2461](https://github.com/Conni2461) for the help debugging the first drafts.
- The [neorocks](https://github.com/nvim-neorocks) surgeons:
  - [**@teto**](https://github.com/teto)
  - [**@vhyrro**](https://github.com/vhyrro)
  - [**@NTBBloodbath**](https://github.com/NTBBloodbath)
  - [**@vigoux**](https://github.com/vigoux)
  - [**@vsedov**](https://github.com/vsedov)
  - [**@mrcjkb**](https://github.com/mrcjkb)

<!-- MARKDOWN LINKS & IMAGES -->
[neovim-shield]: https://img.shields.io/badge/NeoVim-%2357A143.svg?&style=for-the-badge&logo=neovim&logoColor=white
[neovim-url]: https://neovim.io/
[lua-shield]: https://img.shields.io/badge/lua-%232C2D72.svg?style=for-the-badge&logo=lua&logoColor=white
[lua-url]: https://www.lua.org/
[issues-shield]: https://img.shields.io/github/issues/nvim-neorocks/luarocks-tag-release.svg?style=for-the-badge
[issues-url]: https://github.com/nvim-neorocks/luarocks-tag-release/issues
[license-shield]: https://img.shields.io/github/license/nvim-neorocks/luarocks-tag-release.svg?style=for-the-badge
[license-url]: https://github.com/nvim-neorocks/luarocks-tag-release/blob/master/LICENSE
[ci-shield]: https://img.shields.io/github/actions/workflow/status/nvim-neorocks/luarocks-tag-release/nix-build.yml?style=for-the-badge
[ci-url]: https://github.com/nvim-neorocks/luarocks-tag-release/actions/workflows/nix-build.yml

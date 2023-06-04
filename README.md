# LuaRocks tag release action

[![Luarocks release](https://github.com/nvim-neorocks/luarocks-tag-release/actions/workflows/release.yml/badge.svg)](https://github.com/nvim-neorocks/luarocks-tag-release/actions/workflows/release.yml)

Publishes packages to [LuaRocks](https://luarocks.org/) when a git tag is pushed.
No need to add a rockspec to your repository for each release (or at all).

## Quick links

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Usage](#usage)
- [Inputs](#inputs)
- [Example configurations](https://github.com/nvim-neorocks/luarocks-tag-release/wiki/Example-configurations)
- [Limitations](#limitations)
- [Acknowledgements](#acknowledgements)

## Features

* Can generate a [rockspec](https://github.com/luarocks/luarocks/wiki/Rockspec-format) based on repository metadata and information provided to the action.
* Tests a local installation from the rockspec file before uploading.
* Uploads the package to LuaRocks.
* Tests the installation of the uploaded package.

## Prerequisites

* A LuaRocks account and an [API key](https://luarocks.org/settings/api-keys).
* Add the API key to your [repository's GitHub Actions secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets#creating-encrypted-secrets-for-a-repository).

## Usage

Create `.github/workflows/release.yml` in your repository with the following contents:
```yaml
name: LuaRocks release
on:
  push:
    tags:
      - "*"

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

> **Note**
>
> Use the `v5` tag to keep up with the latest releases, without breaking changes.

## Inputs

The following optional inputs can be specified using `with:`

### `name`

The name of the the luarocks package.

* Defaults to the repository name.

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

### `labels`

Labels to add to the rockspec.
If none are specified, this action will use the repository's GitHub.

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

* `neovim-stable` - With access to the [Neovim 0.9 Lua API](https://neovim.io/doc/user/lua.html).
* `neovim-nightly` - With access to the Neovim nightly Lua API.
* `lua` - Plain luajit

Example:

```yaml
- name: LuaRocks Test and Upload
  uses: nvim-neorocks/luarocks-tag-release@v5
  with:
    test_interpreters: |
      neovim-stable
      neovim-nightly
```

### `copy_directories`

Directories in the source directory to be copied to the rock installation prefix as-is. Useful for installing documentation and other files such as samples and tests.

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

>**Note**
>
> The value `{{ neovim.plugin.dirs }}` (set by default) expands to common Neovim plugin directories
> (see also `:help runtimepath`):
>
> * autoload
> * colors
> * compiler
> * doc
> * filetype.lua
> * ftplugin
> * indent
> * keymap
> * lang
> * menu.vim
> * parser
> * plugin
> * queries
> * query
> * rplugin
> * spell
> * syntax
>
>**Warning**
>
> Do not use the following directory names: `lua`, `lib`, `rock_manifest` or the name of your rockspec; those names are used by the .rock format internally, and attempting to copy directories with those names using the build.copy_directories directive will cause a clash.

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

You can also add a modified template to your repository and specify the path to it with the `template` variable.


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
> **Note**
>
> If GitHub can detect the license automatically, it will be displayed in your repository's About section.
>
> ![about](https://user-images.githubusercontent.com/12857160/218101570-b0605716-0457-47c1-ab2e-91d48a48881c.png)


### `version` (optional)

The package version to release to LuaRocks (without the rockspec revision).
By default, this workflow will use the git tag to determine the LuaRocks package version.
If you do not have a workflow that releases based on tags, you can manually set the version input.

The following is an example for a basic workflow that runs daily at 00:00,
sets the package version to `0.0.<number_of_commits>`, and publishes to LuaRocks
if there have been any commits in the last 24 hours:

```yaml
name: "release"
on:
  workflow_dispatch: # allows manual triggering
  schedule:
    - cron: '0 0 * * *' # runs daily at 00:00

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

> **Note**
>
> A `v` prefix (e.g. git tags such as `v1.0.0`) is also supported.
> It will be removed from the LuaRocks version.

## Example configurations

See the [Example configurations wiki page](https://github.com/nvim-neorocks/luarocks-tag-release/wiki/Example-configurations).

## Limitations

* This workflow only works on public repositories.
* It was designed with Neovim plugins in mind. It should work with any LuaRocks package (lua >= 5.1), but this has not been tested.
* This action uses lua 5.1. So any packages that depend on lua > 5.1 will fail to install.

## Acknowledgements

Thanks to:

* [@teto](https://github.com/teto) for the [inspiration](https://teto.github.io/posts/2022-06-22-neovim-plugin-luarocks-2.html) that kickstarted this.
* [@Conni2461](https://github.com/Conni2461) for the help debugging the first drafts.

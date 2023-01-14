# [WIP] LuaRocks tag release action

> :warning:
>
> This action is a work in progress and may be moved to another oragnisation.

Publishes packages to [LuaRocks](https://luarocks.org/) when a git tag is pushed.
No need to add a rockspec to your repo for each release (or at all).

## Features

* Can generate a [rockspec](https://github.com/luarocks/luarocks/wiki/Rockspec-format) based on repository metadata and information provided to the action.
* Tests a local installation from the rockspec file before uploading.
* Uploads the package to LuaRocks.
* Tests the installation of the uploaded package.

## Prerequisites

* A Luarocks account and an [API key](https://luarocks.org/settings/api-keys).
* Add the API key to your [repo's GitHub Actions secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets#creating-encrypted-secrets-for-a-repository).

## Usage

Create `.github/workflows/release.yml` in your repo with the following contents:
```yaml
name: "Luarocks release"
on:
  push:
    tags:
      - '*'

jobs:
  luarocks-release:
    runs-on: ubuntu-latest
    name: Luarocks upload
    steps:
      - name: Checkout
        uses: actions/checkout@v3
      - name: Luarocks Upload
        uses: MrcJkb/luarocks-tag-release@master
        env:
          LUAROCKS_API_KEY: ${{ secrets.LUAROCKS_API_KEY }}
```

## Inputs

The following optional inputs can be specified using `with:`

#### `name`

The name of the the luarocks package.

* Defaults to the repository name.

#### `dependencies`

Lua dependencies.
Any dependencies specified here must be available on Luarocks.

Example:

```yaml
- name: Luarocks Upload
  uses: MrcJkb/luarocks-tag-release@master
  with:
    dependencies: |
      plenary.nvim
      telescope.nvim
```

#### `labels`

Labels to add to the rockspec.
If none are specified, this action will use the repo's GitHub.

Example:

```yaml
- name: Luarocks Upload
  uses: MrcJkb/luarocks-tag-release@master
  with:
    labels: |
      neovim
```

#### `copy_directories`

Directories in the source directory to be copied to the rock installation prefix as-is. Useful for installing documentation and other files such as samples and tests.

Example to specify additional directories:

```yaml
- name: Luarocks Upload
  uses: MrcJkb/luarocks-tag-release@master
  with:
    copy_directories: |
      doc
      plugin
```

> :warning:
>
> Do not use the following directory names: `lua`, `lib`, `rock_manifest` or the name of your rockspec; those names are used by the .rock format internally, and attempting to copy directories with those names using the build.copy_directories directive will cause a clash.

#### `summary`

A short description of the package (one line).
If excluded, this action will fetch it from your repo's about section.

#### `detailed_description`

A more detailed description of the package. Can be multiple lines.

Example:

```yaml
- name: Luarocks Upload
  uses: MrcJkb/luarocks-tag-release@master
  with:
    detailed_description: |
      Publishes packages to LuaRocks when a git tag is pushed.
      Automatically generates a rockspec from repo metadata
      and tests the installation before releasing.
```

#### `build_type`

The LuaRocks build backend.

* Defaults to `builtin`.
* If the installation fails, it may be necessary to [use a Makefile](https://github.com/luarocks/luarocks/wiki/Creating-a-Makefile-that-plays-nice-with-LuaRocks).

Example:

```yaml
- name: Luarocks Upload
  uses: MrcJkb/luarocks-tag-release@master
  with:
    build_type: 'make'
```

## Limitations

* This workflow only works on public repositories.
* This action was designed with Neovim plugins in mind. It should work with any Luarocks package, but this has not been tested.

## Acknowledgements

Thanks to:

* [@teto](https://github.com/teto) for the [inspiration](https://teto.github.io/posts/2022-06-22-neovim-plugin-luarocks-2.html) that kickstarted this.
* [@Conni2461](https://github.com/Conni2461) for the help debugging the first drafts.

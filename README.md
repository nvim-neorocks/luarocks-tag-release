# LuaRocks tag release action

Publishes packages to [LuaRocks](https://luarocks.org/) when a git tag is pushed.
No need to add a rockspec to your repository for each release (or at all).

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
        uses: nvim-neorocks/luarocks-tag-release@v1.0.0
        env:
          LUAROCKS_API_KEY: ${{ secrets.LUAROCKS_API_KEY }}
```

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
  uses: nvim-neorocks/luarocks-tag-release@v1.0.0
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
  uses: nvim-neorocks/luarocks-tag-release@v1.0.0
  with:
    labels: |
      neovim
```

### `copy_directories`

Directories in the source directory to be copied to the rock installation prefix as-is. Useful for installing documentation and other files such as samples and tests.

Example to specify additional directories:

```yaml
- name: LuaRocks Upload
  uses: nvim-neorocks/luarocks-tag-release@v1.0.0
  with:
    copy_directories: |
      doc
      plugin
```

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
  uses: nvim-neorocks/luarocks-tag-release@v1.0.0
  with:
    detailed_description: |
      Publishes packages to LuaRocks when a git tag is pushed.
      Automatically generates a rockspec from repository metadata
      and tests the installation before releasing.
```

### `build_type`

The LuaRocks build backend.

* Defaults to `builtin`.
* If the installation fails, it may be necessary to [use a Makefile](https://github.com/luarocks/luarocks/wiki/Creating-a-Makefile-that-plays-nice-with-LuaRocks).

Example:

```yaml
- name: LuaRocks Upload
  uses: nvim-neorocks/luarocks-tag-release@v1.0.0
  with:
    build_type: "make"
```

### `template`

By default, this workflow will generate a rockspec based on a [predefined template](./rockspec.template).

You can also add a modified template to your repository and specify the path to it with the `template` variable.


Example:

```yaml
- name: LuaRocks Upload
  uses: nvim-neorocks/luarocks-tag-release@v1.0.0
  with:
    template: "/path/to/my/template.rockspec"
```

## Limitations

* This workflow only works on public repositories.
* It was designed with Neovim plugins in mind. It should work with any LuaRocks package (lua >= 5.1), but this has not been tested.
* This action uses lua 5.1. So any packages that depend on lua > 5.1 will fail to install.

## Acknowledgements

Thanks to:

* [@teto](https://github.com/teto) for the [inspiration](https://teto.github.io/posts/2022-06-22-neovim-plugin-luarocks-2.html) that kickstarted this.
* [@Conni2461](https://github.com/Conni2461) for the help debugging the first drafts.

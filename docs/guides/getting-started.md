---
sidebar_position: 1
---

# Getting started

## Install the toolchain

Kern uses [Rokit](https://github.com/rojo-rbx/rokit) to provide its pinned
development tools. After installing Rokit, install this repository's toolchain:

```text
rokit install
```

This makes the pinned `lute` command available for building and running Kern.

## Build Kern

Build the local binary:

```text
lute run scripts/cd.luau
```

It is written to `bin/build`. Run `bin/build init` in a game repository to create
`default.kern.luau`, a `.luaurc` with the `@kern` typedef alias, and a buildable
`src/init.luau` entrypoint.

The normal loop is:

```text
bin/build lint
bin/build transform --check
bin/build check
bin/build build
```

`transform --check` fails when transforms would change source. `check` runs the
whole pipeline without writing output. `build` writes only after the pipeline is
valid.

---
sidebar_position: 1
---

# CI and releases

Kern's automation deliberately uses the same commands available to a project
author. This keeps the release gate representative: a binary is compiled, then
that binary runs `check` and `build` against the repository's sandbox project.

## Pull requests and main

The [`CI` workflow](../../.github/workflows/ci.yml) runs on pull requests, pushes
to `main`, and manual dispatches. It:

- regenerates embedded runtime modules, typedefs, and the API overview, then
  fails if generated files were not committed;
- type-checks the CLI, public typedef entry point, and test runner;
- runs the in-memory unit and integration suite;
- compiles `bin/build`; and
- uses that compiled binary to check and collect Kern's generated artifacts; and
- uses that compiled binary to check and build `sandbox/default.kern.luau`.

Run the same gate locally before opening a pull request:

```text
rokit install
lute run scripts/generate_modules.luau
lute run scripts/generate_types.luau
lute run scripts/generate_docs.luau
lute run scripts/test.luau
lute run scripts/cd.luau
bin/build check
bin/build build
cd sandbox
../bin/build check
../bin/build build
```

`bin/build` and the sandbox output are ignored, so these commands do not add
build artifacts to a commit.

## Releases

Pushing a tag named `v<version>` starts the [`Release` workflow](../../.github/workflows/release.yml).
It builds native binaries on Linux x86_64, macOS arm64, and Windows x86_64,
uploads each as a workflow artifact, and creates a GitHub release with those
three files attached.

`VERSION` is the single source of truth for the CLI and typedef bundles. Prepare
a release with `lute run scripts/version.luau prepare 0.2.0`; this updates
`VERSION` and regenerates every committed artifact. Review and commit those
changes, then push the matching `v0.2.0` tag. The publish job uses
`scripts/check_release_version.luau` to enforce that match.
Manual dispatch builds and retains the artifacts without publishing a release,
which is useful for testing a release build before creating a tag.

The workflows install the exact tool versions from `rokit.toml`. Dependabot
checks the GitHub Actions dependencies weekly.

---
sidebar_position: 1
---

# CI and releases

kern's automation deliberately uses the same commands available to a project
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
- uses that compiled binary to check and collect kern's generated artifacts; and
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
packages each as a ZIP archive containing `kern` (or `kern.exe`), and creates a
GitHub release with those three archives attached. The release job installs the
pinned Rokit toolchain before it validates the release tag, so its version check
does not depend on a runner's preinstalled Lute.

`VERSION` is the single source of truth for the CLI and typedef bundles. Prepare
a release with `lute run scripts/version.luau prepare 0.2.0`; this updates
`VERSION` and regenerates every committed artifact. Review and commit those
changes, then push the matching `v0.2.0` tag. The publish job uses
`scripts/check_release_version.luau` to enforce that match.
Manual dispatch builds and retains the artifacts without publishing a release,
which is useful for testing a release build before creating a tag.

## Rokit consumers

Rokit resolves kern directly from its GitHub releases. Consumers add this to
their own `rokit.toml`, replacing the version with the release they need:

```toml
[tools]
kern = "ratplier/kern@0.1.1"
```

They then run `rokit install`. Keep the uploaded archive names aligned with the
release matrix (`kern-linux-x86_64.zip`, `kern-darwin-arm64.zip`, and
`kern-windows-x86_64.zip`); those names let Rokit select and extract the
matching binary.

## First deployment

After the GitHub repository is connected to `ratplier/kern`, enable GitHub
Actions with permission to create releases. Prepare the version, commit it, and
push the matching tag:

```text
lute run scripts/version.luau prepare 0.1.1
git tag v0.1.1
git push origin v0.1.1
```

The tag triggers the deployment. Before the first tag, use **Run workflow** on
the Release workflow to confirm all three platform artifacts compile; manual
dispatch deliberately does not create a GitHub release.

The workflows install the exact tool versions from `rokit.toml`. Dependabot
checks the GitHub Actions dependencies weekly.

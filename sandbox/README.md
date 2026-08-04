# kern game-project sandbox

This is a small client/server/shared game layout that demonstrates how Kern fits
into a Rojo-style repository.

```text
components/       Tooling-only lint, transform, resolver, and output components
src/client/       Client entrypoints
src/server/       Server entrypoints
src/shared/       Shared modules
default.project.json  Rojo project artifact copied to output
out/              Generated build output
```

From this directory, run:

```text
kern lint
kern transform --check
kern check
kern build
```

Install the repository toolchain with `rokit install`, then build the executable
with `lute run scripts/cd.luau` from the repository root. It is generated at
`bin/build` and can be placed on your `PATH` as `kern`.

The quality component reports unfinished work and global `print` calls. The
migrations component imports `@shared/logger`, changes `print` to `logger.info`,
and modernizes `wait` to `task.wait`. The output component rewrites `@shared/*`
requires to relative output paths, copies the Rojo project, and excludes specs.

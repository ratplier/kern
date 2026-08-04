---
sidebar_position: 5
---

# CLI workflows

Kern discovers `default.kern.luau` from the current directory upward. Use
`--project path/to/default.kern.luau` to select one explicitly.

```text
bin/build lint --fix
bin/build transform --check src
bin/build check
bin/build build
```

Use `check` as the CI gate: it runs linting, syntax/module/finalize transforms,
require resolution, cycle detection, output-path validation, and output planning
without changing the build directory. Run `build` in the release or packaging
step only after `check` succeeds.

Run `bin/build setup` after replacing the binary when editor typedefs need to be
refreshed. It is intentionally separate from normal project commands.

See [CI and releases](../maintainers/ci-cd.md) for the repository workflows and matching local
verification commands.

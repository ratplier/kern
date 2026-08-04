# kern

> [!WARNING]
> kern's implementation, tests, documentation, and automation were produced by
> Codex. Project direction and planning remain the maintainer's work.

kern is a pure-Luau project tool for linting, AST-based transforms, require
rewriting, and deterministic build output. It is designed for game repositories:
the project configuration is Luau, the executable is a platform-specific binary,
and output selection can preserve scripts and non-Luau assets for Rojo workflows.

Build the local executable with `lute run scripts/cd.luau`. The generated binary
is always `bin/build` and is intentionally ignored by Git.

Read the [documentation](docs/index.md) for the generated API overview and
task-oriented guides.

## Toolchain

kern pins its development toolchain in [`rokit.toml`](rokit.toml). Install
[Rokit](https://github.com/rojo-rbx/rokit), then run this once after cloning or
when `rokit.toml` changes:

```text
rokit install
```

This installs the pinned `lute` executable used by every script below. Do not
rely on an arbitrary global Lute version.

## Install kern with Rokit

Once a tagged release exists under `ratplier/kern`, add kern to a consumer
project's `rokit.toml`:

```toml
[tools]
kern = "ratplier/kern@0.1.1"
```

Run `rokit install`, then use `kern` from that project's managed toolchain.
Each release contains a platform-named ZIP archive with the `kern` executable
inside. Rokit selects and extracts the native Linux x86_64, macOS arm64, or
Windows x86_64 archive automatically.

## Versioning

[`VERSION`](VERSION) is the single release-version source. To prepare a release
without manually updating generated bundles, run:

```text
lute run scripts/version.luau prepare 0.2.0
```

Review and commit the updated `VERSION`, generated modules, typedef bundle, and
API overview. Then push the matching `v0.2.0` tag to publish native artifacts.
The Release workflow installs its pinned toolchain before checking the tag and
attaching those artifacts to GitHub Releases.

## Start a project

Run `kern init` in the repository root. It creates `default.kern.luau`, `.luaurc`,
and `src/init.luau`. Then use:

```text
kern lint
kern transform --check
kern check
kern build
```

Run `kern setup` after replacing the executable if an existing repository needs
its editor typedefs refreshed. Normal project commands never modify `~/.kern`.

## Test kern

kern's test suite uses the bundled describe/it assertion framework and runs
entirely against in-memory project fixtures:

```text
lute run scripts/test.luau
```

Tests are organized by responsibility in `tests/unit`, `tests/integration`, and
`tests/helpers`. The integration tests cover project transforms, lint fixes,
module graphs, output filtering, and failure containment.

`check` runs the complete pipeline without modifying output. `build` writes the
configured output directory only after linting, transforms, module resolution,
and graph validation succeed.

## A practical project

```luau
const kern = require("@kern")

const no_prints = kern.lint("no_prints", {
	severity = "warn",
	run = function(tree, context)
		for call in kern.calls.global("print"):visit(tree) do
			context:report(call.span, "Use the game logger instead")
		end
	end,
})

const print_to_logger = kern.transform("print_to_logger", {
	run = function(tree, context)
		for call in kern.calls.global("print"):visit(tree) do
			if call.callee_node ~= nil then
				context:ensure_import("logger", "@shared/logger")
				context:replace(call.callee_node, kern.quote("logger.info"))
			end
		end
	end,
})

return kern.project({
	root = ".",
	entries = { "src/server/init.server.luau", "src/client/init.client.luau" },
	include = { "src/**/*.luau", "src/*.luau" },
	components = {
		no_prints,
		print_to_logger,
		kern.require({ aliases = { ["@shared"] = "src/shared" } }),
		kern.output.directory({
			path = "build",
			include = { "src", "default.project.json" },
			exclude = { "src/**/*.spec.luau" },
		}),
	},
})
```

Use `kern.quote` for a statement, expression, or block generated from source.
`context:replace` and `context:remove` require nodes, keeping normal transforms
anchored to syntax. `replace_range` and `remove_range` are available for the
rare intentionally raw source edit.

## Production workflow

Use `kern check` in CI and before publishing. It validates diagnostics, module
resolution, cycles, transform output after every phase, and safe output paths
without changing the build directory. Run `kern build` only when the check is
clean. A failing custom rule is reported as a `rule_error`; no edits from that
failing transform are applied.

## kern checks kern

This repository has its own [`default.kern.luau`](default.kern.luau) project.
It recursively analyzes kern's source, scripts, tests, typedefs, sandbox, and
tooling components; `kern check` validates the complete self-project without
writing files. `kern build` collects only derived artifacts—the embedded module
and typedef bundles plus generated API JSON and Markdown—into ignored
`generated`. It does not copy source, components, tests, sandbox files, or CI
configuration.

The self-project uses an import-free core entrypoint, so self-packaging does not
need alias rewriting or Lute's host-only `@std` modules. kern's compiled binary
and the sandbox project remain the end-to-end runtime validation in CI.

---
sidebar_position: 4
---

# Output and Rojo

Use `source_root` to emit one source tree directly into an output directory. Use
`include` and `exclude` when a build needs multiple folders or artifacts such as
a Rojo project file.

```luau
kern.output.directory({
	path = "out",
	include = { "src", "default.project.json" },
	exclude = {
		"src/**/*.spec.luau",
		"src/**/.luaurc",
	},
})
```

Directory includes recurse. Output excludes its own target directory
automatically, and rejects paths that escape the project root. The require
resolver rewrites supported string requires to relative output paths during
builds.

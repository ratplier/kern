---
sidebar_position: 2
---

# Projects and components

A project names its entrypoints and combines components. A component is a
reusable group of lint rules, transforms, a require resolver, or an output
emitter. Keep components outside `src` when they are tooling-only.

```luau
const kern = require("@kern")
const quality = require("./components/quality")
const output = require("./components/output")

return kern.project({
	root = ".",
	entries = { "src/server/main.server.luau" },
	include = { "src/**/*.luau", "src/*.luau" },
	components = { quality, output },
})
```

Projects lint every matching `include` file. Builds begin at `entries`, resolve
their reachable module graph, then emit the selected artifacts. This lets you
lint broad source trees while building only runtime-reachable code.

Kern dogfoods this model in the repository's
[`default.kern.luau`](../../default.kern.luau): its recursive `**/*.luau` include
covers the real tooling tree, while the core entrypoint keeps the self-build
independent of Lute's host-only runtime modules.

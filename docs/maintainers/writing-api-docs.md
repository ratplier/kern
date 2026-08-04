---
sidebar_position: 2
---

# Writing API docs

Kern compiles public typedef comments into [`api.json`](../api/api.json), then
renders that data as Docusaurus-compatible Markdown. Use a `--[=[ ... ]=]`
comment immediately before an exported type, function, or assigned API value.

Use a block comment for descriptions with paragraphs, lists, and examples:

```luau
--[=[
	@within Project

	Creates a project from source paths and reusable components.

	@param config Source paths, components, filesystem, output, and diagnostics
	@return The configured project
]=]
function project.new(config)
```

`@within` selects an API section. `@param` and `@return` become structured JSON
fields; ordinary Markdown becomes the declaration description.

Regenerate both the JSON and rendered pages with:

```text
lute run scripts/generate_docs.luau
```

The JSON schema is intentionally small—sections, entries, signatures,
descriptions, parameters, return text, and source paths—so a Docusaurus plugin
can consume `api.json` later without reparsing Luau. Run
`generate_api_json.luau` or `render_api_docs.luau` directly to execute one stage.

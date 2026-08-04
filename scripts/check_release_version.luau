--!strict

const file_system = require("@std/fs")
const process = require("@std/process")

const tag = process.args[2]
if tag == nil or tag == "" then
	error("kern: expected a release tag argument")
end

const version = file_system.readFileToString("VERSION"):gsub("^%s+", ""):gsub("%s+$", "")

if tag ~= `v{version}` then
	error(`kern: release tag '{tag}' does not match VERSION 'v{version}'`)
end

print(`kern: release tag {tag} matches the embedded version`)

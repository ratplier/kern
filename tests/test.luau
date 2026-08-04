--!strict
-- Basic test framework adapted from @ratplier's test API.

export type Info = (...string) -> ()
export type TestApi = {
	stop: () -> { passed: number, failed: number },
	focus: (...string) -> (),
}
export type Test = TestApi & {
	check: (func: () -> ()) -> number,
	describe: (name: string, func: () -> ()) -> (),
	dictionary: (name: string, func: (TestApi) -> ()) -> () -> (),
	it: (description: string, func: (Info) -> ()) -> (),
	type_equal: (a: any, b: any) -> boolean,
	equal: (a: any, b: any) -> boolean,
	assert: (condition: any?, message: string?) -> (),
	assert_eq: (a: any, b: any, message: string?) -> (),
	assert_type_eq: (a: any, b: any, message: string?) -> (),
	assert_error: (func: () -> (), expected: string?) -> (),
	run: (name: string?) -> () -> { passed: number, failed: number },
}

local test = {} :: Test

local test_stats = { passed = 0, failed = 0 }
local test_indent = ""
local focused_tests: { string } = {}

const function is_focused(name: string): boolean
	if #focused_tests == 0 then
		return true
	end

	for _, pattern in focused_tests do
		if name:find(pattern) ~= nil then
			return true
		end
	end

	return false
end

const function create_info(result_table: { string }): Info
	local has_added = false
	return function(...: string)
		const count = select("#", ...)
		if count == 0 then
			return
		end

		for index = 1, count - 1 do
			const message = select(index, ...)
			table.insert(result_table, if has_added then 1 else #result_table + 1, `{test_indent}   |   {message}`)
		end

		const last_message = select(count, ...)
		table.insert(result_table, if has_added then 1 else #result_table + 1, `{test_indent}   └─> {last_message}`)
		has_added = true
	end
end

function test.check(func: () -> ()): number
	const start_time = os.clock()
	func()
	return (os.clock() - start_time) * 1000
end

function test.describe(name: string, func: () -> ())
	if not is_focused(name) then
		return
	end

	print(`{test_indent}📋 {name}`)
	const old_indent = test_indent
	test_indent ..= "  "
	func()
	test_indent = old_indent
end

function test.dictionary(name: string, func: (TestApi) -> ()): () -> ()
	local interface = {} :: TestApi
	interface.focus = function(...: string)
		local values = { ... }
		table.move(values, 1, #values, #focused_tests + 1, focused_tests)
	end

	return function()
		print(`{test_indent}📖 {name}`)
		const old_indent = test_indent
		test_indent ..= "  "
		interface.stop = test.run()
		func(interface)
		test_indent = old_indent
	end
end

function test.it(description: string, func: (Info) -> ())
	local result = {}
	const info = create_info(result)
	const success, error_value = pcall(func, info)

	if success then
		test_stats.passed += 1
		print(`{test_indent}✅ {description}`)
		for _, line in result do
			print(line)
		end
		return
	end

	test_stats.failed += 1
	print(`{test_indent}❌ {description}`)
	info(tostring(error_value))
	for _, line in result do
		print(line)
	end
end

function test.type_equal(a: any, b: any): boolean
	if typeof(a) ~= typeof(b) then
		return false
	end
	if typeof(a) ~= "table" then
		return true
	end

	for key, value in a do
		if not test.type_equal(value, b[key]) then
			return false
		end
	end
	for key in b do
		if a[key] == nil then
			return false
		end
	end
	return true
end

function test.equal(a: any, b: any): boolean
	if not test.type_equal(a, b) then
		return false
	end
	if typeof(a) ~= "table" then
		return a == b
	end

	for key, value in a do
		if not test.equal(value, b[key]) then
			return false
		end
	end
	return true
end

function test.assert(condition: any?, message: string?)
	if condition == nil or condition == false then
		error(message or "assertion failed", 0)
	end
end

function test.assert_eq(a: any, b: any, message: string?)
	test.assert(test.equal(a, b), message)
end

function test.assert_type_eq(a: any, b: any, message: string?)
	test.assert(test.type_equal(a, b), message)
end

function test.assert_error(func: () -> (), expected: string?)
	const success, result = pcall(func)
	test.assert(not success, "expected function to throw")
	if expected ~= nil then
		test.assert(tostring(result):find(expected, 1, true) ~= nil, `expected error containing '{expected}'`)
	end
end

function test.run(name: string?): () -> { passed: number, failed: number }
	test_stats = { passed = 0, failed = 0 }
	const suite_name = name or "test"
	const total_start_time = os.clock()

	return function()
		const elapsed = os.clock() - total_start_time
		print(`📝 {suite_name}: {test_stats.passed} passed, {test_stats.failed} failed in {tostring(elapsed)}s`)
		return test_stats
	end
end

function test.focus(...: string)
	local values = { ... }
	table.move(values, 1, #values, #focused_tests + 1, focused_tests)
end

test.stop = function()
	return test_stats
end

return test

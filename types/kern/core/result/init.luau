--!nocheck

--[=[
	@within Result

	A successful operation result.
]=]
export type Ok<Value> = { ok: true, value: Value }

--[=[
	@within Result

	A failed operation result.
]=]
export type Err<Failure> = { ok: false, error: Failure }

--[=[
	@within Result

	A result that must be narrowed through its `ok` field.
]=]
export type Result<Value, Failure> = Ok<Value> | Err<Failure>

return {}

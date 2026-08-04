--!strict

export type Ok<T> = { ok: true, value: T }
export type Err<E> = { ok: false, error: E }

export type Result<T, E> = Ok<T> | Err<E>

const result = {}

function result.ok<T>(value: T): Ok<T>
	return {
		ok = true,
		value = value,
	}
end

function result.err<E>(error: E): Err<E>
	return {
		ok = false,
		error = error,
	}
end

return result

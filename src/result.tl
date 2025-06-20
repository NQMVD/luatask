-- Result system for task execution with optional return handling
-- Tasks can succeed by default, return values, or use error()/assert() to fail

local record Result
    SUCCESS: string
    FAIL: string
end

Result.SUCCESS = "SUCCESS"
Result.FAIL = "FAIL"

-- Helper function to check if a result is successful
function Result.is_success(result: string): boolean
    return result == Result.SUCCESS
end

-- Helper function to check if a result is a failure
function Result.is_fail(result: string): boolean
    return result == Result.FAIL
end

-- Helper function to validate result values
function Result.is_valid(result: string): boolean
    return result == Result.SUCCESS or result == Result.FAIL
end

-- Run a task function with optional return handling
-- Tasks succeed by default unless they explicitly return FAIL or use error()/assert()
function Result.run_task(task_fn: function, ...: any): boolean, string, {any}
    local call_results = {pcall(task_fn, ...)}
    local success = call_results[1]

    -- If pcall failed (error() or assert() was called)
    if not success then
        local error_msg = tostring(call_results[2]) or "Unknown error"
        return false, Result.FAIL, {error_msg}
    end

    -- Task executed successfully, check return value
    local first_return = call_results[2]

    -- If no return value, default to success
    if first_return == nil then
        return true, Result.SUCCESS, {}
    end

    -- If returned a Result value, use it
    if type(first_return) == "string" and Result.is_valid(first_return as string) then
        local additional_values = {}
        for i = 3, #call_results do
            table.insert(additional_values, call_results[i])
        end
        return true, first_return as string, additional_values
    end

    -- If returned other values, assume success and collect all returns
    local return_values = {}
    for i = 2, #call_results do
        table.insert(return_values, call_results[i])
    end
    return true, Result.SUCCESS, return_values
end

-- Create a result with error message
function Result.error(message: string): boolean, string, {any}
    return false, Result.FAIL, {message}
end

-- Create a successful result with optional values
function Result.success(...: any): boolean, string, {any}
    local values = {...}
    return true, Result.SUCCESS, values
end

return Result

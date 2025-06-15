-- Result enum for task execution status
-- Provides type-safe result handling for task execution

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

return Result

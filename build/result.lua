


local Result = {}




Result.SUCCESS = "SUCCESS"
Result.FAIL = "FAIL"


function Result.is_success(result)
   return result == Result.SUCCESS
end


function Result.is_fail(result)
   return result == Result.FAIL
end


function Result.is_valid(result)
   return result == Result.SUCCESS or result == Result.FAIL
end

return Result

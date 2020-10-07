local function toThrow(fn: () -> any, errorString: string?)
	local ok, result = pcall(fn)

	if not ok then
		if errorString ~= nil then
			local resultErrorString = nil
			if typeof(result) == "string" then
				resultErrorString = result
			elseif typeof(result) == "table" and typeof(result.message) == "string" then
				resultErrorString = result.message
			end

			if resultErrorString == nil then
				return {
					pass = false,
					message = string.format(
						"Matcher Error:\n" ..
						"Expected function to throw a string or an Error " ..
						"object, but it threw an error of type '%s'.\nYou " ..
						"may wish to use `pcall` instead and run custom " ..
						"expectations on the returned error",
						typeof(result)
					),
				}
			end
			if resultErrorString:find(errorString) then
				return {
					pass = true,
					message = string.format(
						"Expected function not to throw with '%s'",
						errorString
					),
				}
			end

			return {
				pass = false,
				message = string.format(
					"Expected function to throw with '%s'",
					errorString
				),
			}
		end

		return {
			pass = true,
			message = "Expected function not to throw",
		}
	end

	return {
		pass = false,
		message = "Expected function to throw",
	}
end

return toThrow
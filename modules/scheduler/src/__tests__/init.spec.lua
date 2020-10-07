--[[
	Defines expectation extensions, including Scheduler-specific ones. This code
	is mostly based on:
	https://github.com/facebook/react/blob/47ff31a77add22bef54aaed9d4fb62d5aa693afd/scripts/jest/matchers/schedulerTestMatchers.js
]]
-- FIXME: roblox-cli has special, hard-coded types for TestEZ that break when we
--use custom matchers added via `expect.extend`
--!nocheck
return function()
	local Workspace = script.Parent.Parent.Parent
	local RobloxJest = require(Workspace.RobloxJest)

	function captureAssertion(fn)
		-- Trick to use a TestEZ expectation matcher inside another Jest
		-- matcher. `fn` contains an assertion; if it throws, we capture the
		-- error and return it, so the stack trace presented to the user points
		-- to the original assertion in the test file.
		local ok, result = pcall(fn)

		if not ok then
			return {
				pass = false,
				message = result.message,
			}
		end

		return { pass = true }
	end

	beforeAll(function()
		local function assertYieldsWereCleared(scheduler)
			local actualYields = scheduler.unstable_clearYields()
			if #actualYields ~= 0 then
				error("Log of yielded values is not empty. " ..
					"Call expectToHaveYielded(scheduler, ...) first.", 3)
			end
		end

		local function expectToFlushAndYield(scheduler, expectedYields)
			assertYieldsWereCleared(scheduler)
			scheduler.unstable_flushAllWithoutAsserting()
			local actualYields = scheduler.unstable_clearYields()

			return captureAssertion(function()
				expect(actualYields).toEqual(expectedYields)
			end)
		end

		local function expectToFlushAndYieldThrough(scheduler, expectedYields)
			assertYieldsWereCleared(scheduler)
			scheduler.unstable_flushNumberOfYields(#expectedYields)
			local actualYields = scheduler.unstable_clearYields()

			return captureAssertion(function()
				expect(actualYields).toEqual(expectedYields)
			end)
		end

		local function expectToFlushWithoutYielding(scheduler)
			return expectToFlushAndYield(scheduler, {})
		end

		local function expectToFlushExpired(scheduler, expectedYields)
			assertYieldsWereCleared(scheduler)
			scheduler.unstable_flushExpired()
			local actualYields = scheduler.unstable_clearYields()

			return captureAssertion(function()
				expect(actualYields).toEqual(expectedYields)
			end)
		end

		local function expectToHaveYielded(scheduler, expectedYields)
			local actualYields = scheduler.unstable_clearYields()

			return captureAssertion(function()
				expect(actualYields).toEqual(expectedYields)
			end)
		end

		expect.extend({
			toEqual = RobloxJest.Matchers.toEqual,
			toThrow = RobloxJest.Matchers.toThrow,
			toFlushAndYield = expectToFlushAndYield,
			toFlushAndYieldThrough = expectToFlushAndYieldThrough,
			toFlushWithoutYielding = expectToFlushWithoutYielding,
			toFlushExpired = expectToFlushExpired,
			toHaveYielded = expectToHaveYielded,
		})
	end)
end
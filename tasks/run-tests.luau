--!strict
--[[
	Runs inside a Roblox server through Open Cloud Luau Execution
	(see lune/run-tests.luau). Erroring marks the task as FAILED, which fails
	the CI job.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local include = ReplicatedStorage:WaitForChild("rbxts_include")
local Jest = require(include.node_modules["@rbxts-js"].Jest) :: any

local projects = {
	ReplicatedStorage:WaitForChild("TS"),
	ServerScriptService:WaitForChild("TS"),
}

local status, result = Jest.runCLI(ReplicatedStorage, {
	ci = true,
	verbose = true,
	passWithNoTests = true,
}, projects):awaitStatus()

if status ~= "Resolved" then
	error(`Jest did not finish: {result}`)
end

local summary = result.results
if summary.numFailedTests > 0 or summary.numFailedTestSuites > 0 or summary.numRuntimeErrorTestSuites > 0 then
	error(`{summary.numFailedTests} test(s) failed across {summary.numFailedTestSuites} suite(s)`)
end

return {
	passed = summary.numPassedTests,
	total = summary.numTotalTests,
}

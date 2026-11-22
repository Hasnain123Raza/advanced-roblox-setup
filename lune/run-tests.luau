--!strict
--[[
	Runs the Jest suite inside a real Roblox server through Open Cloud
	Luau Execution:

	  1. Uploads the test place (built from test.project.json) as a new
	     saved version of ROBLOX_TEST_PLACE_ID.
	  2. Runs tasks/run-tests.luau against that version.
	  3. Prints the logs and exits non-zero if any test failed.

	Usage:
	  lune run run-tests [place file]   (default: build/test.rbxl)

	Needs ROBLOX_API_KEY, ROBLOX_TEST_UNIVERSE_ID and ROBLOX_TEST_PLACE_ID.
	The API key needs the `universe.places:write` and
	`universe.place.luau-execution-session:write` permissions.
]]

local fs = require("@lune/fs")
local net = require("@lune/net")
local process = require("@lune/process")
local serde = require("@lune/serde")
local task = require("@lune/task")

local env = require("./lib/env")

local API = "https://apis.roblox.com"
local TASK_SCRIPT = "tasks/run-tests.luau"
local POLL_SECONDS = 3
local TIMEOUT_SECONDS = 300

local placeFile = process.args[1] or "build/test.rbxl"
local apiKey = env.require("ROBLOX_API_KEY")
local universeId = env.require("ROBLOX_TEST_UNIVERSE_ID")
local placeId = env.require("ROBLOX_TEST_PLACE_ID")

local function fail(message: string): never
	print(`[error] {message}`)
	return process.exit(1)
end

local function request(method: net.HttpMethod, url: string, body: string?, contentType: string?): any
	local headers: net.HttpHeaderMap = { ["x-api-key"] = apiKey }
	if contentType then
		headers["content-type"] = contentType
	end

	local params: net.FetchParams = { method = method, url = url, body = body, headers = headers }
	for attempt = 1, 3 do
		local ok, response = pcall(net.request, params)
		if ok and response.ok then
			return serde.decode("json", response.body)
		end

		local retryable = not ok or response.statusCode == 429 or response.statusCode >= 500
		if not retryable or attempt == 3 then
			local detail = if ok then `HTTP {response.statusCode}: {response.body}` else tostring(response)
			return fail(`{method} {url} failed ({detail})`)
		end
		task.wait(attempt * 2)
	end
	return fail("unreachable")
end

if not fs.isFile(placeFile) then
	fail(`{placeFile} not found. Run \`npm run build:test-place\` first.`)
end

print(`Uploading {placeFile} to place {placeId}...`)
local upload = request(
	"POST",
	`{API}/universes/v1/{universeId}/places/{placeId}/versions?versionType=Saved`,
	fs.readFile(placeFile),
	"application/octet-stream"
)
local version = upload.versionNumber
print(`Uploaded as version {version}.`)

print("Starting Luau execution task...")
local created = request(
	"POST",
	`{API}/cloud/v2/universes/{universeId}/places/{placeId}/versions/{version}/luau-execution-session-tasks`,
	serde.encode("json", { script = fs.readFile(TASK_SCRIPT), timeout = `{TIMEOUT_SECONDS}s` }),
	"application/json"
)

local current = created
while current.state == "QUEUED" or current.state == "PROCESSING" do
	task.wait(POLL_SECONDS)
	current = request("GET", `{API}/cloud/v2/{created.path}`)
end

local logs = request("GET", `{API}/cloud/v2/{created.path}/logs`)
for _, page in logs.luauExecutionSessionTaskLogs or {} do
	for _, message in page.messages or {} do
		print(message)
	end
end

if current.state ~= "COMPLETE" then
	local reason = if current.error then current.error.message else "no error message"
	fail(`Tests failed (task state {current.state}): {reason}`)
end

print("All tests passed.")

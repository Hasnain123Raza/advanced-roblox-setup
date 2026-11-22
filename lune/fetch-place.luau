--!strict
--[[
	Pulls Studio-authored content out of a place file and saves it under
	`place/`, so it can be committed and synced back in with Rojo.

	By default the captured folders are saved — `ReplicatedStorage.Models`
	and `ServerStorage.Models` — and the whole `Workspace`, `Lighting`, and
	`TextChatService` services are captured — see `SERVICES` below.

	Usage:
	  lune run fetch-place                  Download the place in ROBLOX_PLACE_ID
	  lune run fetch-place --place-id <id>  Download a specific place
	  lune run fetch-place --file <path>    Read a local .rbxl or .rbxlx file

	Downloading uses the Roblox login cookie that Roblox Studio stores on this
	machine, so you need to be logged in to Studio.
]]

local fs = require("@lune/fs")
local net = require("@lune/net")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local env = require("./lib/env")

local PLACE_DIR = "place"

-- Services saved whole, one .rbxm file each. Workspace is captured as a
-- single `place/Workspace.rbxm` covering the entire service.
--
-- Onboarding another service (e.g. "ReplicatedFirst") requires BOTH of these in sync:
--   1. Add the name to this list.
--   2. Add a node to the top level of `tree` in default.project.json:
--      "ReplicatedFirst": { "$path": "place/ReplicatedFirst.rbxm" }
-- Then run `npm run place:fetch` and commit place/ReplicatedFirst.rbxm.
-- Full instructions: AGENTS.md ("Studio content pipeline").
local SERVICES: { string } = { "Workspace", "Lighting", "TextChatService" }

-- Folders whose children are saved as separate .rbxm files.
local MODEL_FOLDERS = {
	{ service = "ReplicatedStorage", folder = "Models", dir = `{PLACE_DIR}/replicated-models` },
	{ service = "ServerStorage", folder = "Models", dir = `{PLACE_DIR}/server-models` },
}

local USAGE = [[
Usage:
  lune run fetch-place                  Download the place in ROBLOX_PLACE_ID
  lune run fetch-place --place-id <id>  Download a specific place
  lune run fetch-place --file <path>    Read a local .rbxl or .rbxlx file]]

local function fail(message: string): never
	print(`[error] {message}\n\n{USAGE}`)
	return process.exit(1)
end

type Source = { kind: "file", path: string } | { kind: "id", id: string }

local function parseArgs(args: { string }): Source
	if #args == 0 then
		return { kind = "id", id = env.require("ROBLOX_PLACE_ID") }
	end
	if args[1] == "--help" or args[1] == "-h" then
		print(USAGE)
		return process.exit(0)
	end
	if #args ~= 2 then
		return fail("Expected a flag and a value.")
	end

	local flag, value = args[1], args[2]
	if flag == "--place-id" then
		if not string.match(value, "^%d+$") then
			return fail(`--place-id expects a numeric ID, got '{value}'.`)
		end
		return { kind = "id", id = value }
	elseif flag == "--file" then
		if not string.match(value, "%.rbxlx?$") then
			return fail(`--file expects a .rbxl or .rbxlx path, got '{value}'.`)
		end
		if not fs.isFile(value) then
			return fail(`File not found: '{value}'.`)
		end
		return { kind = "file", path = value }
	end
	return fail(`Unknown flag '{flag}'.`)
end

local function downloadPlace(placeId: string): string
	local cookie = roblox.getAuthCookie()
	if cookie == nil then
		return fail("No Roblox login cookie found. Log in to Roblox Studio on this machine, or use --file.")
	end

	local params: net.FetchParams = {
		url = "https://assetdelivery.roblox.com/v1/asset/",
		headers = { Cookie = cookie :: string },
		query = { id = placeId },
	}
	local response = net.request(params)
	if not response.ok then
		return fail(`Download failed with HTTP {response.statusCode}: {response.body}`)
	end
	return response.body
end

local function clearFolder(dir: string)
	if not fs.isDir(dir) then
		fs.writeDir(dir)
		return
	end
	for _, name in fs.readDir(dir) do
		if string.match(name, "%.rbxmx?$") then
			fs.removeFile(`{dir}/{name}`)
		end
	end
end

local source = parseArgs(process.args)
local content: string
if source.kind == "file" then
	print(`Reading {source.path}...`)
	content = fs.readFile(source.path)
else
	print(`Downloading place {source.id}...`)
	content = downloadPlace(source.id)
end

local game = roblox.deserializePlace(content)

for _, serviceName in SERVICES do
	print(`Saving {serviceName}...`)
	local service = game:GetService(serviceName)
	fs.writeFile(`{PLACE_DIR}/{serviceName}.rbxm`, roblox.serializeModel({ service }))
end

for _, entry in MODEL_FOLDERS do
	clearFolder(entry.dir)
	local folder = game:GetService(entry.service):FindFirstChild(entry.folder)
	if folder == nil then
		print(`Skipping {entry.service}.{entry.folder}: not found in the place.`)
		continue
	end
	for _, child in folder:GetChildren() do
		print(`Saving {entry.service}.{entry.folder}.{child.Name}...`)
		fs.writeFile(`{entry.dir}/{child.Name}.rbxm`, roblox.serializeModel({ child }))
	end
end

print("Done.")

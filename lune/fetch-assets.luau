local net = require("@lune/net")
local roblox = require("@lune/roblox")
local fs = require("@lune/fs")
local process = require("@lune/process")

local HELP = [[
Usage:
  lune run ./lune/fetch-assets
  lune run ./lune/fetch-assets --place-id <id>
  lune run ./lune/fetch-assets --file <path>

Options:
  --place-id <id>   Download place from Roblox using a place ID
  --file <path>     Read a local .rbxl or .rbxlx place file
  --help            Show this message

When no arguments are provided, LUNE_PLACE_ID will be read from .env
]]

local function showHelp()
	print(HELP)
end

local function exitWithError(msg: string)
	print(`[Error] {msg}\n`)
	showHelp()
	process.exit(1)
end

local function parseArgs(): (string?, string?)
	local args = process.args

	if #args == 0 then
		return nil, nil
	end

	if #args == 1 and args[1] == "--help" then
		showHelp()
		process.exit(0)
	end

	if #args == 1 then
		exitWithError(`Unexpected argument: '{args[1]}'`)
	end

	if #args == 2 then
		local flag, value = args[1], args[2]

		if flag == "--place-id" then
			if not value:match("^%d+$") then
				exitWithError(`--place-id expects a numeric ID, got '{value}'`)
			end
			return "id", value
		elseif flag == "--file" then
			if not value:match("%.rbxlx?$") then
				exitWithError(`--file expects a .rbxl or .rbxlx path, got '{value}'`)
			end
			if not fs.isFile(value) then
				exitWithError(`File not found: '{value}'`)
			end
			return "file", value
		else
			exitWithError(`Unknown flag: '{flag}'`)
		end
	end

	exitWithError("Too many arguments provided")
	return nil, nil
end

local function readEnvPlaceId(): string?
	if not fs.isFile(".env") then return nil end
	for line in fs.readFile(".env"):gmatch("[^\r\n]+") do
		if line:match("^%s*#") or line:match("^%s*$") then continue end
		local key, value = line:match("^%s*([^=]+)%s*=%s*(.-)%s*$")
		if key and value then
			value = value:match('^"(.*)"$') or value:match("^'(.*)'$") or value
			if key == "LUNE_PLACE_ID" then return value end
		end
	end
	return nil
end

local function downloadPlaceAsset(placeId: string): string
	local cookie = roblox.getAuthCookie()
	assert(cookie, "Failed to get auth cookie")

	local result = net.request({
		url = "https://assetdelivery.roblox.com/v1/asset/",
		headers = {
			Cookie = cookie,
		},
		query = {
			id = placeId,
		},
	})

	assert(result.ok, result.body)

	return result.body
end

local argType, argValue = parseArgs()
local content: string

if argType == "file" then
	print(`Reading place from {argValue}...`)
	content = fs.readFile(argValue :: string)
elseif argType == "id" then
	print(`Downloading place {argValue}...`)
	content = downloadPlaceAsset(argValue :: string)
else
	local placeId = readEnvPlaceId()
	if not placeId then
		exitWithError("No --place-id or --file argument provided, and LUNE_PLACE_ID not found in .env")
	end
	print(`Downloading place {placeId} from .env...`)
	content = downloadPlaceAsset(placeId :: string)
end

local game = roblox.deserializePlace(content)

local workspace = game:GetService("Workspace")
local lighting = game:GetService("Lighting")
local replicatedStorage = game:GetService("ReplicatedStorage")
local serverStorage = game:GetService("ServerStorage")

print("Saving Workspace...")
fs.writeFile("./assets/Workspace.rbxm", roblox.serializeModel({ workspace }))

print("Saving Lighting...")
fs.writeFile("./assets/Lighting.rbxm", roblox.serializeModel({ lighting }))

print("Cleaning ReplicatedStorage assets...")
for _, file in fs.readDir("./assets/replicated-storage-models") do
	if file ~= ".gitkeep" then
		fs.removeFile(`./assets/replicated-storage-models/{file}`)
	end
end
print("Saving ReplicatedStorage assets...")
for _, child in replicatedStorage.Models:GetChildren() do
	print(`  Saving {child.Name}...`)
	fs.writeFile(`./assets/replicated-storage-models/{child.Name}.rbxm`, roblox.serializeModel({ child }))
end

print("Cleaning ServerStorage assets...")
for _, file in fs.readDir("./assets/server-storage-models") do
	if file ~= ".gitkeep" then
		fs.removeFile(`./assets/server-storage-models/{file}`)
	end
end
print("Saving ServerStorage assets...")
for _, child in serverStorage.Models:GetChildren() do
	print(`  Saving {child.Name}...`)
	fs.writeFile(`./assets/server-storage-models/{child.Name}.rbxm`, roblox.serializeModel({ child }))
end

print("Done!")
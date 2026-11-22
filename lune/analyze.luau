--!strict
--[[
	Type checks every hand-written Luau file with luau-lsp:

	  * lune/   as plain Luau, with Lune's type definitions (from .luaurc)
	  * tasks/  as Roblox code, with Roblox's type definitions and a Rojo
	            sourcemap of the test place

	Roblox's type definitions are downloaded once per luau-lsp version into
	.cache/.

	Usage:
	  lune run analyze
]]

local fs = require("@lune/fs")
local net = require("@lune/net")
local process = require("@lune/process")

local CACHE_DIR = ".cache"
local SOURCEMAP = `{CACHE_DIR}/sourcemap.json`

-- Same solver Roblox Studio uses.
local SOLVER_FLAG = "--flag:LuauSolverV2=true"

local function run(program: string, args: { string }): boolean
	local result = process.exec(program, args, { stdio = "inherit" })
	return result.ok
end

local function capture(program: string, args: { string }): string
	local result = process.exec(program, args)
	if not result.ok then
		print(`[error] {program} {table.concat(args, " ")} failed:\n{result.stderr}`)
		process.exit(1)
	end
	return result.stdout
end

local function robloxDefinitions(): string
	local version = string.match(capture("luau-lsp", { "--version" }), "[%d%.]+")
	if version == nil then
		print("[error] Could not read the luau-lsp version.")
		return process.exit(1)
	end

	local path = `{CACHE_DIR}/globalTypes-{version}.d.luau`
	if fs.isFile(path) then
		return path
	end

	print(`Downloading Roblox type definitions for luau-lsp {version}...`)
	local response =
		net.request(`https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/{version}/scripts/globalTypes.d.luau`)
	if not response.ok then
		print(`[error] Download failed with HTTP {response.statusCode}.`)
		return process.exit(1)
	end
	fs.writeFile(path, response.body)
	return path
end

if not fs.isDir(CACHE_DIR) then
	fs.writeDir(CACHE_DIR)
end

local definitions = robloxDefinitions()
capture("rojo", { "sourcemap", "test.project.json", "--output", SOURCEMAP })

local luneOk = run("luau-lsp", { "analyze", SOLVER_FLAG, "--platform", "standard", "lune" })
local tasksOk = run("luau-lsp", {
	"analyze",
	SOLVER_FLAG,
	"--platform",
	"roblox",
	`--definitions=@roblox={definitions}`,
	"--sourcemap",
	SOURCEMAP,
	"tasks",
})

if not (luneOk and tasksOk) then
	process.exit(1)
end
print("Luau analysis passed.")

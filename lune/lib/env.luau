--!strict
--[[
	Reads configuration from the process environment, falling back to a
	`.env` file in the working directory. Real environment variables win, so
	CI can set values without a `.env` file.
]]

local fs = require("@lune/fs")
local process = require("@lune/process")

local cache: { [string]: string }? = nil

local function loadDotEnv(): { [string]: string }
	local values: { [string]: string } = {}
	if not fs.isFile(".env") then
		return values
	end

	for line in string.gmatch(fs.readFile(".env"), "[^\r\n]+") do
		if string.match(line, "^%s*#") or string.match(line, "^%s*$") then
			continue
		end
		local key, value = string.match(line, "^%s*([%w_]+)%s*=%s*(.-)%s*$")
		if key and value then
			values[key] = string.match(value, '^"(.*)"$') or string.match(value, "^'(.*)'$") or value
		end
	end

	return values
end

local env = {}

--- Returns the value of `name`, or nil when it is unset or empty.
function env.get(name: string): string?
	local value = process.env[name]
	if value ~= nil and value ~= "" then
		return value
	end

	if cache == nil then
		cache = loadDotEnv()
	end
	local fromFile = (cache :: { [string]: string })[name]
	if fromFile ~= nil and fromFile ~= "" then
		return fromFile
	end
	return nil
end

--- Returns the value of `name`, or exits with an error explaining how to set it.
function env.require(name: string): string
	local value = env.get(name)
	if value == nil then
		print(`[error] {name} is not set. Add it to .env or export it in your shell.`)
		process.exit(1)
	end
	return value :: string
end

return env

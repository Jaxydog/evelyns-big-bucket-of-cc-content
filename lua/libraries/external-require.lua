---@class evelyn.RequireLib
local module = {
    ---The base URL used to download dependencies.
    defaultUrl =
    'https://raw.githubusercontent.com/Jaxydog/evelyns-big-bucket-of-cc-content/refs/heads/main/lua/libraries',
    ---The directory in which to download files.
    defaultDir = '/.evelyns-libraries',
}

---@class evelyn.RequireOptions
---
---@field public url? string The URL at which to download the file.
---@field public forceGet? boolean Whether to re-download the file even if it's already stored locally.

---Requires a file that is hosted externally.
---
---@generic T The type of the imported module.
---
---@param name string The name of the library.
---@param options? evelyn.RequireOptions Additional options for this require call.
---
---@return T module The required module.
function externalRequire(name, options)
    local baseDir = module.defaultDir
    local file = ('%s/%s.lua'):format(baseDir, name)

    if not package.path:match('/%.evelyns%-libraries/%?%.lua') then
        package.path = package.path .. ';/.evelyns-libraries/?.lua'
    end

    if (options and options.forceGet) or not fs.exists(file) then
        local baseUrl = options and options.url or module.defaultUrl
        local url = ('%s/%s.lua'):format(baseUrl, name)

        fs.makeDir(baseDir)

        if fs.exists(file) then fs.delete(file) end

        assert(shell.run('wget', url, file), 'Failed to download dependency')
    end

    return require(name)
end

return setmetatable(module, {
    __call = function(_, ...) return externalRequire(...) end
})

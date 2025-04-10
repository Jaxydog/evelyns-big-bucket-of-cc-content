---Additional options for importing libraries.
---
---@class evelyn.externalRequire.options
---
---@field public forceDownload? boolean Always re-download the library, even if it's unnecessary.

---Allows code to import libraries from an online repository.
---
---@class evelyn.externalRequire.lib
local module = {}

---The base directory that stores all downloaded libraries.
---
---@private
module.libraryDir = '/.library'

---The file that stores all repositories.
---
---@private
module.repositoryFile = module.libraryDir .. '/.repositories.json'

---Returns a list of saved repositories and their base URLs.
---
---@return table<string, string> repositories The repository list.
local function loadRepositories()
    local file = fs.open(module.repositoryFile, 'r')

    if not file then return {} end

    local text = file.readAll()
    file.close()

    if not text then return {} end

    local list = textutils.unserializeJSON(text, {
        parse_empty_array = false
    }) or {}

    for key, value in pairs(list) do
        assert(type(key) == 'string' and key:match('^[%l][%l%d-]-$'), 'Invalid repository key')
        assert(type(value) == 'string', 'Invalid repository base URL')
    end

    return list
end

---Saves a list of repositories to a file for later loading.
---
---@param list table<string, string> The repository list.
local function saveRepositories(list)
    if not fs.exists(module.libraryDir) then
        fs.makeDir(module.libraryDir)
    end

    local file = assert(fs.open(module.repositoryFile, 'w+'))

    file.write(textutils.serializeJSON(list))
    file.close()
end

---Saves the given repository and its base URL so that files may be required from it.
---
---@param name string The repository's local name. This should match the pattern `^[%l][%l%d-]-$`
---@param baseUrl string The repository's URL.
function module.addRepository(name, baseUrl)
    assert(name:match('^[%l][%l%d-]-$'), 'Invalid repository name')

    local repositories = loadRepositories()

    assert(not repositories[name], 'The given repository already exists')
    assert(http.checkURL(baseUrl))

    repositories[name] = baseUrl:match('^(.-)/*$')

    saveRepositories(repositories)
end

---Removes the given repository from the list so that it may no longer be used.
---
---@param name string The repository's local name. This should match the pattern `^[%l][%l%d-]-$`
function module.removeRepository(name)
    assert(name:match('^[%l][%l%d-]-$'), 'Invalid repository name')

    local repositories = loadRepositories()

    assert(repositories[name], 'The given repository does not exist')

    repositories[name] = nil

    saveRepositories(repositories)
end

---Returns `true` if the given repository has an associated base URL.
---
---@param name string The repository's local name. This should match the pattern `^[%l][%l%d-]-$`
---
---@return boolean exists Whether the repository exists.
function module.hasRepository(name)
    assert(name:match('^[%l][%l%d-]-$'), 'Invalid repository name')

    local repositories = loadRepositories()

    return repositories[name] ~= nil
end

---Returns the directory that contains all downloads from the given repository.
---
---@param name string The repository's local name. This should match the pattern `^[%l][%l%d-]-$`
---
---@return string directory The directory.
function module.getRepositoryDir(name)
    assert(name:match('^[%l][%l%d-]-$'), 'Invalid repository name')

    return ('%s/%s'):format(module.libraryDir, name)
end

---Returns the base URL associated with the given repository.
---
---@param name string The repository's local name. This should match the pattern `^[%l][%l%d-]-$`
---
---@return string | nil baseUrl The base URL, or `nil` if it doesn't exist.
function module.getRepositoryUrl(name)
    assert(name:match('^[%l][%l%d-]-$'), 'Invalid repository name')

    local repositories = loadRepositories()

    return repositories[name]
end

---Returns the file path of the specified library's file.
---
---@param repository string The repository's local name. This should match the pattern `^[%l][%l%d-]-$`
---@param name string The library's name. This must be a valid filename without an extension.
---
---@return string file The file path.
function module.getLibraryFile(repository, name)
    local directory = module.getRepositoryDir(repository)

    return ('%s/%s.lua'):format(directory, name)
end

---Attempts to require the specified library.
---
---@param name string The import name. Should be in the format `'repository@library'`.
---@param options? evelyn.externalRequire.options Additional import options.
---
---@return unknown module The imported library.
function module.require(name, options)
    local repository, library = name:match('^([%l][%l%d-]-)@(.-)$')

    assert(repository, 'Missing or invalid repository name')
    assert(library, 'Missing or invalid library name')

    local filePath = module.getLibraryFile(repository, library)
    local directory = module.getRepositoryDir(repository)

    if (options and options.forceDownload) or not fs.exists(filePath) then
        local baseUrl = assert(module.getRepositoryUrl(repository), 'Unknown repository')
        local fileUrl = ('%s/%s.lua'):format(baseUrl, library)
        local content = assert(http.get(fileUrl, {}, false)).readAll() or ''

        if not fs.exists(directory) then
            fs.makeDir(directory)
        end

        local file = assert(fs.open(filePath, 'w+'))

        file.write(content)
        file.close()
    end

    if package.path:find(directory, 1, true) == nil then
        package.path = ('%s;%s/?.lua'):format(package.path, directory)
    end

    return require(library)
end

return setmetatable(module, {
    __call = function(v, ...) return v.require(...) end
})

---Allows Lua code to be imported from online repositories.
---
---@class evelyn.library.common.import.Lib
local module = {}

---Defines various path constants as well as provides path utility functions.
---
---@class evelyn.library.common.import.path.Lib
module.path = {}

---The path used as the base directory for all other paths.
module.path.base = '.import'

---Returns the path that should be used for a repository with the given name.
---
---@param name string The repository's name.
---
---@return string path The directory path.
function module.path.repository(name)
    return fs.combine(module.path.base, 'repository', name)
end

---Returns the path that should be used for a library with the given name.
---
---@param repository string The repository's name.
---@param name string The library's filename.
---
---@return string path The directory path.
function module.path.library(repository, name)
    return fs.combine(module.path.base, 'library', repository, name)
end

---Provides a public API for adding and removing library repositories.
---
---@class evelyn.library.common.import.repository.Lib
module.repository = {}

---A repository's data.
---
---@class evelyn.library.common.import.repository.Data
---
---@field public baseUrl string The repository's base URL.
---@field public created integer The repository's creation time in milliseconds since the UTC epoch.

---Returns a new data table for a repository.
---
---@param baseUrl string The base URL.
---
---@return evelyn.library.common.import.repository.Data data The data.
local function newRepositoryData(baseUrl)
    return {
        baseUrl = baseUrl,
        created = os.epoch('utc'),
    }
end

---Saves a repository to the filesystem.
---
---@param name string The repository name.
---@param data evelyn.library.common.import.repository.Data The repository data.
---@param branches? table<string, evelyn.library.common.import.repository.Data> The repository branches.
local function saveRepositoryData(name, data, branches)
    assert(name:match('^%l[%l%d-]*[%l%d]$'), 'Invalid repository name')

    local directory = module.path.repository(name)

    if not fs.exists(directory) then
        fs.makeDir(directory)
    elseif branches ~= nil then
        fs.delete(directory)
        fs.makeDir(directory)
    end

    local file = assert(fs.open(fs.combine(directory, '@'), 'w+'))
    file.write(textutils.serialize(data, { compact = true }))
    file.close()

    for branchName, branchData in pairs(branches or {}) do
        assert(branchName:match('^%l[%l%d-]*[%l%d]$'), 'Invalid branch name')

        file = assert(fs.open(fs.combine(directory, branchName), 'w+'))
        file.write(textutils.serialize(branchData, { compact = true }))
        file.close()
    end
end

---Loads a repository from the filesystem.
---
---@param name string The repository name.
---
---@return evelyn.library.common.import.repository.Data | nil data The repository data.
---@return table<string, evelyn.library.common.import.repository.Data>? branches The repository branches.
local function loadRepositoryData(name)
    assert(name:match('^%l[%l%d-]*[%l%d]$'), 'Invalid repository name')

    local directory = module.path.repository(name)

    if not fs.exists(directory) then
        return nil
    end

    local file = assert(fs.open(fs.combine(directory, '@'), 'r'))
    local text = file.readAll()
    file.close()

    local data = text and textutils.unserialize(text)
    local branches = {}

    for _, path in ipairs(fs.list(directory)) do
        local branchName = fs.getName(path)

        if branchName == '@' then
            goto continue
        end

        assert(branchName:match('^%l[%l%d-]*[%l%d]$'), 'Invalid branch name')

        file = assert(fs.open(fs.combine(directory, '@'), 'r'))
        text = file.readAll()
        file.close()

        branches[branchName] = text and textutils.unserialize(text)

        ::continue::
    end

    return data, branches
end

---Returns `true` if a repository with the given name has been registered.
---
---@param name string The repository name.
---
---@return boolean registered Whether the repository was registered.
function module.repository.has(name)
    return loadRepositoryData(name) ~= nil
end

---Returns `true` if a repository branch with the given name has been registered with the specified repository.
---
---@param name string The repository name.
---@param branchName string The branch name.
---
---@return boolean registered Whether the repository branch was registered.
function module.repository.hasBranch(name, branchName)
    assert(branchName:match('^%l[%l%d-]*[%l%d]$'), 'Invalid branch name')

    local data, branches = loadRepositoryData(name)

    if data == nil then
        error('Unknown repository')
    end

    return branches ~= nil and branches[branchName] ~= nil
end

---Returns a table of registered repositories and their data.
---
---@return table<string, evelyn.library.common.import.repository.Data> repositories The repositories.
function module.repository.list()
    local directory = module.path.repository('')

    if not fs.exists(directory) then
        return {}
    end

    local repositories = {}

    for _, path in ipairs(fs.list(directory)) do
        local name = fs.getName(path)

        repositories[name] = loadRepositoryData(name)
    end

    return repositories
end

---Returns the data table and branches for the specified repository.
---
---@param name string The repository name.
---
---@return evelyn.library.common.import.repository.Data data The data table.
---@return table<string, evelyn.library.common.import.repository.Data> branches The branches.
function module.repository.get(name)
    local data, branches = loadRepositoryData(name)

    if data == nil then
        error('Unknown repository')
    end

    return data, (branches or {})
end

---Adds a repository to the list of globally registered repositories.
---
---@param name string The repository name.
---@param baseUrl string The base URL.
function module.repository.add(name, baseUrl)
    local data = newRepositoryData(baseUrl)

    saveRepositoryData(name, data, {})
end

---Adds a branch to the specified repository.
---
---@param name string The repository name.
---@param branchName string The branch name.
---@param baseUrl string The base URL.
function module.repository.addBranch(name, branchName, baseUrl)
    local data, branches = loadRepositoryData(name)

    if not data then
        error('Unknown repository')
    end

    branches = branches or {}
    branches[branchName] = newRepositoryData(baseUrl)

    saveRepositoryData(name, data, branches)
end

---Removes a repository from the list of globally registered repositories.
---
---@param name string The repository name.
function module.repository.remove(name)
    assert(name:match('^%l[%l%d-]*[%l%d]$'), 'Invalid repository name')

    local directory = module.path.repository(name)

    if fs.exists(directory) then
        fs.delete(directory)
    else
        error('Unknown repository')
    end
end

---Removes a branch from the specified repository.
---
---@param name string The repository name.
---@param branchName string The branch name.
function module.repository.removeBranch(name, branchName)
    local data, branches = loadRepositoryData(name)

    if not data then
        error('Unknown repository')
    end
    if not branches or branches[branchName] == nil then
        error('Unknown branch')
    end

    branches[branchName] = nil

    saveRepositoryData(name, data, branches)
end

---Provides a public API for importing libraries.
---
---@class evelyn.library.common.import.library.Lib
module.library = {}

---The time in milliseconds to wait before re-downloading a cached file by default.
---
---@public
---@type integer
module.library.staleAfter = 24 * 60 * 60 * 1000

---Splits the import path string into its individual parts.
---
---@param path string The import path.
---
---@return string library The library name.
---@return string repository The repository name.
---@return string | nil branch The branch name.
function module.library.splitPath(path)
    local library, repository, branch = nil, nil, nil

    if path:find('^(.-)@(%l[%l%d-]*[%l%d])#(%l[%l%d-]*[%l%d])$') ~= nil then
        library, repository, branch = path:match('^(.-)@(%l[%l%d-]*[%l%d])#(%l[%l%d-]*[%l%d])$')
    elseif path:find('^(.-)@(%l[%l%d-]*[%l%d])$') then
        library, repository = path:match('^(.-)@(%l[%l%d-]*[%l%d])$')
    end

    if library == nil or repository == nil then
        error('Invalid import path string')
    end

    return library, repository, branch
end

---Attempts to import the specified library.
---
---@param path string The import path.
---@param options? evelyn.library.common.import.library.require.Options Additional options.
function module.library.require(path, options)
    ---Additional options provided when importing a library.
    ---
    ---@class evelyn.library.common.import.library.require.Options
    ---
    ---@field public staleAfter? integer The time in milliseconds to wait before re-downloading a cached file.

    local library, repository, branch = module.library.splitPath(path)
    local directory = module.path.library(repository, library)
    local luaFilePath = fs.combine(directory, ('%s.lua'):format(branch or '@'))
    local timeFilePath = fs.combine(directory, ('%s.utc'):format(branch or '@'))
    local shouldReDownload = false

    if not fs.exists(directory) then
        fs.makeDir(directory)

        shouldReDownload = true
    elseif not fs.exists(luaFilePath) then
        shouldReDownload = true
    elseif fs.exists(timeFilePath) then
        local timeFile = assert(fs.open(timeFilePath, 'r'))
        local time = assert(tonumber(timeFile.readAll(), 10))
        timeFile.close()

        local staleAfter = options and options.staleAfter or module.library.staleAfter
        local difference = os.epoch('utc') - time

        shouldReDownload = shouldReDownload or (difference >= staleAfter)
    end

    if shouldReDownload then
        local repositoryData, repositoryBranches = module.repository.get(repository)

        if branch ~= nil and repositoryBranches[branch] == nil then
            error('Unknown branch')
        end

        local baseUrl = branch == nil and repositoryData.baseUrl or repositoryBranches[branch].baseUrl
        local fileUrl = ('%s/%s.lua'):format(baseUrl, library)

        assert(http.checkURL(fileUrl))

        local content = assert(http.get(fileUrl, {}, false)).readAll() or ''

        local luaFile = assert(fs.open(luaFilePath, 'w+'))
        luaFile.write(content)
        luaFile.close()

        local timeFile = assert(fs.open(timeFilePath, 'w+'))
        timeFile.write(tostring(os.epoch('utc')))
        timeFile.close()
    end

    if package.path:find(module.path.library('', ''), nil, true) == nil then
        package.path = ('%s;%s/?.lua'):format(package.path, module.path.library('', ''))
    end

    return require(('%s.%s.%s'):format(repository, library, branch or '@'))
end

return module

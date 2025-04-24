local repositoryUrl = 'https://raw.githubusercontent.com/Jaxydog/evelyns-big-bucket-of-cc-content'
local validUrl, reason = http.checkURL(repositoryUrl)

if validUrl then
    local data = assert(http.get(repositoryUrl .. '/refs/heads/rewrite/lua/library/common/import.lua', {}, false))

    if not fs.exists('.import') then
        fs.makeDir('.import')
    end

    local file = assert(fs.open('.import/import.lua', 'w+'))
    file.write(data)
    file.close()
else
    printError('Failed to install import function')
    printError('Reason: ' .. (reason or 'N/A'))
end

if fs.exists('.import/import.lua') then
    package.path = package.path .. ';.import/?.lua'

    local import = require('import')

    if not import.repository.has('evelyns-common') then
        import.repository.add('evelyns-common', repositoryUrl .. '/refs/heads/rewrite/lua/library/common')
    end
    if not import.repository.has('evelyns-turtle') then
        import.repository.add('evelyns-turtle', repositoryUrl .. '/refs/heads/rewrite/lua/library/turtle')
    end

    if shell.getRunningProgram() == 'startup.lua' then
        _G.import = import.library.require
    else
        printError('Unable to set global function')
        printError('Manual `import` imports will be required')
    end
end

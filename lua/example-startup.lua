local repositoryUrl = 'https://raw.githubusercontent.com/Jaxydog/evelyns-big-bucket-of-cc-content'
local libraryUrl = repositoryUrl .. '/refs/heads/main/lua/libraries/external-require.lua'

local valid, reason = http.checkURL(repositoryUrl)

if valid then
    if fs.exists('/.library/external-require.lua') then
        fs.delete('/.library/external-require.lua')
    end

    local content = assert(http.get(libraryUrl, {}, false)).readAll() or ''

    if not fs.exists('/.library') then
        fs.makeDir('/.library')
    end

    local file = assert(fs.open('/.library/external-require.lua', 'w+'))

    file.write(content)
    file.close()
else
    printError('Unable to download external-require!')
    printError('Reason: ' .. (reason or 'N/A'))
end

if fs.exists('/.library/external-require.lua') then
    package.path = package.path .. ';/.library/?.lua'

    ---@type evelyn.ExternalRequireLib
    local externalRequire = require('external-require')

    if not externalRequire.hasRepository('evelyns') then
        externalRequire.addRepository('evelyns', repositoryUrl .. '/refs/heads/main/lua/libraries')
    end
end

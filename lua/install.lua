--Install the external-require library.
do
    --Remove the file if already present.
    if fs.exists('/.evelyns-libraries/external-require.lua') then
        fs.delete('/.evelyns-libraries/external-require.lua')
    end

    --Download the file from its source.
    assert(shell.run(
        'wget',
        'https://raw.githubusercontent.com/Jaxydog/evelyns-big-bucket-of-cc-content/refs/heads/main/lua/libraries/external-require.lua',
        '/.evelyns-libraries/external-require.lua'
    ), 'Failed to install external-require!')

    --Add downloaded libraries to the require path.
    if not package.path:match('/%.evelyns%-libraries') then
        package.path = package.path .. ';/.evelyns-libraries/?.lua'
    end

    term.clear()
    term.setCursorPos(1, 1)
end

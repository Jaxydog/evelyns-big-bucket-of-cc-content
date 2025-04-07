# Evelyn's Big Bucket of CC Content

A collection of Lua libraries and programs for usage with CC: Tweaked.

## Usage

To use this repository's libraries, add the following to the start of your Lua file.

```lua
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
end
```

Then use the global `externalRequire` function to import it directly.

```lua
local console = externalRequire('console')

console.logInfo('Library downloaded~!')
```

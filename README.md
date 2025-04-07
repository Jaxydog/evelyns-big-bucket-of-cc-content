# Evelyn's Big Bucket of CC Content

A collection of Lua libraries and programs for usage with CC: Tweaked.

## Usage

To use a program within this library,
run the following commands in your ComputerCraft terminal:

```
wget run https://raw.githubusercontent.com/Jaxydog/evelyns-big-bucket-of-cc-content/refs/heads/main/lua/install.lua
wget run https://raw.githubusercontent.com/Jaxydog/evelyns-big-bucket-of-cc-content/refs/heads/main/lua/programs/<name>.lua
```

The simplest way to use this repository's libraries
is to add the following to the top of your file.

```lua
if not fs.exists('/.evelyns-libraries/external-require.lua') then
    assert(shell.run(
        'wget',
        'https://raw.githubusercontent.com/Jaxydog/evelyns-big-bucket-of-cc-content/refs/heads/main/lua/libraries/external-require.lua',
        '/.evelyns-libraries/external-require.lua'
    ), 'Failed to install external-require!')
end
```

You may then use the global `externalRequire` function to import libraries directly.

```lua
local console = externalRequire('console')

console.logInfo('Library downloaded~!')
```

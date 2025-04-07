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
is to add the following to the top of your `startup.lua` file.
Alternatively,
add the [installation file](./lua/install.lua)'s contents
to the start of any file that uses these libraries.

```lua
shell.run('wget', 'run', 'https://raw.githubusercontent.com/Jaxydog/evelyns-big-bucket-of-cc-content/refs/heads/main/lua/install.lua')
```

You may then use the global `externalRequire` function to import libraries directly.

```lua
local console = externalRequire('console')

console.logInfo('Library downloaded~!')
```

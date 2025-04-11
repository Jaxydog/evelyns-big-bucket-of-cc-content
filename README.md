# Evelyn's Big Bucket of CC Content

A collection of Lua libraries and programs for usage with CC: Tweaked.

## Usage

### Programs

To use a program within this repository,
run the following command in your ComputerCraft terminal,
where \<name> is the name of the program:

```
wget run https://raw.githubusercontent.com/Jaxydog/evelyns-big-bucket-of-cc-content/refs/heads/main/lua/programs/<name>.lua
```

Note that you first need to follow the instructions below
for adding external-require to your `startup.lua` file.

### Libraries

The simplest way to use this repository's libraries
is to copy the code within [`example-startup.lua`](./lua/example-startup.lua)
to your `startup.lua` file:

Then add the following to any files that use them:

```lua
if not package.path:match('/%.library/%?%.lua') then
    package.path = package.path .. ';/.library/?.lua'
end

require('external-require')
```

You may then use the global `externalRequire` function to import libraries directly (after rebooting).

```lua
local console = externalRequire('console')

console.logInfo('Library downloaded~!')
```

## Clearing downloads

To delete downloaded libraries,
just delete the `/.library/` directory.

Make sure to reboot your terminal so that
`external-require` re-downloads itself and becomes usable again.

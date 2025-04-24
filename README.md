# Evelyn's Big Bucket of CC Content

A collection of Lua libraries and programs for usage with CC: Tweaked.

## Usage

### Programs

To use a program within this repository,
run the following command in your ComputerCraft terminal,
where \<name> is the name of the program:

```
wget run https://raw.githubusercontent.com/Jaxydog/evelyns-big-bucket-of-cc-content/refs/heads/rewrite/lua/program/<name>.lua
```

Note that you first need to follow the instructions below for
adding the `import` installation procedure to your `startup.lua` file.

### Libraries

The simplest way to use this repository's libraries
is to copy the code from [`startup.lua`](./lua/startup.lua)
into your `startup.lua` file:

```
wget https://raw.githubusercontent.com/Jaxydog/evelyns-big-bucket-of-cc-content/refs/heads/rewrite/lua/startup.lua
```

Then you may use the `import` function globally (after a quick reboot):

```lua
local arrays = import('arrays@evelyns-common')
```

## Clearing downloads

To delete downloaded libraries,
just remove the `/.import/library/` directory.

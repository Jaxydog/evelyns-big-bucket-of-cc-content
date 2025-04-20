---An in-memory item stack that represents all item stacks of a given item within internal storage.
---
---@class evelyn.program.storage.item.stack
---
---@field public name string The item's identifier.
---@field public nbt string | nil The item's NBT hash.
---@field public count integer The total item count.
---
---@field public positions evelyn.program.storage.item.position[] The internal item stack positions.
---@field public details fun(): evelyn.program.storage.item.details A function that returns the stack's extended details.

---An internal item stack position.
---
---@class evelyn.program.storage.item.position
---
---@field public inventory string The inventory's name.
---@field public slot integer The inventory slot.

---Specific details about an in-memory item stack.
---
---@class evelyn.program.storage.item.details
---
---@field public name string The item's identifier.
---@field public displayName string The item's display name.
---
---@field public maxCount integer The item's maximum count for one stack.
---
---@field public durability? number The item's durability percentage.
---@field public damage? integer The item's damage.
---@field public maxDamage? integer The item's maximum damage.
---
---@field public enchantments? evelyn.program.storage.item.enchantment[] The item's enchantments.
---
---@field public itemGroups evelyn.program.storage.item.group[] A list of the item's groups.
---@field public tags table<string, boolean> A list of the item's tags.

---An item enchantment.
---
---@class evelyn.program.storage.item.enchantment
---
---@field public name string The enchantment's identifier.
---@field public level integer The enchantment's level.

---A creative-mode inventory item group.
---
---@class evelyn.program.storage.item.group
---
---@field public id string The group identifier.
---@field public displayName string The group name.

if not package.path:match('/%.library/%?%.lua') then
    package.path = package.path .. ';/.library/?.lua'
end

---@type evelyn.externalRequire.lib
local externalRequire = require('external-require')

print('Loading program...')

---@type evelyn.collectionHelper.lib
local collectionHelper = externalRequire.require('evelyns@collection-helper')

term.clear()
term.setCursorPos(1, 1)

---A peripheral wrapper for the external inventory.
local externalInventory = assert(peripheral.find('inventory', function(name)
    return name:find('barrel', nil, true) ~= nil
end), 'Missing interface inventory')

---@cast externalInventory ccTweaked.peripherals.Inventory

---A list of peripheral wrappers for the internal inventories.
local internalInventories = { peripheral.find('inventory', function(name)
    return name:find('barrel', nil, true) == nil
end) }

assert(#internalInventories > 0, 'Missing internal inventories')

---@cast internalInventories ccTweaked.peripherals.Inventory[]

---Caches the current inventory state to reduce repeated computation.
local cache = {
    ---The internal state. This should not be used directly.
    ---
    ---@private
    ---@type evelyn.program.storage.item.stack[]
    stacks = nil
}

---Stores the current inventory state within the cache.
---
---This is an expensive operation, and should not be called frequently.
function cache:store()
    ---@type table<string, evelyn.program.storage.item.stack>
    local stacks = {}

    for _, inventory in ipairs(internalInventories) do
        local inventoryName = peripheral.getName(inventory)

        for slot, item in pairs(inventory.list()) do
            local key = item.nbt and ('%s#%s'):format(item.name, item.nbt) or item.name
            local detailCache = nil
            local stack = stacks[key] or {
                name = item.name,
                nbt = item.nbt,
                count = 0,
                positions = {},
                details = function()
                    if detailCache == nil then
                        detailCache = assert(inventory.getItemDetail(slot), 'Missing item details')
                    end

                    return detailCache
                end
            }

            stack.positions[#stack.positions + 1] = { inventory = inventoryName, slot = slot }
            stack.count = stack.count + item.count

            stacks[key] = stack
        end
    end

    self.stacks = collectionHelper.table:values(stacks)
end

---Clears the current cache.
function cache:clear()
    self.stacks = nil
end

---Returns the current state of the inventory.
---
---If the cache has not been stored, this will store the current state automatically.
---
---@return evelyn.program.storage.item.stack[] state The inventory state.
function cache:getOrStore()
    if self.stacks == nil then
        self:store()
    end

    return self.stacks
end

---A set of helper functions for managing the internal inventory.
local inventory = {}

---Additional filtering options for the list function.
---
---@class evelyn.program.storage.fn.list.options
---
---@field public include? string[] A list of item identifiers to be included in the list result.
---@field public exclude? string[] A list of item identifiers to be excluded from the list result.

---Returns a list of the contents within the internal inventory.
---
---@param options? evelyn.program.storage.fn.list.options Additional filtering options.
---
---@return evelyn.program.storage.item.stack[] stacks The stacks.
function inventory:list(options)
    options = options or {}

    local stacks = cache:getOrStore()

    if options.include and #options.include > 0 then
        stacks = collectionHelper.array:filter(stacks, function(_, value)
            return collectionHelper.array:find(options.include, value.name) ~= nil
        end)
    end
    if options.exclude and #options.exclude > 0 then
        stacks = collectionHelper.array:filter(stacks, function(_, value)
            return collectionHelper.array:find(options.exclude, value.name) == nil
        end)
    end

    return stacks
end

---Additional filtering options for the insert function.
---
---@class evelyn.program.storage.fn.insert.options
---
---@field public count? integer The number of items to insert for each item identifier.
---@field public include? string[] A list of item identifiers to be included in the transfer.
---@field public exclude? string[] A list of item identifiers to be excluded from the transfer.

---Inserts items into internal storage.
---
---@param options evelyn.program.storage.fn.insert.options Additional filtering options.
---
---@return boolean success Whether all items were successfully inserted.
---@return string | nil reason The reason that insertion failed.
function inventory:insert(options)
    options = options or {}

    local internalStacks = self:list({ include = options.include, exclude = options.exclude })
    ---@type table<string, integer>
    local movedCounts = {}

    for externalSlot, externalStack in pairs(externalInventory.list()) do
        if options.include and #options.include > 0 and collectionHelper.array:find(options.include, externalStack.name) == nil then
            goto continue
        end
        if options.exclude and #options.exclude > 0 and collectionHelper.array:find(options.exclude, externalStack.name) ~= nil then
            goto continue
        end

        local maxCount = options.count ~= nil and options.count or externalStack.count

        for _, internalStack in ipairs(internalStacks) do
            for _, internalPosition in ipairs(internalStack.positions) do
                local movedCount = movedCounts[internalStack.name] or 0

                movedCount = movedCount + externalInventory.pushItems(
                    internalPosition.inventory,
                    externalSlot,
                    maxCount - movedCount,
                    internalPosition.slot
                )

                if movedCount > 0 then cache:clear() end

                movedCounts[internalStack.name] = movedCount

                if movedCount >= maxCount then goto continue end
            end
        end

        for _, internalInventory in ipairs(internalInventories) do
            local internalInventoryName = peripheral.getName(internalInventory)
            local movedCount = movedCounts[externalStack.name] or 0

            movedCount = movedCount + externalInventory.pushItems(
                internalInventoryName,
                externalSlot,
                maxCount - movedCount
            )

            if movedCount > 0 then cache:clear() end

            movedCounts[externalStack.name] = movedCount

            if movedCount >= maxCount then goto continue end
        end

        if externalInventory.getItemDetail(externalSlot) ~= nil
            and collectionHelper.table:findWith(movedCounts, function(_, value) return value > 0 end)
        then
            return false, 'Inventory full'
        end

        ::continue::
    end

    return true, nil
end

---Additional filtering options for the remove function.
---
---@class evelyn.program.storage.fn.remove.options
---
---@field public count? integer The number of items to remove for each item identifier.
---@field public include? string[] A list of item identifiers to be included in the transfer.
---@field public exclude? string[] A list of item identifiers to be excluded from the transfer.

---Removes items from internal storage.
---
---@param options evelyn.program.storage.fn.remove.options Additional filtering options.
---
---@return boolean success Whether all items were successfully inserted.
---@return string | nil reason The reason that insertion failed.
function inventory:remove(options)
    options = options or {}

    local internalStacks = self:list({ include = options.include, exclude = options.exclude })
    ---@type table<string, integer>
    local movedCounts = {}

    for _, internalStack in ipairs(internalStacks) do
        local maxCount = options.count ~= nil
            and options.count
            or math.min(internalStack.details().maxCount, internalStack.count)

        for _, internalPosition in ipairs(internalStack.positions) do
            local movedCount = movedCounts[internalStack.name] or 0

            movedCount = movedCount + externalInventory.pullItems(
                internalPosition.inventory,
                internalPosition.slot,
                maxCount - movedCount
            )

            if movedCount > 0 then cache:clear() end

            movedCounts[internalStack.name] = movedCount

            if movedCount >= maxCount then goto continue end
        end

        if movedCounts[internalStack.name] == nil or movedCounts[internalStack.name] < maxCount then
            return false, 'Not enough items'
        end

        ::continue::
    end

    return true, nil
end

---A function that returns a list of completion strings based on the given input.
---
---@alias evelyn.program.storage.command.complete fun(cacheTable: table, previous: string[], current: string): completions: string[]

---A function that executes a command.
---
---@alias evelyn.program.storage.command.callback fun(parameters: string[]): success: boolean, reason: string | nil

---A list of commands that can be run within the fake shell.
---
---@type table<string, { complete: evelyn.program.storage.command.complete, callback: evelyn.program.storage.command.callback }>
local commands = {}

---The exit command. This is not run directly, as the program exits before invocation.
commands['exit'] = {
    complete = function() return {} end,
    callback = function() return true, nil end,
}
---The clear command. Clears the terminal screen.
commands['clear'] = {
    complete = function() return {} end,
    callback = function()
        term.clear()
        term.setCursorPos(1, 1)

        return true, nil
    end,
}

---The insert command. Pushes stacks into internal storage.
commands['insert'] = {
    complete = function(cacheTable, previous, current)
        if cacheTable['items'] == nil then
            cacheTable['items'] = collectionHelper.table:values(externalInventory.list())
        end

        if #previous == 0 then
            if cacheTable['counts'] then
                cacheTable['counts'] = nil
            end

            return collectionHelper.array:map(collectionHelper.array:filter(cacheTable['items'], function(_, value)
                return value.name:find('^' .. current, nil, false) ~= nil
            end), function(_, value) return value.name end)
        elseif #previous == 1 then
            if cacheTable['counts'] == nil then
                local count = collectionHelper.array:fold(cacheTable['items'], 0, function(currentCount, _, value)
                    if value.name == previous[1] then
                        return currentCount + value.count
                    else
                        return currentCount
                    end
                end)

                cacheTable['counts'] = collectionHelper.array:compute(math.floor(math.sqrt(count)), function(index)
                    return tostring(2 ^ index)
                end)
                if not collectionHelper.array:find(cacheTable['counts'], tostring(count)) then
                    cacheTable['counts'][#cacheTable['counts'] + 1] = tostring(count)
                end
            end

            return collectionHelper.array:filter(cacheTable['counts'], function(_, value)
                return value:find('^' .. current, nil, false) ~= nil
            end)
        else
            return {}
        end
    end,
    callback = function(parameters)
        ---@type evelyn.program.storage.fn.insert.options
        local options = {}

        if parameters[1] then options.include = { parameters[1] } end
        if parameters[2] then options.count = tonumber(parameters[2], 10) end

        return inventory:insert(options)
    end,
}
commands['i'] = commands['insert']

---The remove command. Pushes stacks into external storage.
commands['remove'] = {
    complete = function(cacheTable, previous, current)
        if #previous == 0 then
            if cacheTable['counts'] then
                cacheTable['counts'] = nil
            end

            return collectionHelper.array:map(collectionHelper.array:filter(inventory:list(), function(_, value)
                return value.name:find('^' .. current, nil, false) ~= nil
            end), function(_, value) return value.name end)
        elseif #previous == 1 then
            if cacheTable['counts'] == nil then
                local itemIndex = collectionHelper.array:findWith(inventory:list(), function(_, value)
                    return value.name == previous[1]
                end)

                if not itemIndex then
                    cacheTable['counts'] = {}
                else
                    local count = inventory:list()[itemIndex].count

                    cacheTable['counts'] = collectionHelper.array:compute(math.floor(math.sqrt(count)), function(index)
                        return tostring(2 ^ index)
                    end)
                    if not collectionHelper.array:find(cacheTable['counts'], tostring(count)) then
                        cacheTable['counts'][#cacheTable['counts'] + 1] = tostring(count)
                    end
                end
            end

            return collectionHelper.array:filter(cacheTable['counts'], function(_, value)
                return value:find('^' .. current, nil, false) ~= nil
            end)
        else
            return {}
        end
    end,
    callback = function(parameters)
        ---@type evelyn.program.storage.fn.remove.options
        local options = {}

        if parameters[1] then options.include = { parameters[1] } end
        if parameters[2] then options.count = tonumber(parameters[2], 10) end

        return inventory:remove(options)
    end,
}
commands['r'] = commands['remove']

---The list command. Prints a list of stored items and their counts.
commands['list'] = {
    complete = function(_, previous, current)
        return collectionHelper.array:map(collectionHelper.array:filter(inventory:list(), function(_, value)
            return collectionHelper.array:find(previous, value.name) == nil
                and value.name:find('^' .. current, nil, false) ~= nil
        end), function(_, value) return value.name end)
    end,
    callback = function(parameters)
        local internalStacks = inventory:list({ include = parameters })

        table.sort(internalStacks, function(a, b) return a.count > b.count end)

        for _, internalStack in ipairs(internalStacks) do
            print(('x%s %s'):format(internalStack.count, internalStack.details().displayName))
        end

        return true, nil
    end
}
commands['l'] = commands['list']

commands['list-verbose'] = {
    complete = commands['list'].complete,
    callback = function(parameters)
        local internalStacks = inventory:list({ include = parameters })

        table.sort(internalStacks, function(a, b) return a.count > b.count end)

        for _, internalStack in ipairs(internalStacks) do
            print(('x%s %s (%s)'):format(internalStack.count, internalStack.details().displayName, internalStack.name))

            if internalStack.details().damage and internalStack.details().maxDamage then
                local currentDurability = internalStack.details().maxDamage - internalStack.details().damage

                print(('Durability: %s / %s'):format(currentDurability, internalStack.details().maxDamage))
            end
            if internalStack.details().enchantments and #internalStack.details().enchantments > 0 then
                print('Enchantments:')

                for _, enchantment in ipairs(internalStack.details().enchantments) do
                    print(('  %s %s'):format(enchantment.name, enchantment.level))
                end
            end
        end

        return true, nil
    end
}
commands['lv'] = commands['list-verbose']

while true do
    write('storage> ')

    local completionCache = {}
    local commandInput = read(nil, nil, function(commandInput)
        ---@type string[]
        local commandParts = {}

        for commandPart in commandInput:gmatch('(%S+)') do
            commandParts[#commandParts + 1] = commandPart
        end

        if #commandParts == 1 and commandInput:match('%s$') == nil then
            completionCache = {}

            local commandNames = collectionHelper.table:keys(commands)

            return collectionHelper.array:map(collectionHelper.array:filter(commandNames, function(_, value)
                return value:find('^' .. commandParts[1], nil, false) ~= nil
            end), function(_, value)
                local _, finish = value:find(commandParts[1], nil, true)

                return value:sub((finish or -1) + 1)
            end)
        elseif #commandParts > 1 and commands[commandParts[1]] ~= nil then
            local command = commands[table.remove(commandParts, 1)]
            local current = commandInput:match('%s$') and '' or table.remove(commandParts, #commandParts)

            return collectionHelper.array:map(
                command.complete(completionCache, commandParts, current),
                function(_, value)
                    local _, finish = value:find(current, nil, true)

                    return value:sub((finish or -1) + 1)
                end
            )
        end

        return {}
    end)

    ---@type string[]
    local commandParts = {}

    for commandPart in commandInput:gmatch('(%S+)') do
        commandParts[#commandParts + 1] = commandPart
    end

    if #commandParts == 0 then goto continue end
    if commandParts[1] == 'exit' then break end

    if commands[commandParts[1]] == nil then
        printError(('Unknown command "%s"'):format(commandParts[1]))

        goto continue
    end

    local command = commands[table.remove(commandParts, 1)]
    local success, reason = command.callback(commandParts)

    if not success then printError(('Error: %s'):format(reason)) end

    ::continue::
end

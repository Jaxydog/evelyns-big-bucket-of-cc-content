term.clear()
term.setCursorPos(1, 1)

local storageInterface = assert(peripheral.find('inventory', function(name)
    return name == 'bottom'
end), 'Missing interface inventory')

---@cast storageInterface ccTweaked.peripherals.Inventory

local internalInventories = { peripheral.find('inventory', function(name)
    return name ~= 'bottom'
end) }

assert(#internalInventories > 0, 'Missing internal inventories')

---Returns a list of all keys in the given table.
---
---@generic T The type of the table's keys.
---
---@param map table<T, any> The table.
---
---@return T[] keys A list of the table's keys.
local function tableKeys(map)
    local keys = {}

    for key, _ in pairs(map) do
        table.insert(keys, key)
    end

    return keys
end

---Returns a list of all values in the given table.
---
---@generic T The type of the table's values.
---
---@param map table<any, T> The table.
---
---@return T[] values A list of the table's values.
local function tableValues(map)
    local values = {}

    for _, value in pairs(map) do
        table.insert(values, value)
    end

    return values
end

---Returns whether the given array contains the given value.
---
---@generic T The type of the values within the array.
---
---@param array T[] The array.
---@param value T The value to test for.
---
---@return boolean contains Whether the array contains the value.
local function arrayContains(array, value)
    for _, innerValue in ipairs(array) do
        if innerValue == value then return true end
    end

    return false
end

---Returns a copy of the array with elements removed that do not match the given predicate.
---
---@generic T The type of the values within the array.
---
---@param array T[] The array.
---@param predicate fun(value: T): boolean The predicate.
---
---@return T[] array The filtered array.
local function arrayFilter(array, predicate)
    local newArray = {}

    for _, value in ipairs(array) do
        if predicate(value) then table.insert(newArray, value) end
    end

    return newArray
end

---Returns a copy of the array with duplicate elements removed.
---
---@generic T The type of the values within the array.
---
---@param array T[] The array.
---
---@return T[] array The de-duplicated array.
local function arrayDedupe(array)
    local newArray = {}

    for _, value in ipairs(array) do
        if not arrayContains(newArray, value) then table.insert(newArray, value) end
    end

    return newArray
end

---Maps the values within an array.
---
---@generic T The type of the values within the array.
---@generic U The new type.
---
---@param array T[] The array.
---@param map fun(value: T): U The mapping function.
---
---@return U[] array The mapped array.
local function arrayMap(array, map)
    local newArray = {}

    for index, value in ipairs(array) do
        newArray[index] = map(value)
    end

    return newArray
end

---@cast internalInventories ccTweaked.peripherals.Inventory[]

---A representation of a stack within the internal inventory.
---
---@class evelyn.program.storage.itemStack
---
---@field public name string The item's identifier.
---@field public count integer The total item count.
---@field public nbt string | nil The item's NBT hash, if available.
---@field public positions table<string, evelyn.program.storage.itemPosition[]> The item's positions.
---@field public details evelyn.program.storage.itemDetail The item's details.

---An internal item stack's actual storage position within an inventory.
---
---@class evelyn.program.storage.itemPosition
---
---@field public slot integer The item slot.
---@field public count integer The item count.
---@field public maxCount integer The item's maximum count for this stack.

---Detailed information about a specific item in an inventory.
---
---@class evelyn.program.storage.itemDetail
---
---@field public name string The item's identifier.
---@field public displayName string The item's display name.
---
---@field public count integer The item's count.
---@field public maxCount integer The item's maximum count.
---
---@field public durability? number The item's durability percentage.
---@field public damage? integer The item's damage.
---@field public maxDamage? integer The item's maximum damage.
---
---@field public enchantments? evelyn.program.storage.itemEnchantment[] The item's enchantments.
---
---@field public itemGroups evelyn.program.storage.itemGroup[] A list of the item's groups.
---@field public tags table<string, boolean> A list of the item's tags.

---An item enchantment.
---
---@class evelyn.program.storage.itemEnchantment
---
---@field public name string The enchantment's identifier.
---@field public level integer The enchantment's level.

---A creative-mode inventory item group.
---
---@class evelyn.program.storage.itemGroup
---
---@field public id string The group identifier.
---@field public displayName string The group name.

---Returns a map of item names to their internal inventory stacks.
---
---@param options? { include?: string[], exclude?: string[], inventory?: ccTweaked.peripherals.Inventory }
---
---@return table<string, evelyn.program.storage.itemStack> stacks The internal stacks within storage.
local function getInternalStacks(options)
    options = options or {}

    ---@type table<string, evelyn.program.storage.itemStack>
    local internalStacks = {}

    for _, inventory in ipairs(arrayFilter(internalInventories, function(value)
        return not options.inventory or peripheral.getName(value) == peripheral.getName(options.inventory)
    end)) do
        local inventoryName = peripheral.getName(inventory)

        for slot, item in pairs(inventory.list()) do
            if arrayContains(options.exclude or {}, item.name) then
                goto continue
            end
            if not arrayContains(options.include or {}, item.name) then
                goto continue
            end

            local mapKey = ('%s#%s'):format(item.name, item.nbt or 'nil')
            local internalStack = internalStacks[mapKey] or {
                name = item.name,
                count = 0,
                nbt = item.nbt,
                positions = {},
                ---@type evelyn.program.storage.itemDetail
                detail = assert(inventory.getItemDetail(slot), 'Failed to resolve item data'),
            }

            local positions = internalStack.positions[inventoryName] or {}

            table.insert(positions, { slot = slot, count = item.count, maxCount = internalStack.details.maxCount })

            internalStack.positions[inventoryName] = positions
            internalStack.count = internalStack.count + item.count
            internalStack.details.count = internalStack.count
            internalStack.details.maxCount = internalStack.count

            internalStacks[mapKey] = internalStack

            ::continue::
        end
    end

    return internalInventories
end

---Stores the specified stacks, or all stacks within the interface barrel, within internal storage.
---
---@param inputInventory ccTweaked.peripherals.Inventory The peripheral from which to move items.
---@param options? { include?: string[] }
---
---@return boolean success Whether all possible stacks were stored.
---@return string | nil reason The reason storing failed.
local function storeStacks(inputInventory, options)
    local inputInventoryName = peripheral.getName(inputInventory)
    local outputInventories = arrayFilter(internalInventories, function(value)
        return peripheral.getName(value) ~= inputInventoryName
    end)

    if #outputInventories == 0 then return false, 'No available output inventories' end

    ---@type evelyn.program.storage.itemStack[]
    local currentContents = tableValues(getInternalStacks((options and options.include) and {
        include = options.include
    }))

    for inputSlot, externalStack in pairs(inputInventory.list()) do
        if options and options.include and not arrayContains(options.include, externalStack.name) then
            goto continue
        end

        for _, internalStack in ipairs(currentContents) do
            for outputInventoryName, positions in pairs(internalStack.positions) do
                for _, position in ipairs(positions) do
                    local transferred = inputInventory.pushItems(
                        outputInventoryName,
                        inputSlot,
                        position.maxCount - position.count,
                        position.slot
                    )

                    if transferred >= externalStack.count then goto continue end

                    externalStack.count = externalStack.count - transferred
                end
            end
        end

        if externalStack.count > 0 then return false, 'Storage full' end

        ::continue::
    end

    return true, nil
end

---Retrieves items from the internal inventory.
---
---@param name string The item's name.
---@param count? integer The number of items to extract.
---
---@return boolean success Whether all items were successfully retrieved.
---@return string | nil reason The reason retrieval failed.
local function retrieveStack(name, count)
    local outputInventoryName = peripheral.getName(storageInterface)

    ---@type evelyn.program.storage.itemStack[]
    local currentContents = tableValues(getInternalStacks({ include = { name } }))
    local totalTransferred = 0

    for _, internalStack in ipairs(currentContents) do
        for intputInventoryName, positions in pairs(internalStack.positions) do
            local inputInventory = peripheral.wrap(intputInventoryName)

            ---@cast inputInventory ccTweaked.peripherals.Inventory

            for _, position in ipairs(positions) do
                totalTransferred = totalTransferred + inputInventory.pushItems(
                    outputInventoryName,
                    position.slot,
                    count - totalTransferred
                )

                if totalTransferred >= count then return true, nil end
            end
        end
    end

    return false, 'Not enough stored items'
end

---@type table<string, { complete: (fun(parts: string[]): values: string[]), call: (fun(parts: string[]): success: boolean, reason: string | nil) }>
local commands = {}

commands['exit'] = {
    complete = function() return {} end,
    call = function() return false, 'Exiting program' end
}
commands['clear'] = {
    complete = function() return {} end,
    call = function()
        term.clear()
        term.setCursorPos(1, 1)

        return true, nil
    end
}
commands['store'] = {
    complete = function(parts)
        local currentPart = table.remove(parts, #parts)

        return arrayFilter(arrayMap(tableValues(storageInterface.list()), function(value)
            ---@cast value ccTweaked.peripherals.inventory.item Wow, Lua does NOT know how to use generics.

            return value.name
        end), function(value)
            return not arrayContains(parts, value) and value:match('^' .. currentPart)
        end)
    end,
    call = function(parts)
        local success, reason = storeStacks(storageInterface, { include = parts })

        return success, reason and ('Failed to store items: %s'):format(reason) or 'Failed to store items'
    end
}
commands['get'] = {
    complete = function(parts)
        if #parts == 1 then
            return commands['list'].complete(parts)
        elseif #parts == 2 then
            local totalCount = 0

            for _, value in ipairs(tableValues(getInternalStacks({ include = { parts[1] } }))) do
                ---@cast value evelyn.program.storage.itemStack Wow, Lua does NOT know how to use generics.

                totalCount = totalCount + value.count
            end

            ---@type string[]
            local values = { tostring(totalCount) }

            for i = 1, 12, 1 do
                table.insert(values, tostring(2 ^ i))
            end

            return arrayFilter(values, function(value)
                return value:match('^' .. parts[2])
            end)
        end

        return {}
    end,
    call = function(parts)
        local success, reason = retrieveStack(parts[1], tonumber(parts[2], 10))

        return success, reason and ('Failed to retrieve items: %s'):format(reason) or 'Failed to retrieve items'
    end
}
commands['list'] = {
    complete = function(parts)
        local currentPart = table.remove(parts, #parts)

        return arrayFilter(arrayMap(tableValues(getInternalStacks({ exclude = parts })), function(value)
            ---@cast value evelyn.program.storage.itemStack Wow, Lua does NOT know how to use generics.

            return value.name
        end), function(value)
            return not arrayContains(parts, value) and value:match('^' .. currentPart)
        end)
    end,
    call = function(parts)
        local internalStacks = getInternalStacks({ include = parts })

        for _, stack in pairs(internalStacks) do
            print(('x%s %s'):format(stack.count, stack.details.displayName))
        end

        return true, nil
    end,
}
commands['listv'] = {
    complete = commands['list'].complete,
    call = function(parts)
        local internalStacks = getInternalStacks({ include = parts })

        for _, stack in pairs(internalStacks) do
            print(('x%s %s (%s)'):format(stack.count, stack.details.displayName, stack.name))

            if stack.details.damage and stack.details.maxDamage then
                print(('Damage: %s/%s'):format(stack.details.damage, stack.details.maxDamage))
            end
            if stack.details.enchantments and #stack.details.enchantments > 0 then
                print('Enchantments:')

                for _, enchantment in ipairs(stack.details.enchantments) do
                    print(('%s %s'):format(enchantment.name, enchantment.level))
                end
            end

            print('Physical locations:')

            for inventory, positions in pairs(stack.positions) do
                print(inventory)

                for _, position in ipairs(positions) do
                    print(('#%s - x%s'):format(position.slot, position.count))
                end
            end

            print()
        end

        return true, nil
    end,
}

while true do
    write('storage > ')

    local input = read(nil, nil, function(partial)
        ---@type string[]
        local parts = {}

        for part in partial:gmatch('(%S+)') do
            table.insert(parts, part)
        end

        if #parts == 0 then
            return tableKeys(commands)
        elseif #parts == 1 then
            local commandStart = parts[1]

            return arrayMap(arrayFilter(tableKeys(commands), function(value)
                ---@cast value string Wow, Lua does NOT know how to use generics.

                return value:match('^' .. commandStart)
            end), function(value)
                ---@cast value string Wow, Lua does NOT know how to use generics.

                return value:match('^' .. commandStart .. '(.-)$')
            end)
        elseif commands[parts[1]] ~= nil then
            return arrayMap(arrayDedupe(commands[table.remove(parts, 1)].complete(parts)), function(value)
                return value:match('^' .. parts[#parts] .. '(.-)$')
            end)
        end

        return {}
    end)

    ---@type string[]
    local parts = {}

    for part in input:gmatch('(%S+)') do
        table.insert(parts, part)
    end

    if #parts == 0 then goto continue end

    if parts[1] == 'exit' then break end

    if not commands[parts[1]] then
        printError('Unknown command:', parts[1])

        goto continue
    end

    local success, reason = commands[table.remove(parts, 1)].call(parts)

    if not success then
        printError('Command failed:', reason)
    end

    ::continue::
end

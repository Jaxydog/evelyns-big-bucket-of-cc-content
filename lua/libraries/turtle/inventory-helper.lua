---A turtle's inventory slot.
---
---@alias evelyn.turtle.inventoryHelper.slot
---| ccTweaked.turtle.side An equipment slot on the side of the turtle.
---| ccTweaked.turtle.slot A slot in the internal inventory.

---A turtle's inventory slot's item data.
---
---@alias evelyn.turtle.inventoryHelper.slotInfo
---| nil No item data.
---| ccTweaked.turtle.slotInfo Basic item data.
---| ccTweaked.turtle.slotInfoDetailed Full item data, at the cost of extra resolution time.

---A function that returns the total number of items in a specific slot.
---
---@alias evelyn.turtle.inventoryHelper.slotCountResolver fun(): integer

---A function that resolves a specific slot's item data.
---
---@alias evelyn.turtle.inventoryHelper.slotInfoResolver fun(detailed?: boolean): evelyn.turtle.inventoryHelper.slotInfo

---Provides useful methods for interacting with a turtle's inventory.
---
---@class evelyn.turtle.inventoryHelper.lib
local module = {}

---Returns the item information for the item in the equipment slot on the specified side.
---
---Note that this function is potentially very slot to call.
---
---@param side ccTweaked.turtle.side The equipment slot side.
---@param detailed? boolean Whether to return more detailed information at the cost of extra resolution time.
---
---@return evelyn.turtle.inventoryHelper.slotInfo info The slot information.
---@return string | nil reason The reason that slot information could not be obtained.
function module:getEquippedDetail(side, detailed)
    local initialSlot = turtle.getSelectedSlot()

    local emptySlot = self:findSlot(function(slot, countResolver, _)
        return type(slot) == "number" and countResolver() == 0
    end)
    ---@cast emptySlot ccTweaked.turtle.slot | nil

    if emptySlot == nil then return nil, 'Inventory full' end

    turtle.select(emptySlot)

    local equipFunction = side == 'left' and turtle.equipLeft or turtle.equipRight

    do
        local success, reason = equipFunction()

        if not success then return nil, reason end
    end

    local info = turtle.getItemDetail(nil, detailed)

    if info == nil then
        turtle.select(initialSlot)

        return nil, 'Nothing equipped'
    end

    do
        local success, reason = equipFunction()

        if not success then return nil, reason end
    end

    turtle.select(initialSlot)

    return info, nil
end

---Visit the given slot with the provided callback.
---
---@param slot evelyn.turtle.inventoryHelper.slot The slot to visit.
---@param countResolver evelyn.turtle.inventoryHelper.slotCountResolver Resolves the slot's item count.
---@param infoResolver evelyn.turtle.inventoryHelper.slotInfoResolver Resolves the slot's item information.
---@param callback fun(slot: evelyn.turtle.inventoryHelper.slot, countResolver: evelyn.turtle.inventoryHelper.slotCountResolver, infoResolver: evelyn.turtle.inventoryHelper.slotInfoResolver): ... The callback to invoke.
---
---@return ... The return value.
local function visitSlot(slot, countResolver, infoResolver, callback)
    local cache = {}

    return callback(slot, function()
        cache.count = cache.count or countResolver()

        return cache.count
    end, function(detailed)
        local detailKey = detailed and 'detailed' or 'basic'
        local presenceKey = detailKey .. 'Present'

        cache.info = cache.info or {}

        if cache.info[presenceKey] then
            return cache.info[detailKey]
        end

        cache.info[detailKey] = infoResolver(detailed)
        cache.info[presenceKey] = true

        return cache.info[detailKey]
    end)
end

---Visit the given slot with the provided callback.
---
---@param side ccTweaked.turtle.side The equipment slot side.
---@param callback fun(slot: evelyn.turtle.inventoryHelper.slot, countResolver: evelyn.turtle.inventoryHelper.slotCountResolver, infoResolver: evelyn.turtle.inventoryHelper.slotInfoResolver): ... The callback to invoke.
---
---@return ... The return value.
local function visitEquipmentSlot(side, callback)
    return visitSlot(side, function()
        local detail = module:getEquippedDetail(side, false)

        if not detail then return 0 else return detail.count end
    end, function(detailed)
        return module:getEquippedDetail(side, detailed)
    end, callback)
end

---Visit the given slot with the provided callback.
---
---@param slot ccTweaked.turtle.slot The inventory slot.
---@param callback fun(slot: evelyn.turtle.inventoryHelper.slot, countResolver: evelyn.turtle.inventoryHelper.slotCountResolver, infoResolver: evelyn.turtle.inventoryHelper.slotInfoResolver): ... The callback to invoke.
---
---@return ... The return value.
local function visitInventorySlot(slot, callback)
    return visitSlot(slot, function()
        return turtle.getItemCount(slot)
    end, function(detailed)
        return turtle.getItemDetail(slot, detailed)
    end, callback)
end

---Calls the given function for every slot within the turtle.
---
---@param callback fun(slot: evelyn.turtle.inventoryHelper.slot, countResolver: evelyn.turtle.inventoryHelper.slotCountResolver, infoResolver: evelyn.turtle.inventoryHelper.slotInfoResolver) The function to call.
function module:forEachSlot(callback)
    visitEquipmentSlot('left', callback)
    visitEquipmentSlot('right', callback)

    for currentSlot = 1, 16, 1 do
        visitInventorySlot(currentSlot, callback)
    end
end

---Calls the given function for every slot within the turtle, returning the first slot for which it holds true.
---
---@param predicate fun(slot: evelyn.turtle.inventoryHelper.slot, countResolver: evelyn.turtle.inventoryHelper.slotCountResolver, infoResolver: evelyn.turtle.inventoryHelper.slotInfoResolver): boolean The function to call.
---
---@return evelyn.turtle.inventoryHelper.slot | nil slot The slot.
---@return evelyn.turtle.inventoryHelper.slotCountResolver | nil countResolver The count resolver function.
---@return evelyn.turtle.inventoryHelper.slotInfoResolver | nil infoResolver The item information resolver function.
function module:findSlot(predicate)
    local found, foundSlot, foundCountResolver, foundInfoResolver

    found, foundSlot, foundCountResolver, foundInfoResolver = visitEquipmentSlot('left',
        function(slot, countResolver, infoResolver)
            return predicate(slot, countResolver, infoResolver), slot, countResolver, infoResolver
        end
    )

    if found then return foundSlot, foundCountResolver, foundInfoResolver end

    found, foundSlot, foundCountResolver, foundInfoResolver = visitEquipmentSlot('right',
        function(slot, countResolver, infoResolver)
            return predicate(slot, countResolver, infoResolver), slot, countResolver, infoResolver
        end
    )

    if found then return foundSlot, foundCountResolver, foundInfoResolver end

    for currentSlot = 1, 16, 1 do
        found, foundSlot, foundCountResolver, foundInfoResolver = visitInventorySlot(currentSlot,
            function(slot, countResolver, infoResolver)
                return predicate(slot, countResolver, infoResolver), slot, countResolver, infoResolver
            end
        )

        if found then return foundSlot, foundCountResolver, foundInfoResolver end
    end

    return nil, nil, nil
end

---Calls the given function for every slot within the turtle, modifying and then returning the initial value.
---
---@generic T The folded type.
---
---@param value T The initial value.
---@param fold fun(value: T, slot: evelyn.turtle.inventoryHelper.slot, countResolver: evelyn.turtle.inventoryHelper.slotCountResolver, infoResolver: evelyn.turtle.inventoryHelper.slotInfoResolver): T The function to call.
---
---@return T value The folded value.
function module:foldSlot(value, fold)
    value = visitEquipmentSlot('left', function(slot, countResolver, infoResolver)
        return fold(value, slot, countResolver, infoResolver)
    end)
    value = visitEquipmentSlot('right', function(slot, countResolver, infoResolver)
        return fold(value, slot, countResolver, infoResolver)
    end)

    for currentSlot = 1, 16, 1 do
        value = visitInventorySlot(currentSlot, function(slot, countResolver, infoResolver)
            return fold(value, slot, countResolver, infoResolver)
        end)
    end

    return value
end

---Attempts to equip an item by its name.
---
---@param name string The item name.
---
---@return boolean success Whether the item was equipped.
---@return string | nil reason The reason the item could not be equipped.
function module:equipByName(name)
    local hasLeft, hasRight = false, false
    local slot = self:findSlot(function(slot, _, infoResolver)
        local info = infoResolver(false)

        if slot == 'left' and info ~= nil then hasLeft = true end
        if slot == 'right' and info ~= nil then hasRight = true end

        return info ~= nil and info.count > 0 and info.name == name
    end)

    if type(slot) == 'string' then return true, nil end
    if not slot then return false, 'Missing item' end
    if hasLeft and hasRight then return false, 'Equipment full' end

    local equipFunction = hasLeft and turtle.equipRight or turtle.equipLeft

    turtle.select(slot)

    return equipFunction()
end

---Attempts to refuel the turtle to full from its inventory.
---
---@param limit? integer The maximum amount of fuel.
---
---@return integer gained The amount of fuel gained.
function module:refuelFromInventory(limit)
    local startingLevel = turtle.getFuelLevel()

    if limit == nil then
        local maxLimit = turtle.getFuelLimit()

        if maxLimit == 'unlimited' then
            limit = math.huge
        else
            ---@cast maxLimit integer
            limit = maxLimit
        end
    end

    self:findSlot(function(slot, countResolver, _)
        if type(slot) == 'string' then return false end
        if countResolver() == 0 then return false end

        turtle.select(slot)

        if turtle.refuel() then return turtle.getFuelLevel() >= limit end

        return false
    end)

    return turtle.getFuelLevel() - startingLevel
end

return module

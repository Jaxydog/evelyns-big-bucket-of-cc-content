---@alias evelyn.SlotInfo ccTweaked.turtle.slotInfo | ccTweaked.turtle.slotInfoDetailed

---@alias evelyn.SlotView.Resolver fun(detailed?: boolean): evelyn.SlotInfo | nil
---@alias evelyn.SlotView.Callback fun(slot: ccTweaked.turtle.slot, count: integer, resolve: evelyn.SlotView.Resolver)
---@alias evelyn.SlotView.Predicate fun(slot: ccTweaked.turtle.slot, count: integer, resolve: evelyn.SlotView.Resolver): boolean

---@class evelyn.TurtleLib
local module = {}

---Calls the given function for every slot in the turtle's inventory.
---
---@param callable evelyn.SlotView.Callback The function to call for every slot.
function module.viewSlots(callable)
    for slot = 1, 16, 1 do
        local count = turtle.getItemCount(slot)
        local maybeResolved = nil
        local maybeResolvedDetailed = nil

        callable(slot, count, function(detailed)
            if detailed then
                maybeResolvedDetailed = maybeResolvedDetailed or turtle.getItemDetail(slot, detailed)

                return maybeResolvedDetailed
            else
                maybeResolved = maybeResolved or turtle.getItemDetail(slot, detailed)

                return maybeResolved
            end
        end)
    end
end

---Calls the given function for every slot in the turtle's inventory, returning the first slot for which it returns true.
---
---@param predicate evelyn.SlotView.Predicate The predicate to call for every slot.
---
---@return ccTweaked.turtle.slot | nil slot The first slot that matched the predicate.
---@return integer? count The number of items in the slot.
---@return evelyn.SlotInfo | evelyn.SlotView.Resolver? resolve A getter for the item's data, or the resolved data if the function has already been called.
function module.findSlot(predicate)
    for slot = 1, 16, 1 do
        local count = turtle.getItemCount(slot)
        local maybeResolved = nil
        local maybeResolvedDetailed = nil

        local resolve = function(detailed)
            if detailed then
                maybeResolvedDetailed = maybeResolvedDetailed or turtle.getItemDetail(slot, detailed)

                return maybeResolvedDetailed
            else
                maybeResolved = maybeResolved or turtle.getItemDetail(slot, detailed)

                return maybeResolved
            end
        end

        if predicate(slot, count, resolve) then
            return slot, count, maybeResolved or resolve
        end
    end

    return nil
end

---Creates a new `getEquipped[side]` function.
---
---@param side 'Left' | 'Right' The side to check.
---
---@return fun(detailed?: boolean): evelyn.SlotInfo | nil function The new function.
local function createGetEquippedFunction(side)
    local equipFunction = turtle['equip' .. side]

    return function(detailed)
        local selectedSlot = turtle.getSelectedSlot()
        local emptySlot = module.findSlot(function(_, count) return count == 0 end)

        assert(emptySlot ~= nil, 'Unable to find an empty slot')

        turtle.select(emptySlot)
        equipFunction()

        local slotInfo = turtle.getItemDetail(emptySlot, detailed)

        equipFunction()
        turtle.select(selectedSlot)

        return slotInfo
    end
end

---Returns the details of the item in the left equipped slot.
module.getEquippedLeft = turtle.getEquippedLeft or createGetEquippedFunction('Left')
---Returns the details of the item in the right equipped slot.
module.getEquippedRight = turtle.getEquippedRight or createGetEquippedFunction('Right')

---Attempts to equip an item with the given name.
---
---@param name string The item's name.
---
---@return boolean equipped Whether the item was equipped.
function module.equip(name)
    local empty = { left = false, right = false }
    local slotInfo = module.getEquippedLeft()

    if slotInfo and slotInfo.name == name then return true end
    if not slotInfo then empty.left = true end

    slotInfo = module.getEquippedRight()

    if slotInfo and slotInfo.name == name then return true end
    if not slotInfo then empty.right = true end

    local slot = module.findSlot(function(_, count, resolve)
        return count > 0 and resolve() ~= nil and resolve().name == name
    end)

    if not slot then return false end

    turtle.select(slot)

    if empty.left then
        turtle.equipLeft()

        return true
    elseif empty.right then
        turtle.equipRight()

        return true
    else
        return false
    end
end

return module

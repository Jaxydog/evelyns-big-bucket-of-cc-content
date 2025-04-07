if not turtle then error('This library must be used on a turtle!') end

---@alias evelyn.Rotation
---| 'front'
---| 'left'
---| 'right'
---| 'back'

---@class evelyn.Transform
---
---@field public position ccTweaked.Vector
---@field public rotation evelyn.Rotation

---@class evelyn.TrackingLib
local module = {}

---Creates a new transformation.
---
---@return evelyn.Transform transform The transformation.
function module.newTransformation()
    return { position = vector.new(0, 0, 0), rotation = 'front' }
end

---Rotates the turtle to the left, updating the given transformation.
---
---@param transform evelyn.Transform The turtle's transformation.
function module.turnLeft(transform)
    turtle.turnLeft()

    if transform.rotation == 'front' then
        transform.rotation = 'left'
    elseif transform.rotation == 'left' then
        transform.rotation = 'back'
    elseif transform.rotation == 'back' then
        transform.rotation = 'right'
    elseif transform.rotation == 'right' then
        transform.rotation = 'front'
    end
end

---Rotates the turtle to the right, updating the given transformation.
---
---@param transform evelyn.Transform The turtle's transformation.
function module.turnRight(transform)
    turtle.turnRight()

    if transform.rotation == 'front' then
        transform.rotation = 'right'
    elseif transform.rotation == 'right' then
        transform.rotation = 'back'
    elseif transform.rotation == 'back' then
        transform.rotation = 'left'
    elseif transform.rotation == 'left' then
        transform.rotation = 'front'
    end
end

---Rotates the turtle twice to the left, updating the given transformation.
---
---@param transform evelyn.Transform The turtle's transformation.
function module.turnAround(transform)
    module.turnLeft(transform)
    module.turnLeft(transform)
end

---Turns the turtle towards the front rotation, updating the given transformation.
---
---@param transform evelyn.Transform The turtle's transformation.
function module.turnTowardsFront(transform)
    if transform.rotation == 'right' then
        module.turnLeft(transform)
    elseif transform.rotation == 'back' then
        module.turnAround(transform)
    elseif transform.rotation == 'left' then
        module.turnRight(transform)
    end
end

---Turns the turtle towards the left rotation, updating the given transformation.
---
---@param transform evelyn.Transform The turtle's transformation.
function module.turnTowardsLeft(transform)
    if transform.rotation == 'front' then
        module.turnLeft(transform)
    elseif transform.rotation == 'right' then
        module.turnAround(transform)
    elseif transform.rotation == 'back' then
        module.turnRight(transform)
    end
end

---Turns the turtle towards the back rotation, updating the given transformation.
---
---@param transform evelyn.Transform The turtle's transformation.
function module.turnTowardsBack(transform)
    if transform.rotation == 'left' then
        module.turnLeft(transform)
    elseif transform.rotation == 'front' then
        module.turnAround(transform)
    elseif transform.rotation == 'right' then
        module.turnRight(transform)
    end
end

---Turns the turtle towards the right rotation, updating the given transformation.
---
---@param transform evelyn.Transform The turtle's transformation.
function module.turnTowardsRight(transform)
    if transform.rotation == 'back' then
        module.turnLeft(transform)
    elseif transform.rotation == 'left' then
        module.turnAround(transform)
    elseif transform.rotation == 'front' then
        module.turnRight(transform)
    end
end

---Turns the turtle towards the given rotation, updating the given transformation.
---
---@param transform evelyn.Transform The turtle's transformation.
---@param rotation evelyn.Rotation The target rotation.
function module.turnTowards(transform, rotation)
    if rotation == 'front' then
        module.turnTowardsFront(transform)
    elseif rotation == 'back' then
        module.turnTowardsBack(transform)
    elseif rotation == 'left' then
        module.turnTowardsLeft(transform)
    elseif rotation == 'right' then
        module.turnTowardsRight(transform)
    end
end

---Moves the turtle forwards by the given amount, updating the given transformation.
---
---@param transform evelyn.Transform The turtle's transformation.
---@param amount? integer The number of blocks to move.
---@param breakBlocks? boolean Whether to break blocks that are in the way.
---
---@return boolean moved Whether the turtle was able to move by the specified amount.
function module.moveFront(transform, amount, breakBlocks)
    amount = amount or 1

    if breakBlocks == nil then breakBlocks = false end

    assert(amount > 0, 'The given amount must be greater than zero')

    for _ = 1, amount, 1 do
        while breakBlocks and turtle.detect() and turtle.dig() do end

        if not turtle.forward() then return false end

        if transform.rotation == 'front' then
            transform.position.z = transform.position.z - 1
        elseif transform.rotation == 'back' then
            transform.position.z = transform.position.z + 1
        elseif transform.rotation == 'left' then
            transform.position.x = transform.position.x - 1
        elseif transform.rotation == 'right' then
            transform.position.x = transform.position.x + 1
        end
    end

    return true
end

---Moves the turtle backwards by the given amount, updating the given transformation.
---
---@param transform evelyn.Transform The turtle's transformation.
---@param amount? integer The number of blocks to move.
---
---@return boolean moved Whether the turtle was able to move by the specified amount.
function module.moveBack(transform, amount)
    amount = amount or 1

    assert(amount > 0, 'The given amount must be greater than zero')

    for _ = 1, amount, 1 do
        if not turtle.back() then return false end

        if transform.rotation == 'front' then
            transform.position.z = transform.position.z + 1
        elseif transform.rotation == 'back' then
            transform.position.z = transform.position.z - 1
        elseif transform.rotation == 'left' then
            transform.position.x = transform.position.x + 1
        elseif transform.rotation == 'right' then
            transform.position.x = transform.position.x - 1
        end
    end

    return true
end

---Moves the turtle upwards by the given amount, updating the given transformation.
---
---@param transform evelyn.Transform The turtle's transformation.
---@param amount? integer The number of blocks to move.
---@param breakBlocks? boolean Whether to break blocks that are in the way.
---
---@return boolean moved Whether the turtle was able to move by the specified amount.
function module.moveUp(transform, amount, breakBlocks)
    amount = amount or 1

    if breakBlocks == nil then breakBlocks = false end

    assert(amount > 0, 'The given amount must be greater than zero')

    for _ = 1, amount, 1 do
        while breakBlocks and turtle.detectUp() and turtle.digUp() do end

        if not turtle.up() then return false end

        transform.position.y = transform.position.y + 1
    end

    return true
end

---Moves the turtle downwards by the given amount, updating the given transformation.
---
---@param transform evelyn.Transform The turtle's transformation.
---@param amount? integer The number of blocks to move.
---@param breakBlocks? boolean Whether to break blocks that are in the way.
---
---@return boolean moved Whether the turtle was able to move by the specified amount.
function module.moveDown(transform, amount, breakBlocks)
    amount = amount or 1

    if breakBlocks == nil then breakBlocks = false end

    assert(amount > 0, 'The given amount must be greater than zero')

    for _ = 1, amount, 1 do
        while breakBlocks and turtle.detectDown() and turtle.digDown() do end

        if not turtle.down() then return false end

        transform.position.y = transform.position.y - 1
    end

    return true
end

---Moves the turtle to the given X position, updating the given transformation.
---
---@param transform evelyn.Transform The turtle's transformation.
---@param x integer The target position.
---@param breakBlocks? boolean Whether to break blocks that are in the way.
---
---@return boolean moved Whether the turtle was able to move by the specified amount.
function module.moveToX(transform, x, breakBlocks)
    local difference = x - transform.position.x

    if difference < 0 then
        module.turnTowardsLeft(transform)

        return module.moveFront(transform, -difference, breakBlocks)
    elseif difference > 0 then
        module.turnTowardsRight(transform)

        return module.moveFront(transform, -difference, breakBlocks)
    end

    return true
end

---Moves the turtle to the given Y position, updating the given transformation.
---
---@param transform evelyn.Transform The turtle's transformation.
---@param y integer The target position.
---@param breakBlocks? boolean Whether to break blocks that are in the way.
---
---@return boolean moved Whether the turtle was able to move by the specified amount.
function module.moveToY(transform, y, breakBlocks)
    local difference = y - transform.position.y

    if difference < 0 then
        return module.moveDown(transform, -difference, breakBlocks)
    elseif difference > 0 then
        return module.moveUp(transform, difference, breakBlocks)
    end

    return true
end

---Moves the turtle to the given Z position, updating the given transformation.
---
---@param transform evelyn.Transform The turtle's transformation.
---@param z integer The target position.
---@param breakBlocks? boolean Whether to break blocks that are in the way.
---
---@return boolean moved Whether the turtle was able to move by the specified amount.
function module.moveToZ(transform, z, breakBlocks)
    local difference = z - transform.position.x

    if difference < 0 then
        module.turnTowardsBack(transform)

        return module.moveFront(transform, -difference, breakBlocks)
    elseif difference > 0 then
        module.turnTowardsFront(transform)

        return module.moveFront(transform, -difference, breakBlocks)
    end

    return true
end

---Moves the turtle to the given position, updating the given transformation.
---
---@param transform evelyn.Transform The turtle's transformation.
---@param position ccTweaked.Vector The target position.
---@param breakBlocks? boolean Whether to break blocks that are in the way.
---
---@return boolean moved Whether the turtle was able to move by the specified amount.
function module.moveTo(transform, position, breakBlocks)
    return module.moveToX(transform, position.x, breakBlocks)
        and module.moveToY(transform, position.y, breakBlocks)
        and module.moveToZ(transform, position.z, breakBlocks)
end

return module

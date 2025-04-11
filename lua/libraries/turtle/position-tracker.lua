---A turtle's direction.
---
---@alias evelyn.turtle.positionTracker.direction
---| 'north'
---| 'east'
---| 'south'
---| 'west'

---The world-space for a turtle's transform.
---
---This describes whether a transform's coordinates and direction are absolute or relative to the turtle's state at the
---transform's time of creation.
---
---@alias evelyn.turtle.positionTracker.worldSpace
---| 'local'
---| 'global'

---Determines whether to attempt use GPS when creating a transform.
---
---@alias evelyn.turtle.positionTracker.gpsChoice
---| 'always'
---| 'never'

---A turtle's position.
---
---@class evelyn.turtle.positionTracker.position
---
---@field public x integer The turtle's X position.
---@field public y integer The turtle's Y position.
---@field public z integer The turtle's Z position.

---A turtle transformation.
---
---@class evelyn.turtle.positionTracker.transform
---
---@field public position evelyn.turtle.positionTracker.position The turtle's position.
---@field public direction evelyn.turtle.positionTracker.direction The turtle's direction.
---@field public space evelyn.turtle.positionTracker.worldSpace The transform's world-space.

---Additional options that may be provided when creating a transform.
---
---@class evelyn.turtle.positionTracker.transformOptions
---
---@field public gpsTimeout? integer The timeout duration in seconds for GPS connections.
---@field public skipGps? boolean Whether to skip the GPS connection attempt.

---Additional options that may be provided when moving a turtle.
---
---@class evelyn.turtle.positionTracker.moveOptions
---
---@field public blocks? integer The number of blocks to move. If negative, the turtle moves in reverse.
---@field public breakBlocks? boolean | string[] Whether to break blocks if the destination is obstructed. Can be a list of block identifiers.

---Provides positional tracking for turtles to make movement management easier.
---
---@class evelyn.turtle.positionTracker.lib
local module = {}

---Whether to attempt to resolve the turtle's global position using GPS.
---
---@type evelyn.turtle.positionTracker.gpsChoice
module.gps = 'always'

---Creates a new turtle transform.
---
---It should be assumed that, when using GPS positioning, this function may take some time to complete.
---
---@param options evelyn.turtle.positionTracker.transformOptions Additional options.
---
---@return evelyn.turtle.positionTracker.transform transform The transform.
function module:createTransform(options)
    options = options or {}

    if options.skipGps or module.gps == 'never' or peripheral.find('modem') == nil then
        return { position = { x = 0, y = 0, z = 0 }, direction = 'north', space = 'local' }
    end

    local x, y, z = gps.locate(options.gpsTimeout or 2, false)

    if x == nil or y == nil or z == nil then
        options.skipGps = true

        return self:createTransform(options)
    end

    ---@type evelyn.turtle.positionTracker.position
    local position = { x = x, y = y, z = z }
    local turns = 0

    while turtle.detect() and turns < 3 do
        turtle.turnRight()

        turns = turns + 1
    end

    if turtle.detect() then
        options.skipGps = true

        return self:createTransform(options)
    end

    turtle.forward()

    x, y, z = gps.locate(options.gpsTimeout or 2, false)

    turtle.back()

    if x == nil or y == nil or z == nil then
        options.skipGps = true

        return self:createTransform(options)
    end

    ---@type evelyn.turtle.positionTracker.direction
    local direction

    if z - position.z < 0 then
        direction = 'north'
    elseif x - position.x < 0 then
        direction = 'west'
    elseif x - position.x > 0 then
        direction = 'east'
    elseif z - position.z > 0 then
        direction = 'south'
    end

    ---@type evelyn.turtle.positionTracker.transform
    local transform = { position = position, direction = direction, space = 'global' }

    while turns > 0 do
        self.turn:left(transform)

        turns = turns - 1
    end

    return transform
end

---Handles turtle turning.
---
---@class evelyn.turtle.positionTracker.lib.turn
module.turn = {}

---Turns the turtle left, updating the given transform.
---
---@param transform evelyn.turtle.positionTracker.transform The turtle's transform.
---
---@return boolean success Whether the turtle successfully turned.
---@return string | nil reason The reason that the turtle failed to turn.
function module.turn:left(transform)
    local success, reason = turtle.turnLeft()

    if not success then return false, reason end

    if transform.direction == 'north' then
        transform.direction = 'west'
    elseif transform.direction == 'east' then
        transform.direction = 'north'
    elseif transform.direction == 'south' then
        transform.direction = 'east'
    elseif transform.direction == 'west' then
        transform.direction = 'south'
    end

    return true, nil
end

---Turns the turtle left, updating the given transform.
---
---@param transform evelyn.turtle.positionTracker.transform The turtle's transform.
---
---@return boolean success Whether the turtle successfully turned.
---@return string | nil reason The reason that the turtle failed to turn.
function module.turn:right(transform)
    local success, reason = turtle.turnRight()

    if not success then return false, reason end

    if transform.direction == 'north' then
        transform.direction = 'east'
    elseif transform.direction == 'east' then
        transform.direction = 'south'
    elseif transform.direction == 'south' then
        transform.direction = 'west'
    elseif transform.direction == 'west' then
        transform.direction = 'north'
    end

    return true, nil
end

---Turns the turtle around, updating the given transform.
---
---@param transform evelyn.turtle.positionTracker.transform The turtle's transform.
---
---@return boolean success Whether the turtle successfully turned.
---@return string | nil reason The reason that the turtle failed to turn.
function module.turn:around(transform)
    local success, reason = self:left(transform)

    if not success then return false, reason end

    return self:left(transform)
end

---Turns the turtle towards north, updating the given transform.
---
---If the turtle is already facing north, this function does nothing.
---
---@param transform evelyn.turtle.positionTracker.transform The turtle's transform.
---
---@return boolean success Whether the turtle successfully turned.
---@return string | nil reason The reason that the turtle failed to turn.
function module.turn:north(transform)
    if transform.direction == 'north' then
        return true, nil
    elseif transform.direction == 'east' then
        return self:left(transform)
    elseif transform.direction == 'south' then
        return self:around(transform)
    elseif transform.direction == 'west' then
        return self:right(transform)
    end

    error('Invalid direction state')
end

---Turns the turtle towards north, updating the given transform.
---
---If the turtle is already facing north, this function does nothing.
---
---@param transform evelyn.turtle.positionTracker.transform The turtle's transform.
---
---@return boolean success Whether the turtle successfully turned.
---@return string | nil reason The reason that the turtle failed to turn.
function module.turn:east(transform)
    if transform.direction == 'north' then
        return self:right(transform)
    elseif transform.direction == 'east' then
        return true, nil
    elseif transform.direction == 'south' then
        return self:left(transform)
    elseif transform.direction == 'west' then
        return self:around(transform)
    end

    error('Invalid direction state')
end

---Turns the turtle towards north, updating the given transform.
---
---If the turtle is already facing north, this function does nothing.
---
---@param transform evelyn.turtle.positionTracker.transform The turtle's transform.
---
---@return boolean success Whether the turtle successfully turned.
---@return string | nil reason The reason that the turtle failed to turn.
function module.turn:south(transform)
    if transform.direction == 'north' then
        return self:right(transform)
    elseif transform.direction == 'east' then
        return self:right(transform)
    elseif transform.direction == 'south' then
        return true, nil
    elseif transform.direction == 'west' then
        return self:left(transform)
    end

    error('Invalid direction state')
end

---Turns the turtle towards north, updating the given transform.
---
---If the turtle is already facing north, this function does nothing.
---
---@param transform evelyn.turtle.positionTracker.transform The turtle's transform.
---
---@return boolean success Whether the turtle successfully turned.
---@return string | nil reason The reason that the turtle failed to turn.
function module.turn:west(transform)
    if transform.direction == 'north' then
        return self:left(transform)
    elseif transform.direction == 'east' then
        return self:around(transform)
    elseif transform.direction == 'south' then
        return self:right(transform)
    elseif transform.direction == 'west' then
        return true, nil
    end

    error('Invalid direction state')
end

---Turns the turtle to face the given direction, updating the given transform.
---
---If the turtle is already facing the given direction, this function does nothing.
---
---@param transform evelyn.turtle.positionTracker.transform The turtle's transform.
---@param direction evelyn.turtle.positionTracker.direction The new direction.
---
---@return boolean success Whether the turtle successfully turned.
---@return string | nil reason The reason that the turtle failed to turn.
function module.turn:towards(transform, direction)
    if direction == 'north' then
        return self:north(transform)
    elseif direction == 'east' then
        return self:east(transform)
    elseif direction == 'south' then
        return self:south(transform)
    elseif direction == 'west' then
        return self:west(transform)
    end

    error('Invalid direction argument')
end

---Handles turtle movement.
---
---@class evelyn.turtle.positionTracker.lib.move
module.move = {}

---Attempts to break the block in front of the turtle.
---
---@param detect fun(): boolean The detection function.
---@param inspect fun(): boolean, string | ccTweaked.turtle.inspectInfo The inspection function.
---@param dig fun(): boolean, string | nil The digging function.
---@param blocks? string[] The list of block names to break.
---
---@return boolean success Whether the turtle successfully broke the block.
---@return string | nil reason The reason that the turtle failed to broke the block.
local function breakBlockAhead(detect, inspect, dig, blocks)
    if not detect() then return true, nil end
    if blocks == nil then return dig() end

    local _, data = inspect()

    assert(type(data) ~= 'string', 'Missing block data')

    for _, name in ipairs(blocks) do
        if data.name == name then return dig() end
    end

    return false, ('Breaking not permitted for %s'):format(data.name)
end

---Moves the turtle forwards, updating the given transform.
---
---If the amount of moved blocks is set to zero, this function does nothing.
---
---@param transform evelyn.turtle.positionTracker.transform The turtle's transform.
---@param options? evelyn.turtle.positionTracker.moveOptions Additional movement options.
---
---@return boolean success Whether the turtle successfully moved.
---@return string | nil reason The reason that the turtle failed to move.
function module.move:forward(transform, options)
    options = options or {}

    local blocks = options.blocks or 1

    if blocks == 0 then
        return true, nil
    elseif blocks < 0 then
        options.blocks = -blocks

        return self:backward(transform, options)
    end

    for _ = 1, blocks, 1 do
        while options.breakBlocks ~= nil and options.breakBlocks ~= false and turtle.detect() do
            local breakBlocks = options.breakBlocks
            local success, reason

            if type(breakBlocks) == 'boolean' then
                success, reason = breakBlockAhead(turtle.detect, turtle.inspect, turtle.dig)
            else
                success, reason = breakBlockAhead(turtle.detect, turtle.inspect, turtle.dig, breakBlocks)
            end

            if not success then return false, reason end
        end

        local success, reason = turtle.forward()

        if not success then return false, reason end

        if transform.direction == 'north' then
            transform.position.z = transform.position.z - 1
        elseif transform.direction == 'east' then
            transform.position.x = transform.position.x + 1
        elseif transform.direction == 'south' then
            transform.position.z = transform.position.z + 1
        elseif transform.direction == 'west' then
            transform.position.x = transform.position.x - 1
        else
            error('Invalid direction state')
        end
    end

    return true, nil
end

---Moves the turtle backwards, updating the given transform.
---
---If the amount of moved blocks is set to zero, this function does nothing.
---
---@param transform evelyn.turtle.positionTracker.transform The turtle's transform.
---@param options? evelyn.turtle.positionTracker.moveOptions Additional movement options.
---
---@return boolean success Whether the turtle successfully moved.
---@return string | nil reason The reason that the turtle failed to move.
function module.move:backward(transform, options)
    options = options or {}

    local blocks = options.blocks or 1

    if blocks == 0 then
        return true, nil
    elseif blocks < 0 then
        options.blocks = -blocks

        return self:forward(transform, options)
    end

    for block = 1, blocks, 1 do
        local success, reason = turtle.back()

        if not success then
            if reason ~= 'Movement obstructed' then return false, reason end

            success, reason = module.turn:around(transform)

            if not success then return false, reason end

            options.blocks = blocks - (block - 1)

            success, reason = self:forward(transform, options)

            if not success then return false, reason end

            return module.turn:around(transform)
        end

        if transform.direction == 'north' then
            transform.position.z = transform.position.z - 1
        elseif transform.direction == 'east' then
            transform.position.x = transform.position.x + 1
        elseif transform.direction == 'south' then
            transform.position.z = transform.position.z + 1
        elseif transform.direction == 'west' then
            transform.position.x = transform.position.x - 1
        else
            error('Invalid direction state')
        end
    end

    return true, nil
end

---Moves the turtle up, updating the given transform.
---
---If the amount of moved blocks is set to zero, this function does nothing.
---
---@param transform evelyn.turtle.positionTracker.transform The turtle's transform.
---@param options? evelyn.turtle.positionTracker.moveOptions Additional movement options.
---
---@return boolean success Whether the turtle successfully moved.
---@return string | nil reason The reason that the turtle failed to move.
function module.move:up(transform, options)
    options = options or {}

    local blocks = options.blocks or 1

    if blocks == 0 then
        return true, nil
    elseif blocks < 0 then
        options.blocks = -blocks

        return self:down(transform, options)
    end

    for _ = 1, blocks, 1 do
        while options.breakBlocks ~= nil and options.breakBlocks ~= false and turtle.detectUp() do
            local breakBlocks = options.breakBlocks
            local success, reason

            if type(breakBlocks) == 'boolean' then
                success, reason = breakBlockAhead(turtle.detectUp, turtle.inspectUp, turtle.digUp)
            else
                success, reason = breakBlockAhead(turtle.detectUp, turtle.inspectUp, turtle.digUp, breakBlocks)
            end

            if not success then return false, reason end
        end

        local success, reason = turtle.up()

        if not success then return false, reason end

        transform.position.y = transform.position.y + 1
    end

    return true, nil
end

---Moves the turtle down, updating the given transform.
---
---If the amount of moved blocks is set to zero, this function does nothing.
---
---@param transform evelyn.turtle.positionTracker.transform The turtle's transform.
---@param options? evelyn.turtle.positionTracker.moveOptions Additional movement options.
---
---@return boolean success Whether the turtle successfully moved.
---@return string | nil reason The reason that the turtle failed to move.
function module.move:down(transform, options)
    options = options or {}

    local blocks = options.blocks or 1

    if blocks == 0 then
        return true, nil
    elseif blocks < 0 then
        options.blocks = -blocks

        return self:up(transform, options)
    end

    for _ = 1, blocks, 1 do
        while options.breakBlocks ~= nil and options.breakBlocks ~= false and turtle.detectDown() do
            local breakBlocks = options.breakBlocks
            local success, reason

            if type(breakBlocks) == 'boolean' then
                success, reason = breakBlockAhead(turtle.detectDown, turtle.inspectDown, turtle.digDown)
            else
                success, reason = breakBlockAhead(turtle.detectDown, turtle.inspectDown, turtle.digDown, breakBlocks)
            end

            if not success then return false, reason end
        end

        local success, reason = turtle.down()

        if not success then return false, reason end

        transform.position.y = transform.position.y + 1
    end

    return true, nil
end

---Moves the turtle towards the north, updating the given transform.
---
---If the amount of moved blocks is set to zero, this function does nothing.
---
---@param transform evelyn.turtle.positionTracker.transform The turtle's transform.
---@param options? evelyn.turtle.positionTracker.moveOptions Additional movement options.
---
---@return boolean success Whether the turtle successfully moved.
---@return string | nil reason The reason that the turtle failed to move.
function module.move:north(transform, options)
    local success, reason = module.turn:north(transform)

    if not success then return false, reason end

    return self:forward(transform, options)
end

---Moves the turtle towards the east, updating the given transform.
---
---If the amount of moved blocks is set to zero, this function does nothing.
---
---@param transform evelyn.turtle.positionTracker.transform The turtle's transform.
---@param options? evelyn.turtle.positionTracker.moveOptions Additional movement options.
---
---@return boolean success Whether the turtle successfully moved.
---@return string | nil reason The reason that the turtle failed to move.
function module.move:east(transform, options)
    local success, reason = module.turn:east(transform)

    if not success then return false, reason end

    return self:forward(transform, options)
end

---Moves the turtle towards the south, updating the given transform.
---
---If the amount of moved blocks is set to zero, this function does nothing.
---
---@param transform evelyn.turtle.positionTracker.transform The turtle's transform.
---@param options? evelyn.turtle.positionTracker.moveOptions Additional movement options.
---
---@return boolean success Whether the turtle successfully moved.
---@return string | nil reason The reason that the turtle failed to move.
function module.move:south(transform, options)
    local success, reason = module.turn:south(transform)

    if not success then return false, reason end

    return self:forward(transform, options)
end

---Moves the turtle towards the west, updating the given transform.
---
---If the amount of moved blocks is set to zero, this function does nothing.
---
---@param transform evelyn.turtle.positionTracker.transform The turtle's transform.
---@param options? evelyn.turtle.positionTracker.moveOptions Additional movement options.
---
---@return boolean success Whether the turtle successfully moved.
---@return string | nil reason The reason that the turtle failed to move.
function module.move:west(transform, options)
    local success, reason = module.turn:west(transform)

    if not success then return false, reason end

    return self:forward(transform, options)
end

---Moves the turtle towards the given direction, updating the given transform.
---
---If the amount of moved blocks is set to zero, this function does nothing.
---
---@param transform evelyn.turtle.positionTracker.transform The turtle's transform.
---@param direction evelyn.turtle.positionTracker.direction The movement direction.
---@param options? evelyn.turtle.positionTracker.moveOptions Additional movement options.
---
---@return boolean success Whether the turtle successfully moved.
---@return string | nil reason The reason that the turtle failed to move.
function module.move:towards(transform, direction, options)
    local success, reason = module.turn:towards(transform, direction)

    if not success then return false, reason end

    return self:forward(transform, options)
end

---Moves the turtle to the given X position, updating the given transform.
---
---If the amount of moved blocks is set to zero, this function does nothing.
---
---@param transform evelyn.turtle.positionTracker.transform The turtle's transform.
---@param x integer The X position.
---@param options? evelyn.turtle.positionTracker.moveOptions Additional movement options.
---
---@return boolean success Whether the turtle successfully moved.
---@return string | nil reason The reason that the turtle failed to move.
function module.move:x(transform, x, options)
    options = options or {}

    local difference = x - transform.position.x

    if difference < 0 then
        options.blocks = -difference

        return self:west(transform, options)
    elseif difference > 0 then
        options.blocks = difference

        return self:east(transform, options)
    end

    return true, nil
end

---Moves the turtle to the given Y position, updating the given transform.
---
---If the amount of moved blocks is set to zero, this function does nothing.
---
---@param transform evelyn.turtle.positionTracker.transform The turtle's transform.
---@param y integer The Y position.
---@param options? evelyn.turtle.positionTracker.moveOptions Additional movement options.
---
---@return boolean success Whether the turtle successfully moved.
---@return string | nil reason The reason that the turtle failed to move.
function module.move:y(transform, y, options)
    options = options or {}

    local difference = y - transform.position.y

    if difference < 0 then
        options.blocks = -difference

        return self:down(transform, options)
    elseif difference > 0 then
        options.blocks = difference

        return self:up(transform, options)
    end

    return true, nil
end

---Moves the turtle to the given Z position, updating the given transform.
---
---If the amount of moved blocks is set to zero, this function does nothing.
---
---@param transform evelyn.turtle.positionTracker.transform The turtle's transform.
---@param z integer The Z position.
---@param options? evelyn.turtle.positionTracker.moveOptions Additional movement options.
---
---@return boolean success Whether the turtle successfully moved.
---@return string | nil reason The reason that the turtle failed to move.
function module.move:z(transform, z, options)
    options = options or {}

    local difference = z - transform.position.z

    if difference < 0 then
        options.blocks = -difference

        return self:north(transform, options)
    elseif difference > 0 then
        options.blocks = difference

        return self:south(transform, options)
    end

    return true, nil
end

---Moves the turtle to the given position, updating the given transform.
---
---If the amount of moved blocks is set to zero, this function does nothing.
---
---@param transform evelyn.turtle.positionTracker.transform The turtle's transform.
---@param x integer The X position.
---@param y integer The Y position.
---@param z integer The Z position.
---@param options? evelyn.turtle.positionTracker.moveOptions Additional movement options.
---
---@return boolean success Whether the turtle successfully moved.
---@return string | nil reason The reason that the turtle failed to move.
function module.move:to(transform, x, y, z, options)
    local success, reason = self:y(transform, y, options)

    if not success then return false, reason end

    success, reason = self:z(transform, z, options)

    if not success then return false, reason end

    return self:x(transform, x, options)
end

return module

if not externalRequire then
    if not package.path:match('/%.evelyns%-libraries') then
        package.path = package.path .. ';/.evelyns-libraries/?.lua'
    end

    require('external-require')
end

print('Loading program...')

term.setTextColor(colors.black)

---@type evelyn.ConsoleLib
local console = externalRequire('console')
---@type evelyn.TrackingLib
local tracking = externalRequire('tracking')
---@type evelyn.TurtleLib
local turtleExt = externalRequire('turtle-extensions')

term.clear()
term.setCursorPos(1, 1)
term.setTextColor(colors.white)

console.logInfo('Searching for diamond pickaxe...')

if not turtleExt.equip('minecraft:diamond_pickaxe') then
    console.logError('Missing diamond pickaxe')

    return 1
end

print()

local dimensions = vector.new(0, 0, 0)

::retryReadX::

dimensions.x = console.readInteger('Area width')

if dimensions.x <= 0 then
    console.logError('Size must be greater than 0')

    goto retryReadX
end

::retryReadY::

dimensions.y = console.readInteger('Area height')

if dimensions.y <= 0 then
    console.logError('Size must be greater than 0')

    goto retryReadY
end

::retryReadZ::

dimensions.z = console.readInteger('Area depth')

if dimensions.z <= 0 then
    console.logError('Size must be greater than 0')

    goto retryReadZ
end

if console.readBoolean('Use additional storage?') then
    turtle.select(1)

    local size = 0

    ::retryPlaceStorage::

    do
        local inventory = peripheral.find('inventory', function(name)
            return name == 'top'
        end)

        if inventory then
            size = inventory.size()

            goto placeStorageSucceeded
        end
    end

    if turtle.detectUp() then
        console.logError('Top block is obstructed')

        goto placeStorageFailed
    end
    if not turtle.getItemDetail() then
        console.logInfo('No item in selected slot')

        goto placeStorageFailed
    end
    if not turtle.placeUp() then
        console.logError('Cannot place item in selected slot')

        goto placeStorageFailed
    end

    do
        sleep(0.1) --Wait two ticks for the blocks to update.

        local inventory = peripheral.find('inventory', function(name)
            return name == 'top'
        end)

        if not inventory then
            turtle.digUp()

            console.logError('Item in selected slot is not an inventory')

            goto placeStorageFailed
        end

        size = inventory.size()
    end

    goto placeStorageSucceeded

    ::placeStorageFailed::

    if console.readBoolean('Retry?') then
        goto retryPlaceStorage
    else
        goto cancelStorage
    end

    ::placeStorageSucceeded::

    console.logInfo(('Attached storage with %d slots'):format(size))

    ::cancelStorage::
end

local transform = tracking.newTransformation()
local maxX = math.floor((dimensions.x - 1) / 2)
local minX = -math.ceil((dimensions.x - 1) / 2)

local unchunkedY = dimensions.y % 3
local maxY = dimensions.y - (unchunkedY == 0 and 2 or unchunkedY)
local minY = math.min(maxY, 1)

local fuelLevel = turtle.getFuelLevel()
local fuelLimit = turtle.getFuelLimit()
local fuelEstimate = math.ceil(1.1 *
    (
        1 + math.ceil((dimensions.x - 1) / 2) +              --Initial positioning
        (dimensions.z * 2) +                                 --Z traversal
        math.ceil(dimensions.y * (2 / 3)) +                  --Y chunked traversal
        math.min(unchunkedY, 1) +                            --Y unchunked traversal
        (dimensions.x * math.ceil(dimensions.y * (2 / 3))) + --X chunked traversal
        (dimensions.x * math.min(unchunkedY, 1)) +           --X unchunked traversal
        -minX +                                              --X return
        maxY +                                               --Y return
        (dimensions.z - 1)                                   --Z return
    )
)

print()

console.logInfo(('Estimated fuel cost: %d / %d'):format(fuelEstimate, fuelLimit))
console.logInfo(('Current fuel level: %d'):format(fuelLevel))

if fuelEstimate > fuelLimit then
    console.logError('Excavated area is too big')

    goto excavationFailed
elseif fuelLevel < fuelEstimate then
    print()

    ::retryRefuel::

    console.logInfo('Attempting refuel...')

    turtleExt.viewSlots(function(slot, count)
        if fuelLevel >= fuelEstimate or count == 0 then return end

        turtle.select(slot)
        turtle.refuel()
    end)

    fuelLevel = turtle.getFuelLevel()

    print()

    if fuelLevel >= fuelEstimate then
        console.logInfo(('Estimated fuel cost: %d / %d'):format(fuelEstimate, fuelLimit))
        console.logInfo(('Current fuel level: %d'):format(fuelLevel))
    else
        console.logError(('Estimated fuel cost: %d / %d'):format(fuelEstimate, fuelLimit))
        console.logError(('Current fuel level: %d'):format(fuelLevel))

        if console.readBoolean('Retry?') then
            goto retryRefuel
        else
            goto excavationFailed
        end
    end
end

console.logInfo('Starting excavation!')

for targetZ = 1, dimensions.z, 1 do
    console.logInfo(('Digging layer %d / %d'):format(targetZ, dimensions.z))

    if not tracking.moveToZ(transform, targetZ, true) then goto excavationFailed end

    local startY, finishY, dirY

    if transform.position.y == maxY then
        startY, finishY, dirY = maxY, minY, -3
    else
        startY, finishY, dirY = minY, maxY, 3
    end

    for targetY = startY, finishY, dirY do
        ::unchunkedLoop::

        if not tracking.moveToY(transform, targetY, true) then goto excavationFailed end

        local startX, finishX, dirX

        if transform.position.x == maxX then
            startX, finishX, dirX = maxX, minX, -1
        else
            startX, finishX, dirX = minX, maxX, 1
        end

        for targetX = startX, finishX, dirX do
            if not tracking.moveToX(transform, targetX, true) then goto excavationFailed end

            while targetY ~= dimensions.y - 1 and turtle.detectUp() and turtle.digUp() do end
            while targetY ~= 0 and turtle.detectDown() and turtle.digDown() do end
        end

        if targetY ~= finishY and targetY + 3 > finishY then
            targetY = finishY

            goto unchunkedLoop
        end
    end
end

console.logInfo('Excavation succeeded!')

goto recenter

::excavationFailed::

console.logError('Excavation failed!')

::recenter::

if not tracking.moveTo(transform, vector.new(0, 0, 0), true) then
    goto excavationFailed
end

tracking.turnTowardsFront(transform)

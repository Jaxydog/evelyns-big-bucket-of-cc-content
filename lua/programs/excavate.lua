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

local dimensions = vector.new(0, 0, 0)

::retryReadX::

print()

dimensions.x = console.readInteger('Area width')

if dimensions.x <= 0 then
    console.logError('Size must be greater than 0')

    goto retryReadX
end

::retryReadY::

print()

dimensions.y = console.readInteger('Area height')

if dimensions.y <= 0 then
    console.logError('Size must be greater than 0')

    goto retryReadY
end

::retryReadZ::

print()

dimensions.z = console.readInteger('Area depth')

if dimensions.z <= 0 then
    console.logError('Size must be greater than 0')

    goto retryReadZ
end

::retryPlaceStorage::

print()

if console.readBoolean('Place additional storage?') then
    turtle.select(1)

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
        local inventory = peripheral.find('inventory', function(name)
            return name == 'top'
        end)

        if not inventory then
            turtle.digUp()

            console.logError('Item in selected slot is not an inventory')

            goto placeStorageFailed
        end
    end

    goto placeStorageSucceeded

    ::placeStorageFailed::

    if console.readBoolean('Retry?') then
        goto retryPlaceStorage
    end

    ::placeStorageSucceeded::

    console.logInfo(('Attached storage with %d slots'):format(inventory.size))
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
        1 + math.ceil((dimensions.x - 1) / 2) +            --Initial positioning
        (dimensions.z * 2) +                               --Z traversal
        math.ceil(dimensions.y * (2 / 3)) +                --Y chunked traversal
        math.min(unchunkedY, 1) +                          --Y unchunked traversal
        (dimensions.x * math.ceil(dimensions * (2 / 3))) + --X chunked traversal
        (dimensions.x * math.min(unchunkedY, 1)) +         --X unchunked traversal
        -minX +                                            --X return
        maxY +                                             --Y return
        (dimensions.z - 1)                                 --Z return
    )
)

print()

console.logInfo(('Estimated fuel cost: %d / %d'):format(fuelEstimate, fuelLimit))
console.logInfo(('Current fuel level: %d'):format(fuelLevel))

if fuelEstimate > fuelLimit then
    console.logError('Excavated area is too big')

    goto excavationFailed
elseif fuelLevel < fuelEstimate then
    ::retryRefuel::

    print()

    console.logInfo('Attempting refuel...')

    turtleExt.viewSlots(function(slot, count)
        if fuelLimit >= fuelEstimate or count == 0 then return end

        turtle.select(slot)
        turtle.refuel()
    end)

    fuelLevel = turtle.getFuelLevel()

    print()

    if fuelLevel >= fuelEstimate then
        console.logInfo(('Estimated fuel cost: %d / %d'):format(fuelEstimate, fuelLimit))
        console.logInfo(('Current fuel level: %d'):format(fuelLimit))
    else
        console.logError(('Estimated fuel cost: %d / %d'):format(fuelEstimate, fuelLimit))
        console.logError(('Current fuel level: %d'):format(fuelLimit))

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

    if not tracking.moveToZ(transform, targetZ, true) then
        goto excavationFailed
    end

    local startY, finishY

    if transform.position.y == maxY then
        startY, finishY = maxY, minY
    else
        startY, finishY = minY, maxY
    end

    for targetY = startY, finishY, 3 do
        ::digExtra::

        if not tracking.moveToY(transform, targetY, true) then
            goto excavationFailed
        end

        local startX, finishX

        if transform.position.x == maxX then
            startX, finishX = maxX, minX
        else
            startX, finishX = minX, maxX
        end

        for targetX = startX, finishX, 1 do
            if not tracking.moveToX(transform, targetX, true) then
                goto excavationFailed
            end

            while targetY ~= dimensions.y - 1 and turtle.detectUp() and turtle.digUp() do end
            while targetY ~= 0 and turtle.detectDown() and turtle.digDown() do end
        end

        if targetY + 3 > finishY then
            targetY = finishY

            goto digExtra
        end
    end
end

console.logError('Excavation succeeded!')

goto recenter

::excavationFailed::

console.logError('Excavation failed!')

::recenter::

if not tracking.moveTo(transform, vector.new(0, 0, 0), true) then
    goto excavationFailed
end

tracking.turnTowardsFront(transform)

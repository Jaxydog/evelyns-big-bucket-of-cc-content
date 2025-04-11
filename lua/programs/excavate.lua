if not package.path:match('/%.library/%?%.lua') then
    package.path = package.path .. ';/.library/?.lua'
end

---@type evelyn.externalRequire.lib
local externalRequire = require('external-require')

print('Loading program...')

---@type evelyn.logging.lib
local logging = externalRequire.require('evelyns@logging')
---@type evelyn.query.lib
local query = externalRequire.require('evelyns@query')
---@type evelyn.turtle.positionTracker.lib
local positionTracker = externalRequire.require('evelyns-turtle@position-tracker')
---@type evelyn.turtle.inventoryHelper.lib
local inventoryHelper = externalRequire.require('evelyns-turtle@inventory-helper')

term.clear()
term.setCursorPos(1, 1)

do
    local success, reason = inventoryHelper:equipByName('minecraft:diamond_pickaxe')

    if not success then
        logging:logError('Missing diamond pickaxe: %s', reason)

        return 1
    end
end

local dimensions = {
    x = query.readIntegerInRange('Area width', 0, 256),
    y = query.readIntegerInRange('Area height', 0, 256),
    z = query.readIntegerInRange('Area depth', 0, 256),
}

print()

local hasStorage = false

if query.readBoolean('Use additional storage?', { default = 'n' }) then
    local inventorySlots = 0
    local biggest = { slot = nil, size = 0 }

    ::retryPlaceStorage::

    do
        local inventory = peripheral.find('inventory', function(name)
            return name == 'top'
        end)

        if inventory then
            inventorySlots = inventory.size()

            goto placeStorageSucceeded
        end
    end

    if turtle.detectUp() then
        logging:logError('Top block is obstructed')

        goto placeStorageFailed
    end

    biggest = inventoryHelper:foldSlot(biggest, function(value, slot, countResolver)
        if type(slot) == 'string' then return value end
        if countResolver() == 0 then return value end

        turtle.select(slot)

        if not turtle.placeUp() then return value end

        sleep(0.1)

        local inventory = peripheral.find('inventory', function(name)
            return name == 'top'
        end)

        if not inventory then
            turtle.digUp()

            return value
        end

        local size = inventory.size()

        if value.size < size then
            value.slot = slot
            value.size = size
        end

        turtle.digUp()

        return value
    end)

    if biggest.slot == nil then
        logging:logInfo('No available storage item')

        goto placeStorageFailed
    else
        turtle.select(biggest.slot)

        if not turtle.placeUp() then
            logging:logError('Invalid state')

            goto placeStorageFailed
        end

        inventorySlots = biggest.size
    end

    goto placeStorageSucceeded

    ::placeStorageFailed::

    if query.readBoolean('Retry?') then
        goto retryPlaceStorage
    else
        goto cancelStorage
    end

    ::placeStorageSucceeded::

    logging:logInfo('Attached storage with %d slots', inventorySlots)

    hasStorage = true

    ::cancelStorage::
end

local transform = positionTracker:createTransform({ skipGps = true })
local maxX = math.floor((dimensions.x - 1) / 2)
local minX = -math.ceil((dimensions.x - 1) / 2)

local unchunkedY = dimensions.y % 3
local maxY = dimensions.y - (unchunkedY == 0 and 2 or unchunkedY)
local minY = math.min(maxY, 1)

local fuelLevel = turtle.getFuelLevel()
local fuelLimit = turtle.getFuelLimit()
local fuelEstimate = math.ceil((hasStorage and 2.0 or 1.1) *
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

logging:logInfo('Estimated fuel cost: %d / %d', fuelEstimate, fuelLimit)
logging:logInfo('Current fuel level: %d', fuelLevel)

if fuelEstimate > fuelLimit then
    logging:logError('Excavated area is too big')

    goto excavationFailed
elseif fuelLevel < fuelEstimate then
    print()

    ::retryRefuel::

    logging:logInfo('Attempting refuel...')

    inventoryHelper:refuelFromInventory()
    fuelLevel = turtle.getFuelLevel()

    print()

    if fuelLevel >= fuelEstimate then
        logging:logInfo('Estimated fuel cost: %d / %d', fuelEstimate, fuelLimit)
        logging:logInfo('Current fuel level: %d', fuelLevel)
    else
        logging:logError('Estimated fuel cost: %d / %d', fuelEstimate, fuelLimit)
        logging:logError('Current fuel level: %d', fuelLevel)

        if query.readBoolean('Retry?') then goto retryRefuel else goto excavationFailed end
    end
end

print()
logging:logInfo('Starting excavation!')
print()

for targetZ = 1, dimensions.z, 1 do
    logging:logInfo('Digging layer %d / %d', targetZ, dimensions.z)

    if not positionTracker.move:z(transform, -targetZ, { breakBlocks = true }) then
        goto excavationFailed
    end

    local startY, finishY, dirY

    if transform.position.y == maxY then
        startY, finishY, dirY = maxY, minY, -3
    else
        startY, finishY, dirY = minY, maxY, 3
    end

    for targetY = startY, finishY, dirY do
        ::unchunkedLoop::

        if not positionTracker.move:y(transform, targetY, { breakBlocks = true }) then
            goto excavationFailed
        end

        local startX, finishX, dirX

        if transform.position.x == maxX then
            startX, finishX, dirX = maxX, minX, -1
        else
            startX, finishX, dirX = minX, maxX, 1
        end

        for targetX = startX, finishX, dirX do
            if not positionTracker.move:x(transform, targetX, { breakBlocks = true }) then
                goto excavationFailed
            end

            while targetY ~= dimensions.y - 1 and turtle.detectUp() and turtle.digUp() do end
            while targetY ~= 0 and turtle.detectDown() and turtle.digDown() do end

            if hasStorage and not inventoryHelper:findSlot(function(_, countResolver)
                    return countResolver() == 0
                end)
            then
                logging:logInfo('Returning to clean inventory...')

                if not positionTracker.move:to(transform, 0, 0, 0, { breakBlocks = true }) then
                    goto excavationFailed
                end

                sleep(0.1)

                local inventory = peripheral.find('inventory', function(name)
                    return name == 'top'
                end)

                if inventory then
                    inventoryHelper:forEachSlot(function(slot, countResolver)
                        if type(slot) == 'string' or countResolver() == 0 then return end

                        turtle.select(slot)
                        turtle.dropUp()
                    end)

                    turtle.select(1)

                    if not inventoryHelper:findSlot(function(_, countResolver) return countResolver() == 0 end) then
                        logging:logWarn('Storage block full!')

                        hasStorage = false
                    end
                else
                    logging:logWarn('Storage block missing!')

                    hasStorage = false
                end

                if not positionTracker.move:to(transform, targetX, targetY, targetZ, { breakBlocks = true }) then
                    goto excavationFailed
                end
            end
        end

        if targetY ~= finishY and targetY + 3 > finishY then
            targetY = finishY

            goto unchunkedLoop
        end
    end
end

print()
logging:logInfo('Excavation succeeded!')

goto recenter

::excavationFailed::

print()
logging:logError('Excavation failed!')

::recenter::

assert(positionTracker.move:to(transform, 0, 0, 0, { breakBlocks = true }))
positionTracker.turn:north(transform)

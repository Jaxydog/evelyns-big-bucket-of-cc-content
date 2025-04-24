---Provides convenience methods for arrays.
---
---@class evelyn.library.common.arrays.Lib
local module = {}

---Creates a new array containing `length` values returned by the callback.
---
---@generic T The element type.
---
---@param length integer The length.
---@param callback fun(index: integer): T The callback.
---
---@return T[] array The new array.
function module.new(length, callback)
    local array = {}

    for index = 1, length, 1 do
        array[index] = callback(index)
    end

    return array
end

---Returns a new array containing values that have been mapped by the given callback.
---
---@generic T The element type.
---@generic U The mapped type.
---
---@param array T[] The array.
---@param callback fun(index: integer, value: T): U The callback.
---
---@return U[] array The new array.
function module.map(array, callback)
    local mapped = {}

    for index, value in ipairs(array) do
        mapped[#mapped + 1] = callback(index, value)
    end

    return mapped
end

---Returns a new array containing all values with their duplicates removed.
---
---@generic T The element type.
---
---@param array T[] The array.
---@param predicate? fun(lhs: T, rhs: T): equal: boolean The predicate.
---
---@return T[] array The new array.
function module.dedupe(array, predicate)
    predicate = predicate or function(lhs, rhs)
        return lhs == rhs
    end

    local deduped = {}

    for _, value in ipairs(array) do
        local index = module.find(deduped, function(_, other)
            return predicate(other, value)
        end)

        if index == nil then
            deduped[#deduped + 1] = value
        end
    end

    return deduped
end

---Returns a value computed by the given callback.
---
---@generic T The element type.
---@generic U The folded type.
---
---@param array T[] The array.
---@param initial U The initial value.
---@param callback fun(current: U, index: integer, value: T): U The callback.
---
---@return U value The folded value.
function module.fold(array, initial, callback)
    for index, value in ipairs(array) do
        initial = callback(initial, index, value)
    end

    return initial
end

---Returns the first index for which the predicate returns `true`.
---
---@generic T The element type.
---
---@param array T[] The array.
---@param predicate fun(index: integer, value: T): boolean The predicate.
---
---@return integer? index The array index.
function module.find(array, predicate)
    for index, value in ipairs(array) do
        if predicate(index, value) then
            return index
        end
    end
end

---Returns the first mapped value for which the callback returns non-nil.
---
---@generic T The element type.
---@generic U The mapped type.
---
---@param array T[] The array.
---@param callback fun(index: integer, value: T): U | nil The callback.
---
---@return U? value The mapped value.
function module.findMap(array, callback)
    for index, value in ipairs(array) do
        local mapped = callback(index, value)

        if mapped ~= nil then
            return mapped
        end
    end
end

---Returns a new array containing only values for which the predicate returns `true`.
---
---@generic T The element type.
---
---@param array T[] The array.
---@param predicate fun(index: integer, value: T): boolean The predicate.
---
---@return T[] array The new array.
function module.filter(array, predicate)
    local filtered = {}

    for index, value in ipairs(array) do
        if predicate(index, value) then
            filtered[#filtered + 1] = value
        end
    end

    return filtered
end

---Returns a new array containing only values for which the callback returns non-nil.
---
---@generic T The element type.
---@generic U The mapped type.
---
---@param array T[] The array.
---@param callback fun(index: integer, value: T): U | nil The callback.
---
---@return U[] array The new array.
function module.filterMap(array, callback)
    local filterMapped = {}

    for index, value in ipairs(array) do
        local mapped = callback(index, value)

        if mapped ~= nil then
            filterMapped[#filterMapped + 1] = mapped
        end
    end

    return filterMapped
end

---Returns a new array containing all values within each inner array.
---
---@generic T The element type.
---
---@param array T[][] The array.
---
---@return T[] array The new array.
function module.flat(array)
    local flattened = {}

    for _, inner in ipairs(array) do
        for _, value in ipairs(inner) do
            flattened[#flattened + 1] = value
        end
    end

    return flattened
end

---Returns a new array containing all values returned by the callback.
---
---@generic T The element type.
---@generic U The mapped type.
---
---@param array T[] The array.
---@param callback fun(index: integer, value: T): U[] The callback.
---
---@return U[] array The new array.
function module.flatMap(array, callback)
    local flatMapped = {}

    for index, inner in ipairs(array) do
        for _, value in ipairs(callback(index, inner)) do
            flatMapped[#flatMapped + 1] = value
        end
    end

    return flatMapped
end

return module

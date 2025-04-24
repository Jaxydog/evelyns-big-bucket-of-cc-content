---Provides convenience methods for tables.
---
---@class evelyn.library.common.tables.Lib
local module = {}

---Returns a new array containing the table's keys in an arbitrary order.
---
---@generic K The key type.
---@generic V The value type.
---
---@param table table<K, V> The table.
---
---@return K[] array The new array.
function module.keys(table)
    local array = {}

    for key, _ in pairs(table) do
        array[#array + 1] = key
    end

    return array
end

---Returns a new array containing the table's values in an arbitrary order.
---
---@generic K The key type.
---@generic V The value type.
---
---@param table table<K, V> The table.
---
---@return V[] array The new array.
function module.values(table)
    local array = {}

    for _, value in pairs(table) do
        array[#array + 1] = value
    end

    return array
end

---Returns a new table containing keys and values returned by the callback.
---
---@generic K The key type.
---@generic V The value type.
---@generic T The mapped key type.
---@generic U The mapped value type.
---
---@param table table<K, V> The table.
---@param callback fun(key: K, value: V): key: T, value: U The callback.
---
---@return table<T, U> table The new table.
function module.map(table, callback)
    local mapped = {}

    for key, value in pairs(table) do
        local mappedKey, mappedValue = callback(key, value)

        mapped[mappedKey] = mappedValue
    end

    return mapped
end

---Returns a new table containing all values with their duplicates removed.
---
---@generic K The key type.
---@generic V The value type.
---
---@param table table<K, V> The table.
---@param conflicting? fun(last: K, next: K): K The conflict resolver.
---@param predicate? fun(lhs: V, rhs: V): equal: boolean The predicate.
---
---@return table<K, V> table The new table.
function module.dedupe(table, conflicting, predicate)
    conflicting = conflicting or function(last, _)
        return last
    end
    predicate = predicate or function(lhs, rhs)
        return lhs == rhs
    end

    local deduped = {}

    for tableKey, tableValue in pairs(table) do
        local otherKey = module.find(deduped, function(_, otherValue)
            return predicate(otherValue, tableValue)
        end)

        if otherKey == nil then
            deduped[tableKey] = tableValue
        else
            deduped[otherKey] = nil
            deduped[conflicting(otherKey, tableKey)] = tableValue
        end
    end

    return deduped
end

---Returns a value computed by the given callback.
---
---@generic K The key type.
---@generic V The value type.
---@generic T The folded type.
---
---@param table table<K, V> The table.
---@param initial T The initial value.
---@param callback fun(current: T, key: K, value: V): T The callback.
---
---@return T value The folded value.
function module.fold(table, initial, callback)
    for key, value in pairs(table) do
        initial = callback(initial, key, value)
    end

    return initial
end

---Returns the first key and value for which the predicate returns `true`.
---
---@generic K The key type.
---@generic V The value type.
---
---@param table table<K, V> The table.
---@param predicate fun(key: K, value: V): boolean The predicate.
---
---@return K? key The key.
---@return V? value The value.
function module.find(table, predicate)
    for key, value in pairs(table) do
        if predicate(key, value) then
            return key, value
        end
    end
end

---Returns the first mapped key and value for which the callback returns non-nil.
---
---@generic K The key type.
---@generic V The value type.
---@generic T The mapped key type.
---@generic U The mapped value type.
---
---@param table table<K, V> The table.
---@param callback fun(key: K, value: V): key: T | nil, value: U | nil The callback.
---
---@return T? key The mapped key.
---@return U? value The mapped value.
function module.findMap(table, callback)
    for key, value in pairs(table) do
        local mappedKey, mappedValue = callback(key, value)

        if mappedKey ~= nil and mappedValue ~= nil then
            return mappedKey, mappedValue
        end
    end
end

---Returns a new table containing only keys and values for which the predicate returns `true`.
---
---@generic K The key type.
---@generic V The value type.
---
---@param table table<K, V> The table.
---@param predicate fun(key: K, value: V): boolean The predicate.
---
---@return table<K, V> table The new table.
function module.filter(table, predicate)
    local filtered = {}

    for key, value in pairs(table) do
        if predicate(key, value) then
            filtered[key] = value
        end
    end

    return filtered
end

---Returns a new table containing only keys and values for which the predicate returns non-nil.
---
---@generic K The key type.
---@generic V The value type.
---@generic T The mapped key type.
---@generic U The mapped value type.
---
---@param table table<K, V> The table.
---@param callback fun(key: K, value: V): key: T | nil, value: U | nil The callback.
---
---@return table<T, U> table The new table.
function module.filterMap(table, callback)
    local filterMapped = {}

    for key, value in pairs(table) do
        local mappedKey, mappedValue = callback(key, value)

        if mappedKey ~= nil and mappedValue ~= nil then
            filterMapped[mappedKey] = mappedValue
        end
    end

    return filterMapped
end

---Returns a new table containing all keys and values within each inner table.
---
---@generic K The key type.
---@generic V The value type.
---
---@param table table<K, table<K, V>> The table.
---@param conflicting fun(key: K, lastValue: V, nextValue: V): V The conflict resolver.
---
---@return table<K, V> table The new table.
function module.flat(table, conflicting)
    local flattened = {}

    for _, inner in pairs(table) do
        for key, value in pairs(inner) do
            if flattened[key] == nil then
                flattened[key] = value
            else
                flattened[key] = conflicting(key, flattened[key], value)
            end
        end
    end

    return flattened
end

---Returns a new table containing all keys and values returned by the callback.
---
---@generic K The key type.
---@generic V The value type.
---@generic T The mapped key type.
---@generic U The mapped value type.
---
---@param table table<K, V> The table.
---@param callback fun(key: K, value: V): key: T, value: U The callback.
---@param conflicting fun(key: T, lastValue: U, nextValue: U): U The conflict resolver.
---
---@return table<K, V> table The new table.
function module.flatMap(table, callback, conflicting)
    local flattened = {}

    for key, value in pairs(table) do
        local mappedKey, mappedValue = callback(key, value)

        if flattened[mappedKey] == nil then
            flattened[mappedKey] = mappedValue
        else
            flattened[mappedKey] = conflicting(mappedKey, flattened[mappedKey], mappedValue)
        end
    end

    return flattened
end

return module

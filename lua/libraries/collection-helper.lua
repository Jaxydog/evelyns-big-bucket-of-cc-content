---Provides helper functions for collections.
---
---@class evelyn.collectionHelper.lib
local module = {}

---Provides helper functions for arrays.
---
---@class evelyn.collectionHelper.array.lib
module.array = {}

---Returns a new array where every value is computed using the given function.
---
---@generic T The type stored within the array.
---
---@param length integer The array's length.
---@param compute fun(index: integer): T The function that creates the array's values.
---
---@return T[] array A new array.
function module.array:compute(length, compute)
    local array = {}

    for index = 1, length, 1 do
        array[index] = compute(index)
    end

    return array
end

---Returns the index of the provided value within the given array.
---
---@generic T The type stored within the array.
---
---@param array T[] The array.
---@param value T The value.
---
---@return integer? index The index of the value within the array.
function module.array:find(array, value)
    for index, innerValue in ipairs(array) do
        if innerValue == value then
            return index
        end
    end
end

---Returns the index of the first value within the given array that matches the provided predicate.
---
---@generic T The type stored within the array.
---
---@param array T[] The array.
---@param predicate fun(index: integer, value: T): boolean The predicate.
---
---@return integer? index The index of the value within the array.
function module.array:findWith(array, predicate)
    for index, value in ipairs(array) do
        if predicate(index, value) then
            return index
        end
    end
end

---Returns a new array where every value has been filtered using the given predicate.
---
---@generic T The type stored within the array.
---
---@param array T[] The array.
---@param predicate fun(index: integer, value: T): boolean The predicate.
---
---@return T[] array A new array.
function module.array:filter(array, predicate)
    local filtered = {}

    for index, value in ipairs(array) do
        if predicate(index, value) then
            filtered[#filtered + 1] = value
        end
    end

    return filtered
end

---Returns a new array where every value has been mapped using the given function.
---
---@generic T The type stored within the array.
---@generic U The type stored within the new array.
---
---@param array T[] The array.
---@param mapper fun(index: integer, value: T): U The mapping function.
---
---@return U[] array A new array.
function module.array:map(array, mapper)
    local mapped = {}

    for index, value in ipairs(array) do
        mapped[index] = mapper(index, value)
    end

    return mapped
end

---Returns a new array that contains the contents of all inner arrays within a single list.
---
---@generic T The type stored within the array.
---
---@param array T[][] The array.
---
---@return T[] array A new array.
function module.array:flatten(array)
    local flattened = {}

    for _, innerArray in ipairs(array) do
        for _, value in ipairs(innerArray) do
            flattened[#flattened + 1] = value
        end
    end

    return flattened
end

---Applies the given folding function to the provided array.
---
---@generic T The type stored within the array.
---@generic U The type of the folded value.
---
---@param array T[] The array.
---@param initial U The initial value.
---@param fold fun(current: U, index: integer, value: T): U The folding function.
---
---@return U folded The folded value.
function module.array:fold(array, initial, fold)
    for index, value in ipairs(array) do
        initial = fold(initial, index, value)
    end

    return initial
end

---Provides helper functions for tables.
---
---@class evelyn.collectionHelper.table.lib
module.table = {}

---Returns an array of the keys within the given table.
---
---@generic K The type of the keys within the table.
---@generic V The type of the values within the table.
---
---@param table table<K, V> The table.
---
---@return K[] array A new array.
function module.table:keys(table)
    local keys = {}

    for key, _ in pairs(table) do
        keys[#keys + 1] = key
    end

    return keys
end

---Returns an array of the values within the given table.
---
---@generic K The type of the keys within the table.
---@generic V The type of the values within the table.
---
---@param table table<K, V> The table.
---
---@return V[] array A new array.
function module.table:values(table)
    local values = {}

    for _, value in pairs(table) do
        values[#values + 1] = value
    end

    return values
end

---Returns the key of the provided value within the given table.
---
---@generic K The type of the keys within the table.
---@generic V The type of the values within the table.
---
---@param table table<K, V> The table.
---@param value V The value.
---
---@return K? index The key.
function module.table:find(table, value)
    for key, innerValue in pairs(table) do
        if innerValue == value then
            return key
        end
    end
end

---Returns the first key and value within the given table that matches the provided predicate.
---
---@generic K The type of the keys within the table.
---@generic V The type of the values within the table.
---
---@param table table<K, V> The table.
---@param predicate fun(key: K, value: V): boolean The predicate.
---
---@return K? index The key.
---@return V? value The value.
function module.table:findWith(table, predicate)
    for key, value in pairs(table) do
        if predicate(key, value) then
            return key, value
        end
    end
end

---Returns a new table where every value has been filtered using the given predicate.
---
---@generic K The type of the keys within the table.
---@generic V The type of the values within the table.
---
---@param table table<K, V> The table.
---@param predicate fun(key: K, value: V): boolean The predicate.
---
---@return table<K, V> table A new table.
function module.table:filter(table, predicate)
    local filtered = {}

    for key, value in pairs(table) do
        if predicate(key, value) then
            filtered[key] = value
        end
    end

    return filtered
end

---Returns a new table where every key and value has been mapped using the given function.
---
---@generic K The type of the keys within the table.
---@generic V The type of the values within the table.
---@generic T The type of the keys stored within the new table.
---@generic U The type of the values stored within the new table.
---
---@param table table<K, V> The table.
---@param mapper fun(key: K, value: V): T, U The mapping function.
---
---@return table<T, U> table A new table.
function module.table:map(table, mapper)
    local mapped = {}

    for key, value in pairs(table) do
        local newKey, newValue = mapper(key, value)

        mapped[newKey] = newValue
    end

    return mapped
end

---Returns a new table where every key has been mapped using the given function.
---
---@generic K The type of the keys within the table.
---@generic V The type of the values within the table.
---@generic T The type of the keys stored within the new table.
---
---@param table table<K, V> The table.
---@param mapper fun(key: K, value: V): T The mapping function.
---
---@return table<T, V> table A new table.
function module.table:mapKeys(table, mapper)
    local mapped = {}

    for key, value in pairs(table) do
        mapped[mapper(key, value)] = value
    end

    return mapped
end

---Returns a new table where every value has been mapped using the given function.
---
---@generic K The type of the keys within the table.
---@generic V The type of the values within the table.
---@generic T The type of the values stored within the new table.
---
---@param table table<K, V> The table.
---@param mapper fun(key: K, value: V): T The mapping function.
---
---@return table<K, T> table A new table.
function module.table:mapValues(table, mapper)
    local mapped = {}

    for key, value in pairs(table) do
        mapped[key] = mapper(key, value)
    end

    return mapped
end

---Returns a new table that contains the contents of all inner tables.
---
---@generic K The type of the keys within the table.
---@generic V The type of the values within the table.
---
---@param table table<K, table<K, V>> The table.
---@param onDuplicate fun(key: K, first: V, second: V): V A function that returns the preferred value if a duplicate is found.
---
---@return table<K, V> table A new table.
function module.table:flatten(table, onDuplicate)
    local flattened = {}

    for _, innerTable in pairs(table) do
        for key, value in pairs(innerTable) do
            if flattened[key] ~= nil then
                value = onDuplicate(key, flattened[key], value)
            end

            flattened[key] = value
        end
    end

    return flattened
end

---Applies the given folding function to the provided table.
---
---@generic K The type of the keys within the table.
---@generic V The type of the values within the table.
---@generic T The type of the folded value.
---
---@param table table<K, V> The table.
---@param initial T The initial value.
---@param fold fun(current: T, key: K, value: V): T The folding function.
---
---@return T folded The folded value.
function module.table:fold(table, initial, fold)
    for key, value in pairs(table) do
        initial = fold(initial, key, value)
    end

    return initial
end

return module

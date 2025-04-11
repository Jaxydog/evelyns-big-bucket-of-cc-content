---A set of additional options to be passed into read functions.
---
---@class evelyn.query.options
---
---@field public maxAttempts? integer The maximum number of attempts to read a value before returning `nil`.
---@field public replaceCharacter? string The character used to replace all input text.
---@field public history? string[] The input history.
---@field public completeFunction? (fun(partial: string): string[]) A function that handles auto-completion.
---@field public default? string The default input string, if validation fails.

---Provides better terminal input than the standard `read` function.
---
---@class evelyn.query.lib
local module = {}

---The default prompt builder for read functions.
---
---@param prompt string The prompt string.
---
---@return string prompt The prompt.
function module.defaultPromptBuilder(prompt, _)
    return ('%s: '):format(prompt)
end

---Creates a new read function with the given prompt construction and type validation functions.
---
---@generic T The type returned by the created function.
---
---@param promptBuilder fun(prompt: string, default?: string): string A function that creates the prompt based on the given string.
---@param validator fun(input: string): boolean, T | nil, string | nil A function that validates a given input string.
---
---@return fun(prompt: string, options?: evelyn.query.options): T | nil function The read function.
function module.createReadFunction(promptBuilder, validator)
    return function(promptInput, options)
        ---@type evelyn.query.options
        options = options or {}

        if options.default and not validator(options.default) then
            error('Default value is invalid')
        end

        local attempts = 0
        local prompt = promptBuilder(promptInput, options.default)
        local _, startY = term.getCursorPos()

        while attempts <= (options.maxAttempts or math.huge) do
            term.setCursorPos(1, startY)
            term.clearLine()

            write(prompt)

            term.setTextColor(colors.gray)

            local input = read(options.replaceCharacter, options.history, options.completeFunction, options.default)
            local valid, value, reason = validator(input:match('^%s*(.-)%s*$'))

            term.setTextColor(colors.white)

            if valid then return value end

            printError(('Invalid value%s'):format(reason and (': %s'):format(reason) or ''))
            sleep(1)

            local _, currentY = term.getCursorPos()

            term.setCursorPos(1, currentY - 1)
            term.clearLine()

            attempts = attempts + 1
        end

        return nil
    end
end

---Reads a string from the terminal.
---
---The return value will only ever be `nil` if the `maxAttempts` field is set.
module.readString = module.createReadFunction(module.defaultPromptBuilder, function(input)
    return true, input, nil
end)

---Reads a string from the terminal that matches the given pattern.
---
---The return value will only ever be `nil` if the `maxAttempts` field is set.
---
---@param prompt string The prompt string.
---@param pattern string The pattern to match.
---@param options? evelyn.query.options The read options.
---
---@return string | nil input The input value.
function module.readStringMatching(prompt, pattern, options)
    return module.createReadFunction(module.defaultPromptBuilder, function(input)
        if input:match(pattern) then
            return true, input, nil
        else
            return false, nil, ('should match %s'):format(pattern)
        end
    end)(prompt, options)
end

---Reads a boolean from the terminal.
---
---The return value will only ever be `nil` if the `maxAttempts` field is set.
module.readBoolean = module.createReadFunction(function(prompt, default)
    if default and default:match('^[nN]$') then
        return ('%s [y/N]: '):format(prompt)
    else
        return ('%s [Y/n]: '):format(prompt)
    end
end, function(input)
    if input:match('^[yY]$') then
        return true, true, nil
    elseif input:match('^[nN]$') then
        return true, false, nil
    end

    return false, nil, 'expected boolean'
end)

---Reads a number from the terminal.
---
---The return value will only ever be `nil` if the `maxAttempts` field is set.
module.readNumber = module.createReadFunction(module.defaultPromptBuilder, function(input)
    local numeric = tonumber(input)

    if numeric == nil then
        return false, nil, 'expected number'
    end

    return true, numeric, nil
end)

---Reads a number from the terminal that is within the given range.
---
---The return value will only ever be `nil` if the `maxAttempts` field is set.
---
---@param prompt string The prompt string.
---@param min? number The minimum allowed value.
---@param max? number The maximum allowed value.
---@param options? evelyn.query.options The read options.
---
---@return number | nil input The input value.
function module.readNumberInRange(prompt, min, max, options)
    if min == nil and max == nil then
        return module.readNumber(prompt, options)
    end

    return module.createReadFunction(module.defaultPromptBuilder, function(input)
        local numeric = tonumber(input)

        if numeric == nil then
            return false, nil, 'expected number'
        end

        if min ~= nil and numeric < min then
            return false, nil, ('expected >= %s'):format(min)
        elseif max ~= nil and numeric > max then
            return false, nil, ('expected <= %s'):format(max)
        end

        return true, numeric, nil
    end)(prompt, options)
end

---Reads an integer from the terminal.
---
---The return value will only ever be `nil` if the `maxAttempts` field is set.
module.readInteger = module.createReadFunction(module.defaultPromptBuilder, function(input)
    local numeric = tonumber(input)

    if numeric == nil then
        return false, nil, 'expected number'
    end

    local integer, decimal = math.modf(numeric)

    if decimal ~= 0 then
        return false, nil, 'expected integer'
    end

    return true, integer, nil
end)

---Reads an integer from the terminal that is within the given range.
---
---The return value will only ever be `nil` if the `maxAttempts` field is set.
---
---@param prompt string The prompt string.
---@param min? integer The minimum allowed value.
---@param max? integer The maximum allowed value.
---@param options? evelyn.query.options The read options.
---
---@return integer | nil input The input value.
function module.readIntegerInRange(prompt, min, max, options)
    if min == nil and max == nil then
        return module.readInteger(prompt, options)
    end

    return module.createReadFunction(module.defaultPromptBuilder, function(input)
        local numeric = tonumber(input)

        if numeric == nil then
            return false, nil, 'expected number'
        end

        local integer, decimal = math.modf(numeric)

        if decimal ~= 0 then
            return false, nil, 'expected integer'
        end

        if min ~= nil and integer < min then
            return false, nil, ('expected >= %s'):format(min)
        elseif max ~= nil and integer > max then
            return false, nil, ('expected <= %s'):format(max)
        end

        return true, integer, nil
    end)(prompt, options)
end

return module

---@class evelyn.ConsoleLib
local module = {
    ---Whether debug logging is enabled.
    enableDebugLogging = false,
}

---Creates a new logging function with the given constants.
---
---@param label string The log level label.
---@param color ccTweaked.colors.color The color to use if the terminal has color support.
---@param grayscale ccTweaked.colors.color The color to use if the terminal does not have color support.
---@param condition? fun(): boolean A predicate function that determines whether to output a log.
---
---@return fun(...): number | nil loggingFunction A logging function.
local function createLogFunction(label, color, grayscale, condition)
    return function(...)
        if condition ~= nil and not condition() then
            return 0
        end

        if term.isColor() then
            term.setTextColor(color)
        else
            term.setTextColor(grayscale)
        end

        term.write(('[%s] '):format(label))
        term.setTextColor(colors.white)

        return print(...)
    end
end

---Outputs an informational log.
module.logInfo = createLogFunction('info', colors.lightBlue, colors.white)
---Outputs a warning log.
module.logWarning = createLogFunction('warn', colors.yellow, colors.lightGray)
---Outputs an error log.
module.logError = createLogFunction('error', colors.red, colors.gray)
---Outputs a debug log if debug logging is enabled.
module.logDebug = createLogFunction('debug', colors.magenta, colors.lightGray, function()
    return module.enableDebugLogging == true
end)

---Creates a new terminal reading function with the given constants.
---
---@generic T The type being returned from the function.
---
---@param validation fun(s: string): T? The validation function.
---@param createPrompt? fun(s: string): string A function that creates a prompt string.
---
---@return fun(prompt: string, replace?: string, default?: T): T readFunction A reading function.
local function createReadFunction(validation, createPrompt)
    createPrompt = createPrompt or function(s)
        return ('%s: '):format(s)
    end

    return function(prompt, replace, default)
        local value = nil
        local _, y = term.getCursorPos()

        while value == nil do
            term.setCursorPos(1, y)
            term.clearLine()
            term.write(createPrompt(prompt))
            term.setTextColor(colors.lightGray)

            value = validation(read(replace, nil, nil, default):match('^%s*(.-)%s*$'))

            term.setTextColor(colors.white)
        end

        print()

        return value
    end
end

---Reads a string from the terminal.
module.readString = createReadFunction(function(s)
    return s
end)
---Reads a string from the terminal.
module.readBoolean = createReadFunction(function(s)
    if s:match('^[yY]$') or s:lower() == 'yes' then
        return true
    elseif s:match('^[nN]$') or s:lower() == 'no' then
        return false
    end
end, function(s)
    return ('%s [y/n]: '):format(s)
end)
---Reads a number from the terminal.
module.readNumber = createReadFunction(function(s)
    return tonumber(s)
end)
---Reads an integer from the terminal.
module.readInteger = createReadFunction(function(s)
    local number = tonumber(s)

    if number ~= nil and math.type(number) == 'integer' then
        ---@type integer
        return number
    end
end)

return module

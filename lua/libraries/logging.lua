---A log level.
---
---@alias evelyn.logging.level
---| 'debug' Debug logging.
---| 'info' Informational logging.
---| 'warn' Warning logging.
---| 'error' Error logging.

---A color choice.
---
---@alias evelyn.logging.colorChoice
---| 'auto' Automatically enable color if it's available.
---| 'always' Always enable color, even if it's not available.
---| 'never' Never enable color, even if it's available.

---A logging function.
---
---@alias evelyn.logging.function fun(module: evelyn.logging.lib, format: string, ...: unknown): number

---Provides better logging functionality than the standard `print` and `printError` functions.
---
---@class evelyn.logging.lib
local module = {}

---Determines when logs should be output with color.
---
---@type evelyn.logging.colorChoice
module.color = 'auto'

---Determines the level of logs that should be output.
---
---@type evelyn.logging.level | nil
module.level = 'info'

---Returns `true` if logging functions will output using color.
---
---@return boolean color Whether to use color.
function module:shouldUseColor()
    return self.color == 'always' or (self.color == 'auto' and term.isColor())
end

---Creates a new log function with the given level, color, and predicate.
---
---@param level evelyn.logging.level The log level.
---@param color ccTweaked.colors.color The color to use if colors are enabled.
---@param predicate fun(module: evelyn.logging.lib): boolean A function that determines whether the log should be output.
---
---@return evelyn.logging.function function The logging function.
function module.createLogFunction(level, color, predicate)
    return function(moduleTable, format, ...)
        if not predicate(moduleTable) then return 0 end

        local shouldUseColor = moduleTable:shouldUseColor()

        if shouldUseColor then term.setTextColor(color) end

        local lines = write(('[%s] '):format(level))

        if shouldUseColor then term.setTextColor(colors.white) end

        return lines + print(format:format(...))
    end
end

---Outputs a debug log.
module.logDebug = module.createLogFunction('debug', colors.magenta, function(moduleTable)
    return moduleTable.level == 'debug'
end)
---Outputs an informational log.
module.logInfo = module.createLogFunction('info', colors.lightBlue, function(moduleTable)
    return moduleTable.level == 'debug' or moduleTable.level == 'info'
end)
---Outputs a warning log.
module.logWarn = module.createLogFunction('warn', colors.yellow, function(moduleTable)
    return moduleTable.level == 'debug' or moduleTable.level == 'info' or moduleTable.level == 'warn'
end)
---Outputs a warning log.
module.logError = module.createLogFunction('error', colors.red, function(moduleTable)
    return moduleTable.level ~= nil
end)

return module

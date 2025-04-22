---Provides color constants and convenience methods.
---
---@class evelyn.shell.library.colors.Lib
local module = {}

---Creates a color constant.
---
---@param hex integer The color as a hexadecimal integer.
---@param native integer | nil The native integer code for this color.
---
---@return evelyn.shell.library.colors.Constant The color constant.
local function constant(hex, native)
    ---A color constant.
    ---
    ---@class evelyn.shell.library.colors.Constant
    ---
    ---@field public rgb evelyn.shell.library.colors.Rgb The RGB color.
    ---@field public native integer | nil The native integer code.
    return { rgb = module.rgb.newInteger(hex), native = native }
end


---Constants used for default shell colors.
---
---@enum evelyn.shell.library.colors.constants
module.constants = {
    white = constant(0xF0F0F0, 0x0001),
    lightGray = constant(0x999999, 0x0100),
    darkGray = constant(0x4C4C4C, 0x0080),
    black = constant(0x111111, 0x8000),
    brown = constant(0x7F664C, 0x1000),
    red = constant(0xCC4C4C, 0x4000),
    orange = constant(0xF2B233, 0x0002),
    yellow = constant(0xDEDE6C, 0x0010),
    lime = constant(0x7FCC19, 0x0020),
    green = constant(0x57A64E, 0x2000),
    cyan = constant(0x4C99B2, 0x0200),
    lightBlue = constant(0x99B2F2, 0x0008),
    darkBlue = constant(0x3366CC, 0x0800),
    purple = constant(0xB266E5, 0x0400),
    magenta = constant(0xE57FD8, 0x0004),
    pink = constant(0xF2B2CC, 0x0040),
}

---Provides RGB color support.
---
---@class evelyn.shell.library.colors.rgb.Lib
module.rgb = {}

---The bit mask used to isolate color components.
---
---@private
module.rgb.mask = 0xFF

---The shift used to isolate the red color component.
---
---@private
module.rgb.shiftR = 16

---The shift used to isolate the red color component.
---
---@private
module.rgb.shiftG = 8

---The shift used to isolate the red color component.
---
---@private
module.rgb.shiftB = 0

---The metatable given to all RGB values.
---
---@private
---@type metatable
module.rgb.metatable = {}

---@param value evelyn.shell.library.colors.Rgb
---@param other evelyn.shell.library.colors.Rgb | nil
function module.rgb.metatable.__eq(value, other)
    return other ~= nil and value:integer() == other:integer()
end

---@param value evelyn.shell.library.colors.Rgb
function module.rgb.metatable.__tostring(value)
    return ('rgb(%d, %d, %d)'):format(value:red(), value:green(), value:blue())
end

---Creates a new RGB color.
---
---Each color component should be between `0` and `255`.
---
---@param r integer The color's red component.
---@param g integer The color's green component.
---@param b integer The color's blue component.
---
---@return evelyn.shell.library.colors.Rgb color The new RGB color.
function module.rgb.new(r, g, b)
    ---An RGB color.
    ---
    ---@class evelyn.shell.library.colors.Rgb
    local rgb = {}

    ---The RGB color's packed integer value.
    ---
    ---@private
    ---@type integer
    rgb.packed = ((r & module.rgb.mask) << module.rgb.shiftR)
        | ((g & module.rgb.mask) << module.rgb.shiftG)
        | ((b & module.rgb.mask) << module.rgb.shiftB)

    ---Returns the RGB color as an integer.
    ---
    ---This call is essentially free.
    ---
    ---@return integer int The integer.
    function rgb:integer()
        return self.packed
    end

    ---Returns the RGB color's red component.
    ---
    ---The returned value will be between `0` and `255`.
    ---
    ---@return integer red The red component.
    function rgb:red()
        return (self.packed >> module.rgb.shiftR) & module.rgb.mask
    end

    ---Returns the RGB color's red component.
    ---
    ---The returned value will be between `0.0` and `1.0`.
    ---
    ---@return number red The red component.
    function rgb:redScaled()
        return self:red() / 255.0
    end

    ---Returns the RGB color's green component.
    ---
    ---The returned value will be between `0` and `255`.
    ---
    ---@return integer green The green component.
    function rgb:green()
        return (self.packed >> module.rgb.shiftG) & module.rgb.mask
    end

    ---Returns the RGB color's green component.
    ---
    ---The returned value will be between `0.0` and `1.0`.
    ---
    ---@return number green The green component.
    function rgb:greenScaled()
        return self:green() / 255.0
    end

    ---Returns the RGB color's blue component.
    ---
    ---The returned value will be between `0` and `255`.
    ---
    ---@return integer blue The blue component.
    function rgb:blue()
        return (self.packed >> module.rgb.shiftB) & module.rgb.mask
    end

    ---Returns the RGB color's blue component.
    ---
    ---The returned value will be between `0.0` and `1.0`.
    ---
    ---@return number blue The blue component.
    function rgb:blueScaled()
        return self:blue() / 255.0
    end

    return setmetatable(rgb, module.rgb.metatable)
end

---Creates a new RGB color from the given integer.
---
---@param int integer The RGB integer.
---
---@return evelyn.shell.library.colors.Rgb color The new RGB color.
function module.rgb.newInteger(int)
    local r = (int >> module.rgb.shiftR) & module.rgb.mask
    local g = (int >> module.rgb.shiftG) & module.rgb.mask
    local b = (int >> module.rgb.shiftB) & module.rgb.mask

    return module.rgb.new(r, g, b)
end

---Creates a new RGB color.
---
---Each color component should be between `0.0` and `1.0`.
---
---@param r number The color's red component.
---@param g number The color's green component.
---@param b number The color's blue component.
---
---@return evelyn.shell.library.colors.Rgb color The new RGB color.
function module.rgb.newScaled(r, g, b)
    return module.rgb.new(r * 255.0, g * 255.0, b * 255.0)
end

return module

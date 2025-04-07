if not turtle then
    error('This program must be run on a turtle!')
end

local level = turtle.getFuelLevel()
local limit = turtle.getFuelLimit()
local percent = (level / limit) * 100
local prettyPercent = math.floor((percent * 10) + 0.5) / 10

if not term.isColor() then
    print(('%d / %d (%f%%)'):format(level, limit, prettyPercent))

    return
end

local fillColor

if level == limit then
    fillColor = colors.lightBlue
elseif level >= limit * 0.67 then
    fillColor = colors.green
elseif level >= limit * 0.33 then
    fillColor = colors.yellow
else
    fillColor = colors.red
end

term.setTextColor(fillColor)
term.write(('%d'):format(level))
term.setTextColor(colors.white)
term.write((' / %d ('):format(limit))
term.setTextColor(fillColor)
term.write(('%f'):format(prettyPercent))
term.setTextColor(colors.white)
term.write(')')

print()

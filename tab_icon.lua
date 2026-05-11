-- tab_icon.lua — Aba Icon
-- Claudio Bot | NTO Ultimate

setDefaultTab("Icon")

local iiccoonn = addLabel("ICONES", "ICONES")
iiccoonn:setColor("orange")

UI.Separator()

warning = function() 
    return  
end

-----------------------------
-- Seção: CaveBot / TargetBot
-----------------------------
local cIcon = addIcon("cI", {text="Cave\nBot", switchable=false, moveable=true}, function()
  if CaveBot.isOff() then CaveBot.setOn() else CaveBot.setOff() end
end)
cIcon:setSize({height=30, width=50})
cIcon.text:setFont('verdana-11px-rounded')

local tIcon = addIcon("tI", {text="Target\nBot", switchable=false, moveable=true}, function()
  if TargetBot.isOff() then TargetBot.setOn() else TargetBot.setOff() end
end)
tIcon:setSize({height=30, width=50})
tIcon.text:setFont('verdana-11px-rounded')

macro(100, function()
  if CaveBot.isOn() then
    cIcon.text:setColoredText({"CaveBot\n","white","ON","green"})
  else
    cIcon.text:setColoredText({"CaveBot\n","white","OFF","red"})
  end
  if TargetBot.isOn() then
    tIcon.text:setColoredText({"Target\n","white","ON","green"})
  else
    tIcon.text:setColoredText({"Target\n","white","OFF","red"})
  end
end)

-----------------------------
-- Seção: Escadas Automático
-----------------------------
Stairs = {}
Stairs.Exclude = {}
Stairs.Click = {8367, 6264, 1666, 6207, 1948, 435, 7771, 5542, 8657, 6264, 1646, 1648, 1678, 5291, 1680, 6905, 6262, 1664, 13296, 1067, 13861, 11931, 1949, 6896, 6205, 12097}

function canBeUsed(thing)
    local pPos = player:getPosition()
    local cPos = thing:getPosition()
    if pPos.z ~= cPos.z then
    return false
    elseif table.equals(pPos, cPos) then
        return true
    end
    
    local start
    local destination
    if pPos.z > cPos.z then start = cPos destination = pPos else start = pPos destination = cPos end
    
    local mx
    local my
    if start.x < destination.x then mx = 1 elseif start.x == destination.x then mx = 0 else mx = -1 end
    
    if start.y < destination.y then my = 1 elseif start.y == destination.y then my = 0 else my = -1 end
    
    local A = destination.y - start.y
    local B = start.x - destination.x
    local C = -(A * destination.x + B * destination.y)
    
    while start.x ~= destination.x or start.y ~= destination.y do
        local move_hor = math.abs(A * (start.x + mx) + B * (start.y) + C)
        local move_ver = math.abs(A * (start.x) + B * (start.y + my) + C)
        local move_cross = math.abs(A * (start.x + mx) + B * (start.y + my) + C)
        
        if start.y ~= destination.y and (start.x == destination.x or move_hor > move_ver or move_hor > move_cross) then
            start.y = start.y + my
        end
        
        if start.x ~= destination.x and (start.y == destination.y or move_ver > move_hor or move_ver > move_cross) then
            start.x = start.x + mx
        end
        
        local tile = g_map.getTile({x = start.x, y = start.y, z = start.z})
        if tile then
      if not table.equals(destination, tile:getPosition()) and (not tile:isPathable() or not tile:isWalkable()) then
        return false
      end
        end
    end
    
    return true
    
end

Stairs.postostring = function(pos)
    return(pos.x .. ',' .. pos.y .. ',' .. pos.z)
end

function Stairs.accurateDistance(p1, p2)
    if type(p1) == 'userdata' then
    p1 = p1:getPosition()
  end
  if type(p2) ~= 'table' then
    p2 = pos()
  end
    return math.abs(p1.x-p2.x) + math.abs(p1.y-p2.y)
end

Stairs.Check = {}

Stairs.checkTile = function(tile)
    if not tile then
        return false
  end
  
  local pos = Stairs.postostring(tile:getPosition())
  
    if Stairs.Check[pos] ~= nil then
        return Stairs.Check[pos]
  end
  
    if not tile:getTopUseThing() then
    Stairs.Check[pos] = false
        return false
    end
  
    for _, x in ipairs(tile:getItems()) do
        if table.find(Stairs.Click, x:getId()) then
            Stairs.Check[pos] = true
      return true
        elseif table.find(Stairs.Exclude, x:getId()) then
      Stairs.Check[pos] = false
      return false
    end
    end
  
    local cor = g_map.getMinimapColor(tile:getPosition())
    if cor >= 210 and cor <= 213 and not tile:isPathable() and tile:isWalkable() then
    Stairs.Check[pos] = true
        return true
  else
    Stairs.Check[pos] = false
        return false
    end
end

Stairs.isUsable = function(pos)
  if type(pos) == 'userdata' then
    pos = pos:getPosition()
  end
  
  if type(pos) ~= 'table' then
    return false
  end
  
  local pPos = player:getPosition()
  local inaccurateDistance = getDistanceBetween(pos, pPos)
  if inaccurateDistance <= 2 then
    return true
  end
  if inaccurateDistance > 7 then
    return false
  end
  
  if Stairs.accurateDistance(pPos, pos) > 8 then
    return false
  end
  
  
  local tile = g_map.getTile(pos)
  if tile and not canBeUsed(tile) then
    return false
  end
  
  return true
end

seePath = function(startPos, destPos)
  if not destPos or startPos.z ~= destPos.z then return end
  local params = {}
  local destPosStr = destPos.x .. "," .. destPos.y .. "," .. destPos.z
  params["destination"] = destPosStr
  local paths = findAllPaths(startPos, 100, params)

  if not paths[destPosStr] then return nil end
  
  return translateToPath(paths, destPos)
end

translateToPath = function(paths, destPos)
  local directions = {}
  local destPosStr = destPos
  if type(destPos) ~= 'string' then
    destPosStr = destPos.x .. "," .. destPos.y .. "," .. destPos.z
  end
  
  while destPosStr:len() > 0 do
    local node = paths[destPosStr]
    if not node or node[3] < 0 then break end
    destPosStr = node[4]
    table.insert(directions, destPosStr)
  end
  return directions
end

Stairs.goUse = function(pos)
  local pPos = player:getPosition()
  if Stairs.isUsable(pos)  then
    local tile = g_map.getTile(pos)
    return tile and g_game.use(tile:getTopUseThing())
  else
    local path = seePath(pos, pPos)
    if path then
      for index, position in ipairs(path) do
        local position = position:split(',')
        position = {x = position[1], y = position[2], z = position[3]}
        if not Stairs.isUsable(position) then
          return tile and g_game.use(tile:getTopUseThing())
        end
        tile = g_map.getTile(position)
      end
    end
  end
end
  
Stairs.checkAll = function()
  local tiles = {}
  for _, tile in ipairs(g_map.getTiles(posz())) do
    if Stairs.checkTile(tile) then
      table.insert(tiles, tile)
    end
  end
  if #tiles == 0 then return end
    table.sort(tiles, function(a, b)
        return Stairs.accurateDistance(a:getPosition()) < Stairs.accurateDistance(b:getPosition())
    end)
    for y, z in ipairs(tiles) do
        if seePath(z:getPosition(), pos()) then
            return z
        end
    end
  return false
end

stand = now
onPlayerPositionChange(function(newPos, oldPos)
  stand = now
  tryWalk = nil
  if newPos.z ~= oldPos.z or getDistanceBetween(oldPos, newPos) > 1 or table.equals(Stairs.pos, newPos) then
    Stairs.walk.setOff()
  end
  if Stairs.walk.isOff() then
    checked = nil
  end
end)

timeInPos = function()
  return now - stand
end

onAddThing(function(tile, thing)
  if type(Stairs.pos) == 'table' then
    if table.equals(tile:getPosition(), Stairs.pos) then
      Stairs.bestTile = tile
    end
  end
end)

markOnThing = function(thing, color)
  if thing then
    if thing:getPosition() then
      local useThing = thing:getTopUseThing()
      if useThing and not useThing:isGround() then
        useThing:setMarked(color)
        return true
      else
        if color == '#00FF00' then
          thing:setText('AQUI', 'green')
        elseif color == '#FF0000' then
          thing:setText('AQUI', 'red')
        else
          thing:setText('')
        end
        return true
      end
    end
  end
  return false
end

Stairs.walk = macro(200, function()
  if modules.corelib.g_keyboard.isKeyPressed('escape') then return Stairs.walk.setOff() end
  player:lockWalk(300)
  if tryWalk then return end
  markOnThing(Stairs.bestTile, '#00FF00')
    if Stairs.bestTile:isWalkable() then
    if not Stairs.bestTile:isPathable() then
      if autoWalk(Stairs.pos, 1) then
        tryWalk = true
        return
      end
    end
  end
  return Stairs.goUse(Stairs.pos)
end)

Stairs.walk.setOff()

autoEscadasIcon = macro(200, 'Auto-Escadas', function()
  if Stairs.walk.isOn() then return end
  if not checked then
    markOnThing(Stairs.bestTile, '')
    Stairs.bestTile = Stairs.checkAll()
    Stairs.pos = Stairs.bestTile and Stairs.bestTile:getPosition()
    if markOnThing(Stairs.bestTile, '#FF0000') or timeInPos() >= 500 then
      checked = true
    end
  end
  if modules.corelib.g_keyboard.isKeyPressed('space') and Stairs.bestTile and not modules.game_console:isChatEnabled() then
    Stairs.walk.setOn()
    return
  else
    return markOnThing(Stairs.bestTile, '#FF0000')
  end
end)
posEscadas = addIcon("Auto-Escadas", {item =5544, text = "Auto Escadas",}, autoEscadasIcon)
posEscadas:breakAnchors()
posEscadas:move(800,105)

-----------------------------
-- Seção: Follow Bot
-----------------------------
local Follow = addIcon("Follow", {item=3555, text="[F.ATK]"},
macro(100, "Follow Atk", "Shift+Z", function()
  if g_game.isOnline() and g_game.isAttacking() then g_game.setChaseMode(1) end
end))
Follow:breakAnchors()
Follow:move(750,100)

-- Bug Map OTIMIZADO
local console = modules.game_console

local function checkPos(dx, dy)
  local pos = player:getPosition()
  pos.x = pos.x + dx
  pos.y = pos.y + dy

  local tile = g_map.getTile(pos)
  if tile and tile:getTopUseThing() then
    g_game.use(tile:getTopUseThing())
  end
end

local bugMapMacro = macro(1, "Bug Map (0)", function()
  if console:isChatEnabled() then return end

  local k = modules.corelib.g_keyboard

  if k.isKeyPressed('w') then
    checkPos(0, -5)
  elseif k.isKeyPressed('e') then
    checkPos(5, -5)
  elseif k.isKeyPressed('d') then
    checkPos(5, 0)
  elseif k.isKeyPressed('c') then
    checkPos(5, 5)
  elseif k.isKeyPressed('s') then
    checkPos(0, 5)
  elseif k.isKeyPressed('z') then
    checkPos(-5, 5)
  elseif k.isKeyPressed('a') then
    checkPos(-5, 0)
  elseif k.isKeyPressed('q') then
    checkPos(-5, -5)
  end
end)

addIcon("Bug Map (0)", {item = 9019, text = "BugMap", hotkey = "0"}, function(icon, isOn)
  bugMapMacro.setOn(isOn)
end)



-- DonatorFix
-- Autor: LoboLupus
-- Projeto criado para NTO Ultimate
-- Uso não autorizado, revenda ou redistribuição sem permissão é proibido.
setDefaultTab("Icon")
cor= UI.Button("ICONES DA TELA",scpPanel5)
cor:setColor("#00ff00")

local sep = UI.Separator()
sep:setHeight(1)
sep:setOpacity(0.05)

warning = function() 
    return  
end

-- Adaptado por LoboLupus;

local ttimespelll = addLabel("TIME DAS FUGAS", "TIME DAS FUGAS")
ttimespelll:setColor("orange")

-- Adaptado por LoboLupus;
local timeSpellPanelName = "timespellbot"

-- Main switch UI
local ui = setupUI([[
Panel
  height: 17
  BotSwitch
    id: title
    anchors.top: parent.top
    anchors.left: parent.left
    text-align: center
    width: 130
    !text: tr('Time Spell')

  Button
    id: settings
    anchors.top: prev.top
    anchors.left: prev.right
    anchors.right: parent.right
    margin-left: 3
    height: 17
    text: Setup
]])
ui:setId(timeSpellPanelName)

-- Main Window
local windowUI = setupUI([[
MainWindow
  !text: tr('- TIME SPELL -')
  size: 525 312

  Panel
    id: MainPanel
    image-source: /images/ui/panel_flat
    anchors.top: parent.top
    anchors.left: parent.left
    image-border: 6
    padding: 3
    size: 492 225

    TextList
      id: spellList
      anchors.left: parent.left
      anchors.bottom: parent.bottom
      padding: 1
      size: 270 212
      margin-bottom: 3
      margin-left: 3
      vertical-scrollbar: spellListScrollBar

    VerticalScrollBar
      id: spellListScrollBar
      anchors.top: spellList.top
      anchors.bottom: spellList.bottom
      anchors.right: spellList.right
      step: 14
      pixels-scroll: true

    Label
      id: spellNameLabel
      anchors.left: spellList.right
      anchors.top: spellList.top
      text: Spell Name:
      margin-top: 10
      margin-left: 7

    TextEdit
      id: spellName
      anchors.left: spellNameLabel.right
      anchors.top: parent.top
      margin-top: 5
      margin-left: 12
      width: 125

    Label
      id: onScreenLabel
      anchors.left: spellNameLabel.left
      anchors.top: spellName.bottom
      margin-top: 10
      text: On Screen:

    TextEdit
      id: onScreen
      anchors.left: onScreenLabel.right
      anchors.top: prev.top
      margin-top: -5
      margin-left: 17
      width: 125

    Label
      id: activeTimeLabel
      anchors.left: onScreenLabel.left
      anchors.top: onScreen.bottom
      text: Active Time:
      margin-top: 10

    TextEdit
      id: activeTime
      anchors.left: activeTimeLabel.right
      anchors.top: prev.top
      margin-top: -5
      margin-left: 5
      width: 125

    Label
      id: totalTimeLabel
      anchors.left: activeTimeLabel.left
      anchors.top: activeTime.bottom
      text: Total Time:
      margin-top: 10

    TextEdit
      id: totalTime
      anchors.left: totalTimeLabel.right
      anchors.top: prev.top
      margin-top: -5
      margin-left: 13
      width: 125

    Label
      id: posXLabel
      anchors.left: totalTimeLabel.left
      anchors.top: totalTime.bottom
      text: X:
      margin-top: 10

    TextEdit
      id: posX
      anchors.left: posXLabel.right
      anchors.top: prev.top
      margin-top: -5
      margin-left: 68
      width: 35

    Label
      id: posYLabel
      anchors.left: posX.right
      anchors.top: posX.top
      text: Y:
      margin-top: 5
      margin-left: 25

    TextEdit
      id: posY
      anchors.left: posYLabel.right
      anchors.top: prev.top
      margin-top: -5
      margin-left: 21
      width: 35

    Button
      id: addSpell
      anchors.left: spellList.right
      anchors.bottom: parent.bottom
      margin-bottom: 2
      margin-left: 8
      text: Add
      size: 200 17
      font: cipsoftFont

  HorizontalSeparator
    id: separator
    anchors.right: parent.right
    anchors.left: parent.left
    anchors.bottom: closeButton.top
    margin-bottom: 8

  Button
    id: closeButton
    !text: tr('Close')
    font: cipsoftFont
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    size: 45 21
    margin-top: 15
    margin-right: 5
]], g_ui.getRootWidget())

windowUI:hide()

-- Config file
local configName = modules.game_bot.contentsPanel.config:getCurrentOption().text
local tsName = charClass or name()
local timeSpellFile = "/bot/" .. configName .. "/" .. tsName .. "_TimeSpell.json"
local TimeSpellConfig = { spells = {} }
local spellsWidgets = {}
local MainPanel = windowUI.MainPanel

-- Load config
if g_resources.fileExists(timeSpellFile) then
    local ok, result = pcall(function()
        return json.decode(g_resources.readFileContents(timeSpellFile))
    end)
    if ok and type(result.spells) == "table" then
        TimeSpellConfig = result
    elseif not ok then
        warn("Erro carregando arquivo TimeSpell.json: " .. result)
        TimeSpellConfig = { spells = {} }
    end
end

-- Reset cooldowns
for _, spell in pairs(TimeSpellConfig.spells) do
    spell.activeCd, spell.totalCd = 0, 0
end

-- Save config
local function saveConfig()
    warn("Salvando TimeSpell em: " .. timeSpellFile)
    local ok, result = pcall(function() return json.encode(TimeSpellConfig, 2) end)
    if ok then
        g_resources.writeFileContents(timeSpellFile, result)
        warn("TimeSpell salvo!")
    else
        warn("Erro salvando: " .. result)
    end
end

-- Toggle main switch
ui.title:setOn(TimeSpellConfig.enabled)
ui.title.onClick = function(widget)
    TimeSpellConfig.enabled = not TimeSpellConfig.enabled
    widget:setOn(TimeSpellConfig.enabled)
    saveConfig()
    if not TimeSpellConfig.enabled then
        for k, w in pairs(spellsWidgets) do w:destroy() end
        spellsWidgets = {}
    end
end

-- Open/close window
ui.settings.onClick = function() windowUI:show(); windowUI:raise(); windowUI:focus() end
windowUI.closeButton.onClick = function() windowUI:hide(); saveConfig() end

-- Refresh spells in UI
local function refreshSpells()
    for _, child in pairs(MainPanel.spellList:getChildren()) do child:destroy() end
    for _, spell in pairs(TimeSpellConfig.spells) do
        local label = g_ui.createWidget('Label', MainPanel.spellList)
        label:setText(string.format("[%s]: CD: %.1fs", spell.onScreen, spell.totalTime/1000))
        label:setMargin(2)
        label.onDoubleClick = function()
            MainPanel.spellName:setText(spell.spell)
            MainPanel.onScreen:setText(spell.onScreen)
            MainPanel.activeTime:setText(spell.activeTime)
            MainPanel.totalTime:setText(spell.totalTime)
            MainPanel.posX:setText(spell.x)
            MainPanel.posY:setText(spell.y)
        end
    end
end

-- Add new spell
MainPanel.addSpell.onClick = function()
    local spellName = MainPanel.spellName:getText():trim():lower()
    local onScreen = MainPanel.onScreen:getText():trim()
    local activeTime = tonumber(MainPanel.activeTime:getText()) or 0
    local totalTime = tonumber(MainPanel.totalTime:getText())
    local posX = tonumber(MainPanel.posX:getText()) or 0
    local posY = tonumber(MainPanel.posY:getText()) or 39

    if totalTime and spellName:len() > 0 and onScreen:len() > 0 then
        TimeSpellConfig.spells[spellName] = { spell = spellName, onScreen = onScreen, activeTime = activeTime,
            activeCd = 0, totalTime = totalTime, totalCd = 0, x = posX, y = posY, enabled = true }

        MainPanel.spellName:setText("")
        MainPanel.onScreen:setText("")
        MainPanel.activeTime:setText("")
        MainPanel.totalTime:setText("")
        MainPanel.posX:setText("")
        MainPanel.posY:setText("")

        saveConfig()
        refreshSpells()
    else
        warn("TimeSpell: dados inválidos")
    end
end

-- Helper: remaining time format
local function formatRemaining(time) return string.format("%.0fs", (time - now)/1000) end

-- Attach spell widgets on screen
local spellWidgetTemplate = [[
UIWidget
  background-color: black
  opacity: 0.8
  padding: 0 5
  focusable: true
  phantom: false
  draggable: true
]]

local function attachWidgetCallbacks(key)
    local w = spellsWidgets[key]
    w.onDragEnter = function(widget, mousePos)
        if not modules.corelib.g_keyboard.isCtrlPressed() then return false end
        widget:breakAnchors()
        widget.movingReference = { x = mousePos.x - widget:getX(), y = mousePos.y - widget:getY() }
        return true
    end
    w.onDragMove = function(widget, mousePos)
        local p = widget:getParent():getRect()
        local x = math.min(math.max(p.x, mousePos.x - widget.movingReference.x), p.x + p.width - widget:getWidth())
        local y = math.min(math.max(p.y, mousePos.y - widget.movingReference.y), p.y + p.height - widget:getHeight())
        widget:move(x, y)
        return true
    end
    w.onDragLeave = function(widget)
        local s = TimeSpellConfig.spells[key]
        s.x, s.y = widget:getX(), widget:getY()
        saveConfig()
        return true
    end
end

-- Macro to update spell widgets
macro(100, function()
    if not ui.title:isOn() then return end
    for key, spell in pairs(TimeSpellConfig.spells) do
        local w = spellsWidgets[key]
        if not spell.enabled and w then spellsWidgets[key]:destroy(); spellsWidgets[key] = nil
        elseif spell.enabled then
            if not w then
                w = setupUI(spellWidgetTemplate, g_ui.getRootWidget())
                w:setPosition({x = spell.x, y = spell.y})
                spellsWidgets[key] = w
                attachWidgetCallbacks(key)
            end
            if not spell.totalCd or spell.totalCd < now then w:setText(spell.onScreen .. ": OK"); w:setColor("green")
            elseif spell.activeCd >= now then w:setText(spell.onScreen .. ": " .. formatRemaining(spell.activeCd)); w:setColor("yellow")
            else w:setText(spell.onScreen .. ": " .. formatRemaining(spell.totalCd)); w:setColor("red") end
        end
    end
end)

-- Listen to talk to update cooldowns
onTalk(function(name, level, mode, text)
    if name ~= player:getName() then return end
    local spell = TimeSpellConfig.spells[text:lower()]
    if spell then
        if spell.activeTime > 0 then spell.activeCd = now + spell.activeTime end
        spell.totalCd = now + spell.totalTime
        saveConfig()
    end
end)

-- Initial refresh
refreshSpells()


local sep = UI.Separator()
sep:setHeight(1)
sep:setOpacity(0.05)
-----------------------------
-- DEATH SKILL
-----------------------------
local iiccoonn = addLabel("ICONES", "ICONES")
iiccoonn:setColor("orange")

local configDeath = {
  idPotion = 11808,
  hpPercent = 40,
  duration = 1800000, -- 30 minutos
  textTriggers = { 'perdera skills se morrer nos proximos 30 minutos' },
}
-----------------------------
-- MACRO: USA A POTION
-----------------------------
local potdeath = macro(100, "Potion DeathSkill", function()
  if hppercent() <= configDeath.hpPercent then
    if not storage.timeDeathPotion or storage.timeDeathPotion <= now then
      useWith(configDeath.idPotion, player)
    end
  end
end)

-----------------------------
-- DETECTA MENSAGEM E ATIVA TIMER
-----------------------------
onTextMessage(function(mode, text)
  text = text:lower()

  for _, v in ipairs(configDeath.textTriggers) do
    if text:find(v) then
      storage.timeDeathPotion = now + configDeath.duration
      break
    end
  end
end)

-----------------------------
-- HUD TIMER (ARRASTÁVEL)
-----------------------------
storage.widgetPos = storage.widgetPos or {}

local deathHud = setupUI([[
UIWidget
  background-color: black
  opacity: 0.8
  padding: 0 6
  focusable: true
  phantom: false
  draggable: true
]], g_ui.getRootWidget())

deathHud.onDragEnter = function(widget, mousePos)
  if not modules.corelib.g_keyboard.isCtrlPressed() then return false end
  widget:breakAnchors()
  widget.movingReference = {
    x = mousePos.x - widget:getX(),
    y = mousePos.y - widget:getY()
  }
  return true
end

deathHud.onDragMove = function(widget, mousePos)
  local parentRect = widget:getParent():getRect()
  local x = math.min(
    math.max(parentRect.x, mousePos.x - widget.movingReference.x),
    parentRect.x + parentRect.width - widget:getWidth()
  )
  local y = math.min(
    math.max(parentRect.y - widget:getParent():getMarginTop(), mousePos.y - widget.movingReference.y),
    parentRect.y + parentRect.height - widget:getHeight()
  )
  widget:move(x, y)
  storage.widgetPos["deathHud"] = {x = x, y = y}
  return true
end

storage.widgetPos["deathHud"] = storage.widgetPos["deathHud"] or {x = 50, y = 80}
deathHud:setPosition(storage.widgetPos["deathHud"])

-----------------------------
-- ATUALIZA HUD
-----------------------------
macro(100, function()
  if not storage.timeDeathPotion or storage.timeDeathPotion <= now then
    deathHud:setText("Death Potion: OK")
    deathHud:setColor("green")
  else
    local remaining = math.ceil((storage.timeDeathPotion - now) / 1000)
    local min = math.floor(remaining / 60)
    local sec = remaining % 60

    deathHud:setColor("red")
    deathHud:setText(string.format("Death Potion: %02d:%02d", min, sec))
  end
end)

-----------------------------
-- ÍCONE
-----------------------------

-----------------------------
-- Seção: HUD Timer (KitPill)
-----------------------------
storage.widgetPos = storage.widgetPos or {}

local timespellKitPill = setupUI([[
UIWidget
  background-color: black
  opacity: 0.8
  padding: 0 5
  focusable: true
  phantom: false
  draggable: true
]], g_ui.getRootWidget())

timespellKitPill.onDragEnter = function(widget, mousePos)
  if not modules.corelib.g_keyboard.isCtrlPressed() then return false end
  widget:breakAnchors()
  widget.movingReference = {x = mousePos.x - widget:getX(), y = mousePos.y - widget:getY()}
  return true
end

timespellKitPill.onDragMove = function(widget, mousePos, moved)
  local parentRect = widget:getParent():getRect()
  local x = math.min(math.max(parentRect.x, mousePos.x - widget.movingReference.x), parentRect.x + parentRect.width - widget:getWidth())
  local y = math.min(math.max(parentRect.y - widget:getParent():getMarginTop(), mousePos.y - widget.movingReference.y), parentRect.y + parentRect.height - widget:getHeight())
  widget:move(x, y)
  storage.widgetPos["timespellKitPill"] = {x = x, y = y}
  return true
end

local name = "timespellKitPill"
storage.widgetPos[name] = storage.widgetPos[name] or {}
timespellKitPill:setPosition({x = storage.widgetPos[name].x or 50, y = storage.widgetPos[name].y or 50})

-- Inicializa cooldown
if type(storage.timeKitPill) ~= 'table' or (storage.timeKitPill.t - now) > 120000 then
  storage.timeKitPill = {t = 0}
end

-- Macro atualiza HUD do KitPill
macro(100, function()
  if not storage.timeKitPill.t or storage.timeKitPill.t < now then
    timespellKitPill:setText('KitPill: OK! ')
    timespellKitPill:setColor('green')
  else
    local remainingTime = math.ceil((storage.timeKitPill.t - now) / 1000)
    timespellKitPill:setColor('red')
    timespellKitPill:setText("KitPill: ".. remainingTime .. "s ")
  end
end)

-- Atualiza cooldown quando recebe mensagem
onTextMessage(function(mode, text)
  if text:find("Nhack Nhack") or text:find("Voce esta com o buff do kit pill") then
    storage.timeKitPill.t = now + 30000
  end
end)

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

-- ===================================================
-- HUD Timer • Mode Bijuu (Simple & Stable)
-- Adaptado por: LoboLupus
-- ===================================================

local bijuuOutfits = {
  [158]=true,[161]=true,[303]=true,[269]=true,
  [162]=true,[301]=true,[302]=true,[268]=true,[531]=true
}

local ACTIVE_TIME = 30     -- 30 segundos ativo
local TOTAL_TIME  = 180    -- 3 minutos total

storage.bijuuTimer = storage.bijuuTimer or {
  buff   = 0,
  cd     = 0,
  active = false
}

storage.widgetPos = storage.widgetPos or {}

local bijuuHud = setupUI([[
UIWidget
  background-color: black
  opacity: 0.85
  padding: 0 6
  focusable: true
  phantom: false
  draggable: true
]], g_ui.getRootWidget())

bijuuHud.onDragEnter = function(widget, mousePos)
  if not modules.corelib.g_keyboard.isCtrlPressed() then return false end
  widget:breakAnchors()
  widget.movingReference = {
    x = mousePos.x - widget:getX(),
    y = mousePos.y - widget:getY()
  }
  return true
end

bijuuHud.onDragMove = function(widget, mousePos)
  local parent = widget:getParent():getRect()

  local x = math.min(
    math.max(parent.x, mousePos.x - widget.movingReference.x),
    parent.x + parent.width - widget:getWidth()
  )

  local y = math.min(
    math.max(parent.y, mousePos.y - widget.movingReference.y),
    parent.y + parent.height - widget:getHeight()
  )

  widget:move(x, y)
  storage.widgetPos.bijuuHud = { x = x, y = y }
  return true
end

local pos = storage.widgetPos.bijuuHud or {}
bijuuHud:setPosition({
  x = pos.x or 720,
  y = pos.y or 250
})

macro(200, function()
  local o = player:getOutfit()
  if not o or not o.type then return end

  local now = os.time()
  local isBijuu = bijuuOutfits[o.type] == true

  if not isBijuu and storage.bijuuTimer.active then
    storage.bijuuTimer.active = false
  end

  if isBijuu and not storage.bijuuTimer.active and now >= storage.bijuuTimer.cd then
    storage.bijuuTimer.active = true
    storage.bijuuTimer.buff = now + ACTIVE_TIME
    storage.bijuuTimer.cd   = now + TOTAL_TIME
  end
end)

macro(100, function()
  local now = os.time()

  if now < storage.bijuuTimer.buff then
    bijuuHud:setColor('orange')
    bijuuHud:setText(
      'MODO BIJUU: ' ..
      (storage.bijuuTimer.buff - now) .. 's'
    )

  elseif now < storage.bijuuTimer.cd then
    bijuuHud:setColor('red')
    bijuuHud:setText(
      'MODO BIJUU: ' ..
      (storage.bijuuTimer.cd - now) .. 's'
    )

  else
    bijuuHud:setColor('green')
    bijuuHud:setText('MODO BIJUU: OK')
  end
end)

local timeTrack = {
	["ntoultimate"] = 15,
	["ntolost"] = 5,
	["katon"] = 5, -- NTO SPLIT
	["dbolost"] = 2,
	["dragon ball rising"] = 5,
	["dbo galaxy"] = 5,
	["dbo infinity duel"] = 5
}

local storage = tyrBot and tyrBot.storage or storage;

local pzTime = timeTrack[g_game.getWorldName():lower()] or 15
	

os = os or modules.os

if type(storage.battleTracking) ~= "table" or storage.battleTracking[2] ~= player:getId() or (not os and storage.battleTracking[1] - now > pzTime * 60 * 1000) then
    storage.battleTracking = {0, player:getId(), {}}
end 

onTextMessage(function(mode, text)
	text = text:lower()
	if text:find("o assassinato de") or text:find("was not justified") or text:find("o assassinato do")then
		storage.battleTracking[1] = not os and now + (pzTime * 60 * 1000) or os.time() + (pzTime * 60)
		return
	end
	if not text:find("due to your") and not text:find("you deal") then return end
	local spectators = getSpecs or getSpectators;
	for _, spec in ipairs(spectators()) do
		local specName = spec:getName():lower()
		if spec:isPlayer() and text:find(specName) then
			storage.battleTracking[3][specName] = {timeBattle = not os and now + 60000 or os.time() + 60, playerId = spec:getId()}
			break
		end
	end
end)

math.mod = math.mod or function(base, modulus)
	return base % modulus
end

local function doFormatMin(v)
    v = v > 1000 and v / 1000 or v
    local mins = 00
    if v >= 60 then
        mins = string.format("%02.f", math.floor(v / 60))
    end
    local seconds = string.format("%02.f", math.abs(math.floor(math.mod(v, 60))))
    return mins .. ":" .. seconds
end




storage.widgetPos = storage.widgetPos or {}

local pkTimeWidget = setupUI([[
UIWidget
  background-color: black
  opacity: 0.8
  padding: 0 5
  focusable: true
  phantom: false
  draggable: true
]], g_ui.getRootWidget())


pkTimeWidget.onDragEnter = function(widget, mousePos)
	if not (modules.corelib.g_keyboard.isCtrlPressed()) then
		return false
	end
	widget:breakAnchors()
	widget.movingReference = {x = mousePos.x - widget:getX(), y = mousePos.y - widget:getY()}
	return true
end

pkTimeWidget.onDragMove = function(widget, mousePos, moved)
	local parentRect = widget:getParent():getRect()
	local x = math.min(math.max(parentRect.x, mousePos.x - widget.movingReference.x), parentRect.x + parentRect.width - widget:getWidth())
	local y = math.min(math.max(parentRect.y - widget:getParent():getMarginTop(), mousePos.y - widget.movingReference.y), parentRect.y + parentRect.height - widget:getHeight())        
	widget:move(x, y)
	storage.widgetPos["pkTimeWidget"] = {x = x, y = y}
	return true
end

local name = "pkTimeWidget"
storage.widgetPos[name] = storage.widgetPos[name] or {}
pkTimeWidget:setPosition({x = storage.widgetPos[name].x or 50, y = storage.widgetPos[name].y or 50})



if g_game.getWorldName() == "Katon" then -- FIX NTO SPLIT
	function getSpecs()
		local specs = {}
		for _, tile in pairs(g_map.getTiles(posz())) do
			local creatures = tile:getCreatures();
			if (#creatures > 0) then
				for i = 1, #creatures do
					table.insert(specs, creatures[i]);
				end
			end
		end
		return specs
	end
	function getPlayerByName(name)
		name = name:lower():trim();
		for _, spec in ipairs(getSpecs()) do
			if spec:getName():lower() == name then
				return spec
			end
		end
	end
end

pkTimeMacro = macro(1, function()
	local time = os and os.time() or now
	if isInPz() then storage.battleTracking[1] = 0 end
	for specName, value in pairs(storage.battleTracking[3]) do
		if (os and value.timeBattle >= time) or (not os and value.timeBattle >= time and value.timeBattle - 60000 <= time) then
			local playerSearch = getPlayerByName(specName, true)
			if playerSearch then
				if playerSearch:getId() == value.playerId then
					if playerSearch:getHealthPercent() == 0 then
						storage.battleTracking[1] = not os and time + (pzTime * 60 * 1000) or time + (pzTime * 60)
						storage.battleTracking[3][specName] = nil
					end
				else
					storage.battleTracking[3][specName] = nil
				end
			end
		else
			storage.battleTracking[3][specName] = nil
		end
	end
	local timeWidget = pkTimeWidget
	if storage.battleTracking[1] < time then
		timeWidget:setText("PK Time is: 00:00")
		timeWidget:setColor("green")
	else
		timeWidget:setText("PK Time is: " .. doFormatMin(storage.battleTracking[1] - time))
		timeWidget:setColor("red")
	end
end)
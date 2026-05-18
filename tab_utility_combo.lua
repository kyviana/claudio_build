-- tab_utility_combo.lua — Aba Utility (Combo System + Combo PVE)
-- Claudio Bot | NTO Ultimate

setDefaultTab("Utility")

-- Titulo COMBO SYSTEM
local comboTitle = setupUI([[
Panel
  height: 22
  Label
    color: #FF6600
    font: verdana-11px-rounded
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 22
    text-align: center
    text: COMBO SYSTEM
]], parent)

UI.Separator()

-- Mapeamento centralizado no 0_storage_bootstrap.lua
-- charClass ja foi definido globalmente antes deste arquivo carregar

-- Configs lidas do 0_char_configs.lua (CHARS global)
local charName = player:getName()
charClass = charClass or "tobirama"
local charConfig = (CHARS and CHARS[charClass]) or CHARS and CHARS.tobirama or {}
warn("Combo System: " .. charClass .. " (" .. charName .. ")")

-- Aplica buffs e actionbar automaticamente para o personagem detectado
schedule(1000, function()
    -- Buffs
    if charConfig.buff  and charConfig.buff  ~= "" then storage.buff  = charConfig.buff  end
    if charConfig.buff2 and charConfig.buff2 ~= "" then storage.buff2 = charConfig.buff2 end
    if charConfig.buff3 and charConfig.buff3 ~= "" then storage.buff3 = charConfig.buff3 end
    warn("Buffs aplicados: " .. (charConfig.buff or "") .. " | " .. (charConfig.buff2 or ""))

    -- Actionbar desativada temporariamente
    -- if charConfig.actionbar then ... end
end)

-- TRACKER DE DANO
local damageTracker = { lastSpell = "", totals = {}, enabled = false }

-- FUNCOES UTILITARIAS

local scriptFuncs = {}

scriptFuncs.readProfile = function(filePath, callback)
    if g_resources.fileExists(filePath) then
        local status, result = pcall(function()
            return json.decode(g_resources.readFileContents(filePath))
        end)
        if not status then return warn("Erro ao ler perfil: " .. result) end
        callback(result)
    end
end

scriptFuncs.saveProfile = function(configFile, content)
    local status, result = pcall(function()
        return json.encode(content, 2)
    end)
    if not status then return warn("Erro ao salvar: " .. result) end
    g_resources.writeFileContents(configFile, result)
end

local firstLetterUpper = function(str)
    return (str:gsub("(%a)([%w_']*)", function(first, rest)
        return first:upper() .. rest:lower()
    end))
end

local function formatRemainingTime(time)
    return string.format("%.0f", math.max(0, (time - now) / 1000)) .. "s"
end

-- STORAGE

local MAIN_DIR = "/bot/" .. modules.game_bot.contentsPanel.config:getCurrentOption().text .. "/storage/"
local STORAGE_FILE = MAIN_DIR .. g_game.getWorldName() .. "_combo_" .. charClass .. ".json"

if not g_resources.directoryExists(MAIN_DIR) then
    g_resources.makeDir(MAIN_DIR)
end

local storageCombo = { comboSpells = {}, comboEnabled = false }

scriptFuncs.readProfile(STORAGE_FILE, function(result)
    storageCombo = result
    if type(storageCombo.comboSpells) ~= "table" then
        storageCombo.comboSpells = {}
    end
    for _, spell in ipairs(storageCombo.comboSpells) do
        spell.cooldownSpells = nil
    end
end)

-- Carrega burstOrder fixado pelo Auto-Burst se existir
if storage.fixedBurstOrder and CHARS and CHARS[charClass] then
    CHARS[charClass].burstOrder = storage.fixedBurstOrder
end

-- WIDGETS FLUTUANTES

local comboWidgets = {}

local widgetConfig = [[
UIWidget
  background-color: black
  opacity: 0.8
  padding: 0 5
  focusable: true
  phantom: false
  draggable: true
  text-auto-resize: true
]]

local function rebuildWidgets()
    for _, w in pairs(comboWidgets) do
        if w and not w:isDestroyed() then w:destroy() end
    end
    comboWidgets = {}

    for _, entry in ipairs(storageCombo.comboSpells) do
        if entry.enableTimeSpell then
            local w = setupUI(widgetConfig, g_ui.getRootWidget())
            w:setText(firstLetterUpper(entry.onScreen))
            w.onDragEnter = function(self, mousePos)
                if not modules.corelib.g_keyboard.isCtrlPressed() then return false end
                self:breakAnchors()
                self.movingReference = { x = mousePos.x - self:getX(), y = mousePos.y - self:getY() }
                return true
            end
            w.onDragMove = function(self, mousePos)
                local pr = self:getParent():getRect()
                local x = math.min(math.max(pr.x, mousePos.x - self.movingReference.x), pr.x + pr.width - self:getWidth())
                local y = math.min(math.max(pr.y - self:getParent():getMarginTop(), mousePos.y - self.movingReference.y), pr.y + pr.height - self:getHeight())
                self:move(x, y)
                if entry.widgetPos then
                    entry.widgetPos = { x = x, y = y }
                    scriptFuncs.saveProfile(STORAGE_FILE, storageCombo)
                end
                return true
            end
            w.onDragLeave = function(self) return true end
            if entry.widgetPos then
                w:setPosition(entry.widgetPos)
            else
                w:setPosition({ x = 10, y = 50 + (#comboWidgets * 20) })
            end
            comboWidgets[entry.index] = w
        end
    end
end

-- PAINEL PRINCIPAL

local comboIcon = setupUI([[
Panel
  height: 38
  BotSwitch
    id: title
    anchors.top: parent.top
    anchors.left: parent.left
    text-align: center
    width: 130
    text: Combo

  Button
    id: settings
    anchors.top: prev.top
    anchors.left: prev.right
    anchors.right: parent.right
    margin-left: 3
    height: 17
    text: Setup

  BotSwitch
    id: burstMode
    anchors.top: title.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    margin-top: 2
    height: 17
    text: Burst Mode (maior dano)
]])

-- JANELA DE CONFIGURACAO

local comboInterface = setupUI([[
MainWindow
  text: Combo Setup
  size: 700 310

  TextList
    id: spellList
    anchors.left: parent.left
    anchors.top: parent.top
    padding: 1
    size: 400 215
    margin-top: 11
    margin-left: 11
    vertical-scrollbar: spellListScrollBar

  VerticalScrollBar
    id: spellListScrollBar
    anchors.top: spellList.top
    anchors.bottom: spellList.bottom
    anchors.right: spellList.right
    step: 14
    pixels-scroll: true

  Button
    id: moveUp
    anchors.top: spellList.bottom
    anchors.left: parent.left
    margin-top: 5
    margin-left: 11
    text: Cima
    size: 50 17
    font: cipsoftFont

  Button
    id: moveDown
    anchors.top: spellList.bottom
    anchors.left: moveUp.right
    margin-top: 5
    margin-left: 5
    text: Baixo
    size: 50 17
    font: cipsoftFont

  VerticalSeparator
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.left: spellList.right
    margin-left: 8

  Label
    anchors.left: spellList.right
    anchors.top: parent.top
    text: Cast Spell
    margin-top: 15
    margin-left: 20

  TextEdit
    id: castSpell
    anchors.left: spellList.right
    anchors.top: parent.top
    margin-top: 28
    margin-left: 15
    width: 200

  Label
    anchors.left: spellList.right
    anchors.top: parent.top
    text: On Screen (nome no timer)
    margin-top: 55
    margin-left: 20

  TextEdit
    id: onScreen
    anchors.left: spellList.right
    anchors.top: parent.top
    margin-top: 68
    margin-left: 15
    width: 200

  Label
    anchors.left: spellList.right
    anchors.top: parent.top
    margin-top: 98
    margin-left: 20
    text: Cooldown

  HorizontalScrollBar
    id: cooldown
    anchors.left: spellList.right
    anchors.top: parent.top
    margin-top: 110
    margin-left: 15
    width: 140
    minimum: 0
    maximum: 60000
    step: 100

  Button
    id: findCD
    anchors.left: cooldown.right
    anchors.top: parent.top
    margin-top: 110
    margin-left: 5
    tooltip: Auto-detectar CD (spamma jutsu automaticamente)
    text: !
    size: 17 17

  Label
    id: cdStatus
    anchors.left: spellList.right
    anchors.top: parent.top
    margin-top: 128
    margin-left: 20
    text: CD: 0ms
    font: cipsoftFont

  Label
    anchors.left: spellList.right
    anchors.top: parent.top
    margin-top: 148
    margin-left: 20
    text: Distancia

  HorizontalScrollBar
    id: distance
    anchors.left: spellList.right
    anchors.top: parent.top
    margin-top: 160
    margin-left: 15
    width: 140
    minimum: 0
    maximum: 10
    step: 1

  Button
    id: findDist
    anchors.left: distance.right
    anchors.top: parent.top
    margin-top: 160
    margin-left: 5
    tooltip: Auto-detectar distancia (precisa de alvo atacado)
    text: D
    size: 17 17

  Label
    id: distStatus
    anchors.left: spellList.right
    anchors.top: parent.top
    margin-top: 178
    margin-left: 20
    text: Dist: 0
    font: cipsoftFont

  CheckBox
    id: showTimer
    anchors.left: spellList.right
    anchors.top: parent.top
    margin-top: 198
    margin-left: 15
    text: Mostrar timer na tela
    checked: true

  HorizontalSeparator
    anchors.right: parent.right
    anchors.left: parent.left
    anchors.bottom: closeButton.top
    margin-bottom: 5

  Button
    id: insertSpell
    text: Inserir
    font: cipsoftFont
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    size: 60 21
    margin-bottom: 8
    margin-right: 8

  Button
    id: closeButton
    !text: tr('Fechar')
    font: cipsoftFont
    anchors.right: insertSpell.left
    anchors.bottom: parent.bottom
    size: 60 21
    margin-bottom: 8
    margin-right: 5

]], g_ui.getRootWidget())
comboInterface:hide()

-- HANDLERS

comboInterface.findDist.onClick = function()
    local spellName = comboInterface.castSpell:getText():trim():lower()
    if spellName == "" then
        warn("Preencha o nome do jutsu antes de detectar a distancia.")
        return
    end
    startDetectDist(spellName)
end

-- ENTRADA DA LISTA

local spellEntry = [[
UIWidget
  background-color: alpha
  focusable: true
  height: 18

  CheckBox
    id: enabled
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    width: 14
    height: 14
    margin-left: 3

  CheckBox
    id: showTimespell
    anchors.left: enabled.right
    anchors.verticalCenter: parent.verticalCenter
    width: 14
    height: 14
    margin-left: 2

  Button
    id: remove
    !text: tr('x')
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    margin-right: 4
    width: 14
    height: 14
    font: cipsoftFont

  Label
    id: textToSet
    anchors.left: showTimespell.right
    anchors.right: remove.left
    anchors.verticalCenter: parent.verticalCenter
    margin-left: 4
    margin-right: 4

  $focus:
    background-color: #00000055
]]

-- SCROLLBARS

comboInterface.cooldown:setText("0ms")
comboInterface.cooldown.onValueChange = function(widget, value)
    widget:setText(value >= 1000 and (value / 1000 .. "s") or (value .. "ms"))
    comboInterface.cdStatus:setText("CD: " .. (value >= 1000 and (value/1000 .. "s") or (value .. "ms")))
end

comboInterface.distance:setText("0")
comboInterface.distance.onValueChange = function(widget, value)
    widget:setText(tostring(value))
    comboInterface.distStatus:setText("Dist: " .. value)
end

-- AUTO DETECT CD

local detectingCD = false
local spellBeingDetected = ""
local firstHitTime = nil
local spammingCD = false

comboInterface.findCD.onClick = function()
    local spellName = comboInterface.castSpell:getText():trim():lower()
    if spellName == "" then
        warn("Preencha o nome do jutsu antes de detectar o CD.")
        return
    end
    detectingCD = true
    spammingCD = true
    firstHitTime = nil
    spellBeingDetected = spellName
    comboInterface.cdStatus:setText("Spammando jutsu...")
    comboInterface.cdStatus:setColor("#FFA500")
    comboInterface.findCD:setText("...")
end

macro(100, function()
    if not spammingCD then return end
    say(spellBeingDetected)
end)

onTalk(function(name, level, mode, text, channelId, pos)
    if not detectingCD then return end
    if name ~= player:getName() then return end
    if mode ~= 44 then return end
    local textLower = text:lower():trim()
    if textLower ~= spellBeingDetected then return end
    if not firstHitTime then
        firstHitTime = now
        comboInterface.cdStatus:setText("Aguardando 2a vez...")
        comboInterface.cdStatus:setColor("#FFFF00")
    else
        local detectedCD = now - firstHitTime
        comboInterface.cooldown:setValue(detectedCD)
        comboInterface.cdStatus:setText("CD: " .. string.format("%.1f", detectedCD/1000) .. "s detectado!")
        comboInterface.cdStatus:setColor("#00FF00")
        detectingCD = false
        spammingCD = false
        firstHitTime = nil
        spellBeingDetected = ""
        comboInterface.findCD:setText("!")
    end
end)

-- REFRESH DA LISTA

local function refreshList()
    for i, child in pairs(comboInterface.spellList:getChildren()) do
        child:destroy()
    end

    for index, entry in ipairs(storageCombo.comboSpells) do
        local label = setupUI(spellEntry, comboInterface.spellList)

        label.textToSet:setText(
            firstLetterUpper(entry.spellCast) ..
            " | CD: " .. (entry.cooldown >= 1000 and (entry.cooldown/1000 .. "s") or (entry.cooldown .. "ms")) ..
            " | Dist: " .. entry.distance
        )
        label:setTooltip("On Screen: " .. entry.onScreen)

        label.enabled:setChecked(entry.enabled)
        label.enabled.onClick = function()
            entry.enabled = not entry.enabled
            label.enabled:setChecked(entry.enabled)
            scriptFuncs.saveProfile(STORAGE_FILE, storageCombo)
        end

        label.showTimespell:setChecked(entry.enableTimeSpell)
        label.showTimespell.onClick = function()
            entry.enableTimeSpell = not entry.enableTimeSpell
            label.showTimespell:setChecked(entry.enableTimeSpell)
            if comboWidgets[entry.index] then
                if entry.enableTimeSpell then
                    comboWidgets[entry.index]:show()
                else
                    comboWidgets[entry.index]:hide()
                end
            end
            scriptFuncs.saveProfile(STORAGE_FILE, storageCombo)
        end

        label.remove.onClick = function()
            for i, v in ipairs(storageCombo.comboSpells) do
                if v == entry then table.remove(storageCombo.comboSpells, i) break end
            end
            for i, v in ipairs(storageCombo.comboSpells) do v.index = i end
            scriptFuncs.saveProfile(STORAGE_FILE, storageCombo)
            rebuildWidgets()
            refreshList()
        end

        label.onDoubleClick = function()
            comboInterface.castSpell:setText(entry.spellCast)
            comboInterface.onScreen:setText(entry.onScreen)
            comboInterface.cooldown:setValue(entry.cooldown)
            comboInterface.distance:setValue(entry.distance)
            comboInterface.showTimer:setChecked(entry.enableTimeSpell)
            for i, v in ipairs(storageCombo.comboSpells) do
                if v == entry then table.remove(storageCombo.comboSpells, i) break end
            end
            for i, v in ipairs(storageCombo.comboSpells) do v.index = i end
            rebuildWidgets()
            refreshList()
        end
    end

    rebuildWidgets()
end

-- INSERIR JUTSU

comboInterface.insertSpell.onClick = function()
    local spellName = comboInterface.castSpell:getText():trim():lower()
    local onScreen  = comboInterface.onScreen:getText():trim()
    local cooldown  = comboInterface.cooldown:getValue()
    local distance  = comboInterface.distance:getValue()
    local showTimer = comboInterface.showTimer:isChecked()

    if spellName == "" then return warn("Preencha o nome do jutsu.") end
    if onScreen  == "" then return warn("Preencha o nome On Screen.") end
    if cooldown  == 0  then return warn("Defina o cooldown.") end
    if distance  == 0  then return warn("Defina a distancia.") end

    table.insert(storageCombo.comboSpells, {
        index          = #storageCombo.comboSpells + 1,
        spellCast      = spellName,
        onScreen       = onScreen,
        orangeSpell    = spellName,
        cooldown       = cooldown,
        distance       = distance,
        enableTimeSpell= showTimer,
        enabled        = true,
        widgetPos      = { x = 10, y = 50 + (#storageCombo.comboSpells * 22) }
    })

    scriptFuncs.saveProfile(STORAGE_FILE, storageCombo)
    refreshList()
    comboInterface.castSpell:clearText()
    comboInterface.onScreen:clearText()
    comboInterface.cooldown:setValue(0)
    comboInterface.distance:setValue(0)
    comboInterface.cdStatus:setText("CD: 0ms")
    comboInterface.cdStatus:setColor("#FFFFFF")
end

-- MOVE UP / DOWN

comboInterface.moveUp.onClick = function()
    local action = comboInterface.spellList:getFocusedChild()
    if not action then return end
    local index = comboInterface.spellList:getChildIndex(action)
    if index < 2 then return end
    comboInterface.spellList:moveChildToIndex(action, index - 1)
    storageCombo.comboSpells[index].index = index - 1
    storageCombo.comboSpells[index - 1].index = index
    table.sort(storageCombo.comboSpells, function(a, b) return a.index < b.index end)
    scriptFuncs.saveProfile(STORAGE_FILE, storageCombo)
end

comboInterface.moveDown.onClick = function()
    local action = comboInterface.spellList:getFocusedChild()
    if not action then return end
    local index = comboInterface.spellList:getChildIndex(action)
    if index >= comboInterface.spellList:getChildCount() then return end
    comboInterface.spellList:moveChildToIndex(action, index + 1)
    storageCombo.comboSpells[index].index = index + 1
    storageCombo.comboSpells[index + 1].index = index
    table.sort(storageCombo.comboSpells, function(a, b) return a.index < b.index end)
    scriptFuncs.saveProfile(STORAGE_FILE, storageCombo)
end

-- BOTOES DO PAINEL

comboIcon.title:setOn(storageCombo.comboEnabled or false)
comboIcon.title.onClick = function(widget)
    storageCombo.comboEnabled = not storageCombo.comboEnabled
    widget:setOn(storageCombo.comboEnabled)
    scriptFuncs.saveProfile(STORAGE_FILE, storageCombo)
end

comboIcon.settings.onClick = function()
    if not comboInterface:isVisible() then
        comboInterface:show()
        comboInterface:raise()
        comboInterface:focus()
    else
        comboInterface:hide()
        scriptFuncs.saveProfile(STORAGE_FILE, storageCombo)
    end
end

comboInterface.closeButton.onClick = function()
    comboInterface:hide()
    scriptFuncs.saveProfile(STORAGE_FILE, storageCombo)
end

-- IMPORTAR DO CADASTRO
local _CADVOC_COMBO = "/bot/" .. modules.game_bot.contentsPanel.config:getCurrentOption().text .. "/storage/cadastro_vocacoes.json"

UI.Button("Importar do Cadastro (" .. (charClass or "?") .. ")", function()
    if not g_resources.fileExists(_CADVOC_COMBO) then
        warn("[Combo] cadastro_vocacoes.json nao encontrado.")
        return
    end
    local ok, data = pcall(function()
        return json.decode(g_resources.readFileContents(_CADVOC_COMBO))
    end)
    if not ok or not data or not data.vocacoes or not data.vocacoes[charClass] then
        warn("[Combo] Vocacao '" .. (charClass or "?") .. "' nao encontrada no cadastro.")
        return
    end

    local jutsus = data.vocacoes[charClass].jutsus or {}
    local inserted, skipped = 0, 0

    for _, jutsu in ipairs(jutsus) do
        if jutsu.catDano then
            local exists = false
            for _, s in ipairs(storageCombo.comboSpells) do
                if s.spellCast:lower() == jutsu.spell:lower() then
                    exists = true
                    break
                end
            end
            if not exists then
                table.insert(storageCombo.comboSpells, {
                    index           = #storageCombo.comboSpells + 1,
                    spellCast       = jutsu.spell,
                    onScreen        = jutsu.spell,
                    orangeSpell     = jutsu.spell,
                    cooldown        = 0,
                    distance        = 7,
                    enableTimeSpell = false,
                    enabled         = true,
                    widgetPos       = { x = 10, y = 50 + (#storageCombo.comboSpells * 22) }
                })
                inserted = inserted + 1
            else
                skipped = skipped + 1
            end
        end
    end

    scriptFuncs.saveProfile(STORAGE_FILE, storageCombo)
    refreshList()
    warn("[Combo] Importados: " .. inserted .. " | Ja existiam: " .. skipped .. " | Use ! pra detectar CD de cada jutsu.")
end)

-- JANELA DE DANO

local dmgWindow = setupUI([[
MainWindow
  text: Dano por Jutsu
  size: 560 320

  TextList
    id: dmgList
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: separator.top
    margin: 8 8 8 8
    vertical-scrollbar: dmgScroll

  VerticalScrollBar
    id: dmgScroll
    anchors.top: dmgList.top
    anchors.bottom: dmgList.bottom
    anchors.right: dmgList.right
    step: 14
    pixels-scroll: true

  HorizontalSeparator
    id: separator
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: closeBtn.top
    margin-bottom: 5

  Button
    id: closeBtn
    text: Fechar
    font: cipsoftFont
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    size: 60 21
    margin-bottom: 8
    margin-right: 8

]], g_ui.getRootWidget())
dmgWindow:hide()
dmgWindow.closeBtn.onClick = function() dmgWindow:hide() end

local function showDmgReport()
    local temDados = false
    for _ in pairs(damageTracker.totals) do temDados = true break end
    warn("VER DANO CLICADO - tem dados: " .. tostring(temDados))
    if not temDados then
        warn("Nenhum dano registrado ainda. Ligue o Combo e lute!")
        return
    end
    local list = {}
    for spell, data in pairs(damageTracker.totals) do
        table.insert(list, { spell=spell, total=data.total, hits=data.hits, avg=math.floor(data.total/math.max(1,data.hits)) })
    end
    table.sort(list, function(a,b) return a.total > b.total end)
    local msg = "=== DANO POR JUTSU ===\n"
    for i, entry in ipairs(list) do
        msg = msg .. i .. ". " .. entry.spell .. "\n"
        msg = msg .. "   Total: " .. entry.total .. " | Hits: " .. entry.hits .. " | Media: " .. entry.avg .. "\n"
    end
    warn(msg)
    local ok, err = pcall(function()
        for _, child in pairs(dmgWindow.dmgList:getChildren()) do child:destroy() end
        for i, entry in ipairs(list) do
            local row = g_ui.createWidget("Label", dmgWindow.dmgList)
            row:setText(i .. ". " .. firstLetterUpper(entry.spell) .. " | Total: " .. entry.total .. " | Hits: " .. entry.hits .. " | Media: " .. entry.avg)
            row:setHeight(16)
            row:setColor(i == 1 and "#FFD700" or "#FFFFFF")
        end
        dmgWindow:show()
        dmgWindow:raise()
        dmgWindow:focus()
    end)
    if not ok then warn("Erro janela dano: " .. tostring(err)) end
end

macro(500, "Ver Dano [F9]", function()
    if not modules.corelib.g_keyboard.isKeyPressed("F9") then return end
    showDmgReport()
end)

macro(500, "Reset Dano [F10]", function()
    if not modules.corelib.g_keyboard.isKeyPressed("F10") then return end
    damageTracker.totals = {}
    damageTracker.lastSpell = ""
    warn("Dados de dano resetados.")
end)

-- Auto-Burst: reordena automaticamente por dano médio
storageCombo.autoBurst = storageCombo.autoBurst or false

local autoBurstMacro
autoBurstMacro = macro(500, "Auto-Burst", function()
    if autoBurstMacro:isOff() then
        storageCombo.autoBurst = false
        return
    end
    storageCombo.autoBurst = true
end, parent)

-- Botão: fixa a ordem atual como burstOrder permanente
UI.Button("Fixar Ordem Atual", function()
    local sorted = {}
    for spell, data in pairs(damageTracker.totals) do
        table.insert(sorted, { spell=spell, avg=math.floor(data.total/math.max(1,data.hits)) })
    end
    table.sort(sorted, function(a, b) return a.avg > b.avg end)

    if #sorted == 0 then
        warn("[Auto-Burst] Nenhum dado de dano ainda. Lute primeiro!")
        return
    end

    if CHARS and CHARS[charClass] then
        CHARS[charClass].burstOrder = {}
        for i, entry in ipairs(sorted) do
            CHARS[charClass].burstOrder[entry.spell] = i
        end
    end

    -- Salva no storage pra persistir
    storage.fixedBurstOrder = {}
    for i, entry in ipairs(sorted) do
        storage.fixedBurstOrder[entry.spell] = i
    end

    local msg = "[Auto-Burst] Ordem fixada:\n"
    for i, entry in ipairs(sorted) do
        msg = msg .. i .. ". " .. entry.spell .. " (media: " .. entry.avg .. ")\n"
    end
    warn(msg)
end)

UI.Separator()

-- ==============================
-- COMBO PVE
-- ==============================


local MAIN_DIR_PVE = "/bot/" .. modules.game_bot.contentsPanel.config:getCurrentOption().text .. "/storage/"
local PVE_FILE = MAIN_DIR_PVE .. g_game.getWorldName() .. "_pve_" .. (charClass or "unknown") .. ".json"

if not g_resources.directoryExists(MAIN_DIR_PVE) then g_resources.makeDir(MAIN_DIR_PVE) end

local storagePVE = { spells = {}, enabled = false }
if g_resources.fileExists(PVE_FILE) then
    local ok, result = pcall(function()
        return json.decode(g_resources.readFileContents(PVE_FILE))
    end)
    if ok and result then storagePVE = result end
end

local function savePVE()
    g_resources.writeFileContents(PVE_FILE, json.encode(storagePVE, 2))
end

-- Janela de setup PVE
local pveWindow = setupUI([[
MainWindow
  text: Combo PVE Setup
  size: 500 420

  TabBar
    id: pveTabBar
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    margin-top: 8
    margin-left: 8
    margin-right: 8
    height: 20

  Panel
    id: pveTabContent
    anchors.top: pveTabBar.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: closeBtn.top
    margin-top: 5
    margin-bottom: 5

  Button
    id: closeBtn
    text: Fechar
    font: cipsoftFont
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    size: 60 21
    margin-bottom: 8
    margin-right: 8
]], g_ui.getRootWidget())
pveWindow:hide()

local pveTabBar = pveWindow.pveTabBar
pveTabBar:setContentWidget(pveWindow.pveTabContent)

-- ABA 1: ADICIONAR JUTSUS
local addPanel = g_ui.createWidget("sPanel")
pveTabBar:addTab("Adicionar", addPanel)

local addLabelPVE = UI.Label("Copie todo o !jutsu com Ctrl + A e cola abaixo:", addPanel)
addLabelPVE:setColor("#AAAAAA")

local addEdit = setupUI([[
Panel
  height: 200
  margin-left: 5
  margin-right: 5
  TextEdit
    id: textarea
    anchors.fill: parent
    text-wrap: true
    shift-navigation: true
    multiline: true
]], addPanel)

local function getAddText() return addEdit.textarea:getText() end
local function clearAddText() addEdit.textarea:clearText() end

UI.Button("Inserir", function()
    local text = getAddText():trim()
    if text == "" then return warn("Preencha o campo antes de inserir.") end

    local globalSpells = {
        "skip", "kai", "light", "throw kunai", "regeneration",
        "throw shuriken", "concentrate chakra feet", "jump up",
        "powerdown", "jump down", "chakra down", "sense",
        "bunshin no jutsu", "chakra rest", "big regeneration",
        "kawarimi no jutsu", "kekkei genkai", "atract no jutsu",
    }
    local function isGlobal(spell)
        spell = spell:lower():trim()
        for _, g in ipairs(globalSpells) do
            if spell == g then return true end
        end
        return false
    end

    local inserted, skipped, ignored = 0, 0, 0
    local isJutsuFormat = text:find("Jutsus para Level") ~= nil

    if isJutsuFormat then
        local currentLevel = nil
        for line in text:gmatch("[^\n]+") do
            line = line:trim()
            local lvl = line:match("Jutsus para Level (%d+)")
            if lvl then
                currentLevel = tonumber(lvl)
            elseif currentLevel and line ~= "" then
                local spell = line:match("^%s*(.-)%s*%-%s*:%s*%d")
                if spell and spell ~= "" then
                    spell = spell:lower():trim()
                    if isGlobal(spell) then
                        ignored = ignored + 1
                    else
                        local exists = false
                        for _, s in ipairs(storagePVE.spells) do
                            if s.spell == spell then exists = true break end
                        end
                        if not exists then
                            table.insert(storagePVE.spells, { spell=spell, level=currentLevel, enabled=true, cooldownUntil=0 })
                            inserted = inserted + 1
                        else
                            skipped = skipped + 1
                        end
                    end
                end
            end
        end
    else
        for line in text:gmatch("[^\n]+") do
            line = line:trim():lower()
            if line ~= "" then
                local level = tonumber(line:match("(%d+)%s*$"))
                local spell = line:match("^(.-)%s*%d+%s*$")
                if level and spell and spell ~= "" then
                    spell = spell:trim()
                    if isGlobal(spell) then
                        ignored = ignored + 1
                    else
                        local exists = false
                        for _, s in ipairs(storagePVE.spells) do
                            if s.spell == spell then exists = true break end
                        end
                        if not exists then
                            table.insert(storagePVE.spells, { spell=spell, level=level, enabled=true, cooldownUntil=0 })
                            inserted = inserted + 1
                        else
                            skipped = skipped + 1
                        end
                    end
                end
            end
        end
    end

    savePVE()
    clearAddText()
    refreshComboListPVE()
    warn("Inseridos: " .. inserted .. " | Ja existiam: " .. skipped .. " | Ignorados (globais): " .. ignored)
end, addPanel)

UI.Separator(addPanel)

UI.Button("Importar da Vocacao (" .. (charClass or "?") .. ")", function()
    local cadastroFile = "/bot/" .. modules.game_bot.contentsPanel.config:getCurrentOption().text .. "/storage/cadastro_vocacoes.json"
    local vocData = nil
    if g_resources.fileExists(cadastroFile) then
        local ok, data = pcall(function()
            return json.decode(g_resources.readFileContents(cadastroFile))
        end)
        if ok and data and data.vocacoes and charClass then
            vocData = data.vocacoes[charClass]
        end
    end

    if not vocData or not vocData.jutsus or #vocData.jutsus == 0 then
        warn("[ComboPVE] Nenhum jutsu cadastrado para vocacao: " .. (charClass or "?"))
        return
    end

    local inserted, skipped = 0, 0
    for _, jutsu in ipairs(vocData.jutsus) do
        if jutsu.catDano then
            local exists = false
            for _, s in ipairs(storagePVE.spells) do
                if s.spell == jutsu.spell then exists = true break end
            end
            if not exists then
                table.insert(storagePVE.spells, { spell=jutsu.spell, level=jutsu.level or 1, enabled=true, cooldownUntil=0 })
                inserted = inserted + 1
            else
                skipped = skipped + 1
            end
        end
    end

    savePVE()
    refreshComboListPVE()
    warn("[ComboPVE] Importados: " .. inserted .. " | Ja existiam: " .. skipped)
end, addPanel)

UI.Separator(addPanel)

local spellEntryPVE = [[
UIWidget
  background-color: alpha
  focusable: true
  height: 18
  CheckBox
    id: enabled
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    width: 14
    height: 14
    margin-left: 3
  Label
    id: spellLabel
    anchors.left: enabled.right
    anchors.right: removeBtn.left
    anchors.verticalCenter: parent.verticalCenter
    margin-left: 4
  Button
    id: removeBtn
    text: x
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    margin-right: 4
    width: 14
    height: 14
    font: cipsoftFont
  $focus:
    background-color: #00000055
]]

-- ABA 2: COMBO ATUAL
local comboPanel = g_ui.createWidget("sPanel")
pveTabBar:addTab("Combo Atual", comboPanel)

local comboInfo = UI.Label("Jutsus disponiveis para seu level atual:", comboPanel)
comboInfo:setColor("#AAAAAA")

local comboListPanel = setupUI([[
Panel
  height: 220
  margin-left: 5
  margin-right: 5
  TextList
    id: comboList
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    anchors.right: comboScroll.left
    vertical-scrollbar: comboScroll
  VerticalScrollBar
    id: comboScroll
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    step: 14
    pixels-scroll: true
]], comboPanel)
local comboList = comboListPanel.comboList

function refreshComboListPVE()
    for _, child in pairs(comboList:getChildren()) do child:destroy() end
    local playerLevel = player:getLevel()

    local available = {}
    for _, entry in ipairs(storagePVE.spells) do
        if playerLevel >= entry.level then
            table.insert(available, entry)
        end
    end

    table.sort(available, function(a, b) return a.level > b.level end)
    for i, entry in ipairs(available) do
        entry.enabled = (i <= 5)
    end
    savePVE()

    table.sort(available, function(a, b) return a.level < b.level end)

    local count = 0
    for _, entry in ipairs(available) do
        local row = setupUI(spellEntryPVE, comboList)
        row.spellLabel:setText(entry.spell .. "  [lv " .. entry.level .. "]")
        row.enabled:setChecked(entry.enabled)
        row.enabled.onClick = function()
            entry.enabled = not entry.enabled
            row.enabled:setChecked(entry.enabled)
            savePVE()
        end
        row.removeBtn.onClick = function()
            for i, s in ipairs(storagePVE.spells) do
                if s.spell == entry.spell then table.remove(storagePVE.spells, i) break end
            end
            savePVE()
            refreshComboListPVE()
        end
        count = count + 1
    end

    if count == 0 then
        local empty = g_ui.createWidget("Label", comboList)
        empty:setText("Nenhum jutsu disponivel para o level " .. playerLevel)
        empty:setColor("#888888")
        empty:setHeight(18)
    end
end

UI.Button("Recarregar Lista", function()
    refreshComboListPVE()
end, comboPanel)

-- Painel principal na aba Utility
local pvePanel = setupUI([[
Panel
  height: 25
  BotSwitch
    id: pveSwitch
    anchors.top: parent.top
    anchors.left: parent.left
    text-align: center
    width: 130
    text: Combo PVE
  Button
    id: pveSetup
    anchors.top: parent.top
    anchors.left: prev.right
    anchors.right: parent.right
    margin-left: 3
    height: 25
    text: Setup
]], parent)

pvePanel.pveSwitch:setOn(storagePVE.enabled)
pvePanel.pveSwitch.onClick = function(widget)
    storagePVE.enabled = not storagePVE.enabled
    widget:setOn(storagePVE.enabled)
    savePVE()
    if styleSwitch then styleSwitch(widget) end
end
if styleSwitch then styleSwitch(pvePanel.pveSwitch) end

pvePanel.pveSetup.onClick = function()
    if not pveWindow:isVisible() then
        refreshComboListPVE()
        pveWindow:show()
        pveWindow:raise()
        pveWindow:focus()
    else
        pveWindow:hide()
    end
end

pveWindow.closeBtn.onClick = function() pveWindow:hide() end

macro(50, function()
    if not pvePanel.pveSwitch:isOn() then return end
    if SGO and now < SGO then return end
    if not g_game.isAttacking() then return end
    local target = g_game.getAttackingCreature()
    if not target then return end
    if target:isPlayer() then return end

    local playerLevel = player:getLevel()
    for _, entry in ipairs(storagePVE.spells) do
        if entry.enabled and playerLevel >= entry.level then
            say(entry.spell)
        end
    end
end)

UI.Separator()

-- AUTO-DETECT DISTANCIA

local detectingDist = false
local spellDetectingDist = ""
local lastDistTried = 0

local function startDetectDist(spellName)
    local target = g_game.getAttackingCreature()
    if not target then warn("Selecione um alvo antes de detectar a distancia.") return end
    detectingDist = true
    spellDetectingDist = spellName:lower():trim()
    lastDistTried = getDistanceBetween(player:getPosition(), target:getPosition())
    say(spellDetectingDist)
    comboInterface.distStatus:setText("Testando dist: " .. lastDistTried)
    comboInterface.distStatus:setColor("#FFA500")
end

onTextMessage(function(mode, text)
    local lower = text:lower()
    if detectingDist then
        if lower:find("not reachable") or lower:find("too far") or lower:find("alcance") or lower:find("longe") then
            local maxDist = math.max(1, lastDistTried - 1)
            comboInterface.distance:setValue(maxDist)
            comboInterface.distStatus:setText("Dist detectada: " .. maxDist)
            comboInterface.distStatus:setColor("#00FF00")
            detectingDist = false
            spellDetectingDist = ""
        end
    end
    local dmg = text:match("loses (%d+) hitpoints? due to your")
    if dmg then
        dmg = tonumber(dmg)
        local lastSpell = damageTracker.lastSpell
        if lastSpell and lastSpell ~= "" then
            if not damageTracker.totals[lastSpell] then
                damageTracker.totals[lastSpell] = { total = 0, hits = 0 }
            end
            damageTracker.totals[lastSpell].total = damageTracker.totals[lastSpell].total + dmg
            damageTracker.totals[lastSpell].hits  = damageTracker.totals[lastSpell].hits + 1

            -- Auto-reordena burstOrder por dano médio após cada hit
            if storageCombo.autoBurst then
                local sorted = {}
                for spell, data in pairs(damageTracker.totals) do
                    if data.hits >= 3 then  -- mínimo 3 hits pra ter média confiável
                        table.insert(sorted, { spell=spell, avg=math.floor(data.total/data.hits) })
                    end
                end
                table.sort(sorted, function(a, b) return a.avg > b.avg end)
                if CHARS and CHARS[charClass] then
                    for i, entry in ipairs(sorted) do
                        CHARS[charClass].burstOrder[entry.spell] = i
                    end
                end
            end
        end
    end
end)

onTalk(function(name, level, mode, text, channelId, pos)
    if not detectingDist then return end
    if name ~= player:getName() then return end
    if mode ~= 44 then return end
    if text:lower():trim() == spellDetectingDist then
        comboInterface.distance:setValue(lastDistTried)
        comboInterface.distStatus:setText("Dist detectada: " .. lastDistTried)
        comboInterface.distStatus:setColor("#00FF00")
        detectingDist = false
        spellDetectingDist = ""
    end
end)

-- BURST MODE

storageCombo.burstEnabled = storageCombo.burstEnabled or false
comboIcon.burstMode:setOn(storageCombo.burstEnabled)
comboIcon.burstMode.onClick = function(widget)
    storageCombo.burstEnabled = not storageCombo.burstEnabled
    widget:setOn(storageCombo.burstEnabled)
    warn(storageCombo.burstEnabled and "Burst Mode ON" or "Burst Mode OFF")
end


local function getAvgDmg(spellName)
    local data = damageTracker.totals[spellName:lower():trim()]
    if not data or data.hits == 0 then return 0 end
    return math.floor(data.total / data.hits)
end

-- MACRO COMBO

macro(10, function()
    if not comboIcon.title:isOn() then return end
    if SGO and now < SGO then return end  -- SGO: input manual ativo
    if not g_game.isAttacking() then return end
    local target = g_game.getAttackingCreature()
    if not target then return end
    local targetPos = target:getPosition()
    if not targetPos then return end
    local dist = getDistanceBetween(player:getPosition(), targetPos)
    local available = {}
    for _, spell in ipairs(storageCombo.comboSpells) do
        if spell.enabled and dist <= spell.distance then
            if not spell.cooldownSpells or spell.cooldownSpells <= now then
                table.insert(available, spell)
            end
        end
    end
    if #available == 0 then return end
    if storageCombo.burstEnabled then
        local burstOrder = charConfig.burstOrder or {}
        table.sort(available, function(a, b)
            local posA = burstOrder[a.spellCast:lower()] or 99
            local posB = burstOrder[b.spellCast:lower()] or 99
            return posA < posB
        end)
    else
        table.sort(available, function(a, b) return a.cooldown > b.cooldown end)
    end
    damageTracker.lastSpell = available[1].spellCast
    say(available[1].spellCast)
end)

onStatusMessage = onStatusMessage or function() end
local _origStatus = onStatusMessage
onStatusMessage = function(text)
    _origStatus(text)
    if not detectingDist then return end
    local lower = text:lower()
    if lower:find("not reachable") or lower:find("too far") or lower:find("longe") then
        local maxDist = math.max(1, lastDistTried - 1)
        comboInterface.distance:setValue(maxDist)
        comboInterface.distStatus:setText("Dist detectada: " .. maxDist)
        comboInterface.distStatus:setColor("#00FF00")
        detectingDist = false
        spellDetectingDist = ""
    end
end

-- MACRO TIMERS

macro(10, function()
    for _, spell in ipairs(storageCombo.comboSpells) do
        local w = comboWidgets[spell.index]
        if w and not w:isDestroyed() then
            if not spell.cooldownSpells or spell.cooldownSpells <= now then
                w:setColor("#00FF00")
                w:setText(firstLetterUpper(spell.onScreen) .. " | OK!")
            else
                w:setColor("red")
                w:setText(firstLetterUpper(spell.onScreen) .. " | " .. formatRemainingTime(spell.cooldownSpells))
            end
        end
    end
end)

-- DETECTA JUTSU USADO

onTalk(function(name, level, mode, text, channelId, pos)
    if name ~= player:getName() then return end
    if mode ~= 44 then return end
    local textLower = text:lower():trim()
    for _, spell in ipairs(storageCombo.comboSpells) do
        if textLower == spell.spellCast:lower():trim() then
            if spell.cooldown == 0 then
                -- Auto-detecta CD: mede tempo entre primeiro e segundo uso
                if not spell._firstUseTime then
                    spell._firstUseTime = now
                else
                    local detectedCD = now - spell._firstUseTime
                    if detectedCD > 500 then  -- ignora usos muito rápidos (spam)
                        spell.cooldown = detectedCD
                        spell._firstUseTime = nil
                        scriptFuncs.saveProfile(STORAGE_FILE, storageCombo)
                        warn("[Combo] CD detectado para '" .. spell.spellCast .. "': " .. string.format("%.1f", detectedCD/1000) .. "s")
                    else
                        spell._firstUseTime = now  -- reinicia medição
                    end
                end
            end
            spell.cooldownSpells = now + spell.cooldown
            break
        end
    end
end)

-- INICIALIZA

refreshList()
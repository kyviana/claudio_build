--------------------------------------------------------------------
-- Manual Keys v3.0
-- Teclas prioritarias por vocacao
-- Suporte a Say, Item (use/useWith) e Mouse lateral
-- Claudio Bot - NTO Ultimate
--------------------------------------------------------------------

local _charClass = charClass or "tobirama"

-- STORAGE

local MAIN_DIR     = "/bot/" .. modules.game_bot.contentsPanel.config:getCurrentOption().text .. "/storage/"
local STORAGE_FILE = MAIN_DIR .. g_game.getWorldName() .. "_manualkeys_" .. _charClass .. ".json"

if not g_resources.directoryExists(MAIN_DIR) then
    g_resources.makeDir(MAIN_DIR)
end

storageKeys = { keys = {}, enabled = false }

local function saveStorage()
    local ok, result = pcall(function() return json.encode(storageKeys, 2) end)
    if ok then
        g_resources.writeFileContents(STORAGE_FILE, result)
    else
        warn("[ManualKeys] Erro ao salvar: " .. tostring(result))
    end
end

if g_resources.fileExists(STORAGE_FILE) then
    local ok, result = pcall(function()
        return json.decode(g_resources.readFileContents(STORAGE_FILE))
    end)
    if ok and type(result) == "table" then
        storageKeys = result
        if type(storageKeys.keys) ~= "table" then storageKeys.keys = {} end
    end
end

-- HELPERS

local function isChatOpen()
    return modules.game_console:isChatEnabled()
end

-- Anti double-fire
local _lastFired = {}
local function canFire(id)
    local t = _lastFired[id]
    if not t or (now - t) > 150 then
        _lastFired[id] = now
        return true
    end
    return false
end

-- Mouse buttons map: nome -> numero do g_mouse.isPressed
local MOUSE_BTNS = {
    ["Mouse4"] = 7,
    ["Mouse5"] = 8,
    ["MouseMid"] = 3,
}

local function isMouseBind(input)
    return MOUSE_BTNS[input] ~= nil
end

local function isBindPressed(input)
    if isMouseBind(input) then
        local ok, result = pcall(function()
            return g_mouse.isPressed(MOUSE_BTNS[input])
        end)
        return ok and result
    end

    local kb = modules.corelib.g_keyboard

    -- Modificadores via funcoes dedicadas
    if input == "Ctrl"  then local ok, r = pcall(function() return kb.isCtrlPressed()  end) return ok and r end
    if input == "Alt"   then local ok, r = pcall(function() return kb.isAltPressed()   end) return ok and r end
    if input == "Shift" then local ok, r = pcall(function() return kb.isShiftPressed() end) return ok and r end

    -- Tecla normal
    local ok, result = pcall(function()
        return kb.isKeyPressed(input)
    end)
    return ok and result
end

local function entryLabel(entry)
    if entry.mode == "item" then
        local modeStr = entry.useMode or "yourself"
        return "[" .. entry.input .. "] " .. (entry.label or "item") .. " (" .. modeStr .. ")"
    else
        return "[" .. entry.input .. "] " .. (entry.sayText or "")
    end
end

-- EXECUCAO

local function findItemInContainers(itemId)
    local containers = g_game.getContainers()
    for _, container in pairs(containers) do
        for i = 0, container:getCapacity() - 1 do
            local item = container:getItem(i)
            if item and item:getId() == itemId then
                return item
            end
        end
    end
    return nil
end

local function executeEntry(entry)
    if entry.mode == "item" then
        local itemId = tonumber(entry.itemId)
        if not itemId then return end
        local useMode = entry.useMode or "yourself"

        if useMode == "yourself" then
            useWith(itemId, player)

        elseif useMode == "target" then
            local target = g_game.getAttackingCreature()
            if target then
                useWith(itemId, target)
            end

        elseif useMode == "use" then
            use(itemId)
        end
    else
        say(entry.sayText)
    end
end

-- MACRO PRINCIPAL (teclado + mouse)

macro(30, function()
    if not storageKeys.enabled then return end
    for _, entry in ipairs(storageKeys.keys) do
        if entry.enabled then
            if not (entry.blockOnChat and isChatOpen()) then
                if entry.requireTarget and not g_game.getAttackingCreature() then goto continue end
                local fireId = entry.input .. (entry.sayText or entry.itemId or "")
                if isBindPressed(entry.input) and canFire(fireId) then
                    executeEntry(entry)
                end
            end
            ::continue::
        end
    end
end)

-- DETECTOR AUTOMATICO DE BIND

local _detecting     = false
local _detectTarget  = nil  -- TextEdit que vai receber o resultado

-- Teclas base para scan
local BASE_KEYS = {
    "A","B","C","D","E","F","G","H","I","J","K","L","M",
    "N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
    "0","1","2","3","4","5","6","7","8","9",
    "F1","F2","F3","F4","F5","F6","F7","F8","F9","F10","F11","F12",
    "Space","BackSpace","Delete","Insert","Home","End",
    "PageUp","PageDown","Left","Right","Up","Down",
}

local SCAN_MOUSE = { Mouse4 = 7, Mouse5 = 8, MouseMid = 3 }

local detectMacro = macro(50, function()
    if not _detecting or not _detectTarget then return end

    local kb = modules.corelib.g_keyboard

    local function finish(name)
        _detectTarget:setText(name)
        _detecting = false
        _detectTarget = nil
    end

    -- Mouse
    for name, btn in pairs(SCAN_MOUSE) do
        local ok, pressed = pcall(function() return g_mouse.isPressed(btn) end)
        if ok and pressed then finish(name) return end
    end

    -- Modificadores via funcoes dedicadas
    local okC, ctrl  = pcall(function() return kb.isCtrlPressed()  end)
    local okA, alt   = pcall(function() return kb.isAltPressed()   end)
    local okS, shift = pcall(function() return kb.isShiftPressed() end)
    if okC and ctrl  then finish("Ctrl")  return end
    if okA and alt   then finish("Alt")   return end
    if okS and shift then finish("Shift") return end

    -- Teclas base
    for _, key in ipairs(BASE_KEYS) do
        local ok, pressed = pcall(function() return kb.isKeyPressed(key) end)
        if ok and pressed then finish(key) return end
    end
end)

-- PAINEL PRINCIPAL

local mkIcon = setupUI([[
Panel
  height: 20

  BotSwitch
    id: title
    anchors.top: parent.top
    anchors.left: parent.left
    text-align: center
    width: 130
    text: Manual Keys

  Button
    id: settings
    anchors.top: prev.top
    anchors.left: prev.right
    anchors.right: parent.right
    margin-left: 3
    height: 17
    text: Setup
]])

-- JANELA DE CONFIGURACAO

local mkInterface = setupUI([[
MainWindow
  text: Claudio Manual Keys v3.0
  size: 680 380

  TextList
    id: keyList
    anchors.left: parent.left
    anchors.top: parent.top
    padding: 1
    size: 330 280
    margin-top: 11
    margin-left: 11
    vertical-scrollbar: keyListScroll

  VerticalScrollBar
    id: keyListScroll
    anchors.top: keyList.top
    anchors.bottom: keyList.bottom
    anchors.right: keyList.right
    step: 14
    pixels-scroll: true

  VerticalSeparator
    anchors.top: parent.top
    anchors.bottom: closeBtn.top
    anchors.left: keyList.right
    margin-left: 6

  Label
    anchors.left: keyList.right
    anchors.top: parent.top
    margin-top: 15
    margin-left: 20
    text: Tecla / Botao do Mouse

  TextEdit
    id: inputField
    anchors.left: keyList.right
    anchors.top: parent.top
    margin-top: 28
    margin-left: 16
    width: 155
    tooltip: Digite ou clique em Detectar

  Button
    id: detectBtn
    anchors.left: keyList.right
    anchors.top: parent.top
    margin-top: 28
    margin-left: 175
    width: 60
    height: 18
    font: cipsoftFont
    text: Detectar

  Label
    anchors.left: keyList.right
    anchors.top: parent.top
    margin-top: 55
    margin-left: 20
    text: Modo

  CheckBox
    id: modeSay
    anchors.left: keyList.right
    anchors.top: parent.top
    margin-top: 70
    margin-left: 16
    width: 200
    text: Say (jutsu)
    checked: true

  CheckBox
    id: modeItem
    anchors.left: keyList.right
    anchors.top: parent.top
    margin-top: 87
    margin-left: 16
    width: 200
    text: Item

  Label
    id: sayLabel
    anchors.left: keyList.right
    anchors.top: parent.top
    margin-top: 112
    margin-left: 20
    text: Jutsu (sayText)

  TextEdit
    id: sayField
    anchors.left: keyList.right
    anchors.top: parent.top
    margin-top: 125
    margin-left: 16
    width: 200

  Label
    id: itemIdLabel
    anchors.left: keyList.right
    anchors.top: parent.top
    margin-top: 112
    margin-left: 20
    text: Item ID

  TextEdit
    id: itemIdField
    anchors.left: keyList.right
    anchors.top: parent.top
    margin-top: 125
    margin-left: 16
    width: 75

  Label
    id: itemLabelLbl
    anchors.left: keyList.right
    anchors.top: parent.top
    margin-top: 112
    margin-left: 105
    text: Apelido

  TextEdit
    id: itemLabelField
    anchors.left: keyList.right
    anchors.top: parent.top
    margin-top: 125
    margin-left: 101
    width: 115

  Label
    id: useModeLabel
    anchors.left: keyList.right
    anchors.top: parent.top
    margin-top: 153
    margin-left: 20
    text: Usar como

  CheckBox
    id: useYourself
    anchors.left: keyList.right
    anchors.top: parent.top
    margin-top: 168
    margin-left: 16
    width: 200
    text: Use on yourself
    checked: true

  CheckBox
    id: useTarget
    anchors.left: keyList.right
    anchors.top: parent.top
    margin-top: 185
    margin-left: 16
    width: 200
    text: Use on target

  CheckBox
    id: useSimple
    anchors.left: keyList.right
    anchors.top: parent.top
    margin-top: 202
    margin-left: 16
    width: 200
    text: Use

  CheckBox
    id: blockChat
    anchors.left: keyList.right
    anchors.top: parent.top
    margin-top: 230
    margin-left: 16
    width: 220
    text: Bloquear se chat aberto
    checked: true

  CheckBox
    id: requireTarget
    anchors.left: keyList.right
    anchors.top: parent.top
    margin-top: 248
    margin-left: 16
    width: 220
    text: Somente com target

  HorizontalSeparator
    anchors.right: parent.right
    anchors.left: parent.left
    anchors.bottom: closeBtn.top
    margin-bottom: 5

  Button
    id: insertBtn
    text: Inserir
    font: cipsoftFont
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    size: 60 21
    margin-bottom: 8
    margin-right: 8

  Button
    id: closeBtn
    text: Fechar
    font: cipsoftFont
    anchors.right: insertBtn.left
    anchors.bottom: parent.bottom
    size: 60 21
    margin-bottom: 8
    margin-right: 5

]], g_ui.getRootWidget())
mkInterface:hide()

-- MODO SAY/ITEM: mostra/esconde campos

local function updateModeFields()
    local isSay = mkInterface.modeSay:isChecked()
    mkInterface.sayLabel:setVisible(isSay)
    mkInterface.sayField:setVisible(isSay)
    mkInterface.itemIdLabel:setVisible(not isSay)
    mkInterface.itemIdField:setVisible(not isSay)
    mkInterface.itemLabelLbl:setVisible(not isSay)
    mkInterface.itemLabelField:setVisible(not isSay)
    mkInterface.useModeLabel:setVisible(not isSay)
    mkInterface.useYourself:setVisible(not isSay)
    mkInterface.useTarget:setVisible(not isSay)
    mkInterface.useSimple:setVisible(not isSay)
end

-- Exclusao mutua modo
mkInterface.modeSay.onCheckChange = function(widget, checked)
    if checked then mkInterface.modeItem:setChecked(false) updateModeFields()
    elseif not mkInterface.modeItem:isChecked() then widget:setChecked(true) end
end
mkInterface.modeItem.onCheckChange = function(widget, checked)
    if checked then mkInterface.modeSay:setChecked(false) updateModeFields()
    elseif not mkInterface.modeSay:isChecked() then widget:setChecked(true) end
end

-- Exclusao mutua useMode
local useModeWidgets = {}
local function selectUseMode(selected)
    for _, w in ipairs(useModeWidgets) do w:setChecked(w == selected) end
end
useModeWidgets = { mkInterface.useYourself, mkInterface.useTarget, mkInterface.useSimple }
for _, w in ipairs(useModeWidgets) do
    w.onCheckChange = function(self, checked)
        if checked then selectUseMode(self)
        else
            local anyOn = false
            for _, v in ipairs(useModeWidgets) do if v:isChecked() then anyOn = true break end end
            if not anyOn then self:setChecked(true) end
        end
    end
end

updateModeFields()

-- DETECTOR DE BIND

mkInterface.detectBtn.onClick = function()
    if _detecting then
        _detecting = false
        _detectTarget = nil
        mkInterface.detectBtn:setText("Detectar")
        mkInterface.detectBtn:setColor("#FFFFFF")
    else
        _detecting = true
        _detectTarget = mkInterface.inputField
        mkInterface.inputField:clearText()
        mkInterface.detectBtn:setText("Aguarde...")
        mkInterface.detectBtn:setColor("#FFA500")
    end
end

-- Quando deteccao finaliza, restaura botao
macro(100, function()
    if not _detecting and mkInterface.detectBtn:getText() == "Aguarde..." then
        mkInterface.detectBtn:setText("Detectar")
        mkInterface.detectBtn:setColor("#FFFFFF")
    end
end)

-- ENTRY TEMPLATE

local entryUI = [[
UIWidget
  background-color: alpha
  focusable: true
  height: 22

  CheckBox
    id: chkEnabled
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    width: 14
    height: 14
    margin-left: 3

  Label
    id: lblText
    anchors.left: chkEnabled.right
    anchors.right: btnRemove.left
    anchors.verticalCenter: parent.verticalCenter
    margin-left: 5
    margin-right: 4
    font: verdana-11px-rounded

  Button
    id: btnRemove
    !text: tr('x')
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    margin-right: 10
    width: 18
    height: 18
    font: cipsoftFont

  $focus:
    background-color: #00000055
]]

-- REFRESH LISTA

function refreshMKList()
    for _, child in pairs(mkInterface.keyList:getChildren()) do child:destroy() end

    for i, entry in ipairs(storageKeys.keys) do
        local row = setupUI(entryUI, mkInterface.keyList)
        local color = entry.mode == "item" and "#88DDFF" or "#FFDD88"
        row.lblText:setColor(color)
        row.lblText:setText(entryLabel(entry))
        row:setTooltip(
            "Modo: " .. (entry.mode == "item" and ("Item | " .. (entry.useMode or "yourself")) or "Say") ..
            " | Chat block: " .. tostring(entry.blockOnChat)
        )

        row.chkEnabled:setChecked(entry.enabled)
        row.chkEnabled.onClick = function()
            entry.enabled = not entry.enabled
            row.chkEnabled:setChecked(entry.enabled)
            saveStorage()
        end

        row.btnRemove.onClick = function()
            table.remove(storageKeys.keys, i)
            saveStorage()
            refreshMKList()
        end

        row.onDoubleClick = function()
            mkInterface.inputField:setText(entry.input)
            mkInterface.blockChat:setChecked(entry.blockOnChat)
            mkInterface.requireTarget:setChecked(entry.requireTarget or false)
            if entry.mode == "item" then
                mkInterface.modeItem:setChecked(true)
                mkInterface.modeSay:setChecked(false)
                mkInterface.itemIdField:setText(tostring(entry.itemId or ""))
                mkInterface.itemLabelField:setText(entry.label or "")
                local umMap = { yourself=mkInterface.useYourself, target=mkInterface.useTarget, use=mkInterface.useSimple }
                selectUseMode(umMap[entry.useMode or "yourself"] or mkInterface.useYourself)
            else
                mkInterface.modeSay:setChecked(true)
                mkInterface.modeItem:setChecked(false)
                mkInterface.sayField:setText(entry.sayText or "")
            end
            updateModeFields()
            table.remove(storageKeys.keys, i)
            saveStorage()
            refreshMKList()
        end
    end
end

-- INSERIR

mkInterface.insertBtn.onClick = function()
    local inp   = mkInterface.inputField:getText():trim()
    local block = mkInterface.blockChat:isChecked()

    if inp == "" then return warn("[ManualKeys] Preencha a tecla.") end

    local entry = { input = inp, blockOnChat = block, enabled = true }

    if mkInterface.modeItem:isChecked() then
        local itemId = mkInterface.itemIdField:getText():trim()
        local label  = mkInterface.itemLabelField:getText():trim()
        if itemId == "" then return warn("[ManualKeys] Preencha o Item ID.") end
        if label  == "" then return warn("[ManualKeys] Preencha o Apelido.") end
        local useMode = "yourself"
        if mkInterface.useTarget:isChecked() then useMode = "target" end
        if mkInterface.useSimple:isChecked() then useMode = "use"    end
        entry.mode    = "item"
        entry.itemId  = tonumber(itemId)
        entry.label   = label
        entry.useMode = useMode
    else
        local sayText = mkInterface.sayField:getText():trim():lower()
        if sayText == "" then return warn("[ManualKeys] Preencha o jutsu.") end
        entry.mode    = "say"
        entry.sayText = sayText
    end
    entry.requireTarget = mkInterface.requireTarget:isChecked()

    table.insert(storageKeys.keys, entry)
    saveStorage()
    refreshMKList()

    mkInterface.inputField:clearText()
    mkInterface.sayField:clearText()
    mkInterface.itemIdField:clearText()
    mkInterface.itemLabelField:clearText()
    mkInterface.modeSay:setChecked(true)
    mkInterface.modeItem:setChecked(false)
    selectUseMode(mkInterface.useYourself)
    mkInterface.blockChat:setChecked(true)
    mkInterface.requireTarget:setChecked(false)
    updateModeFields()
end

-- BOTOES DO PAINEL

mkIcon.title:setOn(storageKeys.enabled or false)
mkIcon.title.onClick = function(widget)
    storageKeys.enabled = not storageKeys.enabled
    widget:setOn(storageKeys.enabled)
    saveStorage()
end

mkIcon.settings.onClick = function()
    if not mkInterface:isVisible() then
        mkInterface:show(); mkInterface:raise(); mkInterface:focus()
    else
        mkInterface:hide(); saveStorage()
    end
end

mkInterface.closeBtn.onClick = function()
    _detecting = false
    _detectTarget = nil
    mkInterface:hide()
    saveStorage()
end

-- INIT

refreshMKList()
warn("[ManualKeys] Carregado - vocacao: " .. _charClass .. " | keys: " .. #storageKeys.keys)
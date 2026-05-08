--------------------------------------------------------------------
-- 0_sgo.lua
-- SGO - Bloqueio global de sistemas automaticos por input manual
-- Quando uma tecla configurada e pressionada, seta SGO por X ms
-- Sistemas automaticos (combo, buff) checam SGO antes de disparar
-- Manual Keys, pote, jump NAO checam SGO - executam sempre
--------------------------------------------------------------------

local SGO_FILE = "/bot/" .. modules.game_bot.contentsPanel.config:getCurrentOption().text .. "/storage/sgo_config.json"

-- Carrega config salva
local sgoConfig = { enabled = true, delay = 300, keys = {} }
if g_resources.fileExists(SGO_FILE) then
    local ok, result = pcall(function()
        return json.decode(g_resources.readFileContents(SGO_FILE))
    end)
    if ok and result then sgoConfig = result end
end
if type(sgoConfig.keys) ~= "table" then sgoConfig.keys = {} end

local function saveSGO()
    pcall(function()
        g_resources.writeFileContents(SGO_FILE, json.encode(sgoConfig, 2))
    end)
end

-- Variavel global — checada pelos sistemas automaticos
SGO = 0

local kb = modules.corelib.g_keyboard

local function isKeyPressed(input)
    if not input or input == "" then return false end
    if input == "MouseLeft"   then return pcall(function() return g_mouse.isPressed(1) end) end
    if input == "MouseRight"  then return pcall(function() return g_mouse.isPressed(2) end) end
    if input == "MouseMiddle" then return pcall(function() return g_mouse.isPressed(4) end) end
    if input == "Mouse4"      then local ok, r = pcall(function() return g_mouse.isPressed(6) end) return ok and r end
    if input == "Mouse5"      then local ok, r = pcall(function() return g_mouse.isPressed(7) end) return ok and r end
    if input == "Ctrl"        then local ok, r = pcall(function() return kb.isCtrlPressed()  end) return ok and r end
    if input == "Alt"         then local ok, r = pcall(function() return kb.isAltPressed()   end) return ok and r end
    if input == "Shift"       then local ok, r = pcall(function() return kb.isShiftPressed() end) return ok and r end
    local ok, r = pcall(function() return kb.isKeyPressed(input) end)
    return ok and r
end

-- Macro detector: roda a 10ms, seta SGO quando tecla pressionada
macro(10, function()
    if not sgoConfig.enabled then return end
    if modules.game_console:isChatEnabled() then return end
    -- Checa teclas do SGO configuradas manualmente
    for _, key in ipairs(sgoConfig.keys) do
        if key ~= "" and isKeyPressed(key) then
            SGO = now + sgoConfig.delay
            return
        end
    end
    -- Checa teclas do Manual Keys automaticamente
    if storageKeys and type(storageKeys.keys) == "table" then
        for _, entry in ipairs(storageKeys.keys) do
            if entry.enabled and entry.input and entry.input ~= "" then
                if isKeyPressed(entry.input) then
                    SGO = now + sgoConfig.delay
                    return
                end
            end
        end
    end
end)

-- ==============================
-- INTERFACE NO MAIN
-- ==============================

-- Switch + delay scroll
local sgoPanel = setupUI([[
Panel
  height: 40
  BotSwitch
    id: title
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 20
    text-align: center
    text: SGO

  HorizontalScrollBar
    id: delayScroll
    anchors.top: title.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    margin-top: 2
    margin-left: 4
    margin-right: 4
    height: 16
    minimum: 100
    maximum: 1000
    step: 50
]], parent)

sgoPanel.title:setOn(sgoConfig.enabled)
if styleSwitch then styleSwitch(sgoPanel.title) end
sgoPanel.title.onClick = function(widget)
    sgoConfig.enabled = not sgoConfig.enabled
    widget:setOn(sgoConfig.enabled)
    if styleSwitch then styleSwitch(widget) end
    saveSGO()
end

sgoPanel.delayScroll:setValue(sgoConfig.delay)
sgoPanel.delayScroll:setText("Pausa: " .. sgoConfig.delay .. "ms")
sgoPanel.delayScroll.onValueChange = function(widget, value)
    widget:setText("Pausa: " .. value .. "ms")
    sgoConfig.delay = value
    saveSGO()
end

UI.Separator()

-- Botao de setup das teclas
local sgoSetupBtn = setupUI([[
Panel
  height: 20
  Button
    id: btn
    font: verdana-11px-rounded
    anchors.fill: parent
    height: 20
    color: #AAAAAA
    background-color: #111111
    border-width: 1
    border-color: #555555
    text: SGO - Teclas
]], parent)

-- Janela de configuracao de teclas
local sgoWindow = setupUI([[
MainWindow
  text: SGO - Teclas que pausam automaticos
  size: 360 420

  TextList
    id: keyList
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: keyScroll.left
    anchors.bottom: separator.top
    margin: 8 0 8 8
    vertical-scrollbar: keyScroll
  VerticalScrollBar
    id: keyScroll
    anchors.top: keyList.top
    anchors.bottom: keyList.bottom
    anchors.right: parent.right
    margin-right: 8
    step: 14
    pixels-scroll: true
  HorizontalSeparator
    id: separator
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: addPanel.top
    margin-bottom: 4
  Panel
    id: addPanel
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: closeBtn.top
    height: 24
    margin-bottom: 4
    TextEdit
      id: keyEdit
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      anchors.right: detectBtn.left
      margin-left: 8
      margin-right: 4
      height: 20
    Button
      id: detectBtn
      anchors.right: addBtn.left
      anchors.verticalCenter: parent.verticalCenter
      margin-right: 4
      width: 60
      height: 20
      text: Detectar
      font: cipsoftFont
    Button
      id: addBtn
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      margin-right: 8
      width: 50
      height: 20
      text: Add
      font: cipsoftFont
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
sgoWindow:hide()

local function refreshKeyList()
    for _, c in pairs(sgoWindow.keyList:getChildren()) do c:destroy() end
    for i, key in ipairs(sgoConfig.keys) do
        local row = setupUI([[
UIWidget
  background-color: alpha
  focusable: true
  height: 18
  $focus:
    background-color: #00000055
]], sgoWindow.keyList)

        local lbl = setupUI([[
Label
  anchors.left: parent.left
  anchors.right: parent.right
  anchors.verticalCenter: parent.verticalCenter
  margin-left: 4
  margin-right: 22
  color: #FFFFFF
]], row)
        lbl:setText(key)

        local btnX = setupUI([[
Button
  anchors.right: parent.right
  anchors.verticalCenter: parent.verticalCenter
  margin-right: 2
  width: 16
  height: 14
  text: x
  font: cipsoftFont
]], row)

        btnX.onClick = function()
            table.remove(sgoConfig.keys, i)
            saveSGO()
            refreshKeyList()
        end
    end
end

-- Detectar tecla
local _detecting = false
sgoWindow.addPanel.detectBtn.onClick = function()
    sgoWindow.addPanel.keyEdit:clearText()
    sgoWindow.addPanel.keyEdit:setText("Pressione uma tecla...")
    _detecting = true
    schedule(3000, function() _detecting = false end)
end

-- Adicionar tecla manualmente
sgoWindow.addPanel.addBtn.onClick = function()
    local key = sgoWindow.addPanel.keyEdit:getText():trim()
    if key == "" or key == "Pressione uma tecla..." then return end
    -- Verifica duplicata
    for _, k in ipairs(sgoConfig.keys) do
        if k == key then return end
    end
    table.insert(sgoConfig.keys, key)
    saveSGO()
    sgoWindow.addPanel.keyEdit:clearText()
    refreshKeyList()
end

-- Detector de tecla pressionada
onKeyDown(function(keyCode, keyText, modifiers)
    if not _detecting then return end
    _detecting = false
    local key = keyText
    if key and key ~= "" then
        sgoWindow.addPanel.keyEdit:clearText()
        sgoWindow.addPanel.keyEdit:setText(key)
    end
end)

sgoWindow.closeBtn.onClick = function() sgoWindow:hide() end

sgoSetupBtn.btn.onClick = function()
    if not sgoWindow:isVisible() then
        refreshKeyList()
        sgoWindow:show()
        sgoWindow:raise()
        sgoWindow:focus()
    else
        sgoWindow:hide()
    end
end

UI.Separator()
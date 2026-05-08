----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
scriptFuncs = {};
comboSpellsWidget = {};
fugaSpellsWidgets = {};

scriptFuncs.readProfile = function(filePath, callback)
    if g_resources.fileExists(filePath) then
        local status, result = pcall(function()
            return json.decode(g_resources.readFileContents(filePath))
        end)
        if not status then
            return warn("Error: ".. result)
        end

        callback(result);
    end
end

scriptFuncs.saveProfile = function(configFile, content)
    local status, result = pcall(function()
        return json.encode(content, 2)
    end);

    if not status then
        return warn("Error:" .. result);
    end
    g_resources.writeFileContents(configFile, result);
end

storageProfiles = {
    comboSpells = {},
    fugaSpells = {},
    keySpells = {}
}

MAIN_DIRECTORY = "/bot/" .. modules.game_bot.contentsPanel.config:getCurrentOption().text .. "/storage/"
-- Storage por vocacao
local _cv = charClass or 'tobirama'
STORAGE_DIRECTORY = '' .. MAIN_DIRECTORY .. g_game.getWorldName() .. '_fuga_' .. _cv .. '.json';

if not g_resources.directoryExists(MAIN_DIRECTORY) then
    g_resources.makeDir(MAIN_DIRECTORY);
end

function resetCooldowns()
    if storageProfiles then
        if storageProfiles.comboSpells then
            for _, spell in ipairs(storageProfiles.comboSpells) do
                spell.cooldownSpells = nil
            end
        end
    end
end

scriptFuncs.readProfile(STORAGE_DIRECTORY, function(result)
    storageProfiles = result;
    if (type(storageProfiles.comboSpells) ~= 'table') then
        storageProfiles.comboSpells = {};
    end
    if (type(storageProfiles.fugaSpells) ~= 'table') then
        storageProfiles.fugaSpells = {};
    end
    if (type(storageProfiles.keySpells) ~= 'table') then
        storageProfiles.keySpells = {};
    end
    resetCooldowns();
end);

scriptFuncs.reindexTable = function(t)
    if not t or type(t) ~= "table" then
        return
    end

    local i = 0
    for _, e in pairs(t) do
        i = i + 1
        e.index = i
    end
end

firstLetterUpper = function(str)
    return (str:gsub("(%a)([%w_']*)", function(first, rest)
        return first:upper() .. rest:lower()
    end))
end

storage['iconScripts'] = storage['iconScripts'] or {
    comboMacro = false,
    fugaMacro = false,
    keyMacro = false
}

local isOn = storage['iconScripts'];

function removeTable(tbl, index)
    table.remove(tbl, index)
end

function canCastFuga()
    for key, value in ipairs(storageProfiles.fugaSpells) do
        if ((value.enableLifes and value.lifes > 0 and value.activeCooldown and value.activeCooldown >= os.time()) or
            (not value.enableLifes and value.activeCooldown and value.activeCooldown >= os.time())) then
            return true;
        end
    end
    return false;
end

function getPlayersAttack(multifloor)
    multifloor = multifloor or false;
    local count = 0;
    for _, spec in ipairs(getSpectators(multifloor)) do
        if spec:isPlayer() and spec:isTimedSquareVisible() and table.equals(spec:getTimedSquareColor(), colorToMatch) then
            count = count + 1;
        end
    end
    return count;
end

function calculatePercentage(var)
    local multiplier = getPlayersAttack(false);
    return multiplier and var + (multiplier * 7) or var
end

function stopToCast()
    if not fugaIcon.title:isOn() then
        return false;
    end
    for index, value in ipairs(storageProfiles.fugaSpells) do
        if value.enabled and value.activeCooldown and value.activeCooldown >= os.time() then
            return false;
        end
        if hppercent() <= calculatePercentage(value.selfHealth) + 3 then
            if (not value.totalCooldown or value.totalCooldown <= os.time()) then
                return true;
            end
        end
    end
    return false;
end

function isAnySelectedKeyPressed()
    for index, value in ipairs(storageProfiles.keySpells) do
        if value.enabled and (modules.corelib.g_keyboard.isKeyPressed(value.keyPress)) then
            return true;
        end
    end
    return false;
end

function formatTime(seconds)
    if seconds < 60 then
        return seconds .. 's'
    else
        local minutes = math.floor(seconds / 60)
        local remainingSeconds = seconds % 60
        return string.format("%dm %02ds", minutes, remainingSeconds)
    end
end

formatRemainingTime = function(time)
    local remainingTime = (time - now) / 1000;
    local timeText = '';
    timeText = string.format("%.0f", (time - now) / 1000) .. "s";
    return timeText;
end

formatOsTime = function(time)
    local remainingTime = (time - os.time());
    local timeText = '';
    timeText = string.format("%.0f", (time - os.time())) .. "s";
    return timeText;
end

attachSpellWidgetCallbacks = function(widget, spellId, table)
    widget.onDragEnter = function(self, mousePos)
        if not modules.corelib.g_keyboard.isCtrlPressed() then
            return false
        end
        self:breakAnchors()
        self.movingReference = {
            x = mousePos.x - self:getX(),
            y = mousePos.y - self:getY()
        }
        return true
    end

    widget.onDragMove = function(self, mousePos, moved)
        local parentRect = self:getParent():getRect()
        local newX = math.min(math.max(parentRect.x, mousePos.x - self.movingReference.x),
            parentRect.x + parentRect.width - self:getWidth())
        local newY = math.min(math.max(parentRect.y - self:getParent():getMarginTop(),
            mousePos.y - self.movingReference.y), parentRect.y + parentRect.height - self:getHeight())
        self:move(newX, newY)
        if table[spellId] then
            table[spellId].widgetPos = {
                x = newX,
                y = newY
            }
            scriptFuncs.saveProfile(STORAGE_DIRECTORY, storageProfiles)
        end
        return true
    end

    widget.onDragLeave = function(self, pos)
        return true
    end
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local spellEntry = [[
UIWidget
  background-color: alpha
  text-offset: 18 0
  focusable: true
  height: 16

  CheckBox
    id: enabled
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    width: 15
    height: 15
    margin-top: 2
    margin-left: 3

  $focus:
    background-color: #00000055

  CheckBox
    id: showTimespell
    anchors.left: enabled.left
    anchors.verticalCenter: parent.verticalCenter
    width: 15
    height: 15
    margin-top: 2
    margin-left: 15

  $focus:
    background-color: #00000055

  Label
    id: textToSet
    anchors.left: showTimespell.left
    anchors.verticalCenter: parent.verticalCenter
    margin-left: 20

  Button
    id: remove
    !text: tr('x')
    anchors.right: parent.right
    margin-right: 15
    width: 15
    height: 15
    tooltip: Remove Spell
]]

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

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------

fugaIcon = setupUI([[
Panel
  height: 20
  BotSwitch
    id: title
    anchors.top: parent.top
    anchors.left: parent.left
    text-align: center
    width: 130
    text: TimeSpell

  Button
    id: settings
    anchors.top: prev.top
    anchors.left: prev.right
    anchors.right: parent.right
    margin-left: 3
    height: 17
    text: Setup

]])

fugaInterface = setupUI([[
MainWindow
  text: TimeSpell Panel
  size: 550 340

  Panel
    image-source: /images/ui/panel_flat
    anchors.top: parent.top
    anchors.right: sep2.left
    anchors.left: parent.left
    anchors.bottom: separator.top
    margin: 5 5 5 5
    image-border: 6
    padding: 3
    size: 320 235

  Panel
    image-source: /images/ui/panel_flat
    anchors.top: parent.top
    anchors.left: sep2.left
    anchors.right: parent.right
    anchors.bottom: separator.top
    margin: 5 5 5 5
    image-border: 6
    padding: 3
    size: 320 235


  TextList
    id: spellList
    anchors.left: parent.left
    anchors.top: parent.top
    padding: 1
    size: 240 215
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
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    margin-bottom: 8
    margin-left: 11
    text: Move Up
    size: 60 17
    font: cipsoftFont

  Button
    id: moveDown
    anchors.bottom: parent.bottom
    anchors.left: moveUp.right
    margin-bottom: 8
    margin-left: 5
    text: Move Down
    size: 65 17
    font: cipsoftFont

  VerticalSeparator
    id: sep2
    anchors.top: parent.top
    anchors.bottom: closeButton.top
    anchors.horizontalCenter: parent.horizontalCenter
    margin-left: 3
    margin-bottom: 5

  HorizontalSeparator
    id: separator
    anchors.right: parent.right
    anchors.left: parent.left
    anchors.bottom: closeButton.top
    margin-bottom: 5

  Label
    id: castSpellLabel
    anchors.left: castSpell.right
    anchors.top: parent.top
    text: Cast Spell
    margin-top: 19
    margin-left: 15

  TextEdit
    id: castSpell
    anchors.left: spellList.right
    anchors.top: parent.top
    margin-left: 34
    margin-top: 15
    width: 100

  Label
    id: orangeSpellLabel
    anchors.left: orangeSpell.right
    anchors.top: parent.top
    text: Orange Spell
    margin-top: 49
    margin-left: 15

  TextEdit
    id: orangeSpell
    anchors.left: spellList.right
    anchors.top: parent.top
    margin-top: 45
    margin-left: 34
    width: 100

  CheckBox
    id: sameSpell
    anchors.left: orangeSpellLabel.right
    anchors.top: parent.top
    margin-top: 49
    margin-left: 8
    tooltip: Same Spell

  Label
    id: onScreenLabel
    anchors.left: orangeSpell.right
    anchors.top: parent.top
    text: On Screen
    margin-top: 79
    margin-left: 15

  TextEdit
    id: onScreen
    anchors.left: spellList.right
    anchors.top: parent.top
    margin-left: 34
    margin-top: 75
    width: 100

  CheckBox
    id: isTimeSpell
    anchors.left: spellList.right
    anchors.top: parent.top
    margin-top: 105
    margin-left: 20
    width: 14
    height: 14
    tooltip: Marcar como TimeSpell (sem HP%)

  HorizontalScrollBar
    id: hppercent
    anchors.left: isTimeSpell.right
    anchors.top: parent.top
    margin-top: 103
    margin-left: 5
    width: 100
    minimum: 0
    maximum: 100
    step: 1

  Label
    id: hppercentLabel
    anchors.left: hppercent.right
    anchors.top: parent.top
    margin-top: 105
    margin-left: 5
    text: Self Health

  HorizontalScrollBar
    id: cooldownTotal
    anchors.left: spellList.right
    anchors.top: parent.top
    margin-left: 20
    margin-top: 125
    width: 100
    minimum: 0
    maximum: 180
    step: 1

  Button
    id: findCD
    anchors.left: cooldownTotal.right
    anchors.top: parent.top
    margin-top: 125
    margin-left: 3
    tooltip: Auto-detectar CD
    text: !
    size: 17 17

  Label
    id: cooldownTotalLabel
    anchors.left: findCD.right
    anchors.top: parent.top
    margin-top: 127
    margin-left: 5
    text: Total Cooldown

  Label
    id: cdTotalStatus
    anchors.left: spellList.right
    anchors.top: parent.top
    margin-top: 143
    margin-left: 20
    text: CD: 0s
    font: cipsoftFont

  HorizontalScrollBar
    id: cooldownActive
    anchors.left: spellList.right
    anchors.top: parent.top
    margin-left: 20
    margin-top: 158
    width: 100
    minimum: 0
    maximum: 180
    step: 1

  Label
    id: cooldownActiveLabel
    anchors.left: cooldownActive.right
    anchors.top: parent.top
    margin-top: 160
    margin-left: 5
    text: Active Cooldown

  TextEdit
    id: outfitIdEdit
    anchors.left: spellList.right
    anchors.top: parent.top
    margin-top: 178
    margin-left: 20
    width: 55

  Button
    id: captureOutfit
    anchors.left: outfitIdEdit.right
    anchors.top: parent.top
    margin-top: 178
    margin-left: 3
    text: Capturar ID
    size: 70 17
    font: cipsoftFont

  Label
    id: outfitIdLabel
    anchors.left: captureOutfit.right
    anchors.top: parent.top
    margin-top: 180
    margin-left: 5
    text: Outfit ID
    font: cipsoftFont

  CheckBox
    id: activeByOutfit
    anchors.left: spellList.right
    anchors.top: parent.top
    margin-top: 200
    margin-left: 20
    width: 14
    height: 14
    tooltip: Active cooldown so comeca ao mudar outfit (ex: Magen Shinkarasu)

  Label
    id: activeByOutfitLabel
    anchors.left: activeByOutfit.right
    anchors.top: parent.top
    margin-top: 202
    margin-left: 5
    text: Active por outfit
    font: cipsoftFont

  CheckBox
    id: reviveOption
    anchors.top: parent.top
    anchors.left: spellList.right
    margin-top: 222
    margin-left: 20
    !text: tr('Revive')
    tooltip: Revive Fuga
    width: 60

  CheckBox
    id: lifesOption
    anchors.top: parent.top
    anchors.left: reviveOption.right
    margin-top: 222
    margin-left: 5
    tooltip: Lifes Fuga
    width: 45
    !text: tr('Lifes')

  SpinBox
    id: lifesValue
    anchors.top: parent.top
    anchors.left: lifesOption.right
    margin-top: 220
    margin-left: 3
    size: 27 20
    minimum: 0
    maximum: 10
    step: 1
    editable: true
    focusable: true

  CheckBox
    id: multipleOption
    anchors.top: parent.top
    anchors.left: spellList.right
    margin-top: 242
    margin-left: 20
    !text: tr('Multiple')
    tooltip: Multiple Scape
    width: 70

  Button
    id: insertSpell
    text: Insert Spell
    font: cipsoftFont
    anchors.right: parent.right
    anchors.bottom: closeButton.top
    size: 75 21
    margin-bottom: 5
    margin-right: 5

  Button
    id: closeButton
    !text: tr('Close')
    font: cipsoftFont
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    size: 60 21
    margin-bottom: 8
    margin-right: 5

]], g_ui.getRootWidget())
fugaInterface:hide();

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------

fugaIcon.title:setOn(isOn.fugaMacro);
fugaIcon.title.onClick = function(widget)
    isOn.fugaMacro = not isOn.fugaMacro;
    widget:setOn(isOn.fugaMacro);
    scriptFuncs.saveProfile(STORAGE_DIRECTORY, storageProfiles);
end

fugaIcon.settings.onClick = function(widget)
    if not fugaInterface:isVisible() then
        fugaInterface:show();
        fugaInterface:raise();
        fugaInterface:focus();
    else
        fugaInterface:hide();
        scriptFuncs.saveProfile(STORAGE_DIRECTORY, storageProfiles);
    end
end

fugaInterface.closeButton.onClick = function(widget)
    fugaInterface:hide();
    scriptFuncs.saveProfile(STORAGE_DIRECTORY, storageProfiles);
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

fugaInterface.hppercent:setText('0%')
fugaInterface.hppercent.onValueChange = function(widget, value)
    widget:setText(value .. '%')
end

-- TimeSpell checkbox — quando marcado desativa o slider de HP%
fugaInterface.isTimeSpell.onCheckChange = function(widget, checked)
    if checked then
        fugaInterface.hppercent:setValue(1)
        fugaInterface.hppercent:setEnabled(false)
        fugaInterface.hppercentLabel:setColor("#888888")
    else
        fugaInterface.hppercent:setEnabled(true)
        fugaInterface.hppercent:setValue(0)
        fugaInterface.hppercentLabel:setColor("#FFFFFF")
    end
end

-- Auto-detect CD (botao !)
local fugaDetectingCD = false
local fugaSpammingCD = false
local fugaFirstHitTime = nil
local fugaSpellDetecting = ""

fugaInterface.findCD.onClick = function()
    local spellName = fugaInterface.castSpell:getText():trim():lower()
    if spellName == "" then
        warn("Preencha o Cast Spell antes de detectar o CD.")
        return
    end
    fugaDetectingCD = true
    fugaSpammingCD = true
    fugaFirstHitTime = nil
    fugaSpellDetecting = spellName
    fugaInterface.cdTotalStatus:setText("Spammando...")
    fugaInterface.cdTotalStatus:setColor("#FFA500")
    fugaInterface.findCD:setText("...")
end

macro(100, function()
    if not fugaSpammingCD then return end
    say(fugaSpellDetecting)
end)

onTalk(function(name, level, mode, text)
    if not fugaDetectingCD then return end
    if name ~= player:getName() then return end
    if mode ~= 44 then return end
    if text:lower():trim() ~= fugaSpellDetecting then return end
    if not fugaFirstHitTime then
        fugaFirstHitTime = now
        fugaInterface.cdTotalStatus:setText("Aguardando 2a vez...")
        fugaInterface.cdTotalStatus:setColor("#FFFF00")
    else
        local detectedCD = math.floor((now - fugaFirstHitTime) / 1000)
        fugaInterface.cooldownTotal:setValue(math.min(detectedCD, 180))
        fugaInterface.cdTotalStatus:setText("CD: " .. detectedCD .. "s detectado!")
        fugaInterface.cdTotalStatus:setColor("#00FF00")
        fugaDetectingCD = false
        fugaSpammingCD = false
        fugaFirstHitTime = nil
        fugaSpellDetecting = ""
        fugaInterface.findCD:setText("!")
    end
end)

-- Capturar Outfit ID atual + iniciar medicao do active cooldown
local outfitCaptureTime = nil
local outfitCapturedType = nil

fugaInterface.captureOutfit.onClick = function()
    local spellName = fugaInterface.castSpell:getText():trim():lower()
    if spellName == "" then
        warn("Preencha o Cast Spell antes de capturar.")
        return
    end
    -- Usa o jutsu
    say(spellName)
    -- Aguarda um instante pra outfit mudar antes de capturar
    schedule(300, function()
        local lp = g_game.getLocalPlayer()
        if not lp then return end
        local outfitType = lp:getOutfit().type
        fugaInterface.outfitIdEdit:setText(tostring(outfitType))
        outfitCaptureTime = now
        outfitCapturedType = outfitType
        warn("Jutsu usado: " .. spellName .. " | Outfit ID: " .. tostring(outfitType) .. " | Medindo tempo...")
        fugaInterface.captureOutfit:setText("Medindo...")
        fugaInterface.captureOutfit:setColor("#FFA500")
    end)
end

fugaInterface.cooldownTotal:setText('0s')
fugaInterface.cooldownTotal.onValueChange = function(widget, value)
    local formattedTime = formatTime(value)
    widget:setText(value .. 's')
    -- widget:setText(formattedTime)
end

fugaInterface.cooldownActive:setText('0s')
fugaInterface.cooldownActive.onValueChange = function(widget, value)
    local formattedTime = formatTime(value)
    widget:setText(value .. 's')
    -- widget:setText(formattedTime)
end


fugaInterface.sameSpell:setChecked(true);
fugaInterface.orangeSpell:setEnabled(false);
fugaInterface.sameSpell.onCheckChange = function(widget, checked)
    if checked then
        fugaInterface.orangeSpell:setEnabled(false)
    else
        fugaInterface.orangeSpell:setEnabled(true)
        fugaInterface.orangeSpell:setText(fugaInterface.castSpell:getText())
    end
end

fugaInterface.lifesValue:hide();
fugaInterface.lifesOption.onCheckChange = function(self, checked)
    if checked then
        fugaInterface.multipleOption:hide();
        fugaInterface.lifesValue:show();
    else
        fugaInterface.multipleOption:show();
        fugaInterface.lifesValue:hide();
    end
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function refreshFugaList(list, table)
    if table then
        for i, child in pairs(list.spellList:getChildren()) do
            child:destroy();
        end
        for _, widget in pairs(fugaSpellsWidgets) do
            widget:destroy();
        end
        for index, entry in ipairs(table) do
            local label = setupUI(spellEntry, list.spellList)
            local newWidget = setupUI(widgetConfig, g_ui.getRootWidget())
            newWidget:setText(firstLetterUpper(entry.spellCast))
            attachSpellWidgetCallbacks(newWidget, entry.index, storageProfiles.fugaSpells)

            if not entry.widgetPos then
                entry.widgetPos = {
                    x = 0,
                    y = 50
                }
            end
            if entry.enableTimeSpell then
                newWidget:show();
            else
                newWidget:hide();
            end
            newWidget:setPosition(entry.widgetPos)
            fugaSpellsWidgets[entry.index] = newWidget;
            label.onDoubleClick = function(widget)
                local spellTable = entry;
                list.castSpell:setText(spellTable.spellCast);
                list.orangeSpell:setText(spellTable.orangeSpell);
                list.onScreen:setText(spellTable.onScreen);
                list.hppercent:setValue(spellTable.selfHealth);
                list.cooldownTotal:setValue(spellTable.cooldownTotal);
                list.cooldownActive:setValue(spellTable.cooldownActive);
                list.outfitIdEdit:setText(tostring(spellTable.outfitId or ""));
                list.activeByOutfit:setChecked(spellTable.activeByOutfit or false);
                list.isTimeSpell:setChecked(spellTable.isTimeSpell or false);
                if spellTable.isTimeSpell then
                    list.hppercent:setEnabled(false)
                    list.hppercentLabel:setColor("#888888")
                else
                    list.hppercent:setEnabled(true)
                    list.hppercentLabel:setColor("#FFFFFF")
                end
                -- Restaura lifes, revive e multiple
                list.reviveOption:setChecked(spellTable.enableRevive or false);
                if spellTable.enableLifes then
                    list.lifesOption:setChecked(true);
                    list.lifesValue:setValue(spellTable.amountLifes or 1);
                    list.multipleOption:hide();
                    list.lifesValue:show();
                else
                    list.lifesOption:setChecked(false);
                    list.lifesValue:hide();
                end
                if spellTable.enableMultiple then
                    list.multipleOption:setChecked(true);
                    list.multipleOption:show();
                else
                    list.multipleOption:setChecked(false);
                end
                for i, v in ipairs(storageProfiles.fugaSpells) do
                    if v == entry then
                        removeTable(storageProfiles.fugaSpells, i)
                    end
                end
                scriptFuncs.reindexTable(table);
                newWidget:destroy();
                label:destroy();
            end
            label.enabled:setChecked(entry.enabled);
            label.enabled:setTooltip(not entry.enabled and 'Enable Spell' or 'Disable Spell');
            label.enabled.onClick = function(widget)
                entry.enabled = not entry.enabled;
                label.enabled:setChecked(entry.enabled);
                label.enabled:setTooltip(not entry.enabled and 'Enable Spell' or 'Disable Spell');
                scriptFuncs.saveProfile(STORAGE_DIRECTORY, storageProfiles);
            end
            label.showTimespell:setChecked(entry.enableTimeSpell)
            label.showTimespell:setTooltip(not entry.enableTimeSpell and 'Enable Time Spell' or 'Disable Time Spell');
            label.showTimespell.onClick = function(widget)
                entry.enableTimeSpell = not entry.enableTimeSpell;
                label.showTimespell:setChecked(entry.enableTimeSpell);
                label.showTimespell:setTooltip(not entry.enableTimeSpell and 'Enable Time Spell' or 'Disable Time Spell');
                if entry.enableTimeSpell then
                    newWidget:show();
                else
                    newWidget:hide();
                end
                scriptFuncs.saveProfile(STORAGE_DIRECTORY, storageProfiles);
            end
            label.remove.onClick = function(widget)
                for i, v in ipairs(storageProfiles.fugaSpells) do
                    if v == entry then
                        removeTable(storageProfiles.fugaSpells, i)
                    end
                end
                scriptFuncs.reindexTable(table);
                newWidget:destroy();
                label:destroy();
            end
            label.onClick = function(widget)
                fugaInterface.moveDown:show();
                fugaInterface.moveUp:show();
            end
            label.textToSet:setText(firstLetterUpper(entry.spellCast));
            label:setTooltip('Orange Message: ' .. entry.orangeSpell .. ' | On Screen: ' .. entry.onScreen ..
                                 ' | Total Cooldown: ' .. entry.cooldownTotal .. 's | Active Cooldown: ' ..
                                 entry.cooldownActive .. 's | Hppercent: ' .. entry.selfHealth)
        end
    end
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

fugaInterface.moveUp.onClick = function()
    local action = fugaInterface.spellList:getFocusedChild();
    if (not action) then
        return;
    end
    local index = fugaInterface.spellList:getChildIndex(action);
    if (index < 2) then
        return;
    end
    fugaInterface.spellList:moveChildToIndex(action, index - 1);
    fugaInterface.spellList:ensureChildVisible(action);
    storageProfiles.fugaSpells[index].index = index - 1;
    storageProfiles.fugaSpells[index - 1].index = index;
    table.sort(storageProfiles.fugaSpells, function(a, b)
        return a.index < b.index
    end)
    scriptFuncs.saveProfile(STORAGE_DIRECTORY, storageProfiles);
end

fugaInterface.moveDown.onClick = function()
    local action = fugaInterface.spellList:getFocusedChild()
    if not action then
        return;
    end
    local index = fugaInterface.spellList:getChildIndex(action)
    if index >= fugaInterface.spellList:getChildCount() then
        return
    end
    fugaInterface.spellList:moveChildToIndex(action, index + 1);
    fugaInterface.spellList:ensureChildVisible(action);
    storageProfiles.fugaSpells[index].index = index + 1;
    storageProfiles.fugaSpells[index + 1].index = index;
    table.sort(storageProfiles.fugaSpells, function(a, b)
        return a.index < b.index
    end)
    scriptFuncs.saveProfile(STORAGE_DIRECTORY, storageProfiles);
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

fugaInterface.insertSpell.onClick = function(widget)
    local spellName = fugaInterface.castSpell:getText():trim():lower();
    local orangeMsg = fugaInterface.orangeSpell:getText():trim():lower();
    local onScreen = fugaInterface.onScreen:getText();
    orangeMsg = (orangeMsg:len() == 0) and spellName or orangeMsg;
    local hppercent = fugaInterface.hppercent:getValue();
    local cooldownTotal = fugaInterface.cooldownTotal:getValue();
    local cooldownActive = fugaInterface.cooldownActive:getValue();

    if spellName:len() == 0 then
        return warn('Invalid Spell Name.');
    end
    if not fugaInterface.sameSpell:isChecked() and orangeMsg:len() == 0 then
        return warn('Invalid Orange Spell.')
    end
    if onScreen:len() == 0 then
        return warn('Invalid Text On Screen')
    end
    if hppercent == 0 and not fugaInterface.isTimeSpell:isChecked() then
        return warn('Invalid Hppercent.')
    end
    if cooldownTotal == 0 then
        return warn('Invalid Cooldown Total.')
    end

    local spellConfig = {
        index = #storageProfiles.fugaSpells + 1,
        spellCast = spellName,
        orangeSpell = orangeMsg,
        onScreen = onScreen,
        selfHealth = hppercent,
        cooldownActive = cooldownActive,
        cooldownTotal = cooldownTotal,
        enableTimeSpell = true,
        isTimeSpell = fugaInterface.isTimeSpell:isChecked(),
        outfitId = tonumber(fugaInterface.outfitIdEdit:getText()) or 0,
        activeByOutfit = fugaInterface.activeByOutfit:isChecked(),
        enabled = true
    }

    if fugaInterface.lifesOption:isChecked() then
        spellConfig.lifes = 0;
        spellConfig.enableLifes = true;
        if fugaInterface.lifesValue:getValue() == 0 then
            return warn('Invalid Life Value.')
        end
        spellConfig.amountLifes = fugaInterface.lifesValue:getValue();
    end
    if fugaInterface.reviveOption:isChecked() then
        spellConfig.enableRevive = true;
        spellConfig.alreadyChecked = false;
    end
    if fugaInterface.multipleOption:isChecked() then
        spellConfig.enableMultiple = true;
        spellConfig.count = 3;
    end
    table.insert(storageProfiles.fugaSpells, spellConfig)
    refreshFugaList(fugaInterface, storageProfiles.fugaSpells)
    scriptFuncs.saveProfile(STORAGE_DIRECTORY, storageProfiles)

    fugaInterface.activeByOutfit:setChecked(false)
    fugaInterface.isTimeSpell:setChecked(false)
    fugaInterface.outfitIdEdit:clearText()
    fugaInterface.cdTotalStatus:setText("CD: 0s")
    fugaInterface.cdTotalStatus:setColor("#FFFFFF")
    fugaInterface.castSpell:clearText()
    fugaInterface.orangeSpell:clearText()
    fugaInterface.onScreen:clearText()
    fugaInterface.cooldownTotal:setValue(0)
    fugaInterface.cooldownActive:setValue(0)
    fugaInterface.hppercent:setValue(0)
    fugaInterface.reviveOption:setChecked(false);
    fugaInterface.lifesOption:setChecked(false);
    fugaInterface.multipleOption:setChecked(false);
    fugaInterface.multipleOption:show();
    fugaInterface.lifesValue:hide();
end

refreshFugaList(fugaInterface, storageProfiles.fugaSpells);

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

storage.widgetPos = storage.widgetPos or {};
informationWidget = {};

local widgetNames = {'showText'}

for i, widgetName in ipairs(widgetNames) do
    informationWidget[widgetName] = setupUI(widgetConfig, g_ui.getRootWidget())
end

local function attachSpellWidgetCallbacks(key)
    informationWidget[key].onDragEnter = function(widget, mousePos)
        if not modules.corelib.g_keyboard.isCtrlPressed() then
            return false
        end
        widget:breakAnchors()
        widget.movingReference = {
            x = mousePos.x - widget:getX(),
            y = mousePos.y - widget:getY()
        }
        return true
    end

    informationWidget[key].onDragMove = function(widget, mousePos, moved)
        local parentRect = widget:getParent():getRect()
        local x = math.min(math.max(parentRect.x, mousePos.x - widget.movingReference.x),
            parentRect.x + parentRect.width - widget:getWidth())
        local y = math.min(math.max(parentRect.y - widget:getParent():getMarginTop(),
            mousePos.y - widget.movingReference.y), parentRect.y + parentRect.height - widget:getHeight())
        widget:move(x, y)
        return true
    end

    informationWidget[key].onDragLeave = function(widget, pos)
        storage.widgetPos[key] = {}
        storage.widgetPos[key].x = widget:getX();
        storage.widgetPos[key].y = widget:getY();
        return true
    end
end

for key, value in pairs(informationWidget) do
    attachSpellWidgetCallbacks(key)
    informationWidget[key]:setPosition(storage.widgetPos[key] or {0, 50})
end

local toShow = informationWidget['showText'];

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
macro(10, function()
    if not (fugaSpellsWidgets and storageProfiles.fugaSpells) then
        return;
    end

    for index, spellConfig in ipairs(storageProfiles.fugaSpells) do
        local widget = fugaSpellsWidgets[spellConfig.index];
        if widget then
            local textToSet = firstLetterUpper(spellConfig.onScreen)
            local color = 'green'
            if spellConfig.activeCooldown and spellConfig.activeCooldown > os.time() then
                textToSet = textToSet .. ' | ' .. formatOsTime(spellConfig.activeCooldown)
                color = 'blue'
                if spellConfig.enableLifes and spellConfig.lifes == 0 then
                    spellConfig.activeCooldown = nil;
                end
            elseif spellConfig.totalCooldown and spellConfig.totalCooldown > os.time() then
                textToSet = textToSet .. ' | ' .. formatOsTime(spellConfig.totalCooldown)
                color = 'red'
            else
                textToSet = textToSet .. ' | OK!'
                if spellConfig.enableMultiple and spellConfig.canReset then
                    spellConfig.count = 3;
                    spellConfig.canReset = false;
                end
                if spellConfig.enableLifes then
                    spellConfig.lifes = 0;
                end
                if spellConfig.enableRevive then
                    spellConfig.alreadyChecked = false;
                end
            end
            if spellConfig.enableMultiple and spellConfig.count > 0 then
                textToSet = 'COUNT: ' .. spellConfig.count .. ' | ' .. textToSet
            end
            if spellConfig.enableLifes and spellConfig.lifes > 0 then
                textToSet = 'VIDAS: ' .. spellConfig.lifes .. ' | ' .. textToSet
            end
            widget:setText(textToSet)
            widget:setColor(color)
        end
    end
end);

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------

-- Monitora outfit pra detectar fim do active cooldown e medir tempo
local lastOutfitType = nil
macro(200, function()
    local lp = g_game.getLocalPlayer()
    if not lp then return end
    local currentOutfit = lp:getOutfit().type

    -- Medicao automatica do active cooldown via Capturar ID
    if outfitCaptureTime and outfitCapturedType then
        if currentOutfit ~= outfitCapturedType then
            local elapsed = math.floor((now - outfitCaptureTime) / 1000)
            fugaInterface.cooldownActive:setValue(math.min(elapsed, 180))
            warn("Active Cooldown detectado: " .. elapsed .. "s")
            fugaInterface.captureOutfit:setText("Capturar ID")
            fugaInterface.captureOutfit:setColor("#FFFFFF")
            outfitCaptureTime = nil
            outfitCapturedType = nil
        end
    end

    if lastOutfitType == nil then
        lastOutfitType = currentOutfit
        return
    end
    if currentOutfit ~= lastOutfitType then
        for _, spell in ipairs(storageProfiles.fugaSpells) do
            if spell.outfitId and spell.outfitId ~= 0 then
                if lastOutfitType == spell.outfitId then
                    -- Saiu do outfit especial — zera active cooldown
                    spell.activeCooldown = os.time()
                    warn("Saiu do outfit (" .. spell.spellCast .. ") - Active CD zerado")
                end
                if currentOutfit == spell.outfitId and spell.activeByOutfit then
                    -- Entrou no outfit especial - inicia active cooldown na tela
                    -- Preserva o totalCooldown que ja estava contando
                    spell.activeCooldown = os.time() + (spell.cooldownActive or 0)
                    spell._totalCooldownSaved = spell.totalCooldown
                    warn("Entrou no outfit (" .. spell.spellCast .. ") - Active CD: " .. tostring(spell.cooldownActive or 0) .. "s")
                end
            end
        end
        lastOutfitType = currentOutfit
    end
end)

-- macro fuga
-- Delay: 10ms — minimo possivel para reagir rapido a queda de HP
-- Logica: cada jutsu verifica seu proprio totalCooldown individualmente
-- Um jutsu "ativo" (activeCooldown) NAO bloqueia outros jutsus de disparar
local selfPlayer = g_game.getLocalPlayer();

macro(10, function()
    if not fugaIcon.title:isOn() then
        return;
    end
    if isInPz() then
        return;
    end
    local time = os.time();
    local selfHealth = selfPlayer:getHealthPercent();
    for key, value in ipairs(storageProfiles.fugaSpells) do
        if value.enabled and selfHealth <= calculatePercentage(value.selfHealth) then
            -- Verifica apenas o totalCooldown do proprio jutsu
            -- activeCooldown de outro jutsu nao bloqueia este
            if not value.totalCooldown or value.totalCooldown <= time then
                say(value.spellCast)
            end
        end
    end
end);

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------

onTalk(function(name, level, mode, text, channelId, pos)
    text = text:lower();
    if name ~= player:getName() then
        return;
    end
    for index, value in ipairs(storageProfiles.fugaSpells) do
        if text == value.orangeSpell then
            if value.enableLifes then
                value.activeCooldown = os.time() + (value.cooldownActive);
                value.totalCooldown = os.time() + (value.cooldownTotal);
                value.lifes = value.amountLifes;
                -- warn('1 IF: ' .. value.orangeSpell)
            end
            if value.enableRevive and not value.alreadyChecked then
                value.totalCooldown = os.time() + (value.cooldownTotal);
                -- activeCooldown NAO começa aqui — só ao morrer/reviver
                value.alreadyChecked = true;
                -- warn('2 IF: ' .. value.orangeSpell)
            end
            if value.enableMultiple then
                if value.count > 0 then
                    value.count = value.count - 1
                    value.activeCooldown = os.time() + (value.cooldownActive);
                    if value.count == 0 then
                        value.totalCooldown = os.time() + (value.cooldownTotal);
                        value.canReset = true;
                    end
                end
            end
            if not (value.enableLifes or value.enableRevive or value.enableMultiple) then
                if not value.activeByOutfit then
                    -- Se o totalCooldown já está contando, é um segundo disparo — ignora
                    if value.totalCooldown and value.totalCooldown > os.time() then
                        -- segundo disparo, ignora
                    else
                        value.activeCooldown = os.time() + (value.cooldownActive);
                        value.totalCooldown = os.time() + (value.cooldownTotal);
                    end
                else
                    if not value.totalCooldown or value.totalCooldown <= os.time() then
                        value.totalCooldown = os.time() + (value.cooldownTotal);
                    end
                end
            end
        end
    end
end);



----------------------------------------------------------------------------------------------------

onTextMessage(function(mode, text)
    local textLower = text:lower()
    for key, value in ipairs(storageProfiles.fugaSpells) do
        if value.enableLifes then
            if textLower:find('morreu e renasceu') and value.activeCooldown and value.activeCooldown >= os.time() then
                value.lifes = value.lifes - 1;
            end
        end
        if value.enableRevive and value.alreadyChecked then
            if textLower:find('morreu e renasceu') or textLower:find('you are dead') or textLower:find('voce morreu') then
                value.activeCooldown = os.time() + (value.cooldownActive);
                value.alreadyChecked = false;
            end
        end
    end
end);

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------

onPlayerPositionChange(function(newPos, oldPos)
    local izanagiPos = {
        x = 1214,
        y = 686,
        z = 6
    };
    for key, value in ipairs(storageProfiles.fugaSpells) do
        if value.enableRevive and value.spellCast == 'izanagi' then
            if newPos.x == izanagiPos.x and newPos.y == izanagiPos.y and newPos.z == izanagiPos.z then
                value.activeCooldown = nil;
                value.alreadyChecked = true;
            end
        end
    end
end);
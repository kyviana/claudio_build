-----------------------------
-- Claudio Bot - Alarme
-- Movido para aba Utility
-----------------------------
setDefaultTab("Utility")

local sep = UI.Separator()
sep:setHeight(1)
sep:setOpacity(0.05)

local panelName = "alarms"
local ui = setupUI([[
Panel
  height: 19
  BotSwitch
    id: title
    anchors.top: parent.top
    anchors.left: parent.left
    text-align: center
    width: 130
    !text: tr('Alarme')
  Button
    id: alerts
    anchors.top: prev.top
    anchors.left: prev.right
    anchors.right: parent.right
    margin-left: 3
    height: 17
    text: Edite
]])
ui:setId(panelName)

if not storage[panelName] then
    storage[panelName] = {
        enabled = false,
        privateMessage = false,
        playerpk = false,
        creatureDetected = false,
    }
end

local config = storage[panelName]

ui.title:setOn(config.enabled)
ui.title.onClick = function(widget)
    config.enabled = not config.enabled
    widget:setOn(config.enabled)
end

rootWidget = g_ui.getRootWidget()
if rootWidget then
    alarmsWindow = UI.createWindow('AlarmsWindow', rootWidget)
    alarmsWindow:hide()

    alarmsWindow.closeButton.onClick = function(widget)
        alarmsWindow:hide()
    end

    alarmsWindow.playerpk:setOn(config.playerpk)
    alarmsWindow.playerpk.onClick = function(widget)
        config.playerpk = not config.playerpk
        widget:setOn(config.playerpk)
    end

    alarmsWindow.creatureDetected:setOn(config.creatureDetected)
    alarmsWindow.creatureDetected.onClick = function(widget)
        config.creatureDetected = not config.creatureDetected
        widget:setOn(config.creatureDetected)
    end

    alarmsWindow.privateMessage:setOn(config.privateMessage)
    alarmsWindow.privateMessage.onClick = function(widget)
        config.privateMessage = not config.privateMessage
        widget:setOn(config.privateMessage)
    end

    onTalk(function(name, level, mode, text, channelId, pos)
        if config.enabled and config.privateMessage and mode == 4 then
            playSound("/sounds/Private_Message.ogg")
            g_window.setTitle("PM de: " .. name)
        end
    end)

    macro(100, function()
        if not config.enabled then return end
        local specs = getSpectators()

        if config.playerpk then
            for _, spec in ipairs(specs) do
                if spec:isPlayer() and spec:getSkull() ~= skull() then
                    local pos = spec:getPosition()
                    if math.max(math.abs(posx() - pos.x), math.abs(posy() - pos.y)) <= 8 then
                        playSound("/sounds/alarm.ogg")
                        delay(1500)
                        return
                    end
                end
            end
        end

        if config.creatureDetected then
            for _, spec in ipairs(specs) do
                if not spec:isPlayer() then
                    local pos = spec:getPosition()
                    if math.max(math.abs(posx() - pos.x), math.abs(posy() - pos.y)) <= 8 then
                        playSound("/sounds/Creature_Detected.ogg")
                        delay(1500)
                        return
                    end
                end
            end
        end
    end)
end

ui.alerts.onClick = function(widget)
    alarmsWindow:show()
    alarmsWindow:raise()
    alarmsWindow:focus()
end
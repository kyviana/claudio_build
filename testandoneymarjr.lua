local welcomePanel = setupUI([[
Panel
  id: welcomePanel
  anchors.centerIn: parent
  width: 300
  height: 180
  background-color: #0a0a0aee
  border: 1px solid #333333

  Label
    id: title
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    margin-top: 18
    text: Claudio Custom
    font: verdana-11px-rounded
    color: #ff4444

  Label
    id: subtitle
    anchors.top: title.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    margin-top: 6
    text: NTO Ultimate
    font: verdana-11px-rounded
    color: #aaaaaa

  Label
    id: version
    anchors.top: subtitle.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    margin-top: 14
    text: Bem vindo!
    font: verdana-11px-rounded
    color: #ffffff

  Button
    id: closeBtn
    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    margin-bottom: 14
    width: 100
    height: 20
    text: Entrar
]], g_ui.getRootWidget())

welcomePanel.closeBtn.onClick = function()
    welcomePanel:destroy()
end

-- fecha automaticamente apos 5 segundos
schedule(5000, function()
    if welcomePanel and not welcomePanel:isDestroyed() then
        welcomePanel:destroy()
    end
end)
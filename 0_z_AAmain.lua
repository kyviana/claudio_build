-----------------------------
-- Claudio Bot - Main Tab
-- NTO Ultimate
-----------------------------

-- Label com nome e classe
local charName = player:getName()

local uiLabel = setupUI([[
Panel
  height: 20
  Label
    id: charLabel
    color: #FFFFFF
    font: tahoma-bold-11px
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 20
    text-align: center
    text: ]] .. charName .. [[ [?]
]], parent)

-- Atualiza o label apos tudo carregar
schedule(500, function()
    local cl = charClass and (charClass:sub(1,1):upper() .. charClass:sub(2):lower()) or "?"
    if uiLabel and uiLabel.charLabel then
        uiLabel.charLabel:setText(charName .. " [" .. cl .. "]")
    end
end)

-- Cor pulsante: tons de preto ao branco
local pulse = { "#FFFFFF", "#CCCCCC", "#999999", "#CCCCCC" }
local pi = 1
macro(600, function()
    if not uiLabel or not uiLabel.charLabel then return end
    uiLabel.charLabel:setColor(pulse[pi])
    pi = pi + 1
    if pi > #pulse then pi = 1 end
end)

UI.Separator()

-- ==============================
-- BOTAO PAINEL
-- ==============================

local uiPainelBtn = setupUI([[
Panel
  height: 25
  Button
    id: openPainel
    font: verdana-11px-rounded
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 25
    text: - PAINEL -
    background-color: #111111
    border-width: 1
    border-color: #FFFFFF
    color: #FFFFFF
]], parent)

local painelPulse = { "#FFFFFF", "#BBBBBB", "#888888", "#BBBBBB" }
local painelPi = 1
macro(500, function()
    if not uiPainelBtn or not uiPainelBtn.openPainel then return end
    uiPainelBtn.openPainel:setColor(painelPulse[painelPi])
    painelPi = painelPi + 1
    if painelPi > #painelPulse then painelPi = 1 end
end)

uiPainelBtn.openPainel.onClick = function()
    if PainelsWindow then
        PainelsWindow:show()
        PainelsWindow:raise()
        PainelsWindow:focus()
    end
end

UI.Separator()

-- ==============================
-- CHANGELOG
-- ==============================

-- URL do Gist: use sempre o link /raw/ sem hash fixo (auto-atualiza)
-- Formato: https://gist.github.com/{user}/{id}/raw/{filename}
local CHANGELOG_URL = "https://gist.githubusercontent.com/kyviana/34361ac7ffe6938bcd790d38c9960b46/raw/gistfile1.txt"

local changelogWindow = setupUI([[
MainWindow
  text: Claudio Bot - Changelog
  size: 620 480
  TextList
    id: logList
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: logScroll.left
    anchors.bottom: separator.top
    margin: 8 0 8 8
    vertical-scrollbar: logScroll
  VerticalScrollBar
    id: logScroll
    anchors.top: logList.top
    anchors.bottom: logList.bottom
    anchors.right: parent.right
    margin-right: 8
    step: 14
    pixels-scroll: true
  HorizontalSeparator
    id: separator
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: closeBtn.top
    margin-bottom: 5
  CheckBox
    id: dontShow
    anchors.left: parent.left
    anchors.verticalCenter: closeBtn.verticalCenter
    margin-left: 8
    width: 14
    height: 14
  Label
    id: dontShowLabel
    text: Nao mostrar novamente
    anchors.left: dontShow.right
    anchors.verticalCenter: closeBtn.verticalCenter
    margin-left: 5
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
changelogWindow:hide()

-- Largura util da lista em caracteres (aprox. para cipsoftFont ~7px/char, janela 620px - margens)
local WRAP_CHARS = 85

-- Quebra texto longo em multiplas linhas preservando palavras
local function wrapText(text, maxChars)
    if #text <= maxChars then return { text } end
    local lines = {}
    local indent = text:match("^(%s+)") or ""  -- preserva indentacao inicial
    local remaining = text
    local first = true
    while #remaining > 0 do
        if #remaining <= maxChars then
            table.insert(lines, remaining)
            break
        end
        -- Encontra ultimo espaco antes do limite
        local cutAt = maxChars
        local lastSpace = remaining:sub(1, maxChars):match(".*()%s")
        if lastSpace and lastSpace > #indent + 5 then
            cutAt = lastSpace - 1
        end
        table.insert(lines, remaining:sub(1, cutAt))
        remaining = indent .. "  " .. remaining:sub(cutAt + 2)  -- indenta continuacao
        first = false
    end
    return lines
end

local function addChangelogLine(text, color)
    -- Linha vazia: spacer pequeno
    if text == "" then
        local spacer = g_ui.createWidget("Label", changelogWindow.logList)
        spacer:setText("")
        spacer:setHeight(5)
        return
    end
    -- Quebra linhas longas
    local wrapped = wrapText(text, WRAP_CHARS)
    for i, line in ipairs(wrapped) do
        local row = g_ui.createWidget("Label", changelogWindow.logList)
        row:setText(line)
        row:setColor(color or "#FFFFFF")
        row:setHeight(15)
    end
end

-- Limpa a lista e recarrega o changelog do Gist
local function loadChangelog()
    for _, child in pairs(changelogWindow.logList:getChildren()) do child:destroy() end
    addChangelogLine("Carregando changelog...", "#AAAAAA")

    -- Cache-buster: timestamp forca GitHub a servir versao fresca sempre
    local url = CHANGELOG_URL .. "?t=" .. os.time()

    HTTP.get(url, function(data, err)
        for _, child in pairs(changelogWindow.logList:getChildren()) do child:destroy() end

        if err then
            addChangelogLine("Erro de rede: " .. tostring(err), "#FF4444")
            warn("[Changelog] Erro HTTP: " .. tostring(err))
            return
        end

        if not data or type(data) ~= "string" or #data < 3 then
            addChangelogLine("Changelog vazio ou sem resposta.", "#FF8800")
            warn("[Changelog] data vazio ou invalido")
            return
        end

        -- Sanitizacao: remove BOM UTF-8, whitespace e normaliza quebras de linha
        local cleaned = data
            :gsub("^\xEF\xBB\xBF", "")
            :gsub("^%s+", "")
            :gsub("%s+$", "")
            :gsub("\r\n", "\n")

        warn("[Changelog] Carregado - " .. #cleaned .. " chars")

        -- Parser de texto puro linha a linha
        -- Secao atual determina a cor dos itens abaixo
        local currentSection = nil

        for line in (cleaned .. "\n"):gmatch("([^\n]*)\n") do
            local trimmed = line:gsub("^%s+", ""):gsub("%s+$", "")

            -- Linha vazia: separador entre secoes
            if trimmed == "" then
                addChangelogLine("", "#FFFFFF")

            -- Versao (ex: "v0.1.0" ou "v 0.1.0")
            elseif trimmed:match("^v%s*%d") then
                addChangelogLine("=== CLAUDIO BOT " .. trimmed:upper() .. " ===", "#FFD700")

            -- Cabecalho de secao
            elseif trimmed:upper():find("PRONTO") then
                currentSection = "pronto"
                addChangelogLine("[ PRONTO ]", "#00FF88")

            elseif trimmed:upper():find("REVISAO") or trimmed:upper():find("REVISÃO") then
                currentSection = "revisao"
                addChangelogLine("[ REVISAO ]", "#FFDD00")

            elseif trimmed:upper():find("PENDENTE") then
                currentSection = "pendente"
                addChangelogLine("[ PENDENTE ]", "#FF6666")

            -- Item normal: cor depende da secao atual
            else
                -- Remove prefixo # se existir
                local text = trimmed:gsub("^#%s*", "")
                local color = "#FFFFFF"
                if currentSection == "pronto"   then color = "#AAFFCC"
                elseif currentSection == "revisao"  then color = "#FFFFAA"
                elseif currentSection == "pendente" then color = "#FFAAAA"
                end
                addChangelogLine("  " .. text, color)
            end
        end
    end)
end

local function openChangelog()
    loadChangelog()
    changelogWindow:show()
    changelogWindow:raise()
    changelogWindow:focus()
end

changelogWindow.closeBtn.onClick = function()
    if changelogWindow.dontShow:isChecked() then
        storage.changelogDontShow = true
    end
    changelogWindow:hide()
end

-- Botao Changelog no Main
local uiChangelogBtn = setupUI([[
Panel
  height: 20
  Button
    id: openChangelog
    font: verdana-11px-rounded
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 20
    color: #AAAAAA
    background-color: #111111
    border-width: 1
    border-color: #555555
    text: Changelog
]], parent)

uiChangelogBtn.openChangelog.onClick = function()
    openChangelog()
end

-- Botao Nick/Voc abaixo do Changelog
local uiNickVocBtn = setupUI([[
Panel
  height: 20
  Button
    id: openNickVoc
    font: verdana-11px-rounded
    anchors.fill: parent
    height: 20
    color: #AAAAAA
    background-color: #111111
    border-width: 1
    border-color: #555555
    text: Nick / Voc
]], parent)

uiNickVocBtn.openNickVoc.onClick = function()
    if openCadastroWindow then
        openCadastroWindow()
    end
end

UI.Separator()

-- Abre automaticamente ao carregar se não marcou "não mostrar"
if not storage.changelogDontShow then
    schedule(2000, function()
        openChangelog()
    end)
end
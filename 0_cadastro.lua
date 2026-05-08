--------------------------------------------------------------------
-- 0_cadastro.lua
-- Sistema de cadastro de vocacoes e personagens
-- Claudio Bot - NTO Ultimate
--------------------------------------------------------------------

local _CADASTRO_DIR = "/bot/" .. modules.game_bot.contentsPanel.config:getCurrentOption().text .. "/storage/"
local CADASTRO_FILE = _CADASTRO_DIR .. "cadastro_vocacoes.json"

-- Jutsus globais ignorados no parser
local GLOBAIS = {
    "skip", "kai", "light", "throw kunai", "regeneration",
    "throw shuriken", "concentrate chakra feet", "jump up",
    "powerdown", "jump down", "chakra down", "sense",
    "bunshin no jutsu", "chakra rest", "big regeneration",
    "kawarimi no jutsu", "kekkei genkai", "atract no jutsu",
    "shunshin", "henge no jutsu", "clone no jutsu",
}

local function isGlobal(spell)
    spell = spell:lower():trim()
    for _, g in ipairs(GLOBAIS) do
        if spell == g then return true end
    end
    return false
end

-- Jutsus globais pre-populados no Manual Keys pra qualquer vocacao
local MANUAL_KEYS_GLOBAIS = {
    "kawarimi no jutsu",
    "kai",
    "concentrate chakra feet",
}

-- Carrega dados salvos
local cadastroData = { vocacoes = {} }
if g_resources.fileExists(CADASTRO_FILE) then
    local ok, result = pcall(function()
        return json.decode(g_resources.readFileContents(CADASTRO_FILE))
    end)
    if ok and result then
        cadastroData = result
        -- Garante que vocacoes existe mesmo em arquivos antigos
        if not cadastroData.vocacoes then
            cadastroData.vocacoes = {}
        end
    end
end

local function saveCadastro()
    pcall(function()
        g_resources.writeFileContents(CADASTRO_FILE, json.encode(cadastroData, 2))
    end)
end

-- Injeta vocacoes do cadastro no CHARS global
local function injectCadastroIntoChars()
    if not CHARS then return end
    for vocName, voc in pairs(cadastroData.vocacoes) do
        if not CHARS[vocName] then
            CHARS[vocName] = {
                names      = voc.names or {},
                buff       = voc.buff  or "",
                buff2      = voc.buff2 or "",
                buff3      = voc.buff3 or "",
                regen      = voc.regen or "big regeneration",
                burstOrder = {},
                fugaOrder  = {},
                actionbar  = {},
                jutsus     = voc.jutsus or {},
            }
        else
            -- Vocacao ja existe: apenas adiciona nomes novos
            local existing = CHARS[vocName]
            for _, name in ipairs(voc.names or {}) do
                local found = false
                for _, n in ipairs(existing.names) do
                    if n == name then found = true break end
                end
                if not found then
                    table.insert(existing.names, name)
                end
            end
        end
    end
end

-- Injeta apos todos os scripts carregarem (CHARS precisa existir)
schedule(500, function()
    injectCadastroIntoChars()
end)



local cadastroWindow = setupUI([[
MainWindow
  text: Gerenciar Vocacoes e Personagens
  size: 620 760

  TabBar
    id: tabBar
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    margin-top: 8
    margin-left: 8
    margin-right: 8
    height: 20

  Panel
    id: tabContent
    anchors.top: tabBar.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: closeBtn.top
    margin-top: 5
    margin-bottom: 8

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
cadastroWindow:hide()

local tabBar = cadastroWindow.tabBar
tabBar:setContentWidget(cadastroWindow.tabContent)

-- ============================================================
-- ABA 1: ADICIONAR NICKNAME EM VOCACAO EXISTENTE
-- ============================================================
local tabNick = g_ui.createWidget("sPanel")
tabBar:addTab("Add Personagem", tabNick)

UI.Label("Adicionar personagem em vocacao ja cadastrada:", tabNick):setColor("#AAAAAA")
UI.Separator(tabNick)

-- Dropdown de vocacoes
UI.Label("Vocacao:", tabNick)
local vocDropdown = setupUI([[
ComboBox
  height: 22
  margin-left: 5
  margin-right: 5
]], tabNick)

local function refreshVocDropdown()
    vocDropdown:clearOptions()
    -- Vocacoes do char_configs hardcoded
    if CHARS then
        for vName, _ in pairs(CHARS) do
            vocDropdown:addOption(vName)
        end
    end
    -- Vocacoes do cadastro
    for vName, _ in pairs(cadastroData.vocacoes) do
        if not CHARS or not CHARS[vName] then
            vocDropdown:addOption(vName .. " *")
        end
    end
end
refreshVocDropdown()

UI.Label("Nome do personagem:", tabNick)
local nickEdit = setupUI([[
TextEdit
  height: 22
  margin-left: 5
  margin-right: 5
]], tabNick)

UI.Separator(tabNick)

-- Lista de personagens cadastrados (definida antes do botao pra refreshNickList funcionar)
UI.Label("Personagens cadastrados:", tabNick):setColor("#AAAAAA")
local nickListPanel = setupUI([[
Panel
  height: 200
  margin-left: 5
  margin-right: 5
  TextList
    id: list
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    anchors.right: scroll.left
    vertical-scrollbar: scroll
  VerticalScrollBar
    id: scroll
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    step: 14
    pixels-scroll: true
]], tabNick)

local function refreshNickList()
    for _, c in pairs(nickListPanel.list:getChildren()) do c:destroy() end
    local all = {}
    if CHARS then
        for vName, cfg in pairs(CHARS) do
            for _, n in ipairs(cfg.names or {}) do
                table.insert(all, { name = n, voc = vName })
            end
        end
    end
    table.sort(all, function(a, b) return a.voc < b.voc end)
    for _, entry in ipairs(all) do
        local row = setupUI([[
UIWidget
  background-color: alpha
  focusable: true
  height: 18
  $focus:
    background-color: #00000055
]], nickListPanel.list)

        local lbl = setupUI([[
Label
  anchors.left: parent.left
  anchors.right: parent.right
  anchors.verticalCenter: parent.verticalCenter
  margin-left: 3
  margin-right: 20
  color: #CCCCCC
]], row)
        lbl:setText("[" .. entry.voc .. "]  " .. entry.name)

        local btnDel = setupUI([[
Button
  anchors.right: parent.right
  anchors.verticalCenter: parent.verticalCenter
  margin-right: 2
  width: 16
  height: 14
  text: x
  font: cipsoftFont
]], row)

        btnDel.onClick = function()
            -- Remove do CHARS em memoria
            if CHARS and CHARS[entry.voc] then
                for i, n in ipairs(CHARS[entry.voc].names) do
                    if n == entry.name then
                        table.remove(CHARS[entry.voc].names, i)
                        break
                    end
                end
            end
            -- Remove do cadastro JSON
            if cadastroData.vocacoes[entry.voc] then
                for i, n in ipairs(cadastroData.vocacoes[entry.voc].names or {}) do
                    if n == entry.name then
                        table.remove(cadastroData.vocacoes[entry.voc].names, i)
                        break
                    end
                end
            end
            saveCadastro()
            refreshNickList()
            warn("[Cadastro] Personagem '" .. entry.name .. "' removido de '" .. entry.voc .. "'")
        end
    end
end
refreshNickList()

UI.Button("Adicionar Personagem", function()
    local voc = vocDropdown:getCurrentOption().text:gsub(" %*$", "")
    local name = nickEdit:getText():trim()
    if name == "" then
        warn("[Cadastro] Nome vazio")
        return
    end

    -- Verifica se ja existe no CHARS
    if CHARS and CHARS[voc] then
        for _, n in ipairs(CHARS[voc].names) do
            if n == name then
                warn("[Cadastro] Personagem ja cadastrado em " .. voc)
                return
            end
        end
        table.insert(CHARS[voc].names, name)
    end

    -- Salva no cadastro JSON
    if not cadastroData.vocacoes[voc] then
        cadastroData.vocacoes[voc] = { names = {}, jutsus = {} }
    end
    if not cadastroData.vocacoes[voc].names then
        cadastroData.vocacoes[voc].names = {}
    end
    local found = false
    for _, n in ipairs(cadastroData.vocacoes[voc].names) do
        if n == name then found = true break end
    end
    if not found then
        table.insert(cadastroData.vocacoes[voc].names, name)
    end

    saveCadastro()
    injectCadastroIntoChars()
    nickEdit:clearText()
    refreshNickList()
    warn("[Cadastro] Personagem '" .. name .. "' adicionado em vocacao '" .. voc .. "'")
end, tabNick)

-- ============================================================
-- ABA 3: GERENCIAR VOCACOES (editar / excluir)
-- ============================================================
local tabEdit = g_ui.createWidget("sPanel")
tabBar:addTab("Vocacoes", tabEdit)

UI.Label("Selecione a vocacao:", tabEdit):setColor("#AAAAAA")
local editVocDropdown = setupUI([[
ComboBox
  font: verdana-11px-rounded
  height: 22
  margin-left: 5
  margin-right: 5
]], tabEdit)

local editBuff1 = nil
local editBuff2 = nil
local editBuff3 = nil
local editRegen = nil

local function refreshEditVocDropdown()
    editVocDropdown:clearOptions()
    -- Apenas vocacoes do cadastro (editaveis)
    for vName, _ in pairs(cadastroData.vocacoes) do
        editVocDropdown:addOption(vName)
    end
end
refreshEditVocDropdown()

UI.Separator(tabEdit)
UI.Label("Buffs:", tabEdit):setColor("#AAAAAA")

local editBuffPanel = setupUI([[
Panel
  height: 22
  margin-left: 5
  margin-right: 5
  TextEdit
    id: b1
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    width: 160
  Label
    anchors.left: b1.right
    anchors.verticalCenter: parent.verticalCenter
    margin-left: 3
    text: |
    font: cipsoftFont
  TextEdit
    id: b2
    anchors.top: parent.top
    anchors.left: b1.right
    anchors.bottom: parent.bottom
    width: 160
    margin-left: 8
  Label
    anchors.left: b2.right
    anchors.verticalCenter: parent.verticalCenter
    margin-left: 3
    text: |
    font: cipsoftFont
  TextEdit
    id: b3
    anchors.top: parent.top
    anchors.left: b2.right
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    margin-left: 8
]], tabEdit)

UI.Label("Regen spell:", tabEdit):setColor("#AAAAAA")
local editRegenEdit = setupUI([[
TextEdit
  height: 22
  margin-left: 5
  margin-right: 5
]], tabEdit)

-- Preenche campos ao mudar vocacao no dropdown
local function loadVocForEdit()
    local voc = editVocDropdown:getCurrentOption().text
    if not voc or voc == "" then return end
    local data = cadastroData.vocacoes[voc]
    if not data then
        -- Voc do char_configs hardcoded
        if CHARS and CHARS[voc] then
            editBuffPanel.b1:setText(CHARS[voc].buff  or "")
            editBuffPanel.b2:setText(CHARS[voc].buff2 or "")
            editBuffPanel.b3:setText(CHARS[voc].buff3 or "")
            editRegenEdit:setText(CHARS[voc].regen or "big regeneration")
        end
        return
    end
    editBuffPanel.b1:setText(data.buff  or "")
    editBuffPanel.b2:setText(data.buff2 or "")
    editBuffPanel.b3:setText(data.buff3 or "")
    editRegenEdit:setText(data.regen or "big regeneration")
end

editVocDropdown.onOptionChange = function() loadVocForEdit() end
schedule(200, loadVocForEdit)

UI.Separator(tabEdit)

-- Botao salvar edicao
UI.Button("Salvar Alteracoes", function()
    local voc = editVocDropdown:getCurrentOption().text
    if not voc or voc == "" then return end

    local b1 = editBuffPanel.b1:getText():trim()
    local b2 = editBuffPanel.b2:getText():trim()
    local b3 = editBuffPanel.b3:getText():trim()
    local regen = editRegenEdit:getText():trim()

    -- Atualiza cadastro JSON
    if not cadastroData.vocacoes[voc] then
        cadastroData.vocacoes[voc] = { names = {}, jutsus = {} }
    end
    cadastroData.vocacoes[voc].buff  = b1
    cadastroData.vocacoes[voc].buff2 = b2
    cadastroData.vocacoes[voc].buff3 = b3
    cadastroData.vocacoes[voc].regen = regen

    -- Atualiza CHARS em memoria
    if CHARS and CHARS[voc] then
        CHARS[voc].buff  = b1
        CHARS[voc].buff2 = b2
        CHARS[voc].buff3 = b3
        CHARS[voc].regen = regen
    end

    -- Atualiza storage global de buff se for a vocacao atual
    if charClass == voc then
        storage.buff  = b1
        storage.buff2 = b2
        storage.buff3 = b3
    end

    saveCadastro()
    warn("[Cadastro] Vocacao '" .. voc .. "' atualizada")
end, tabEdit)

UI.Separator(tabEdit)

-- Botao excluir vocacao
UI.Button("Excluir Vocacao", function()
    local voc = editVocDropdown:getCurrentOption().text
    if not voc or voc == "" then return end

    -- Remove do cadastro JSON
    cadastroData.vocacoes[voc] = nil
    saveCadastro()

    -- Remove do CHARS em memoria
    if CHARS then CHARS[voc] = nil end

    -- Limpa TimeSpell e Manual Keys em memoria se for vocacao atual
    if charClass == voc then
        if storageProfiles then
            storageProfiles.fugaSpells = {}
            if refreshFugaList and fugaInterface then
                refreshFugaList(fugaInterface, storageProfiles.fugaSpells)
            end
        end
        if storageKeys then
            storageKeys.keys = {}
            if refreshMKList then refreshMKList() end
        end
    end

    -- Atualiza todos os dropdowns
    refreshEditVocDropdown()
    refreshVocDropdown()
    refreshNickList()

    warn("[Cadastro] Vocacao '" .. voc .. "' removida")
end, tabEdit)

-- ============================================================
-- ABA 2: ADD VOCACAO
local tabVoc = g_ui.createWidget("sPanel")
tabBar:addTab("Add Vocacao", tabVoc)

UI.Label("Nome da vocacao (ex: tobirama, shisui):", tabVoc):setColor("#AAAAAA")
local vocNameEdit = setupUI([[
TextEdit
  height: 22
  margin-left: 5
  margin-right: 5
]], tabVoc)

UI.Label("Buffs (deixe vazio se nao houver):", tabVoc):setColor("#AAAAAA")
local buffPanel = setupUI([[
Panel
  height: 22
  margin-left: 5
  margin-right: 5
  TextEdit
    id: buff1
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    width: 160
  Label
    id: sep1
    anchors.left: buff1.right
    anchors.verticalCenter: parent.verticalCenter
    margin-left: 4
    text: |
    font: cipsoftFont
  TextEdit
    id: buff2
    anchors.top: parent.top
    anchors.left: sep1.right
    anchors.bottom: parent.bottom
    width: 160
    margin-left: 4
  Label
    id: sep2
    anchors.left: buff2.right
    anchors.verticalCenter: parent.verticalCenter
    margin-left: 4
    text: |
    font: cipsoftFont
  TextEdit
    id: buff3
    anchors.top: parent.top
    anchors.left: sep2.right
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    margin-left: 4
]], tabVoc)
buffPanel.buff2:setText("kekkei genkai")

UI.Label("Regen spell:", tabVoc):setColor("#AAAAAA")
local regenEdit = setupUI([[
TextEdit
  height: 22
  margin-left: 5
  margin-right: 5
]], tabVoc)
regenEdit:setText("big regeneration")

UI.Separator(tabVoc)
UI.Label("Cole o output do !jutsu abaixo:", tabVoc):setColor("#AAAAAA")

local jutsuEdit = setupUI([[
Panel
  height: 100
  margin-left: 5
  margin-right: 5
  TextEdit
    id: area
    anchors.fill: parent
    text-wrap: true
    shift-navigation: true
    multiline: true
    color: #222222
]], tabVoc)

UI.Button("Parsear Jutsus", function()
    local text = jutsuEdit.area:getText():trim()
    if text == "" then return end

    -- Reutiliza o parser do Combo PVE
    local parsed = {}
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
                    if not isGlobal(spell) then
                        local exists = false
                        for _, p in ipairs(parsed) do
                            if p.spell == spell then exists = true break end
                        end
                        if not exists then
                            table.insert(parsed, { spell = spell, level = currentLevel, tipo = "dano" })
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
                if level and spell and spell ~= "" and not isGlobal(spell:trim()) then
                    table.insert(parsed, { spell = spell:trim(), level = level, tipo = "dano" })
                end
            end
        end
    end

    -- Armazena temporariamente para a lista de selecao
    _parsedJutsus = parsed
    warn("[Cadastro] Parseados " .. #parsed .. " jutsus")

    -- Atualiza lista de selecao de categoria
    refreshJutsuList()
end, tabVoc)

-- Lista de jutsus com checkboxes de categoria
local jutsuListPanel = setupUI([[
Panel
  height: 340
  margin-left: 5
  margin-right: 5
  TextList
    id: list
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    anchors.right: jScroll.left
    vertical-scrollbar: jScroll
  VerticalScrollBar
    id: jScroll
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    step: 14
    pixels-scroll: true
]], tabVoc)

-- Row com checkboxes multiplas: Keys, Dano, Timer
local jutsuRowTpl = [[
UIWidget
  background-color: alpha
  focusable: true
  height: 18
  $focus:
    background-color: #00000055
]]

local function createJutsuRow(parent, entry)
    -- Garante campos de categorias no entry
    if entry.catKeys  == nil then entry.catKeys  = false end
    if entry.catDano  == nil then entry.catDano  = false end
    if entry.catTimer == nil then entry.catTimer = false end

    local row = setupUI(jutsuRowTpl, parent)

    -- Layout direita -> esquerda:
    -- [x=20] [Timer chk=14 lbl=36=50] [Dano chk=14 lbl=36=50] [Keys chk=14 lbl=36=50] = 170px
    -- Nome ocupa o restante ate margin-right: 174

    local btnX = setupUI([[
Button
  anchors.right: parent.right
  anchors.verticalCenter: parent.verticalCenter
  margin-right: 2
  width: 16
  height: 16
  font: cipsoftFont
  text: x
]], row)

    local chkTimer = setupUI([[
CheckBox
  anchors.right: parent.right
  anchors.verticalCenter: parent.verticalCenter
  margin-right: 22
  width: 14
  height: 14
]], row)
    setupUI([[
Label
  anchors.right: parent.right
  anchors.verticalCenter: parent.verticalCenter
  margin-right: 38
  width: 36
  color: #AAAAAA
  text: Timer
]], row)

    local chkDano = setupUI([[
CheckBox
  anchors.right: parent.right
  anchors.verticalCenter: parent.verticalCenter
  margin-right: 78
  width: 14
  height: 14
]], row)
    setupUI([[
Label
  anchors.right: parent.right
  anchors.verticalCenter: parent.verticalCenter
  margin-right: 94
  width: 32
  color: #AAAAAA
  text: Dano
]], row)

    local chkKeys = setupUI([[
CheckBox
  anchors.right: parent.right
  anchors.verticalCenter: parent.verticalCenter
  margin-right: 130
  width: 14
  height: 14
]], row)
    setupUI([[
Label
  anchors.right: parent.right
  anchors.verticalCenter: parent.verticalCenter
  margin-right: 146
  width: 32
  color: #AAAAAA
  text: Keys
]], row)

    -- Nome: ocupa da esquerda ate antes dos checkboxes
    local nameLabel = setupUI([[
Label
  anchors.left: parent.left
  anchors.right: parent.right
  anchors.verticalCenter: parent.verticalCenter
  margin-left: 3
  margin-right: 182
]], row)
    nameLabel:setText(entry.spell .. "  [lv" .. (entry.level or "?") .. "]")
    nameLabel:setColor("#FFFFFF")

    chkKeys:setChecked(entry.catKeys)
    chkDano:setChecked(entry.catDano)
    chkTimer:setChecked(entry.catTimer)

    chkKeys.onClick  = function() entry.catKeys  = not entry.catKeys  chkKeys:setChecked(entry.catKeys)   end
    chkDano.onClick  = function() entry.catDano  = not entry.catDano  chkDano:setChecked(entry.catDano)   end
    chkTimer.onClick = function() entry.catTimer = not entry.catTimer chkTimer:setChecked(entry.catTimer) end

    btnX.onClick = function()
        for j, e in ipairs(_parsedJutsus) do
            if e.spell == entry.spell then table.remove(_parsedJutsus, j) break end
        end
        refreshJutsuList()
    end

    return row
end

_parsedJutsus = _parsedJutsus or {}

function refreshJutsuList()
    for _, c in pairs(jutsuListPanel.list:getChildren()) do c:destroy() end
    for i, entry in ipairs(_parsedJutsus) do
        createJutsuRow(jutsuListPanel.list, entry)
    end
    if #_parsedJutsus == 0 then
        local empty = g_ui.createWidget("Label", jutsuListPanel.list)
        empty:setText("Nenhum jutsu parseado ainda")
        empty:setColor("#888888")
        empty:setHeight(18)
    end
end
refreshJutsuList()

local _btnSalvarVoc = UI.Button("Salvar Nova Vocacao", function()
    local vocName = vocNameEdit:getText():trim():lower()
    if vocName == "" then
        warn("[Cadastro] Nome da vocacao vazio")
        return
    end

    local buff1 = buffPanel.buff1:getText():trim()
    local buff2 = buffPanel.buff2:getText():trim()
    local buff3 = buffPanel.buff3:getText():trim()
    local regen = regenEdit:getText():trim()

    -- Monta dados da vocacao
    local vocData = {
        names  = {},
        buff   = buff1,
        buff2  = buff2,
        buff3  = buff3,
        regen  = regen ~= "" and regen or "big regeneration",
        jutsus = _parsedJutsus,
    }

    -- Salva no cadastro
    if not cadastroData.vocacoes[vocName] then
        cadastroData.vocacoes[vocName] = vocData
    else
        -- Atualiza campos mas preserva names
        cadastroData.vocacoes[vocName].buff   = buff1
        cadastroData.vocacoes[vocName].buff2  = buff2
        cadastroData.vocacoes[vocName].buff3  = buff3
        cadastroData.vocacoes[vocName].regen  = regen
        cadastroData.vocacoes[vocName].jutsus = _parsedJutsus
    end

    -- Injeta no CHARS em memoria
    injectCadastroIntoChars()

    -- Pre-popula Manual Keys com fugas + globais
    local MK_FILE = _CADASTRO_DIR .. g_game.getWorldName() .. "_manualkeys_" .. vocName .. ".json"
    local mkData = { keys = {}, enabled = false }

    -- Globais fixos sempre presentes no MK
    local globaisParaMK = { "kawarimi no jutsu", "kai", "concentrate chakra feet" }
    if buff1 ~= "" then table.insert(globaisParaMK, buff1) end

    for _, g in ipairs(globaisParaMK) do
        table.insert(mkData.keys, {
            input       = "",
            mode        = "say",
            sayText     = g,
            blockOnChat = true,
            enabled     = false,
        })
    end

    -- Jutsus marcados como Keys
    for _, jutsu in ipairs(_parsedJutsus) do
        if jutsu.catKeys then
            table.insert(mkData.keys, {
                input       = "",
                mode        = "say",
                sayText     = jutsu.spell,
                blockOnChat = true,
                enabled     = false,
            })
        end
    end

    -- Pre-popula TimeSpell com jutsus marcados como Timer
    local TS_FILE = _CADASTRO_DIR .. g_game.getWorldName() .. "_fuga_" .. vocName .. ".json"
    local tsData = { comboSpells = {}, fugaSpells = {}, keySpells = {} }
    -- Carrega existente se houver
    if g_resources.fileExists(TS_FILE) then
        local ok, existing = pcall(function()
            return json.decode(g_resources.readFileContents(TS_FILE))
        end)
        if ok and existing then tsData = existing end
        if type(tsData.fugaSpells) ~= "table" then tsData.fugaSpells = {} end
        if type(tsData.comboSpells) ~= "table" then tsData.comboSpells = {} end
        if type(tsData.keySpells) ~= "table" then tsData.keySpells = {} end
    end

    local tsIndex = #tsData.fugaSpells
    for _, jutsu in ipairs(_parsedJutsus) do
        if jutsu.catTimer then
            local found = false
            for _, s in ipairs(tsData.fugaSpells) do
                if s.spellCast == jutsu.spell then found = true break end
            end
            if not found then
                tsIndex = tsIndex + 1
                table.insert(tsData.fugaSpells, {
                    index          = tsIndex,
                    spellCast      = jutsu.spell,
                    orangeSpell    = "",
                    onScreen       = jutsu.spell,
                    selfHealth     = 100,
                    cooldownTotal  = 0,
                    cooldownActive = 0,
                    totalCooldown  = 0,
                    activeCooldown = 0,
                    outfitId       = 0,
                    enableTimeSpell = false,
                    enabled        = false,
                    widgetPos      = { x = 0, y = 0 },
                })
            end
        end
    end

    saveCadastro()
    g_resources.writeFileContents(MK_FILE, json.encode(mkData, 2))
    g_resources.writeFileContents(TS_FILE, json.encode(tsData, 2))
    warn("[Cadastro] MK: " .. #mkData.keys .. " keys | TS: " .. #tsData.fugaSpells .. " timers")

    -- Injeta em memoria sem precisar fechar o client
    -- Manual Keys
    if storageKeys and charClass == vocName then
        storageKeys.keys = mkData.keys
        if refreshMKList then refreshMKList() end
    end

    -- TimeSpell (storageProfiles do combo_system)
    if storageProfiles and charClass == vocName then
        storageProfiles.fugaSpells = tsData.fugaSpells
        -- Reindexa
        for i, s in ipairs(storageProfiles.fugaSpells) do
            s.index = i
        end
        -- Atualiza UI da lista do timespell
        if refreshFugaList and fugaInterface then
            refreshFugaList(fugaInterface, storageProfiles.fugaSpells)
        end
        -- Salva
        if scriptFuncs and scriptFuncs.saveProfile then
            scriptFuncs.saveProfile(STORAGE_DIRECTORY, storageProfiles)
        end
    end

    -- Reseta campos
    vocNameEdit:clearText()
    buffPanel.buff1:clearText()
    buffPanel.buff2:setText("kekkei genkai")
    buffPanel.buff3:clearText()
    regenEdit:setText("big regeneration")
    jutsuEdit.area:clearText()
    _parsedJutsus = {}
    refreshJutsuList()
    refreshVocDropdown()
    refreshEditVocDropdown()

    warn("[Cadastro] Vocacao '" .. vocName .. "' salva com " .. #vocData.jutsus .. " jutsus | MK pre-populado")
end, tabVoc)

-- ==============================
-- BOTAO NO MAIN
-- ==============================
cadastroWindow.closeBtn.onClick = function()
    cadastroWindow:hide()
end

-- Funcao global para abrir o gerenciador (chamada pelo botao no main)
function openCadastroWindow()
    if not cadastroWindow:isVisible() then
        refreshVocDropdown()
        refreshNickList()
        cadastroWindow:show()
        cadastroWindow:raise()
        cadastroWindow:focus()
    else
        cadastroWindow:hide()
    end
end
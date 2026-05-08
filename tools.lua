-----------------------------
-- Claudio Bot - Hotkeys Tab
-- NTO Ultimate
-----------------------------
setDefaultTab("Hotkeys")

-- ==============================
-- LABEL HOTKEYS [VOCACAO]
-- ==============================

local _charLabel = charClass and (charClass:sub(1,1):upper() .. charClass:sub(2):lower()) or "?"

setupUI([[
Panel
  height: 22
  Label
    color: #FFFFFF
    font: verdana-11px-rounded
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 22
    text-align: center
    text: ]] .. "HOTKEYS " .. _charLabel .. [[
]], parent)

UI.Separator()

-- ==============================
-- HOTKEYS ESPECIFICAS POR VOCACAO
-- ==============================

if charClass == "tobirama" then

    -- ID Kunai
    local kunaiPanel = setupUI([[
Panel
  height: 22
  Label
    id: kunaiLabel
    text: ID Kunai
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    text-align: center
  BotItem
    id: kunaiItem
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    margin-right: 4
]], parent)

    storage.kunaiId = storage.kunaiId or "11863"
    kunaiPanel.kunaiItem:setItemId(tonumber(storage.kunaiId) or 11863)
    kunaiPanel.kunaiItem.onItemChange = function(widget)
        storage.kunaiId = tostring(widget:getItemId())
    end

    -- Bug Map Kunai
    local bugMap = {}
    bugMap.directions = {
        ["W"] = {x = 0,  y = -5, direction = 0},
        ["E"] = {x = 3,  y = -3},
        ["D"] = {x = 5,  y = 0,  direction = 1},
        ["C"] = {x = 3,  y = 3},
        ["S"] = {x = 0,  y = 5,  direction = 2},
        ["Z"] = {x = -3, y = 3},
        ["A"] = {x = -5, y = 0,  direction = 3},
        ["Q"] = {x = -3, y = -3},
    }
    bugMap.isKeyPressed = modules.corelib.g_keyboard.isKeyPressed

    macro(100, "Bug Map Kunai", function()
        if modules.game_console:isChatEnabled() or modules.corelib.g_keyboard.isCtrlPressed() then return end
        local curPos = pos()
        for key, config in pairs(bugMap.directions) do
            if bugMap.isKeyPressed(key) then
                if config.direction then turn(config.direction) end
                local tile = g_map.getTile({x = curPos.x + config.x, y = curPos.y + config.y, z = curPos.z})
                if tile then
                    return useWith(tonumber(storage.kunaiId), tile:getTopUseThing())
                end
            end
        end
    end, parent)

    UI.Separator()

    -- Stack + Mundo (F1)
    local hiraCD = 0
    onTalk(function(name, level, mode, text)
        if name ~= player:getName() then return end
        if mode ~= 44 then return end
        if text:lower():trim() == "hiraishingiri" then
            hiraCD = now + 4103
        end
    end)

    local stackMundoMacro = macro(50, "Stack + Mundo [F1]", function()
        if not modules.corelib.g_keyboard.isKeyPressed("F1") then return end
        local target = g_game.getAttackingCreature()
        if not target then return end
        local targetPos = target:getPosition()
        if not targetPos then return end
        if not target:isPlayer() then return end

        local distance = getDistanceBetween(targetPos, pos())
        if distance > 0 then
            if now >= hiraCD then
                stopCombo = now + 200
                say("hiraishingiri")
            else
                local tile = g_map.getTile(targetPos)
                if tile then
                    useWith(tonumber(storage.kunaiId), tile:getTopUseThing())
                end
            end
        else
            stopCombo = now + 200
            say("kokuangyo no jutsu")
        end
    end)

    UI.Separator()

end -- tobirama

-- ==============================
-- STACK NO MOB (WASD)
-- Vocacoes: tobirama, minato, madara (configure abaixo)
-- ==============================
local STACK_MOB_CLASSES = { tobirama = true, minato = true, madara = true }

if STACK_MOB_CLASSES[charClass] then
    -- Configuracoes por vocacao
    local STACK_SPELLS = {
        tobirama = "hiraishingiri",
        minato   = "flash rasengan",
        madara   = "katon goukakyuu no jutsu",
        shisui   = "shunshin no shisui",
    }
    local stackSpell = STACK_SPELLS[charClass] or ""
    local stackKey   = "2"

    UI.Separator()

    local _stackLabel = setupUI([[
Panel
  height: 18
  Label
    anchors.fill: parent
    text-align: center
    color: #AAAAAA
    font: verdana-11px-rounded
    text: Stack Mob [WASD + ]] .. stackKey .. [[]
]], parent)

    local stackSpellEdit = UI.TextEdit(stackSpell, parent)
    stackSpellEdit.onTextChange = function(_, text)
        stackSpell = text:trim()
    end

    -- Stack: pega mob mais distante na direcao pressionada
    -- Cone de ±2 sqm no eixo perpendicular (igual elfbot)
    -- Sem limite de distancia maxima
    local function Stack(stackDir)
        local stackIn
        local furthest = 0
        local pPos = pos()
        local px, py = pPos.x, pPos.y

        for _, spec in ipairs(getSpectators()) do
            if spec:isMonster() then
                local sp = spec:getPosition()
                if sp then
                    local sx, sy = sp.x, sp.y
                    local dist = getDistanceBetween(sp, pPos)
                    local match = false
                    -- Verifica direcao + cone de ±2 sqm no eixo perpendicular
                    if stackDir == "n" and sy < py and math.abs(sx-px) <= 2 then match = true end
                    if stackDir == "s" and sy > py and math.abs(sx-px) <= 2 then match = true end
                    if stackDir == "w" and sx < px and math.abs(sy-py) <= 2 then match = true end
                    if stackDir == "e" and sx > px and math.abs(sy-py) <= 2 then match = true end
                    if match and dist > furthest then
                        furthest = dist
                        stackIn = spec
                    end
                end
            end
        end

        if not stackIn then return end
        g_game.attack(nil)
        g_game.attack(stackIn)
        if stackSpell ~= "" then
            say(stackSpell)
            schedule(50, function() g_game.attack(nil) end)
        end
    end

    macro(1, "Stack Mob", function()
        if modules.game_console:isChatEnabled() then return end
        if not modules.corelib.g_keyboard.isKeyPressed(stackKey) then return end
        local kb = modules.corelib.g_keyboard
        if kb.isKeyPressed("W") then Stack("n")
        elseif kb.isKeyPressed("S") then Stack("s")
        elseif kb.isKeyPressed("A") then Stack("w")
        elseif kb.isKeyPressed("D") then Stack("e")
        end
    end, parent)
end

-- ==============================
-- TURN + RETA
-- Vocacoes: tobirama, minato (configure abaixo)
-- ==============================
local TURN_RETA_CLASSES = { tobirama = true, shisui = true }

if TURN_RETA_CLASSES[charClass] then
    local RETA_SPELLS = {
        tobirama = "suiton suikodan no jutsu",
        shisui   = "katon kairyudan no jutsu",
    }
    local retaSpell = RETA_SPELLS[charClass] or ""
    local maxDist   = { x = 7, y = 7 }
    local minDist   = 1
    local _retaPressed = false

    UI.Separator()

    local _retaLabel = setupUI([[
Panel
  height: 18
  Label
    anchors.fill: parent
    text-align: center
    color: #AAAAAA
    font: verdana-11px-rounded
    text: Turn + Reta [` ]
]], parent)

    local retaSpellEdit = UI.TextEdit(retaSpell, parent)
    retaSpellEdit.onTextChange = function(_, text)
        retaSpell = text:trim()
    end

    -- Detecta tecla ` (backtick) que nao funciona com isKeyPressed por string
    onKeyDown(function(keyCode, keyText, modifiers)
        if modules.game_console:isChatEnabled() then return end
        if keyCode ~= "`" then return end
        _retaPressed = true
        schedule(100, function() _retaPressed = false end)
    end)

    macro(1, "Turn + Reta", function()
        if not _retaPressed then return end
        _retaPressed = false
        local target = g_game.getAttackingCreature()
        if not target then return end
        local targetPos = target:getPosition()
        if not targetPos then return end
        local pPos = pos()
        local tx, ty = targetPos.x, targetPos.y
        local px, py = pPos.x, pPos.y

        if math.abs(tx-px) > maxDist.x or math.abs(ty-py) > maxDist.y then return end

        local function turnToTarget()
            if px == tx then
                if ty > py then turn(2) else turn(0) end
            else
                if tx > px then turn(1) else turn(3) end
            end
        end

        local walked = false

        -- Condicoes exatas do elfbot: diferenca de 1 em cada eixo
        -- Eixo Y diferente por 1: alinha andando no eixo X
        if     ty > py and tx == px+1 then g_game.walk(1) walked = true
        elseif ty > py and tx == px-1 then g_game.walk(3) walked = true
        elseif ty < py and tx == px+1 then g_game.walk(1) walked = true
        elseif ty < py and tx == px-1 then g_game.walk(3) walked = true
        -- Eixo X diferente por 1: alinha andando no eixo Y
        elseif tx > px and ty == py+1 then g_game.walk(2) walked = true
        elseif tx > px and ty == py-1 then g_game.walk(0) walked = true
        elseif tx < px and ty == py+1 then g_game.walk(2) walked = true
        elseif tx < px and ty == py-1 then g_game.walk(0) walked = true
        end

        if walked then
            schedule(200, function()
                -- recalcula posicao apos o walk
                local newPos = pos()
                local npx, npy = newPos.x, newPos.y
                if npx == tx then
                    if ty > npy then turn(2) else turn(0) end
                else
                    if tx > npx then turn(1) else turn(3) end
                end
                schedule(50, function()
                    if retaSpell ~= "" then say(retaSpell) end
                end)
            end)
        elseif px == tx or py == ty then
            turnToTarget()
            if retaSpell ~= "" then say(retaSpell) end
        end
    end, parent)

    UI.Separator()
end

-- ==============================
-- AUTOFUGA SHISUI
-- ==============================

if charClass == "shisui" then

    -- Garante que fugaConfig e uma array ordenada (ipairs respeita indices numericos)
    local fugaConfig = {}
    for i, f in ipairs(CHARS.shisui.fugaOrder) do
        fugaConfig[i] = f
    end

    -- Estado de cooldowns em runtime (os.time = segundos)
    local fugaState = {}
    for _, f in ipairs(fugaConfig) do
        fugaState[f.spell] = { totalCD = 0, activeCD = 0 }
        --warn("[Autofuga] Registrado: " .. f.spell)
    end

    -- Timestamp do inicio do ciclo de fugas
    -- Reseta quando nenhuma fuga esta em CD (ciclo terminou)
    local _fugaCycleStart = 0
    local _CYCLE_MAX_CD   = 65 -- maior totalCD do shisui

    -- Helpers
    local CORVO_OUTFITS = { [863] = true, [864] = true }

    local function isActive(spell)
        local s = fugaState[spell]
        return s and s.activeCD > os.time()
    end

    local function isInTotalCD(spell)
        local s = fugaState[spell]
        return s and s.totalCD > os.time()
    end

    local function isInCorvo()
        local lp = g_game.getLocalPlayer()
        if not lp then return false end
        return CORVO_OUTFITS[lp:getOutfit().type] == true
    end

    -- Ciclo ativo = alguma fuga foi usada nos ultimos _CYCLE_MAX_CD segundos
    local function isCycleActive()
        return os.time() < (_fugaCycleStart + _CYCLE_MAX_CD)
    end

    local function canCast(entry)
        -- Proprio total CD ainda rodando
        if isInTotalCD(entry.spell) then return false end

        -- Corvo: nao dispara jutsu de corvo se ja esta em corvo
        local spellLower = entry.spell:lower()
        if spellLower == "magen shinkarasu" or spellLower == "sanzengarasu no jutsu" then
            if isInCorvo() then return false end
        end

        -- blockedBy: nao dispara se qualquer um estiver com activeCD rodando
        for _, b in ipairs(entry.blockedBy) do
            if isActive(b) then return false end
        end

        -- requiresActive: o jutsu ancora (kawarimi) deve ter sido usado no ciclo atual
        -- Aceita: ancora ativo, ancora em totalCD, ou ciclo ainda em andamento
        if #entry.requiresActive > 0 then
            local ok = false
            for _, r in ipairs(entry.requiresActive) do
                if isActive(r) or isInTotalCD(r) then
                    ok = true
                    break
                end
            end
            if not ok then
                ok = isCycleActive()
            end
            if not ok then return false end
        end

        return true
    end

    -- Painel: switch + campo HP numa linha so
    -- Switch
    local autoFugaPanel = setupUI([[
Panel
  height: 20
  BotSwitch
    id: title
    anchors.fill: parent
    text-align: center
    text: Autofuga
]], parent)

    autoFugaPanel.title:setOn(false)
    autoFugaPanel.title.onClick = function(widget)
        widget:setOn(not widget:isOn())
        if styleSwitch then styleSwitch(widget) end
    end
    if styleSwitch then styleSwitch(autoFugaPanel.title) end

    -- Threshold persistido em arquivo JSON
    local FUGA_HP_FILE = "/bot/" .. modules.game_bot.contentsPanel.config:getCurrentOption().text .. "/storage/autofuga_hp_shisui.json"
    local function loadFugaHP()
        if g_resources.fileExists(FUGA_HP_FILE) then
            local ok, val = pcall(function()
                return json.decode(g_resources.readFileContents(FUGA_HP_FILE))
            end)
            if ok and val and tonumber(val.hp) then return tonumber(val.hp) end
        end
        return 45
    end
    local function saveFugaHP(val)
        pcall(function()
            g_resources.writeFileContents(FUGA_HP_FILE, json.encode({ hp = val }, 2))
        end)
    end

    local _fugaHPThreshold = loadFugaHP()

    -- Campo HP numa linha separada usando UI nativo do bot
    local hpLabel = UI.Label("Ativar com HP <= " .. _fugaHPThreshold .. "%", parent)
    hpLabel:setColor("#AAAAAA")

    local hpEdit = UI.TextEdit(tostring(_fugaHPThreshold), parent)
    hpEdit.onTextChange = function(widget, text)
        local val = tonumber(text:trim())
        if val and val >= 1 and val <= 100 then
            _fugaHPThreshold = val
            hpLabel:setText("Ativar com HP <= " .. val .. "%")
            saveFugaHP(val)
        end
    end

    UI.Separator()

    -- onTalk: apenas seta activeCD quando servidor confirma o jutsu
    -- totalCD ja e setado pelo macro imediatamente ao disparar
    onTalk(function(name, level, mode, text)
        if name ~= player:getName() then return end
        if mode ~= 44 then return end
        local t = text:lower():trim()
        for _, entry in ipairs(fugaConfig) do
            if t == entry.spell:lower() then
                local s = fugaState[entry.spell]
                -- So seta activeCD se totalCD ja esta rodando (macro disparou)
                if s.totalCD > os.time() then
                    s.activeCD = os.time() + entry.activeCD
                    --warn("[Autofuga] Confirmado: " .. entry.spell .. " | activeCD: " .. entry.activeCD .. "s")
                end
                break
            end
        end
    end)

    -- Izanagi: active CD começa ao morrer/reviver
    onTextMessage(function(mode, text)
        local t = text:lower()
        if t:find("morreu e renasceu") or t:find("you are dead") or t:find("voce morreu") then
            for _, entry in ipairs(fugaConfig) do
                if entry.enableRevive then
                    local s = fugaState[entry.spell]
                    if s.totalCD > os.time() then
                        s.activeCD = os.time() + entry.activeCD
                        --warn("[Autofuga] Revive detectado - " .. entry.spell .. " active CD iniciado")
                    end
                end
            end
        end
    end)

    -- Macro principal: 10ms, dispara UMA fuga por vez com global CD
    local _globalFugaCD = 0
    local _lastDispatched = ""
    macro(10, function()
        if not autoFugaPanel.title:isOn() then return end
        if isInPz() then return end

        -- Global CD entre disparos (now = milissegundos)
        if now < _globalFugaCD then return end

        local hp = player:getHealthPercent()
        if hp > _fugaHPThreshold then return end

        -- Percorre em ordem de prioridade, dispara apenas o primeiro disponivel
        for _, entry in ipairs(fugaConfig) do
            if canCast(entry) then
                local t = os.time()
                local s = fugaState[entry.spell]
                -- totalCD imediato para bloquear re-disparo
                s.totalCD = t + entry.totalCD
                -- Inicia ciclo se nao estiver ativo
                if not isCycleActive() then
                    _fugaCycleStart = t
                    --warn("[Autofuga] Novo ciclo iniciado")
                end
                -- Global CD de 1s entre disparos para evitar double-fire
                _globalFugaCD = now + 1000
                _lastDispatched = entry.spell
                say(entry.spell)
                --warn("[Autofuga] >> " .. entry.spell .. " | HP: " .. hp .. "% | gCD ate: " .. _globalFugaCD)
                return
            end
        end
    end)



end -- shisui

-- ==============================
-- COMBO PVE
-- Switch + icone na tela + janela de setup
-- ==============================

local MAIN_DIR = "/bot/" .. modules.game_bot.contentsPanel.config:getCurrentOption().text .. "/storage/"
local PVE_FILE = MAIN_DIR .. g_game.getWorldName() .. "_pve_" .. (charClass or "unknown") .. ".json"

if not g_resources.directoryExists(MAIN_DIR) then g_resources.makeDir(MAIN_DIR) end

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

-- Macro CD tracker PVE

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

local addLabel = UI.Label("Copie todo o !jutsu com Ctrl + A e cola abaixo:", addPanel)
addLabel:setColor("#AAAAAA")

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

    -- Jutsus globais a ignorar
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

    -- Detecta formato: !jutsu (Jutsus para Level X / nome - : custo)
    -- ou formato simples: nome level
    local isJutsuFormat = text:find("Jutsus para Level") ~= nil

    if isJutsuFormat then
        local currentLevel = nil
        for line in text:gmatch("[^\n]+") do
            line = line:trim()
            -- Detecta linha de level
            local lvl = line:match("Jutsus para Level (%d+)")
            if lvl then
                currentLevel = tonumber(lvl)
            elseif currentLevel and line ~= "" then
                -- Extrai nome do jutsu (antes do " - :")
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
                            table.insert(storagePVE.spells, {
                                spell = spell,
                                level = currentLevel,
                                enabled = true,
                                cooldownUntil = 0
                            })
                            inserted = inserted + 1
                        else
                            skipped = skipped + 1
                        end
                    end
                end
            end
        end
    else
        -- Formato simples: jutsu level (uma por linha)
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
                            table.insert(storagePVE.spells, {
                                spell = spell,
                                level = level,
                                enabled = true,
                                cooldownUntil = 0
                            })
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
    refreshAddList()
    warn("Inseridos: " .. inserted .. " | Ja existiam: " .. skipped .. " | Ignorados (globais): " .. ignored)
end, addPanel)

UI.Separator(addPanel)

-- Botao importar jutsus de dano do cadastro da vocacao atual
UI.Button("Importar da Vocacao (" .. (charClass or "?") .. ")", function()
    -- Le o cadastro diretamente do arquivo JSON
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
                table.insert(storagePVE.spells, {
                    spell         = jutsu.spell,
                    level         = jutsu.level or 1,
                    enabled       = true,
                    cooldownUntil = 0,
                })
                inserted = inserted + 1
            else
                skipped = skipped + 1
            end
        end
    end

    savePVE()
    refreshComboList()
    warn("[ComboPVE] Importados: " .. inserted .. " | Ja existiam: " .. skipped)
end, addPanel)

UI.Separator(addPanel)

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

local function refreshAddList() end -- lista somente na aba Combo Atual

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

local function refreshComboList()
    for _, child in pairs(comboList:getChildren()) do child:destroy() end
    local playerLevel = player:getLevel()

    -- Filtra disponiveis pelo level atual
    local available = {}
    for _, entry in ipairs(storagePVE.spells) do
        if playerLevel >= entry.level then
            table.insert(available, entry)
        end
    end

    -- Auto-seleciona os 5 de maior level, desmarca o resto
    table.sort(available, function(a, b) return a.level > b.level end)
    for i, entry in ipairs(available) do
        entry.enabled = (i <= 5)
    end
    savePVE()

    -- Ordena por level crescente pra exibir
    table.sort(available, function(a, b) return a.level < b.level end)

    local count = 0
    for _, entry in ipairs(available) do
        local row = setupUI(spellEntry, comboList)
        row.spellLabel:setText(entry.spell .. "  [lv " .. entry.level .. "]")
        row.enabled:setChecked(entry.enabled)
        row.enabled.onClick = function()
            entry.enabled = not entry.enabled
            row.enabled:setChecked(entry.enabled)
            savePVE()
        end
        row.removeBtn.onClick = function()
            for i, s in ipairs(storagePVE.spells) do
                if s.spell == entry.spell then
                    table.remove(storagePVE.spells, i)
                    break
                end
            end
            savePVE()
            refreshComboList()
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
    refreshComboList()
end, comboPanel)

-- Painel principal na aba Hotkeys
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
        refreshAddList()
        refreshComboList()
        pveWindow:show()
        pveWindow:raise()
        pveWindow:focus()
    else
        pveWindow:hide()
    end
end

pveWindow.closeBtn.onClick = function() pveWindow:hide() end

-- Macro Combo PVE (dispara todos os jutsus marcados de uma vez)
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

refreshAddList()

UI.Separator()

UI.Button("Hotkeys/Macros/Scripts", function(newText)
    UI.MultilineEditorWindow(storage.ingame_hotkeys or "", {
        title = "Hotkeys editor",
        description = "Adicione suas scripts aqui!"
    }, function(text)
        storage.ingame_hotkeys = text
        reload()
    end)
end)

for _, scripts in pairs({storage.ingame_hotkeys}) do
    if type(scripts) == "string" and scripts:len() > 3 then
        local status, result = pcall(function()
            assert(load(scripts, "ingame_editor"))()
        end)
        if not status then
            error("Ingame editor error:\n" .. result)
        end
    end
end

UI.Separator()

-- ==============================
-- PAINEL e SCRIPTS WINDOW
-- Mantidos funcionais (sem botoes na aba)
-- Acessiveis via botoes no Main
-- ==============================

local PainelPanelName = "listt"
if not storage[PainelPanelName] then
    storage[PainelPanelName] = {}
end

rootWidget = g_ui.getRootWidget()
if rootWidget then
    PainelsWindow = UI.createWidget('PainelWindow', rootWidget)
    PainelsWindow:hide()
    local PTabBar = PainelsWindow.paTabBar
    PTabBar:setContentWidget(PainelsWindow.paImagem)
    for v = 1, 1 do

    hpPanel  = g_ui.createWidget("hpPanel")
    hpPanel2 = g_ui.createWidget("hpPanel")
    hpPanel3 = g_ui.createWidget("hpPanel")
    hpPanel4 = g_ui.createWidget("hpPanel")

    PTabBar:addTab("HP", hpPanel)
    cor = UI.Label("Regeneration:", hpPanel)
    cor:setColor("red")
    UI.Separator(hpPanel)

    if type(storage.heal) ~= "table" then
        storage.heal = {on=false, title="HP%", text="big regeneration", min=0, max=99}
    end
    if type(storage.heal2) ~= "table" then
        storage.heal2 = {on=false, title="HP%", text="regeneration", min=0, max=99}
    end
    for _, healingInfo in ipairs({storage.heal, storage.heal2}) do
        local healingmacro = macro(30, function()
            local hp = player:getHealthPercent()
            if healingInfo.max >= hp and hp >= healingInfo.min then
                if TargetBot then TargetBot.saySpell(healingInfo.text)
                else say(healingInfo.text) end
            end
        end, hpPanel)
        healingmacro.setOn(healingInfo.on)
        UI.DualScrollPanel(healingInfo, function(widget, newParams)
            healingInfo = newParams
            healingmacro.setOn(healingInfo.on)
        end, hpPanel)
    end

    PTabBar:addTab("Potion", hpPanel2)
    cor = UI.Label("Potions:", hpPanel2)
    cor:setColor("red")
    UI.Separator(hpPanel2)
    Panels.HealthItem(hpPanel2)
    UI.Separator(hpPanel2)
    Panels.HealthItem(hpPanel2)
    UI.Separator(hpPanel2)
    Panels.HealthItem(hpPanel2)
    UI.Separator(hpPanel2)
    Panels.ManaItem(hpPanel2)

    PTabBar:addTab("Haste", hpPanel3)
    cor = UI.Label("Pressa:", hpPanel3)
    cor:setColor("red")
    UI.Separator(hpPanel3)

    Panels.Haste(hpPanel3)
    UI.Separator(hpPanel3)
    Panels.AntiParalyze(hpPanel3)
    UI.Separator(hpPanel3)

    PTabBar:addTab("Buff", hpPanel4)
    cor = UI.Label("Buffs:", hpPanel4)
    cor:setColor("red")
    UI.Separator(hpPanel4)

    local _charClass = charClass or ""
    if _charClass ~= "" and CHARS and CHARS[_charClass] then
        local defaults = CHARS[_charClass]
        if not storage.buff  or storage.buff  == "" or storage.buff  == "buff"  then storage.buff  = defaults.buff  end
        if not storage.buff2 or storage.buff2 == "" or storage.buff2 == "buff 2" then storage.buff2 = defaults.buff2 end
        if not storage.buff3 or storage.buff3 == "" or storage.buff3 == "buff 3" then storage.buff3 = defaults.buff3 end
    end

    -- Sistema de buff por tempo fixo + detector de selo
    local BUFF_DURATION_KEY = "buffDuration_" .. (charClass or "unknown")
    local _buffDurations = { buff1 = 60, buff2 = 60 }
    if storage[BUFF_DURATION_KEY] and type(storage[BUFF_DURATION_KEY]) == "table" then
        _buffDurations = storage[BUFF_DURATION_KEY]
    end

    local function saveDurations()
        storage[BUFF_DURATION_KEY] = { buff1 = _buffDurations.buff1, buff2 = _buffDurations.buff2 }
    end

    _buffCD = 0
    _sealedUntil = 0

    local _buff1ExpiresAt = 0
    local _buff2ExpiresAt = 0
    local _lastML = player:getMagicLevel()

    -- Detecta queda brusca de ML (selo removeu o buff)
    -- Solta buff1 uma vez pra capturar o timestamp do selo
    macro(500, function()
        local ml = player:getMagicLevel()
        if ml < _lastML - 20 then
            local b1 = storage.buff or ""
            if b1 ~= "" then
                schedule(200, function() say(b1) end)
            end
        end
        _lastML = ml
    end)

    -- Detector de selos via onTextMessage mode=43
    -- Quando tenta soltar buff e está selado, servidor retorna a mensagem com tempo restante
    -- Captura o tempo e seta _buffCD pra tentar de novo só quando o selo acabar
    onTextMessage(function(mode, text)
        if mode ~= 43 then return end
        local segundos = text:match("[Ss]eu jutsu foi selado por (%d+) segundos")
        if not segundos then return end
        -- verificacao de skill removida: valor base ja é 25, nao serve como filtro
        local duracao = (tonumber(segundos) + 2) * 1000
        -- zera timers dos buffs pra forçar tentativa apos o selo acabar
        _buff1ExpiresAt = 0
        _buff2ExpiresAt = 0
        _buffCD = now + duracao
        _sealedUntil = now + duracao
    end)

    -- Detecta cast dos buffs via onTalk para iniciar o timer
    onTalk(function(name, level, mode, text)
        if name ~= player:getName() then return end
        local t = text:lower():trim()
        local b1 = (storage.buff  or ""):lower():trim()
        local b2 = (storage.buff2 or ""):lower():trim()
        local b2match = (t == "buff" or t == b2)

        if t == b1 and b1 ~= "" and _buffDurations.buff1 > 0 then
            _buff1ExpiresAt = now + (_buffDurations.buff1 * 1000)
        end
        if b2match and b2 ~= "" and _buffDurations.buff2 > 0 then
            _buff2ExpiresAt = now + (_buffDurations.buff2 * 1000)
        end
    end)

    buffs = macro(200, "Buff", function()
        if SGO and now < SGO then return end
        if isInPz() then return end
        if hasPartyBuff() then return end
        if now < _buffCD then return end

        local b1 = storage.buff  or ""
        local b2 = storage.buff2 or ""
        local b3 = storage.buff3 or ""
        local d1 = _buffDurations.buff1
        local d2 = _buffDurations.buff2

        if d1 == 0 and b1 ~= "" then return end  -- duracao nao configurada

        local buff1Ativo = (d1 > 0 and now < _buff1ExpiresAt)
        local buff2Ativo = (d2 > 0 and now < _buff2ExpiresAt)

        if not buff1Ativo and b1 ~= "" then
            _buffCD = now + 4000
            say(b1)
            if b2 ~= "" then schedule(2000, function() say(b2) end) end
            if b3 ~= "" then schedule(3500, function() say(b3) end) end
        elseif buff1Ativo and not buff2Ativo and b2 ~= "" and d2 > 0 then
            _buffCD = now + 4000
            say(b2)
            if b3 ~= "" then schedule(1500, function() say(b3) end) end
        end
    end, hpPanel4)

    UI.Button("Resetar timers de buff", function()
        _buff1ExpiresAt = 0
        _buff2ExpiresAt = 0
        _buffCD = 0
    end, hpPanel4)

    -- ==============================
    -- ==============================
    -- ICONE BUFF NA TELA DO JOGO
    -- ==============================
    local BOT_DIR = "/bot/" .. modules.game_bot.contentsPanel.config:getCurrentOption().text .. "/"
    local BUFF_ICON_OFF = BOT_DIR .. "buff_off.png"
    local BUFF_ICON_ON  = BOT_DIR .. "buff_on.png"
    local _buffIconOn = false

    local BUFF_ICON_POS_FILE = BOT_DIR .. "storage/buff_icon_pos.json"
    local _buffIconPos = {x=545, y=610}
    if g_resources.fileExists(BUFF_ICON_POS_FILE) then
        local ok, pos = pcall(function()
            return json.decode(g_resources.readFileContents(BUFF_ICON_POS_FILE))
        end)
        if ok and pos and pos.x and pos.y then _buffIconPos = pos end
    end

    local buffIconWidget = setupUI([[
UIWidget
  width: 80
  height: 32
  phantom: false
  focusable: true
  draggable: true
  visible: false
  background-color: alpha
]], g_ui.getRootWidget())
    buffIconWidget:setPosition({x=_buffIconPos.x, y=_buffIconPos.y})

    buffIconWidget.onDragEnter = function(widget, mousePos)
        if not modules.corelib.g_keyboard.isCtrlPressed() then return false end
        widget:breakAnchors()
        widget.movingReference = {x = mousePos.x - widget:getX(), y = mousePos.y - widget:getY()}
        return true
    end
    buffIconWidget.onDragMove = function(widget, mousePos)
        local x = mousePos.x - widget.movingReference.x
        local y = mousePos.y - widget.movingReference.y
        widget:move(x, y)
        return true
    end
    buffIconWidget.onDragLeave = function(widget)
        _buffIconPos = {x = widget:getX(), y = widget:getY()}
        pcall(function()
            g_resources.writeFileContents(BUFF_ICON_POS_FILE, json.encode(_buffIconPos, 2))
        end)
        return true
    end

    local function applyBuffIcon(on)
        local path = on and BUFF_ICON_ON or BUFF_ICON_OFF
        if g_resources.fileExists(path) then
            buffIconWidget:setImageSource(path)
        end
        buffIconWidget:show()
        _buffIconOn = on
    end

    schedule(500, function() applyBuffIcon(false) end)

    buffIconWidget.onClick = function()
        if not buffs then return end
        if buffs:isOn() then
            buffs:setOff()
        else
            buffs:setOn(true)
        end
        applyBuffIcon(buffs:isOn())
    end

    -- sync hardcoded, sem aparecer na lista de macros
    macro(1000, function()
        if not buffs then return end
        local on = buffs:isOn()
        if on ~= _buffIconOn then applyBuffIcon(on) end
    end)

    cor = UI.Label("Buff 1:", hpPanel4) cor:setColor("white")
    addTextEdit("buff", storage.buff or "", function(widget, text) storage.buff = text end, hpPanel4)
    cor = UI.Label("Duracao (s):", hpPanel4) cor:setColor("yellow")
    addTextEdit("buffDur1", tostring(_buffDurations.buff1), function(widget, text)
        local val = tonumber(text)
        if val then
            _buffDurations.buff1 = val
            saveDurations()
        end
    end, hpPanel4)

    cor = UI.Label("Buff 2:", hpPanel4) cor:setColor("white")
    addTextEdit("buff2", storage.buff2 or "", function(widget, text) storage.buff2 = text end, hpPanel4)
    cor = UI.Label("Duracao (s):", hpPanel4) cor:setColor("yellow")
    addTextEdit("buffDur2", tostring(_buffDurations.buff2), function(widget, text)
        local val = tonumber(text)
        if val then
            _buffDurations.buff2 = val
            saveDurations()
        end
    end, hpPanel4)

    cor = UI.Label("Buff 3:", hpPanel4) cor:setColor("white")
    addTextEdit("buff3", storage.buff3 or "", function(widget, text) storage.buff3 = text end, hpPanel4)

    end
end

PainelsWindow.closeButton.onClick = function(widget) PainelsWindow:hide() end
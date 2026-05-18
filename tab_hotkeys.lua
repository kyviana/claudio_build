-- tab_hotkeys.lua — Aba Hotkeys
-- Claudio Bot | NTO Ultimate

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
-- SISTEMA DE HOTKEYS CONFIGURAVEL
-- ==============================

-- Catalogo: todas as hotkeys disponíveis no bot
-- Qualquer vocação pode habilitar qualquer hotkey pela janela
-- exceto as marcadas com shisui_only, que só aparecem para shisui
local HK_CATALOG = {}
local _hkCatalogFull = {
    { key = "kunai_id",     label = "Kunai Item (seletor)" },
    { key = "bugmap_kunai", label = "Bug Map Kunai (dash)" },
    { key = "stack_mundo",  label = "Stack + Mundo [F1]",
      spells = { tobirama="hiraishingiri", shisui="shunshin no shisui" } },
    { key = "stack_mob",    label = "Stack Mob [WASD+2]",
      spells = { tobirama="hiraishingiri", minato="flash rasengan", madara="katon goukakyuu no jutsu", shisui="shunshin no shisui" } },
    { key = "turn_reta",    label = "Turn + Reta [` ]",
      spells = { tobirama="suiton suikodan no jutsu", shisui="katon kairyudan no jutsu" } },
    { key = "autofuga",     label = "Autofuga", shisui_only = true },
    { key = "saikan",       label = "Cura Area (Saikan)" },
    { key = "heal_party",   label = "Cura Single Target (Party)" },
}
for _, hk in ipairs(_hkCatalogFull) do
    if not hk.shisui_only or charClass == "shisui" then
        table.insert(HK_CATALOG, hk)
    end
end

-- Persistencia das hotkeys em arquivo JSON (sobrevive ao fechar o client)
local _HK_DIR  = "/bot/" .. modules.game_bot.contentsPanel.config:getCurrentOption().text .. "/storage/"
local _HK_FILE = _HK_DIR .. "hotkeys_cfg_" .. (charClass or "unknown") .. ".json"

if not g_resources.directoryExists(_HK_DIR) then g_resources.makeDir(_HK_DIR) end

local _hkCfg = {}
if g_resources.fileExists(_HK_FILE) then
    local ok, result = pcall(function()
        return json.decode(g_resources.readFileContents(_HK_FILE))
    end)
    if ok and result then _hkCfg = result end
end

local function hkSaveCfg()
    pcall(function()
        g_resources.writeFileContents(_HK_FILE, json.encode(_hkCfg, 2))
    end)
end

-- Helper: checa se hotkey está habilitada para vocacao atual
local function hkEnabled(key)
    return _hkCfg[key] == true
end

-- Helper: spell configurada (usa storage se editado, senão default do catalogo)
local function hkSpell(key)
    local spellKey = "hkspell_" .. key .. "_" .. (charClass or "unknown")
    if storage[spellKey] and storage[spellKey] ~= "" then
        return storage[spellKey]
    end
    for _, hk in ipairs(HK_CATALOG) do
        if hk.key == key and hk.spells then
            return hk.spells[charClass] or ""
        end
    end
    return ""
end

-- Janela de configuracao — mostra TODAS as hotkeys, independente da vocacao
local _hkWin = nil
do
    local winH = 60 + #HK_CATALOG * 26 + 40
    local uiStr = [[
MainWindow
  id: hkConfigWin
  text: Hotkeys - ]] .. (charClass or "?") .. [[

  size: 240 ]] .. winH .. [[

  visible: false
  Label
    id: hkTitle
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 22
    text-align: center
    color: #00ff99
    font: verdana-11px-rounded
    text: Selecione as hotkeys ativas:
]]

    for i, hk in ipairs(HK_CATALOG) do
        local topAnchor = i == 1 and "hkTitle.bottom" or ("hkCheck" .. (i-1) .. ".bottom")
        local isOn = _hkCfg[hk.key] and "true" or "false"
        uiStr = uiStr .. [[
  CheckBox
    id: hkCheck]] .. i .. [[

    anchors.top: ]] .. topAnchor .. [[

    anchors.left: parent.left
    anchors.right: parent.right
    margin-left: 8
    margin-top: 4
    height: 22
    text: ]] .. hk.label .. [[

    checked: ]] .. isOn .. [[

]]
    end

    local lastId = "hkCheck" .. #HK_CATALOG
    uiStr = uiStr .. [[
  Button
    id: hkSaveBtn
    anchors.top: ]] .. lastId .. [[.bottom
    anchors.left: parent.left
    margin-top: 8
    margin-left: 6
    width: 150
    height: 22
    text: Salvar e Recarregar
  Button
    id: hkCloseBtn
    anchors.top: ]] .. lastId .. [[.bottom
    anchors.right: parent.right
    margin-top: 8
    margin-right: 6
    width: 60
    height: 22
    text: Fechar
]]

    _hkWin = setupUI(uiStr, g_ui.getRootWidget())

    _hkWin:getChildById("hkSaveBtn").onClick = function()
        local newCfg = {}
        for i, hk in ipairs(HK_CATALOG) do
            local cb = _hkWin:getChildById("hkCheck" .. i)
            newCfg[hk.key] = cb and cb:isChecked() or false
        end
        _hkCfg = newCfg
        hkSaveCfg()
        _hkWin:hide()
        reload()
    end

    _hkWin:getChildById("hkCloseBtn").onClick = function()
        _hkWin:hide()
    end
end

-- Botao no painel do bot — só abre a janela
UI.Button("Configurar Hotkeys", function()
    if _hkWin then
        _hkWin:show()
        _hkWin:raise()
        _hkWin:focus()
    end
end)

UI.Separator()

-- ==============================
-- HOTKEYS ESPECIFICAS POR VOCACAO
-- ==============================

if hkEnabled("kunai_id") or hkEnabled("bugmap_kunai") or hkEnabled("stack_mundo") then

    -- ID Kunai
    if hkEnabled("kunai_id") then
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
    end -- kunai_id

    -- Bug Map Kunai
    if hkEnabled("bugmap_kunai") then
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

    local _kunaiCD = 0

    onTextMessage(function(mode, text)
        if mode == 28 and text:find("lose 4500 chakra") then
            _kunaiCD = now + 5000
        end
    end)

    macro(100, "Bug Map Kunai", function()
        if modules.game_console:isChatEnabled() or modules.corelib.g_keyboard.isCtrlPressed() then return end
        if now < _kunaiCD then return end
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
    end -- bugmap_kunai

    UI.Separator()

    -- Stack + Mundo (F1)
    if hkEnabled("stack_mundo") then
    local _stackSpell = hkSpell("stack_mundo")  -- ex: hiraishingiri / shunshin no shisui
    local _mundoSpell = hkSpell("stack_mundo_mundo") ~= "" and hkSpell("stack_mundo_mundo") or (
        charClass == "shisui" and "kotoamatsukami" or "kokuangyo no jutsu"
    )
    local stackCD = 0

    onTalk(function(name, level, mode, text)
        if name ~= player:getName() then return end
        if mode ~= 44 then return end
        local t = text:lower():trim()
        if t == _stackSpell:lower() then
            stackCD = now + 4103
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
            if now >= stackCD then
                stopCombo = now + 200
                say(_stackSpell)
            else
                local tile = g_map.getTile(targetPos)
                if tile then
                    useWith(tonumber(storage.kunaiId), tile:getTopUseThing())
                end
            end
        else
            stopCombo = now + 200
            say(_mundoSpell)
        end
    end)

    UI.Separator()
    end -- stack_mundo

end -- bloco kunai/bugmap/stack_mundo

-- ==============================
-- STACK NO MOB (WASD)
-- Vocacoes: tobirama, minato, madara (configure abaixo)
-- ==============================
if hkEnabled("stack_mob") then
    local stackSpell = hkSpell("stack_mob")
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
        storage["hkspell_stack_mob_" .. (charClass or "unknown")] = stackSpell
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
if hkEnabled("turn_reta") then
    local retaSpell = hkSpell("turn_reta")
    local maxDist   = { x = 7, y = 7 }
    local minDist   = 1
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
        storage["hkspell_turn_reta_" .. (charClass or "unknown")] = retaSpell
    end

    -- Detecta tecla ` (backtick) que nao funciona com isKeyPressed por string
    macro(50, "Turn + Reta", function()
        if modules.game_console:isChatEnabled() then return end
        if not modules.corelib.g_keyboard.isKeyPressed("`") then return end
        if SGO and now < SGO then return end
        SGO = now + 300  -- pausa o combo enquanto reta ativa
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

        -- Já está na reta: solta o jutsu imediatamente sem virar ou andar
        if px == tx or py == ty then
            turnToTarget()
            if retaSpell ~= "" then say(retaSpell) end
            return
        end

        -- Não está na reta: tenta alinhar andando 1 sqm
        local walked = false
        if     ty > py and tx == px+1 then g_game.walk(1) walked = true
        elseif ty > py and tx == px-1 then g_game.walk(3) walked = true
        elseif ty < py and tx == px+1 then g_game.walk(1) walked = true
        elseif ty < py and tx == px-1 then g_game.walk(3) walked = true
        elseif tx > px and ty == py+1 then g_game.walk(2) walked = true
        elseif tx > px and ty == py-1 then g_game.walk(0) walked = true
        elseif tx < px and ty == py+1 then g_game.walk(2) walked = true
        elseif tx < px and ty == py-1 then g_game.walk(0) walked = true
        end

        if walked then
            schedule(200, function()
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
        end
    end, parent)

    UI.Separator()
end

-- ==============================
-- AUTOFUGA SHISUI
-- ==============================

if hkEnabled("autofuga") then

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

-- ==============================
-- SAIKAN: cura em area, sempre dispara
-- ==============================
if hkEnabled("saikan") then
    local _saikanSpell = "saikan chuushutsu no jutsu"
    local _saikanCfgFile = "/bot/" .. modules.game_bot.contentsPanel.config:getCurrentOption().text .. "/storage/saikan_cfg_" .. (charClass or "unknown") .. ".json"
    local _saikanCfg = { hp = 90 }
    if g_resources.fileExists(_saikanCfgFile) then
        local ok, r = pcall(function() return json.decode(g_resources.readFileContents(_saikanCfgFile)) end)
        if ok and r then _saikanCfg = r end
    end
    local function saveSaikanCfg()
        pcall(function() g_resources.writeFileContents(_saikanCfgFile, json.encode(_saikanCfg, 2)) end)
    end

    local _saikanCD = 0

    onTextMessage(function(mode, text)
        if text:find("Aguarde (%d+) segundo") then
            local secs = tonumber(text:match("Aguarde (%d+) segundo"))
            if secs then _saikanCD = now + (secs + 1) * 1000 end
        end
    end)

    UI.Separator()
    local saikanMacro
    saikanMacro = macro(90, "Cura Area (Saikan)", function()
        if saikanMacro:isOff() then return end
        if SGO and now < SGO then return end
        if now < _saikanCD then return end
        say(_saikanSpell)
    end, parent)
    UI.Separator()
end

-- ==============================
-- HEAL PARTY: single target, percorre players visiveis
-- ==============================
if hkEnabled("heal_party") then
    local _healCfgFile = "/bot/" .. modules.game_bot.contentsPanel.config:getCurrentOption().text .. "/storage/heal_party_cfg_" .. (charClass or "unknown") .. ".json"

    local _daiHp     = 95
    local _chiyuteHp = 85
    local _daiCD     = 0
    local _chiyuteCD = 0
    local _lastHealSpell = ""

    -- Carrega config salva
    if g_resources.fileExists(_healCfgFile) then
        local ok, r = pcall(function() return json.decode(g_resources.readFileContents(_healCfgFile)) end)
        if ok and r then
            _daiHp     = tonumber(r.daiHp)     or 95
            _chiyuteHp = tonumber(r.chiyuteHp) or 85
        end
    end

    local function saveHealCfg()
        pcall(function()
            g_resources.writeFileContents(_healCfgFile, json.encode({ daiHp=_daiHp, chiyuteHp=_chiyuteHp }, 2))
        end)
    end

    -- Captura qual jutsu foi usado pelo onTalk mode 44
    onTalk(function(name, level, mode, text)
        if name ~= player:getName() then return end
        if mode ~= 44 then return end
        local t = text:lower()
        if t:find("dai chiyute") then _lastHealSpell = "dai"
        elseif t:find("chiyute") then _lastHealSpell = "chiyute" end
    end)

    -- Captura cooldown via onTextMessage
    onTextMessage(function(mode, text)
        if not text:find("Aguarde") then return end
        local secs = tonumber(text:match("Aguarde (%d+) segundo"))
        if not secs then return end
        local cd = now + (secs + 1) * 1000
        if _lastHealSpell == "dai" then _daiCD = cd
        elseif _lastHealSpell == "chiyute" then _chiyuteCD = cd end
    end)

    local healPartyMacro
    healPartyMacro = macro(50, "Cura Single (Party)", function()
        if healPartyMacro:isOff() then return end
        if SGO and now < SGO then return end

        local specs = getSpectators()
        local targets = {}
        for _, spec in ipairs(specs) do
            if spec:isPlayer() and spec ~= player then
                local hp = spec:getHealthPercent()
                if type(hp) == "number" then
                    table.insert(targets, { creature=spec, hp=hp })
                end
            end
        end

        table.sort(targets, function(a, b) return a.hp < b.hp end)

        for _, t in ipairs(targets) do
            local name = t.creature:getName()
            if t.hp <= _daiHp and now >= _daiCD then
                _lastHealSpell = "dai"
                say('dai chiyute no Jutsu "' .. name)
                return
            elseif t.hp <= _chiyuteHp and now >= _chiyuteCD then
                _lastHealSpell = "chiyute"
                say('Chiyute no Jutsu "' .. name)
                return
            end
        end
    end, parent)

    UI.Label("Dai Chiyute HP% <=:")
    addTextEdit("daiHp", tostring(_daiHp), function(_, text)
        local v = tonumber(text)
        if v then _daiHp = v saveHealCfg() end
    end)
    UI.Label("Chiyute HP% <=:")
    addTextEdit("chiyuteHp", tostring(_chiyuteHp), function(_, text)
        local v = tonumber(text)
        if v then _chiyuteHp = v saveHealCfg() end
    end)

    UI.Separator()
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
            -- Não usa big regeneration enquanto estiver em modo bijuu
            if inBijuuOutfit and inBijuuOutfit() then return end
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

    local hpPanel5 = g_ui.createWidget("hpPanel")
    PTabBar:addTab("Summon", hpPanel5)

    -- Config da vocacao — lê do cadastro_vocacoes.json
    local _summonCfg = (CHARS[charClass] and CHARS[charClass].summon) or { spell = "", name = "", qtd = 1, usePlayerName = false }
    local _cadPath = "/bot/" .. modules.game_bot.contentsPanel.config:getCurrentOption().text .. "/storage/cadastro_vocacoes.json"
    if g_resources.fileExists(_cadPath) then
        local ok, data = pcall(function() return json.decode(g_resources.readFileContents(_cadPath)) end)
        if ok and data and data.vocacoes and data.vocacoes[charClass] and data.vocacoes[charClass].summon then
            _summonCfg = data.vocacoes[charClass].summon
        end
    end

    cor = UI.Label("Jutsu:", hpPanel5) cor:setColor("white")
    addTextEdit("summonSpell", _summonCfg.spell or "", function(_, text)
        _summonCfg.spell = text
    end, hpPanel5)

    cor = UI.Label("Nome da invocacao:", hpPanel5) cor:setColor("white")
    addTextEdit("summonName", _summonCfg.name or "", function(_, text)
        _summonCfg.name = text
    end, hpPanel5)

    local _usePlayerName = _summonCfg.usePlayerName or false

    local _chkRow = setupUI([[
Panel
  height: 20
]], hpPanel5)
    local _chkBox = setupUI([[
CheckBox
  anchors.left: parent.left
  anchors.verticalCenter: parent.verticalCenter
  margin-left: 4
  width: 14
  height: 14
]], _chkRow)
    setupUI([[
Label
  anchors.left: parent.left
  anchors.verticalCenter: parent.verticalCenter
  margin-left: 22
  color: #AAAAAA
  text: Usa nick do personagem
]], _chkRow)

    _chkBox:setChecked(_usePlayerName)
    _chkBox.onClick = function()
        _usePlayerName = not _usePlayerName
        _summonCfg.usePlayerName = _usePlayerName
        _chkBox:setChecked(_usePlayerName)
    end

    cor = UI.Label("Quantidade:", hpPanel5) cor:setColor("white")
    addTextEdit("summonQtd", tostring(_summonCfg.qtd or 1), function(_, text)
        local val = tonumber(text)
        if val then _summonCfg.qtd = val end
    end, hpPanel5)

    local _cadastroPath = "/bot/" .. modules.game_bot.contentsPanel.config:getCurrentOption().text .. "/storage/cadastro_vocacoes.json"

    UI.Button("Salvar na vocacao", function()
        _summonCfg.usePlayerName = _usePlayerName
        if CHARS[charClass] then CHARS[charClass].summon = _summonCfg end
        -- Salva no cadastro_vocacoes.json
        if g_resources.fileExists(_cadastroPath) then
            local ok, data = pcall(function() return json.decode(g_resources.readFileContents(_cadastroPath)) end)
            if ok and data and data.vocacoes then
                if not data.vocacoes[charClass] then data.vocacoes[charClass] = {} end
                data.vocacoes[charClass].summon = _summonCfg
                g_resources.writeFileContents(_cadastroPath, json.encode(data, 2))
                warn("[Summon] Salvo no cadastro_vocacoes.json para: " .. charClass)
            end
        end
    end, hpPanel5)

    summons = macro(1000, "Summon", function()
        if summons.isOff() then return end
        if not _summonCfg.spell or _summonCfg.spell == "" then return end

        local petName = _summonCfg.usePlayerName and player:getName() or (_summonCfg.name or "")
        if petName == "" then return end

        local count = 0
        local pPos  = player:getPosition()

        for _, spec in ipairs(getSpectators()) do
            if spec:isCreature() and spec ~= player then
                if spec:getName():lower() == petName:lower() then
                    local sp = spec:getPosition()
                    if math.abs(pPos.z - sp.z) > 3 then
                        say("kai") return
                    end
                    count = count + 1
                end
            end
        end
        if count < (_summonCfg.qtd or 1) then
            say(_summonCfg.spell)
        end
    end, hpPanel5)
    cor = UI.Label("Buffs:", hpPanel4)
    cor:setColor("red")
    UI.Separator(hpPanel4)

    local _buffKey1 = "buff_"  .. (charClass or "unknown")
    local _buffKey2 = "buff2_" .. (charClass or "unknown")
    local _buffKey3 = "buff3_" .. (charClass or "unknown")

    local _charClass = charClass or ""
    if _charClass ~= "" and CHARS and CHARS[_charClass] then
        local defaults = CHARS[_charClass]
        if not storage[_buffKey1] or storage[_buffKey1] == "" or storage[_buffKey1] == "buff"  then storage[_buffKey1] = defaults.buff  end
        if not storage[_buffKey2] or storage[_buffKey2] == "" or storage[_buffKey2] == "buff 2" then storage[_buffKey2] = defaults.buff2 end
        if not storage[_buffKey3] or storage[_buffKey3] == "" or storage[_buffKey3] == "buff 3" then storage[_buffKey3] = defaults.buff3 end
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
        if ml < _lastML - 20 and not isInPz() then
            local b1 = storage[_buffKey1] or ""
            if b1 ~= "" then
                schedule(200, function() say(b1) end)
            end
        end
        _lastML = ml
        -- na PZ reseta tudo pra sair ja buffado
        if isInPz() then
            _buff1ExpiresAt = 0
            _buff2ExpiresAt = 0
            _buffCD = 0
            _sealedUntil = 0
        end
    end)

    -- Estado de confirmação de cada buff — declarado antes dos callbacks
    local _buff1Confirmed = false
    local _buff2Confirmed = false
    local _buff3Confirmed = false
    local _buffRetryCD = 0

    -- Detector de selos e confirmação de buffs via onTextMessage
    onTextMessage(function(mode, text)
        local t = text:lower()

        -- Selo: bloqueia buff por X segundos
        if mode == 43 then
            local segundos = text:match("[Ss]eu jutsu foi selado por (%d+) segundos")
            if segundos then
                local duracao = (tonumber(segundos) + 2) * 1000
                _buff1ExpiresAt = 0
                _buff2ExpiresAt = 0
                _buffCD = now + duracao
                _sealedUntil = now + duracao
            end
            return
        end

        -- "Este buff já está ativo" mode 46 — confirma buff pendente
        if t:find("este buff j") or t:find("buff j.*ativo") or t:find("already active") then
            local b1 = (storage[_buffKey1] or ""):lower():trim()
            local b2 = (storage[_buffKey2] or ""):lower():trim()
            local b3 = (storage[_buffKey3] or ""):lower():trim()
            -- Confirma o último buff tentado baseado em qual estava pendente
            if b1 ~= "" and not _buff1Confirmed then
                _buff1Confirmed = true
                _buff1ExpiresAt = now + (_buffDurations.buff1 * 1000)
            elseif b2 ~= "" and not _buff2Confirmed then
                _buff2Confirmed = true
                _buff2ExpiresAt = now + (_buffDurations.buff2 * 1000)
            elseif b3 ~= "" and not _buff3Confirmed then
                _buff3Confirmed = true
            end
        end
    end)

    -- Detecta confirmação de cada buff via onTalk mode 44
    onTalk(function(name, level, mode, text)
        if name ~= player:getName() then return end
        if mode ~= 44 then return end
        local t = text:lower():trim()
        local b1 = (storage[_buffKey1] or ""):lower():trim()
        local b2 = (storage[_buffKey2] or ""):lower():trim()
        local b3 = (storage[_buffKey3] or ""):lower():trim()
        -- Usa find pra não depender de pontuação extra do servidor
        if b1 ~= "" and t:find(b1, 1, true) then
            _buff1Confirmed = true
            _buff1ExpiresAt = now + (_buffDurations.buff1 * 1000)
        end
        if b2 ~= "" and t:find(b2, 1, true) then
            _buff2Confirmed = true
            _buff2ExpiresAt = now + (_buffDurations.buff2 * 1000)
        end
        if b3 ~= "" and t:find(b3, 1, true) then
            _buff3Confirmed = true
        end
    end)

    buffs = macro(200, "Buff", function()
        if buffs:isOff() then return end
        -- SGO pausa apenas a renovação, não o retry de buffs pendentes
        if isInPz() then return end
        if now < _buffCD then return end
        if now < _buffRetryCD then return end

        local b1 = storage[_buffKey1] or ""
        local b2 = storage[_buffKey2] or ""
        local b3 = storage[_buffKey3] or ""

        if b1 == "" then return end

        local b1Ativo = _buff1Confirmed and now < _buff1ExpiresAt
        local b2Ativo = _buff2Confirmed and now < _buff2ExpiresAt
        local b2needed = b2 ~= "" and _buffDurations.buff2 > 0
        local b3needed = b3 ~= ""

        -- Se nenhum buff ativo, inicia ciclo completo
        if not b1Ativo then
            if SGO and now < SGO then return end  -- pausa renovação durante SGO
            _buff1Confirmed = false
            _buff2Confirmed = false
            _buff3Confirmed = false
            _buffCD = now + 8000
            say(b1)
            return
        end

        -- Buff1 ativo — verifica se buff2 precisa ser usado
        if b2needed and not b2Ativo then
            _buff2Confirmed = false
            _buffRetryCD = now + 3000
            say(b2)
            return
        end

        -- Buff2 ativo — verifica buff3 se necessário
        if b3needed and not _buff3Confirmed then
            _buff3Confirmed = false
            _buffRetryCD = now + 3000
            say(b3)
            return
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
    addTextEdit("buff_" .. (charClass or "unknown"), storage[_buffKey1] or "", function(widget, text) storage[_buffKey1] = text end, hpPanel4)
    cor = UI.Label("Duracao (s):", hpPanel4) cor:setColor("yellow")
    addTextEdit("buffDur1", tostring(_buffDurations.buff1), function(widget, text)
        local val = tonumber(text)
        if val then
            _buffDurations.buff1 = val
            saveDurations()
        end
    end, hpPanel4)

    cor = UI.Label("Buff 2:", hpPanel4) cor:setColor("white")
    addTextEdit("buff2_" .. (charClass or "unknown"), storage[_buffKey2] or "", function(widget, text) storage[_buffKey2] = text end, hpPanel4)
    cor = UI.Label("Duracao (s):", hpPanel4) cor:setColor("yellow")
    addTextEdit("buffDur2", tostring(_buffDurations.buff2), function(widget, text)
        local val = tonumber(text)
        if val then
            _buffDurations.buff2 = val
            saveDurations()
        end
    end, hpPanel4)

    cor = UI.Label("Buff 3:", hpPanel4) cor:setColor("white")
    addTextEdit("buff3_" .. (charClass or "unknown"), storage[_buffKey3] or "", function(widget, text) storage[_buffKey3] = text end, hpPanel4)

    end
end

PainelsWindow.closeButton.onClick = function(widget) PainelsWindow:hide() end

-- ==============================
-- HOTKEYS/MACROS/SCRIPTS 2
-- ==============================

UI.Button("Hotkeys/Macros/Scripts 2", function(newText)
  UI.MultilineEditorWindow(storage.ingame_hotkeys2 or "", {title="Hotkeys editor 2", description="Adicione suas scripts aqui!\nBy: @LoboLupus"}, function(text)
    storage.ingame_hotkeys2 = text
    reload()
  end)
end)

for _, scripts in pairs({storage.ingame_hotkeys2}) do
  if type(scripts) == "string" and scripts:len() > 3 then
    local status, result = pcall(function()
      assert(load(scripts, "ingame_editor"))()
    end)
    if not status then 
      error("Ingame edior error:\n" .. result)
    end
  end
end
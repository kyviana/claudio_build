--------------------------------------------------------------------
-- 0_char_configs.lua
-- Configuracao central de personagens - Claudio Bot
-- Todos os scripts leem daqui via CHARS[charClass]
--------------------------------------------------------------------

CHARS = {
    tobirama = {
        names  = { "Ilyes Fitoussi", "Kojiro Hiroshima" },
        buff   = "suiton saijin",
        buff2  = "kekkei genkai",
        buff3  = "",
        regen  = "big regeneration",
        burstOrder = {
            ["suiton goshokuzame"]         = 1,
            ["suiton suishoha"]            = 2,
            ["daibakufu no jutsu"]         = 3,
            ["suiton tenkyu"]              = 4,
            ["suiton suiryudan no jutsu"]  = 5,
            ["suiton teppodama"]           = 6,
            ["suiton suijinheki no jutsu"] = 7,
        },
        summon = { spell = "taju kagebunshin no jutsu", name = "Ilyes Fitoussi", qtd = 5 },
        actionbar = {
            ["1.1"] = { hotkey = "F", sayText = "kai",                        autoSay = true, type = 1 },
            ["1.2"] = { hotkey = "X", sayText = "kawarimi no jutsu",          autoSay = true, type = 1 },
            ["1.3"] = { hotkey = "1", sayText = "suiton fuin suigadan",       autoSay = true, type = 1 },
            ["1.4"] = { hotkey = "2", sayText = "hiraishingiri",              autoSay = true, type = 1 },
            ["1.5"] = { hotkey = "3", sayText = "kokuangyo no jutsu",         autoSay = true, type = 1 },
            ["1.6"] = { hotkey = "Y", sayText = "suiton teppodama",           autoSay = true, type = 1 },
        },
    },

    shisui = {
        names  = { "Yusei Kazuya", "Sergio Moro", "Rodriguezzz" },
        buff   = "susanoo",
        buff2  = "kekkei genkai",
        buff3  = "",
        regen  = "big regeneration",
        burstOrder = {
            ["katon karyu endan"]  = 1,
            ["katon daibakuha"]    = 2,
            ["susanoo tsukumo"]    = 3,
            ["katon endan"]        = 4,
            ["fuumetsu shuriken"]  = 5,
            ["susanoo danmaku"]    = 6,
        },
        -- Autofuga: hierarquia de fugas por prioridade
        -- requiresActive: so dispara se esses jutsus estiverem com activeCooldown rodando
        -- blockedBy: nao dispara se qualquer um desses estiver com activeCooldown rodando
        -- safe: se true, nao pode morrer enquanto ativo (bloqueia fugas menos prioritarias)
        fugaOrder = {
            -- Kawarimi: ancora do ciclo, dispara sempre que disponivel
            { spell = "kawarimi no jutsu",     totalCD = 35, activeCD = 10, safe = true,
              requiresActive = {},
              blockedBy = { "izanagi", "mangekyou susanoo" } },

            -- Magen: invulneravel 5s
            { spell = "magen shinkarasu",      totalCD = 45, activeCD = 5,  safe = true,
              requiresActive = { "kawarimi no jutsu" },
              blockedBy = { "izanagi" } },

            -- Sanzen: invisivel/perde alvo
            { spell = "sanzengarasu no jutsu", totalCD = 45, activeCD = 5,  safe = false,
              requiresActive = { "kawarimi no jutsu" },
              blockedBy = { "magen shinkarasu", "izanagi" } },

            -- Izanagi: revive completo — enquanto ativo (10s) bloqueia TUDO
            { spell = "izanagi",               totalCD = 60, activeCD = 10, safe = true,
              enableRevive = true,
              requiresActive = { "kawarimi no jutsu" },
              blockedBy = {} },

            -- Susanoo: escudo 20s, bloqueado por izanagi e magen
            { spell = "mangekyou susanoo",     totalCD = 65, activeCD = 20, safe = false,
              requiresActive = { "kawarimi no jutsu" },
              blockedBy = { "izanagi", "magen shinkarasu" } },
        },
        summon = { spell = "", name = "", qtd = 1 },
        actionbar = {
            --["1.1"] = { hotkey = "1", sayText = "izanagi",           autoSay = true, type = 1 },
            --["1.2"] = { hotkey = "W", sayText = "katon daibakuha",   autoSay = true, type = 1 },
            --["1.3"] = { hotkey = "E", sayText = "susanoo tsukumo",   autoSay = true, type = 1 },
            --["1.4"] = { hotkey = "F", sayText = "kai",               autoSay = true, type = 1 },
            --["1.5"] = { hotkey = "T", sayText = "fuumetsu shuriken", autoSay = true, type = 1 },
            --["1.6"] = { hotkey = "Y", sayText = "susanoo danmaku",   autoSay = true, type = 1 },
            --["1.7"] = { hotkey = "X", sayText = "kawarimi no jutsu", autoSay = true, type = 1 },
        },
    },

    -- maitogai = {
    --     names  = { "Akira Ren" },
    --     buff   = "",
    --     buff2  = "",
    --     buff3  = "",
    --     regen  = "big regeneration",
    --     burstOrder = {},
    --     actionbar  = {},
    -- },
}

-- Carrega vocacoes do cadastro e injeta no CHARS antes da deteccao
local _cadastroPath = "/bot/" .. modules.game_bot.contentsPanel.config:getCurrentOption().text .. "/storage/cadastro_vocacoes.json"
if g_resources.fileExists(_cadastroPath) then
    local _ok, _data = pcall(function()
        return json.decode(g_resources.readFileContents(_cadastroPath))
    end)
    if _ok and _data and _data.vocacoes then
        for vocName, voc in pairs(_data.vocacoes) do
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
                    summon     = voc.summon or { spell = "", name = "", qtd = 1 },
                    jutsus     = voc.jutsus or {},
                }
            else
                -- Vocacao ja existe: injeta apenas nomes novos
                for _, name in ipairs(voc.names or {}) do
                    local found = false
                    for _, n in ipairs(CHARS[vocName].names) do
                        if n == name then found = true break end
                    end
                    if not found then
                        table.insert(CHARS[vocName].names, name)
                    end
                end
            end
        end
        warn("[CharConfigs] Cadastro injetado no CHARS")
    end
end

-- Detecta charClass pelo nome do personagem logado
charClass = nil
local _playerName = player:getName()
for class, config in pairs(CHARS) do
    for _, n in ipairs(config.names) do
        if n == _playerName then
            charClass = class
            break
        end
    end
    if charClass then break end
end
charClass = charClass or "tobirama"

warn("[CharConfigs] Personagem: " .. _playerName .. " | Classe: " .. charClass)
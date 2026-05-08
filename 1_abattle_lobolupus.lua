-----------------------------
-- DonatorFix
-- Autor: LoboLupus
-- Projeto criado para NTO Ultimate
-- Edited by: LoboLupus
-----------------------------
labelcc = UI.Label("FILTRO BATTLE")
labelcc:setFont("verdana-11px-rounded")
labelcc:setColor("orange")

local PainelName = "FiltroBattles"
FiltroIcon = setupUI([[
Panel
  height: 20
  margin-top: 3
  
  BattlePlayers
    id: players
    anchors.left: parent.left
    margin-left: 27
    image-source: /images/game/battle/battle_players
    !tooltip: tr('Filtrar players.')

  BattleNPCs
    id: npcs
    anchors.left: prev.left
    margin-left: 30
    image-source: /images/game/battle/battle_npcs
    !tooltip: tr('Filtrar Npcs.')

  BattleMonsters
    id: mobs
    anchors.left: prev.left
    margin-left: 30
    image-source: /images/game/battle/battle_monsters
    !tooltip: tr('Filtrar mobs.')

  BattleSkulls
    id: sempk
    anchors.left: prev.left
    margin-left: 30
    image-source: /images/game/battle/battle_skulls
    !tooltip: tr('Filtrar Player sem PK.')

  BattleParty
    id: party
    anchors.left: prev.left
    margin-left: 30
    image-source: /images/game/battle/battle_party
    !tooltip: tr('Filtrar Membros do Grupo.')
]], parent)

-- Armazenamento das opções
storage.FiltroPlayers = storage.FiltroPlayers or false
storage.FiltroNpcs = storage.FiltroNpcs or false
storage.FiltroMobs = storage.FiltroMobs or false
storage.FiltroSkull = storage.FiltroSkull or false
storage.FiltroParty = storage.FiltroParty or false

-- Atualiza ícones conforme ativação
macro(100, function()
  FiltroIcon.players:setImageColor(storage.FiltroPlayers and '#696969' or '#FFFFFF')
  FiltroIcon.npcs:setImageColor(storage.FiltroNpcs and '#696969' or '#FFFFFF')
  FiltroIcon.mobs:setImageColor(storage.FiltroMobs and '#696969' or '#FFFFFF')
  FiltroIcon.sempk:setImageColor(storage.FiltroSkull and '#696969' or '#FFFFFF')
  FiltroIcon.party:setImageColor(storage.FiltroParty and '#696969' or '#FFFFFF')
end)

-- Eventos de clique
FiltroIcon.players.onClick = function() storage.FiltroPlayers = not storage.FiltroPlayers end
FiltroIcon.npcs.onClick = function() storage.FiltroNpcs = not storage.FiltroNpcs end
FiltroIcon.mobs.onClick = function() storage.FiltroMobs = not storage.FiltroMobs end
FiltroIcon.sempk.onClick = function() storage.FiltroSkull = not storage.FiltroSkull end
FiltroIcon.party.onClick = function() storage.FiltroParty = not storage.FiltroParty end

-- Lógica do filtro em si
FiltrarBattle = macro(1, function() end)
modules.game_battle.doCreatureFitFilters = function(creature)
  if creature:isLocalPlayer() or creature:getHealthPercent() <= 0 then
    return false
  end
  local pos = creature:getPosition()
  if not pos or pos.z ~= posz() or not creature:canBeSeen() then return false end

  if creature:isMonster() and FiltrarBattle.isOn() and storage.FiltroMobs then
    return false
  elseif creature:isPlayer() and FiltrarBattle.isOn() and storage.FiltroPlayers then
    return false
  elseif creature:isNpc() and FiltrarBattle.isOn() and storage.FiltroNpcs then
    return false
  elseif creature:isPlayer() and (creature:getEmblem() == 1 or creature:getShield() == 3 or creature:getShield() == 4) 
    and FiltrarBattle.isOn() and storage.FiltroParty then
    return false
  elseif creature:isPlayer() and creature:getSkull() == 0 and storage.FiltroSkull then
    return false
  end
  return true
end

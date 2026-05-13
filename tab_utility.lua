-- tab_utility.lua — Aba Utility (Sense, Follow, Alarme)
-- Claudio Bot | NTO Ultimate

setDefaultTab("Utility")
UI.Separator()
local qqcoisa = addLabel("SENSE", "SENSE")
qqcoisa:setColor("orange")

-----------------------------

local configName = modules.game_bot.contentsPanel.config:getCurrentOption().text
local pathBot = "/bot/" .. configName .. "/"

-----------------------------
-- ARROW
-----------------------------
local widgetArrow = setupUI([[
UIWidget
  height: 64
  width: 64
  anchors.centerIn: parent
  visible: false
]], modules.game_interface.getMapPanel())

-----------------------------
-- STORAGE (UNIFICADO)
-----------------------------
if not storage["exiva/senseAdvanced"] then
  storage["exiva/senseAdvanced"] = {
    Spell = "Sense",
    LastTargetKey = "T",
    LastSenseKey = "V",
    CurrentTarget = nil
  }
end

local config = storage["exiva/senseAdvanced"]

local mainTab = addTab("Utility")

-----------------------------
-- POSIÇÕES DA SETA
-----------------------------
local positions = {
    west = {marginLeft = -80, marginTop = 0, rotation = 270},
    east = {marginLeft = 80, marginTop = 0, rotation = 90},
    north = {marginLeft = 0, marginTop = -80, rotation = 0},
    south = {marginLeft = 0, marginTop = 80, rotation = 180},
    ["north-west"] = {marginLeft = -80, marginTop = -80, rotation = 315},
    ["north-east"] = {marginLeft = 80, marginTop = -80, rotation = 45},
    ["south-west"] = {marginLeft = -80, marginTop = 80, rotation = 225},
    ["south-east"] = {marginLeft = 80, marginTop = 80, rotation = 135}
}

local evento = nil

local function showArrow(direction)
    local pos = positions[direction]
    if not pos then return end

    widgetArrow:setVisible(true)
    widgetArrow:setRotation(pos.rotation)
    widgetArrow:setMarginLeft(pos.marginLeft)
    widgetArrow:setMarginTop(pos.marginTop)
    widgetArrow:show()

    if evento and type(evento) == "number" then
        removeEvent(evento)
    end

    modules.corelib.g_effects.fadeIn(widgetArrow)

    evento = modules.corelib.scheduleEvent(function()
        modules.corelib.g_effects.fadeOut(widgetArrow)
        evento = nil
    end, 1800)
end

-----------------------------
-- CAPTURA TEXTO DO SENSE
-----------------------------
onTextMessage(function(mode, text)
    if mode ~= 20 then return end

    local playerName = text:match('^(.-) is very .- to the [a-z-]+%.')
    if playerName then
        config.CurrentTarget = playerName:trim()
    end

    local dir =
        text:match("is .- to the ([a-z-]+)%.") or
        text:match("is to the ([a-z-]+)%.")

    if dir then
        showArrow(dir)
    end
end)

-----------------------------
-- HOTKEYS MANUAIS (T e V)
-----------------------------
onKeyPress(function(keys)
    if not modules.corelib.g_app.isMobile() and modules.game_console:isChatEnabled() then
        return
    end

    keys = keys:lower()

    if keys == config.LastTargetKey:lower() then
        if Player and type(Player) == "string" then
            say(config.Spell .. ' "' .. Player .. '"')
            config.CurrentTarget = Player
        else
            modules.game_textmessage.displayGameMessage("Nao ha nenhum ultimo alvo salvo.")
        end

    elseif keys == config.LastSenseKey:lower() then
        if config.CurrentTarget and type(config.CurrentTarget) == "string" then
            say(config.Spell .. ' "' .. config.CurrentTarget .. '"')
        else
            modules.game_textmessage.displayGameMessage("Nao ha nenhum ultimo Sense salvo.")
        end
    end
end)

----------------------------------------
-- ATUALIZA ALVO AO ATACAR PLAYER
----------------------------------------
macro(1, function()
    if g_game.isAttacking() then
        local creature = g_game.getAttackingCreature()
        if creature and creature:isPlayer() then
            Player = creature:getName()
            config.CurrentTarget = Player
        end
    end
end)

----------------------------------------
-- AUTO SENSE + SENSE TARGET (UNIFICADO)
----------------------------------------
macro(2500, "Auto-Sense", function()
    if not config.CurrentTarget then return end

    local locatePlayer = getPlayerByName(config.CurrentTarget)
    local sameFloor = locatePlayer and locatePlayer:getPosition().z == player:getPosition().z
    local nearby = sameFloor and getDistanceBetween(pos(), locatePlayer:getPosition()) <= 8

    if not nearby then
        say(config.Spell .. ' "' .. config.CurrentTarget .. '"')
        delay(2500)
    end
end)

-----------------------------
-- xSENSE (CHAT: xNome)
-----------------------------
onTalk(function(name, level, mode, text)
    if name ~= player:getName() then return end

    if text:sub(1,1):lower() == 'x' then
        local target = text:sub(2):trim()
        if target == "" then return end

        config.CurrentTarget = target
        say(config.Spell .. ' "' .. target)
    end
end)

-----------------------------
-- DOWNLOAD DA SETA
-----------------------------
if not g_resources.fileExists(pathBot .. "/arrow.png") then
    HTTP.get("https://i.imgur.com/UCpAD89.png", function(data, err)
        if not err then
            g_resources.writeFileContents(pathBot .. "/arrow.png", data)
            widgetArrow:setImageSource(pathBot .. "/arrow.png")
        end
    end)
else
    widgetArrow:setImageSource(pathBot .. "/arrow.png")
end

local sep = UI.Separator()
sep:setHeight(1)
sep:setOpacity(0.05)

UI.Separator()

-----------------------------
-- Follow Escada
-----------------------------
UI.Separator()
local qqcoisa = addLabel("FOLLOW", "FOLLOW")
qqcoisa:setColor("orange")

UI.Label("Segue player escada/jump:")
FollowPlayer = {
  targetId = nil,
  obstaclesQueue = {},
  obstacleWalkTime = 0,
  currentTargetId = nil,
  keyToClearTarget = 'Escape',
  walkDirTable = {
      [0] = {'y', -1},
      [1] = {'x', 1},
      [2] = {'y', 1},
      [3] = {'x', -1},
  },
  flags = {
      ignoreNonPathable = true,
      precision = 0,
      ignoreCreatures = true
  },
  jumpSpell = {
      up = 'jump up',
      down = 'jump down'
  },
  defaultItem = 1111,
  defaultSpell = 'skip',
  customIds = {
      {
          id = 1948,
          castSpell = false
      },
      {
          id = 595,
          castSpell = false
      },
      {
          id = 1067,
          castSpell = false
      },
      {
          id = 1080,
          castSpell = false
      },
      {
          id = 386,
          castSpell = true
      },
  },
  lastCancelFollow = 0,
  followDelay = 300
};


FollowPlayer.distanceFromPlayer = function(position)
  local distx = math.abs(posx() - position.x);
  local disty = math.abs(posy() - position.y);

  return math.sqrt(distx * distx + disty * disty);
end

FollowPlayer.walkToPathDir = function(path)
  if (path) then
      g_game.walk(path[1], false);
  end
end

FollowPlayer.getDirection = function(playerPos, direction)
  local walkDir = FollowPlayer.walkDirTable[direction];
  if (walkDir) then
      playerPos[walkDir[1]] = playerPos[walkDir[1]] + walkDir[2];
  end
  return playerPos;
end


FollowPlayer.checkItemOnTile = function(tile, table)
  if (not tile) then return nil end;
  for _, item in ipairs(tile:getItems()) do
      local itemId = item:getId();
      for _, itemSelected in ipairs(table) do
          if (itemId == itemSelected.id) then
              return itemSelected;
          end
      end
  end
  return nil;
end

FollowPlayer.shiftFromQueue = function()
  g_game.cancelFollow();
  lastCancelFollow = now + FollowPlayer.followDelay;
  table.remove(FollowPlayer.obstaclesQueue, 1);
end

FollowPlayer.checkIfWentToCustomId = function(creature, newPos, oldPos, scheduleTime)
  local tile = g_map.getTile(oldPos);

  local customId = FollowPlayer.checkItemOnTile(tile, FollowPlayer.customIds);

  if (not customId) then return; end

  if (not scheduleTime) then
      scheduleTime = 0;
  end

  schedule(scheduleTime, function()
      if (oldPos.z == posz() or #FollowPlayer.obstaclesQueue > 0) then
          table.insert(FollowPlayer.obstaclesQueue, {
              oldPos = oldPos,
              newPos = newPos,
              tilePos = oldPos,
              customId = customId,
              tile = g_map.getTile(oldPos),
              isCustom = true
          });
          g_game.cancelFollow();
          lastCancelFollow = now + FollowPlayer.followDelay;
      end
  end);
end


FollowPlayer.checkIfWentToStair = function(creature, newPos, oldPos, scheduleTime)

  if (g_map.getMinimapColor(oldPos) ~= 210) then return; end
  local tile = g_map.getTile(oldPos);

  if (tile:isPathable()) then return; end

  if (not scheduleTime) then
      scheduleTime = 0;
  end

  schedule(scheduleTime, function()
      if (oldPos.z == posz() or #FollowPlayer.obstaclesQueue > 0) then
          table.insert(FollowPlayer.obstaclesQueue, {
              oldPos = oldPos,
              newPos = newPos,
              tilePos = oldPos,
              tile = tile,
              isStair = true
          });
          g_game.cancelFollow();
          lastCancelFollow = now + FollowPlayer.followDelay;
      end
  end);
end


FollowPlayer.checkIfWentToDoor = function(creature, newPos, oldPos)
  if (FollowPlayer.obstaclesQueue[1] and FollowPlayer.distanceFromPlayer(newPos) < FollowPlayer.distanceFromPlayer(oldPos)) then return; end
  if (math.abs(newPos.x - oldPos.x) == 2 or math.abs(newPos.y - oldPos.y) == 2) then
          

      local doorPos = {
          z = oldPos.z
      }

      local directionX = oldPos.x - newPos.x
      local directionY = oldPos.y - newPos.y

      if math.abs(directionX) > math.abs(directionY) then

          if directionX > 0 then
              doorPos.x = newPos.x + 1
              doorPos.y = newPos.y
          else
              doorPos.x = newPos.x - 1
              doorPos.y = newPos.y
          end
      else
          if directionY > 0 then
              doorPos.x = newPos.x
              doorPos.y = newPos.y + 1
          else
              doorPos.x = newPos.x
              doorPos.y = newPos.y - 1
          end
      end

      local doorTile = g_map.getTile(doorPos);

      if (not doorTile:isPathable() or doorTile:isWalkable()) then return; end

      table.insert(FollowPlayer.obstaclesQueue, {
          newPos = newPos,
          tilePos = doorPos,
          tile = doorTile,
          isDoor = true,
      });
      g_game.cancelFollow();
      lastCancelFollow = now + FollowPlayer.followDelay;
  end
end


FollowPlayer.checkifWentToJumpPos = function(creature, newPos, oldPos)
  local pos1 = { x = oldPos.x - 1, y = oldPos.y - 1 };
  local pos2 = { x = oldPos.x + 1, y = oldPos.y + 1 };

  local hasStair = nil
  for x = pos1.x, pos2.x do
      for y = pos1.y, pos2.y do
          local tilePos = { x = x, y = y, z = oldPos.z };
          if (g_map.getMinimapColor(tilePos) == 210) then
              hasStair = true;
              goto continue;
          end
      end
  end
  ::continue::

  if (hasStair) then return; end

  local spell = newPos.z > oldPos.z and FollowPlayer.jumpSpell.down or FollowPlayer.jumpSpell.up;
  local dir = creature:getDirection();

  if (newPos.z > oldPos.z) then
      spell = FollowPlayer.jumpSpell.down;
  end

  table.insert(FollowPlayer.obstaclesQueue, {
      oldPos = oldPos,
      oldTile = g_map.getTile(oldPos),
      spell = spell,
      dir = dir,
      isJump = true,
  });
  g_game.cancelFollow();
  lastCancelFollow = now + FollowPlayer.followDelay;
end


onCreaturePositionChange(function(creature, newPos, oldPos)
  if (FollowPlayer.mainMacro.isOff()) then return; end

  if creature:getId() == FollowPlayer.currentTargetId and newPos and oldPos and oldPos.z == newPos.z then
      FollowPlayer.checkIfWentToDoor(creature, newPos, oldPos);
  end
end);


onCreaturePositionChange(function(creature, newPos, oldPos)
  if (FollowPlayer.mainMacro.isOff()) then return; end

  if creature:getId() == FollowPlayer.currentTargetId and newPos and oldPos and oldPos.z == posz() and oldPos.z ~= newPos.z then
      FollowPlayer.checkifWentToJumpPos(creature, newPos, oldPos);
  end
end);


onCreaturePositionChange(function(creature, newPos, oldPos)
  if (FollowPlayer.mainMacro.isOff()) then return; end

  if creature:getId() == FollowPlayer.currentTargetId and oldPos and g_map.getMinimapColor(oldPos) == 210 then
      local scheduleTime = oldPos.z == posz() and 0 or 250;

      FollowPlayer.checkIfWentToStair(creature, newPos, oldPos, scheduleTime);
  end
end);



onCreaturePositionChange(function(creature, newPos, oldPos)
  if (FollowPlayer.mainMacro.isOff()) then return; end
  if creature:getId() == FollowPlayer.currentTargetId and oldPos and oldPos.z == posz() and (not newPos or oldPos.z ~= newPos.z) then
      FollowPlayer.checkIfWentToCustomId(creature, newPos, oldPos);
  end
end);


macro(1, function()
  if (FollowPlayer.mainMacro.isOff()) then return; end

  if (FollowPlayer.obstaclesQueue[1] and ((not FollowPlayer.obstaclesQueue[1].isJump and FollowPlayer.obstaclesQueue[1].tilePos.z ~= posz()) or (FollowPlayer.obstaclesQueue[1].isJump and FollowPlayer.obstaclesQueue[1].oldPos.z ~= posz()))) then
      table.remove(FollowPlayer.obstaclesQueue, 1);
  end
end);



macro(100, function()
  if (FollowPlayer.mainMacro.isOff()) then return; end
  if (FollowPlayer.obstaclesQueue[1] and FollowPlayer.obstaclesQueue[1].isStair) then
      local start = now
      local playerPos = pos();
      local walkingTile = FollowPlayer.obstaclesQueue[1].tile;
      local walkingTilePos = FollowPlayer.obstaclesQueue[1].tilePos;

      if (FollowPlayer.distanceFromPlayer(walkingTilePos) < 2) then
          if (FollowPlayer.obstacleWalkTime < now) then
              local nextFloor = g_map.getTile(walkingTilePos); -- workaround para caso o TILE descarregue, conseguir pegar os atributos ainda assim.
              if (nextFloor:isPathable()) then
                  FollowPlayer.obstacleWalkTime = now + 250;
                  use(nextFloor:getTopUseThing());
              else
                  FollowPlayer.obstacleWalkTime = now + 250;
                  FollowPlayer.walkToPathDir(findPath(playerPos, walkingTilePos, 1, { ignoreCreatures = false, precision = 0, ignoreNonPathable = true }));
              end
              FollowPlayer.shiftFromQueue();
              return 
          end
      end
      local path = findPath(playerPos, walkingTilePos, 50, { ignoreNonPathable = true, precision = 0, ignoreCreatures = false });
      if (path == nil or #path <= 1) then
          if (path == nil) then
              use(walkingTile:getTopUseThing());
          end
          return
      end
      
      local tileToUse = playerPos;
      for i, value in ipairs(path) do
          if (i > 5) then break; end
          tileToUse = FollowPlayer.getDirection(tileToUse, value);
      end
      tileToUse = g_map.getTile(tileToUse);
      if (tileToUse) then
          use(tileToUse:getTopUseThing());
      end
  end
end);


macro(1, function()
  if (FollowPlayer.mainMacro.isOff()) then return; end

  if (FollowPlayer.obstaclesQueue[1] and FollowPlayer.obstaclesQueue[1].isDoor) then
      local playerPos = pos();
      local walkingTile = FollowPlayer.obstaclesQueue[1].tile;
      local walkingTilePos = FollowPlayer.obstaclesQueue[1].tilePos;
      if (table.compare(playerPos, FollowPlayer.obstaclesQueue[1].newPos)) then
          FollowPlayer.obstacleWalkTime = 0;
          FollowPlayer.shiftFromQueue();
      end
      
      local path = findPath(playerPos, walkingTilePos, 50, { ignoreNonPathable = true, precision = 0, ignoreCreatures = false });
      if (path == nil or #path <= 1) then
          if (path == nil) then

              if (FollowPlayer.obstacleWalkTime < now) then
                  g_game.use(walkingTile:getTopThing());
                  FollowPlayer.obstacleWalkTime = now + 500;
              end
          end
          return
      end
  end
end);


macro(100, function()
  if (FollowPlayer.mainMacro.isOff()) then return; end
  
  if (FollowPlayer.obstaclesQueue[1] and FollowPlayer.obstaclesQueue[1].isJump) then
      local playerPos = pos();
      local walkingTilePos = FollowPlayer.obstaclesQueue[1].oldPos;
      local distance = FollowPlayer.distanceFromPlayer(walkingTilePos);
      if (playerPos.z ~= walkingTilePos.z) then
          FollowPlayer.shiftFromQueue();
          return;
      end

      local path = findPath(playerPos, walkingTilePos, 50, { ignoreNonPathable = true, precision = 0, ignoreCreatures = false });
      
      if (distance == 0) then
          g_game.turn(FollowPlayer.obstaclesQueue[1].dir);
          schedule(50, function()
              if (FollowPlayer.obstaclesQueue[1]) then
                  say(FollowPlayer.obstaclesQueue[1].spell);
              end
          end)
          return;
      elseif (distance < 2) then
          local nextFloor = g_map.getTile(walkingTilePos); -- workaround para caso o TILE descarregue, conseguir pegar os atributos ainda assim.
          if (FollowPlayer.obstacleWalkTime < now) then
              FollowPlayer.walkToPathDir(findPath(playerPos, walkingTilePos, 1, { ignoreCreatures = false, precision = 0, ignoreNonPathable = true }));
              FollowPlayer.obstacleWalkTime = now + 500;
          end
          return 
      elseif (distance >= 2 and distance < 5 and path) then
          use(FollowPlayer.obstaclesQueue[1].oldTile:getTopUseThing());
      elseif (path) then
          local tileToUse = playerPos;
          for i, value in ipairs(path) do
              if (i > 5) then break; end
              tileToUse = FollowPlayer.getDirection(tileToUse, value);
          end
          tileToUse = g_map.getTile(tileToUse);
          if (tileToUse) then
              use(tileToUse:getTopUseThing());
          end
      end
  end
end);


macro(100, function()
  if (FollowPlayer.mainMacro.isOff()) then return; end
  
  if (FollowPlayer.obstaclesQueue[1] and FollowPlayer.obstaclesQueue[1].isCustom) then
      local playerPos = pos();
      local walkingTile = FollowPlayer.obstaclesQueue[1].tile;
      local walkingTilePos = FollowPlayer.obstaclesQueue[1].tilePos;
      local distance = FollowPlayer.distanceFromPlayer(walkingTilePos);
      if (playerPos.z ~= walkingTilePos.z) then
          FollowPlayer.shiftFromQueue();
          return;
      end
      
      if (distance == 0) then
          if (FollowPlayer.obstaclesQueue[1].customId.castSpell) then
              say(FollowPlayer.defaultSpell);
              return;
          end
      elseif (distance < 2) then
          local item = findItem(FollowPlayer.defaultItem)
          if (FollowPlayer.obstaclesQueue[1].customId.castSpell or not item) then
              local nextFloor = g_map.getTile(walkingTilePos); -- workaround para caso o TILE descarregue, conseguir pegar os atributos ainda assim.
              if (FollowPlayer.obstacleWalkTime < now) then
                  FollowPlayer.walkToPathDir(findPath(playerPos, walkingTilePos, 1, { ignoreCreatures = false, precision = 0, ignoreNonPathable = true }));
                  FollowPlayer.obstacleWalkTime = now + 500;
              end
          elseif (item) then
              g_game.useWith(item, walkingTile);
              FollowPlayer.shiftFromQueue();
          end
          return 
      end

      local path = findPath(playerPos, walkingTilePos, 50, { ignoreNonPathable = true, precision = 0, ignoreCreatures = false });
      if (path == nil or #path <= 1) then
          if (path == nil) then
              use(walkingTile:getTopUseThing());
          end
          return
      end
      
      local tileToUse = playerPos;
      for i, value in ipairs(path) do
          if (i > 5) then break; end
          tileToUse = FollowPlayer.getDirection(tileToUse, value);
      end
      tileToUse = g_map.getTile(tileToUse);
      if (tileToUse) then
          use(tileToUse:getTopUseThing());
      end
  end
end);


addTextEdit("FollowPlayer", storage.FollowPlayerName or "Nome do player", function(widget, text)
  storage.FollowPlayerName = text;
end);

FollowPlayer.mainMacro = macro(FollowPlayer.followDelay, 'Follow Persistent', function()
  local followingPlayer = g_game.getFollowingCreature();
  local playerToFollow = getCreatureByName(storage.FollowPlayerName);
  if (not playerToFollow) then return; end
  if (not findPath(pos(), playerToFollow:getPosition(), 50, { ignoreNonPathable = true, precision = 0, ignoreCreatures = true })) then
      if (followingPlayer and followingPlayer:getId() == playerToFollow:getId()) then
          lastCancelFollow = now + FollowPlayer.followDelay;
          return g_game.cancelFollow();
      end
  elseif (not followingPlayer and playerToFollow and playerToFollow:canShoot() and FollowPlayer.lastCancelFollow < now) then
      g_game.follow(playerToFollow);
  end
end);


macro(1, function()
  if (FollowPlayer.mainMacro.isOff()) then return; end
  local playerToFollow = getCreatureByName(storage.FollowPlayerName);

  if (playerToFollow and FollowPlayer.currentTargetId ~= playerToFollow:getId()) then
      FollowPlayer.currentTargetId = playerToFollow:getId();
  end
end);

macro(1000, function()
  if (FollowPlayer.mainMacro.isOff()) then return; end
  local target = g_game.getFollowingCreature();


  if (target) then
      local targetPos = target:getPosition();

      if (not targetPos or targetPos.z ~= posz()) then
          g_game.cancelFollow();
      end
  end
end);


UI.Separator()



-- ==============================
-- ALARME
-- ==============================

UI.Separator()

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
-- ==============================
-- BIJUU SYSTEM
-- ==============================

setDefaultTab("Utility")

UI.Separator()
local bijuuLabel = addLabel("BIJUU", "BIJUU")
bijuuLabel:setColor("orange")
UI.Separator()

-- Catálogo completo de bijuus
local BIJUU_CATALOG = {
    { name="Ichibi",  id=158, spells={"Bijuu Sabaku Kyu","Bijuu Sabaku Taisou","Bijuu Shudan","Ultimate Bijuu Dama"} },
    { name="Nibi",    id=161, spells={"Bijuu Katon Ryuka","Bijuu Katon Endan","Bijuu Katon no Jutsu","Ultimate Bijuu Dama"} },
    { name="Sanbi",   id=303, spells={"Bijuu Suigadan","Bijuu Goshokuzame","Bijuu Suisahan","Ultimate Bijuu Dama"} },
    { name="Yonbi",   id=269, spells={"Bijuu Yokai Furie","Bijuu Yokai Youton","Bijuu Youton Shaku Karyu","Ultimate Bijuu Dama"} },
    { name="Gobi",    id=162, spells={"Bijuu Yuugeton Koogeki","Bijuu Chinbou","Bijuu Suihei","Ultimate Bijuu Dama"} },
    { name="Rokubi",  id=301, spells={"Bijuu Doku Chiri","Bijuu Suiton Homatsu","Bijuu Chiyute Saisei","Ultimate Bijuu Dama"} },
    { name="Nanabi",  id=302, spells={"Bijuu Fuujin","Bijuu Doton Kouka","Ultimate Bijuu Dama"} },
    { name="Hachibi", id=268, spells={"Bijuu Chikara","Bijuu Yoroi Sokudo","Bijuu Shokushu","Ultimate Bijuu Dama"} },
    { name="Kyuubi",  id=531, spells={"Bijuu Dai Panchi","Bijuu Renzoku Dama","Bijuu Chakura Tenso","Ultimate Bijuu Dama"} },
}

-- IDs válidos de bijuu
local BIJUU_IDS = {}
for _, b in ipairs(BIJUU_CATALOG) do BIJUU_IDS[b.id] = b end

-- Estado
local _bijuuActive    = false   -- está transformado agora
local _bijuuExpires   = 0       -- when transformation ends
local _bijuuCooldown  = 0       -- when can transform again
local _yaibaCooldown  = 0       -- CD do bijuu yaiba (15s)
local BIJUU_DURATION  = 30000   -- 30s em ms
local BIJUU_CD_TOTAL  = 180000  -- 180s em ms
local BIJUU_YAIBA_CD  = 15000   -- 15s em ms

-- Detecta qual bijuu está ativa agora
local function getCurrentBijuu()
    local outfitId = player:getOutfit().type
    return BIJUU_IDS[outfitId]
end

local function inBijuuMode()
    return getCurrentBijuu() ~= nil
end

-- Storage de configuração (checkboxes por bijuu)
local _BJ_DIR  = "/bot/" .. modules.game_bot.contentsPanel.config:getCurrentOption().text .. "/storage/"
local _BJ_FILE = _BJ_DIR .. "bijuu_cfg.json"
local _bjCfg   = { enabled = {}, active_spells = {} }
if g_resources.fileExists(_BJ_FILE) then
    local ok, result = pcall(function()
        return json.decode(g_resources.readFileContents(_BJ_FILE))
    end)
    if ok and result then _bjCfg = result end
end
if type(_bjCfg.enabled) ~= "table" then _bjCfg.enabled = {} end
if type(_bjCfg.active_spells) ~= "table" then _bjCfg.active_spells = {} end

local function saveBijuuCfg()
    pcall(function()
        g_resources.writeFileContents(_BJ_FILE, json.encode(_bjCfg, 2))
    end)
end

-- Detecta transformação via mudança de outfit
local _lastOutfit = player:getOutfit().type
onCreatureAppear(function(creature)
    if creature ~= player then return end
end)

-- Checa entrada/saída da bijuu por polling de outfit
local function checkBijuuState()
    local bijuu = getCurrentBijuu()
    local wasActive = _bijuuActive
    _bijuuActive = bijuu ~= nil

    if _bijuuActive and not wasActive then
        -- Acabou de transformar
        _bijuuExpires  = now + BIJUU_DURATION
        _bijuuCooldown = now + BIJUU_CD_TOTAL
        _yaibaCooldown = 0
    elseif not _bijuuActive and wasActive then
        -- Voltou ao normal
        _bijuuExpires = 0
    end
end

-- Janela de configuração
local bijuuWindow = setupUI([[
MainWindow
  text: Bijuu Setup
  size: 260 420
  visible: false
  Button
    id: bjCloseBtn
    text: Fechar
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    margin-bottom: 8
    margin-right: 8
    width: 60
    height: 22
]], g_ui.getRootWidget())

-- Scroll com checkboxes por bijuu
local bjScrollPanel = setupUI([[
Panel
  anchors.top: parent.top
  anchors.left: parent.left
  anchors.right: parent.right
  anchors.bottom: bjCloseBtn.top
  margin-bottom: 5
  TextList
    id: bjList
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    anchors.right: bjScroll.left
    vertical-scrollbar: bjScroll
  VerticalScrollBar
    id: bjScroll
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    step: 14
    pixels-scroll: true
]], bijuuWindow)

local bjList = bjScrollPanel.bjList

-- Popular checkboxes
for _, bijuu in ipairs(BIJUU_CATALOG) do
    -- Label da bijuu
    local bjHeader = g_ui.createWidget("Label", bjList)
    bjHeader:setText("[ " .. bijuu.name .. " - outfit " .. bijuu.id .. " ]")
    bjHeader:setColor("#FF6600")
    bjHeader:setHeight(18)
    bjHeader:setFont("verdana-11px-rounded")

    -- Bijuu Yaiba é sempre incluído (não configurável)
    local yaibaLbl = g_ui.createWidget("Label", bjList)
    yaibaLbl:setText("  + Bijuu Yaiba [auto - CD 15s]")
    yaibaLbl:setColor("#888888")
    yaibaLbl:setHeight(16)

    -- Checkboxes dos outros jutsus
    for _, spell in ipairs(bijuu.spells) do
        local key = bijuu.id .. "_" .. spell
        local isChecked = (_bjCfg.active_spells[key] ~= false)
        local cb = g_ui.createWidget("CheckBox", bjList)
        cb:setText(spell)
        cb:setChecked(isChecked)
        cb:setHeight(18)
        cb:setMarginLeft(6)
        cb.onCheckChange = function(widget, checked)
            _bjCfg.active_spells[key] = checked
            saveBijuuCfg()
        end
    end
end

bijuuWindow.bjCloseBtn.onClick = function() bijuuWindow:hide() end

-- Painel na aba Utility
-- Switch único: controla Healing + Yaiba juntos
local bijuuPanel = setupUI([[
Panel
  height: 25
  BotSwitch
    id: bjSwitch
    anchors.top: parent.top
    anchors.left: parent.left
    width: 130
    text: Bijuu
  Button
    id: bjSetup
    anchors.top: parent.top
    anchors.left: prev.right
    anchors.right: parent.right
    margin-left: 3
    height: 25
    text: Setup
]], parent)

bijuuPanel.bjSwitch:setOn(_bjCfg.enabled and true or false)
bijuuPanel.bjSwitch.onClick = function(widget)
    _bjCfg.enabled = not (_bjCfg.enabled == true)
    widget:setOn(_bjCfg.enabled)
    saveBijuuCfg()
end

bijuuPanel.bjSetup.onClick = function()
    bijuuWindow:show()
    bijuuWindow:raise()
    bijuuWindow:focus()
end

-- Combo bijuu: switch separado, opcional
-- CD global dos jutsus de bijuu — setado pelo onTextMessage
local _bijuuSpellCD = 0

-- Captura "Aguarde X segundos para usar o jutsu novamente."
-- e "Somente pode usar jutsus de bijuu com suas transformacoes!"
onTextMessage(function(mode, text)
    if text:find("Aguarde (%d+) segundo") then
        local secs = tonumber(text:match("Aguarde (%d+) segundo"))
        if secs then
            _bijuuSpellCD = now + (secs + 1) * 1000
        end
    elseif text:find("Somente pode usar jutsus de bijuu") then
        -- bijuu acabou, bloqueia combo por 3s pra não spammar
        _bijuuSpellCD = now + 3000
    end
end)

local bijuuComboMacro
bijuuComboMacro = macro(100, "Bijuu Combo", function()
    if bijuuComboMacro:isOff() then return end
    checkBijuuState()
    if not _bijuuActive then return end
    if SGO and now < SGO then return end
    if not g_game.isAttacking() then return end
    if now < _bijuuSpellCD then return end
    local bijuu = getCurrentBijuu()
    if not bijuu then return end
    for _, spell in ipairs(bijuu.spells) do
        local key = bijuu.id .. "_" .. spell
        if _bjCfg.active_spells[key] ~= false then
            say(spell)
        end
    end
end, parent)

-- Healing e Yaiba: controlados pelo bjSwitch, sem switch próprio
local function _bjIsOn()
    return bijuuPanel.bjSwitch:isOn()
end

macro(100, function()
    if not _bjIsOn() then return end
    checkBijuuState()
    -- Usa inBijuuOutfit() como verificação direta além de _bijuuActive
    local emBijuu = _bijuuActive or (inBijuuOutfit and inBijuuOutfit())
    if not emBijuu then return end
    -- Healing: sem target, sem SGO
    if hppercent() < 100 then
        say("bijuu regeneration")
    end
    -- Yaiba: com SGO, sem target
    if SGO and now < SGO then return end
    if now >= _yaibaCooldown then
        say("Bijuu Yaiba")
        _yaibaCooldown = now + BIJUU_YAIBA_CD
    end
end)

-- HUD Timer Bijuu — sem fundo, so texto colorido, some quando OK
local _BJ_HUD_POS_FILE = _BJ_DIR .. "bijuu_hud_pos.json"
local _bjHudPos = { x = 720, y = 250 }
if g_resources.fileExists(_BJ_HUD_POS_FILE) then
    local ok, result = pcall(function()
        return json.decode(g_resources.readFileContents(_BJ_HUD_POS_FILE))
    end)
    if ok and result and result.x then _bjHudPos = result end
end

local bijuuHud = setupUI([[
UIWidget
  background-color: alpha
  opacity: 1
  padding: 0 2
  focusable: true
  phantom: false
  draggable: true
  font: verdana-13px-rounded
  width: 80
  height: 16
  text-auto-resize: true
]], g_ui.getRootWidget())

bijuuHud:setPosition({ x = _bjHudPos.x, y = _bjHudPos.y })

bijuuHud.onDragEnter = function(widget, mousePos)
    if not modules.corelib.g_keyboard.isCtrlPressed() then return false end
    widget:breakAnchors()
    widget.movingReference = { x = mousePos.x - widget:getX(), y = mousePos.y - widget:getY() }
    return true
end
bijuuHud.onDragMove = function(widget, mousePos)
    local p = widget:getParent():getRect()
    local x = math.min(math.max(p.x, mousePos.x - widget.movingReference.x), p.x + p.width - widget:getWidth())
    local y = math.min(math.max(p.y, mousePos.y - widget.movingReference.y), p.y + p.height - widget:getHeight())
    widget:move(x, y)
    return true
end
bijuuHud.onDragLeave = function(widget)
    _bjHudPos = { x = widget:getX(), y = widget:getY() }
    pcall(function()
        g_resources.writeFileContents(_BJ_HUD_POS_FILE, json.encode(_bjHudPos, 2))
    end)
    return true
end

macro(100, function()
    if now < _bijuuExpires then
        local rem = math.ceil((_bijuuExpires - now) / 1000)
        bijuuHud:setOpacity(1)
        bijuuHud:setColor("#FF00FF")
        bijuuHud:setText("Bijuu " .. rem .. "s")
        bijuuHud:show()
    elseif now < _bijuuCooldown then
        local rem = math.ceil((_bijuuCooldown - now) / 1000)
        local total = BIJUU_CD_TOTAL / 1000
        local pct = 1 - (rem / total)
        local r, g
        if pct < 0.5 then
            r = 255
            g = math.floor(pct * 2 * 165)
        else
            r = 255
            g = math.floor(165 + (pct - 0.5) * 2 * 90)
        end
        local hex = string.format("#%02X%02X00", r, g)
        bijuuHud:setOpacity(1)
        bijuuHud:setColor(hex)
        bijuuHud:setText("Bijuu " .. rem .. "s")
        bijuuHud:show()
    else
        local pulse = (math.sin(now / 300) + 1) / 2
        local opacity = 0.4 + pulse * 0.6
        bijuuHud:setOpacity(opacity)
        bijuuHud:setColor("white")
        bijuuHud:setText("Bijuu")
        bijuuHud:show()
    end
end)

UI.Separator()

-- ==============================
-- COMBO LEADER
-- ==============================

setDefaultTab("Utility")

UI.Separator()
local clLabel = addLabel("PVE", "PVE")
clLabel:setColor("orange")
UI.Separator()

local _lastSentId = nil
local _lastCancelFollow = 0
local FOLLOW_DELAY = 300
local _clLeaderName = nil

-- LIDER
local clLeaderMacro
clLeaderMacro = macro(500, "Sou o Lider", function()
    if clLeaderMacro:isOff() then
        if _lastSentId ~= nil then
            talkChannel(1, "!cl stop")
            _lastSentId = nil
        end
        return
    end
    local target = g_game.getAttackingCreature()
    if target then
        local id = target:getId()
        if id ~= _lastSentId then
            talkChannel(1, "!cl " .. id)
            _lastSentId = id
        end
    else
        if _lastSentId ~= nil then
            talkChannel(1, "!cl stop")
            _lastSentId = nil
        end
    end
end, parent)

-- SEGUIDOR: onTalk escuta qualquer !cl no party
local clFollowMacro
onTalk(function(name, level, mode, text, channelId, pos)
    if clFollowMacro and clFollowMacro:isOff() then return end
    if name == player:getName() then return end
    if mode ~= 7 then return end
    -- Atualiza nome do lider automaticamente
    if text:match("^!cl") then
        _clLeaderName = name
    end
    if text == "!cl stop" then
        g_game.cancelAttackAndFollow()
        local leader = _clLeaderName and getCreatureByName(_clLeaderName)
        if leader then
            schedule(500, function() g_game.follow(leader) end)
        end
        return
    end
    local id = text:match("^!cl (%d+)$")
    if not id then return end
    local mob = g_map.getCreatureById(tonumber(id))
    if mob and mob ~= g_game.getAttackingCreature() then
        g_game.cancelFollow()
        _lastCancelFollow = now + 1000
        g_game.attack(mob)
    end
end)

clFollowMacro = macro(FOLLOW_DELAY, "Seguidor", function()
    if clFollowMacro:isOff() then
        g_game.cancelAttackAndFollow()
        _clLeaderName = nil
        _lastCancelFollow = 0
        return
    end
    if not _clLeaderName then return end
    if g_game.getAttackingCreature() then return end
    local leader = getCreatureByName(_clLeaderName)
    if not leader then return end
    local following = g_game.getFollowingCreature()
    if not findPath(pos(), leader:getPosition(), 50, {ignoreNonPathable=true, precision=0, ignoreCreatures=true}) then
        if following and following:getId() == leader:getId() then
            _lastCancelFollow = now + FOLLOW_DELAY
            g_game.cancelFollow()
        end
    elseif not following and leader:canShoot() and _lastCancelFollow < now then
        g_game.follow(leader)
    end
end, parent)

-- JUTSU DE AREA
UI.Separator()

local _CADVOC_PATH = "/bot/" .. modules.game_bot.contentsPanel.config:getCurrentOption().text .. "/storage/cadastro_vocacoes.json"
local _areaSpellCD = 0

local function loadAreaSpell()
    if not g_resources.fileExists(_CADVOC_PATH) then return "" end
    local ok, data = pcall(function() return json.decode(g_resources.readFileContents(_CADVOC_PATH)) end)
    if ok and data and data.vocacoes and charClass then
        local voc = data.vocacoes[charClass]
        if voc and voc.areaSpell then return voc.areaSpell end
    end
    return ""
end

local function saveAreaSpell(spell)
    local data = { vocacoes = {} }
    if g_resources.fileExists(_CADVOC_PATH) then
        local ok, result = pcall(function() return json.decode(g_resources.readFileContents(_CADVOC_PATH)) end)
        if ok and result then data = result end
    end
    if not data.vocacoes then data.vocacoes = {} end
    if not data.vocacoes[charClass] then data.vocacoes[charClass] = {} end
    data.vocacoes[charClass].areaSpell = spell
    pcall(function() g_resources.writeFileContents(_CADVOC_PATH, json.encode(data, 2)) end)
end

local _areaSpell = loadAreaSpell()

onTextMessage(function(mode, text)
    if text:find("Aguarde (%d+) segundo") then
        local secs = tonumber(text:match("Aguarde (%d+) segundo"))
        if secs and _areaSpell ~= "" then
            _areaSpellCD = now + (secs + 1) * 1000
        end
    end
end)

local areaMacro
areaMacro = macro(200, "Jutsu Area", function()
    if areaMacro:isOff() then return end
    if SGO and now < SGO then return end
    if now < _areaSpellCD then return end
    if _areaSpell == "" then return end
    say(_areaSpell)
end, parent)

UI.Label("Jutsu de Area:")
UI.TextEdit(_areaSpell, function(widget, text)
    _areaSpell = text:trim():lower()
    saveAreaSpell(_areaSpell)
end)

UI.Separator()
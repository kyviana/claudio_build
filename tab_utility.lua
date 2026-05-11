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
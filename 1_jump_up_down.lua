-----------------------------
-- DonatorFix
-- Projeto criado para NTO Ultimate
-- Adaptado by: LoboLupus
-----------------------------
local sep = UI.Separator()
sep:setHeight(1)
sep:setOpacity(0.05)

-- Titulo JUMP
local jumpTitle = setupUI([[
Panel
  height: 20
  Label
    color: #FF6600
    font: verdana-11px-rounded
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 20
    text-align: center
    text: JUMP
]], parent)


local jumpBySave = {};


jumpBySave.extraJumpDirections = {
	['W'] = {x = 0, y = -1, dir = 0},
	['D'] = {x = 1, y = 0, dir = 1},
	['S'] = {x = 0, y = 1, dir = 2},
	['A'] = {x = -1, y = 0, dir = 3}
}

local arrowXkey = {
	["W"] = "Up",
	["S"] = "Down",
	["D"] = "Right",
	["A"] = "Left"
};

for KEY, ARROW in pairs(arrowXkey) do
	jumpBySave.extraJumpDirections[ARROW] = table.copy(jumpBySave.extraJumpDirections[KEY]);
end

jumpBySave.standingTime = now;

onPlayerPositionChange(function(newPos, oldPos)
	jumpBySave.standingTime = now
end)

jumpBySave.standTime = function()
	return now - jumpBySave.standingTime;
end

local isMobile = modules._G.g_app.isMobile();
if (isMobile) then
	local keypad = g_ui.getRootWidget():recursiveGetChildById("keypad");
	jumpBySave.pointer = keypad.pointer;

	local North = {
		highest = {x = -16, y = 29},
		lowest = {x = -75, y = -30},
		info = {
			dir = 0,
			x = 0,
			y = -1
		};
	};
	local East = {
		highest = {x = 29, y = 75},
		lowest = {x = -30, y = 15},
		info = {
			dir = 1,
			x = 1,
			y = 0
		};
	};
	local South = {
		highest = {x = 75, y = 29},
		lowest = {x = 16, y = -30},
		info = {
			dir = 2,
			x = 0,
			y = 1
		};
	};
	local West = {
		highest = {x = 29, y = -15},
		lowest = {x = -30, y = -75},
		info = {
			dir = 3,
			x = -1,
			y = 0
		};
	}
	jumpBySave.DIRS = {North, East, South, West};
end

jumpBySave.getPressedKeys = function()
	local wasdWalking = modules.game_walking.wsadWalking;
	
	if (isMobile) then
		local marginTop, marginLeft = jumpBySave.pointer:getMarginTop(), jumpBySave.pointer:getMarginLeft();
		for index, value in ipairs(jumpBySave.DIRS) do
			if (
				(marginTop >= value.lowest.x and marginTop <= value.highest.x) and
				(marginLeft >= value.lowest.y and marginLeft <= value.highest.y)
			) then
				return value.info;
			end
		end
	else
		for walkKey, value in pairs(jumpBySave.extraJumpDirections) do
			if (modules.corelib.g_keyboard.isKeyPressed(walkKey)) then
				-- local tbl = pressedKeys[value.wasdWalking and 'wordKey' or 'arrowKey'];
				-- info(walkKey);
				if (#walkKey > 1 or wasdWalking) then
					return value;
				end
			end
		end
	end
end

macro(100, "Auto Jump", function()
	if (stopCombo and stopCombo - 100 >= now) then return; end
	if (player:isWalking() or jumpBySave.standTime() <= 100) then return; end
	local values = jumpBySave.getPressedKeys();
	if (not values) then return; end
	local pos = pos();
	
	turn(values.dir);
	pos.x = pos.x + values.x;
	pos.y = pos.y + values.y;
	local tile = g_map.getTile(pos);
	say(tile and tile:isFullGround() and "Jump up" or "Jump Down");
end)

storage.jumps = storage.jumps or {};

local config = storage.jumps;

jumpBySave.posToString = function(pos)
	return pos.x .. ',' .. pos.y .. ',' .. pos.z;
end

if (#config > 0) then
	for index, value in ipairs(config) do
		config[jumpBySave.posToString(value)] = {
			direction = value.direction,
			jumpTo = value.jumpTo
		};
		config[index] = nil;
	end
end

onPlayerPositionChange(function(newPos, oldPos)
	jumpBySave.lastWalkPos = oldPos;
	jumpBySave.actualWalkPos = newPos;
	jumpBySave.isWalking = nil;
end)

function Creature:setAndClear(text, delay)
	self:setText(text);
	delay = delay or 100;
	local time = now + delay;
	self.time = time;
	schedule(delay, function()
		if (self.time ~= time) then return; end
		self:clearText();
	end)
end

onTalk(function(name, level, mode, text)
	if (not storage.jumps.savePositions) then return; end
	if (name ~= player:getName()) then return; end
	if (mode ~= 44) then return; end
	if (not jumpBySave.actualWalkPos or not jumpBySave.lastWalkPos) then return; end
	if (jumpBySave.actualWalkPos.z == jumpBySave.lastWalkPos.z) then return; end
	if text:lower():find('jump') then
		local lastWalkPos = jumpBySave.posToString(jumpBySave.lastWalkPos);
		if (not storage.jumps[lastWalkPos]) then
			text = text:gsub('"', "");
			text = text:gsub(":", "");
			saveJump = text:trim();
			config[lastWalkPos] = {
				direction = jumpBySave.correctDirection(),
				jumpTo = saveJump
			};
			player:setAndClear(lastWalkPos .. '\n Saved as: ' .. saveJump);
		end
	end
end)

jumpBySave.correctDirection = function()

	local dir = player:getDirection();
	
	if (dir <= 3) then
		return dir;
	end
	
	return dir < 6 and 1 or 3;
end

jumpBySave.getDistance = function(p1, p2)

    local distx = math.abs(p1.x - p2.x);
    local disty = math.abs(p1.y - p2.y);

    return math.sqrt(distx * distx + disty * disty);
end
	
	
jumpBySave.findNearestJump = function()
	local playerPos = pos();
	local nearest = {};
	
	if (jumpBySave.tile) then
		jumpBySave.tile:setText("");
		jumpBySave.tile = nil;
	end
	
	for stringPos, value in pairs(config) do
		
		local splitPos = stringPos:split(',');
		if (#splitPos == 3) then
			local tilePos = {
				x = tonumber(splitPos[1]),
				y = tonumber(splitPos[2]),
				z = tonumber(splitPos[3])
			};
			if (tilePos.z == playerPos.z) then
				local distance = jumpBySave.getDistance(tilePos, playerPos);
				if (not nearest.distance or distance < nearest.distance) then
					local tile = g_map.getTile(tilePos);
					if (tile and tile:isWalkable() and tile:isPathable()) then
						if (findPath(playerPos, tilePos)) then
							nearest = {
								tile = tile,
								distance = distance,
								direction = value.direction,
								jumpTo = value.jumpTo;
							};
						end
					end
				end
				
			end
		end
	end
	
	return nearest;
end

local qqcoisa = UI.TextEdit(storage.kunaiId or "", function(widget, text)
    storage.kunaiId = text
end)
qqcoisa:setFont("verdana-11px-rounded")
qqcoisa:setColor("white")
qqcoisa:setTooltip("Para utilizar o sunshin jump e escada, preencha com o ID da Kunai. Caso contrario deixe vazio.")



local JUMPKEY = UI.TextEdit(storage.autojumper or "coloque a tecla para ativar", function(widget, text)    
    storage.autojumper = text
end)
JUMPKEY:setFont("verdana-11px-rounded")
JUMPKEY:setColor("white")
JUMPKEY:setTooltip("Preencha com o atalho que deseja para utilizar o auto-jump")




isKeyPressed = modules.corelib.g_keyboard.isKeyPressed;
jumpBySave.executeMacro = macro(200, "Jump Marcacao", function()
	if (jumpBySave.isWalking) then return; end
	local jumpInfo = jumpBySave.findNearestJump();
	if (not isKeyPressed(not isMobile and storage.autojumper)) then
		if (jumpInfo.tile) then
			jumpBySave.tile = jumpInfo.tile;
			jumpInfo.tile:setText(jumpInfo.jumpTo, "red");
		end
		local pos = jumpBySave.posToString(pos());
		if (isKeyPressed("Delete")) then
			if (storage.jumps[pos]) then
				player:setAndClear(pos .. '\n Removed.');
				storage.jumps[pos] = nil;
			end
		end
	elseif (jumpInfo.tile) then
		local tilePos = jumpInfo.tile:getPosition();
		if (tilePos) then
			jumpBySave.tile = jumpInfo.tile;
			jumpBySave.tile:setText(jumpInfo.jumpTo, "green");
			local distanceFromTile = getDistanceBetween(tilePos, pos());
			
			if (distanceFromTile == 0) then
				g_game.turn(jumpInfo.direction);
				say(jumpInfo.jumpTo);
				-- if (jumpBySave.correctDirection() == jumpInfo.direction) then
				-- else
				-- end
			elseif (distanceFromTile == 1) then
				autoWalk(tilePos, 1);
				jumpBySave.isWalking = true;
			else
				jumpBySave.doWalk(tilePos);
			end
		end
	else
		player:setAndClear("No jump nearby.");
	end
end)

error = function(msg)
	return modules.game_bot.message("error", msg);
end


jumpBySave.nextPosition = {
    {x = 0, y = -1},
    {x = 1, y = 0},
    {x = 0, y = 1},
    {x = -1, y = 0},
    {x = 1, y = -1},
    {x = 1, y = 1},
    {x = -1, y = 1},
    {x = -1, y = -1}
}

jumpBySave.getNextDirection = function(pos, dir)
	local offSet = jumpBySave.nextPosition[dir + 1];
	
	pos.x = pos.x + offSet.x;
	pos.y = pos.y + offSet.y;
	
	return pos;
end


jumpBySave.doWalk = function(pos)
	local playerPos = player:getPosition();
	local path = findPath(playerPos, pos);
	
	if (not path) then return; end
	
	local kunaiThing;
	for index, dir in ipairs(path) do
		if (index > 10) then break; end
		
		playerPos = jumpBySave.getNextDirection(playerPos, dir);
		local tmpTile = g_map.getTile(playerPos);
		if (tmpTile and tmpTile:isWalkable(true) and tmpTile:isPathable() and tmpTile:canShoot()) then
			kunaiThing = tmpTile:getTopThing();
		end
	end
	local tile = g_map.getTile(playerPos);
	
	if (tile) then
		
		local topThing = tile:getTopThing();
		local distance = getDistanceBetween(playerPos, player:getPosition());
		if (distance > 1 and storage.kunaiId and kunaiThing) then
			g_game.stop();
			useWith(tonumber(storage.kunaiId), kunaiThing);
		end
		if (not topThing) then return; end
		use(topThing);
	end
end

local checkBox = setupUI([[
CheckBox
  id: checkBox
  font: cipsoftFont
  text: Save Positions
]]);

checkBox.onCheckChange = function(widget, checked)
	storage.jumps.savePositions = checked;
end

if (storage.jumps.savePositions == nil) then
	storage.jumps.savePositions = true;
end

checkBox:setChecked(storage.jumps.savePositions);

addIcon("jumpIcon", {item = 3001, text = "Jump"}, jumpBySave.executeMacro);

timeEnemy = {};
enemy_data = {spells={}};
storage._enemy = storage._enemy or {};
local dir = "/bot/storage";
local path = dir .. "/" .. g_game.getWorldName() .. ".json";

if not g_resources.directoryExists(dir) then
    g_resources.makeDir(dir);
end
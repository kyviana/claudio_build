-- =====================================
-- DonatorFix - Storage Bootstrap
-- Autor: LoboLupus
-- =====================================

storage = storage or {}

-- Subtabelas globais
storage.extras = storage.extras or {}
storage.targetbot = storage.targetbot or {}
storage.combat = storage.combat or {}
storage.ui = storage.ui or {}

-- Defaults seguros
storage.extras.killUnder = storage.extras.killUnder or 30
storage.extras.debug = storage.extras.debug or false

-- charClass definido pelo 0_char_configs.lua
-- Fallback caso o arquivo nao tenha carregado ainda
charClass = charClass or "tobirama"

--modules.game_bot.botWindow.contentsPanel:setImageSource("/bot/MADARA1.3/wallpaper/lobolupus")
--Adaptado e criado por LoboLupus
local function doDownloadImage(imageUrl, widget)
  local function callback(filePath, error)
    if error then
      warn(error)
      return
    end
    widget:setImageSource(filePath)
  end
  modules._G.HTTP.downloadImage(imageUrl, callback)
end
--lobolupus
local rootWidget = g_ui.getRootWidget()
if not rootWidget then return end

local botWindow = rootWidget:recursiveGetChildById("botWindow")
if not botWindow then return end

local contents = botWindow:recursiveGetChildById("contentsPanel")
if not contents then return end

local urlImage = "https://stories.cnnbrasil.com.br/wp-content/uploads/sites/9/2026/04/diniz-tecnico-corinthians.jpg"
doDownloadImage(urlImage, contents)

local MIN_WIDTH = 170
local MAX_WIDTH = 400
local STEP      = 20

local function updateButtonsBot()
  local bw = modules.game_bot.botWindow
  bw.closeButton:setImageColor("#363434")
  bw.minimizeButton:setImageColor("#363434")
  bw.lockButton:setImageColor("#363434")
  bw:setImageSource()
  bw:setBackgroundColor("black")
  bw:setBorderWidth(1)
  bw:setBorderColor("black")
  bw:setText("Claudio")
  bw:setFont("verdana-11px-rounded")
  bw:setColor("white")

  -- Botoes de resize no header
  local function addResizeBtn(id, label, dx)
    local existing = bw:recursiveGetChildById(id)
    if existing then return end
    local btn = g_ui.createWidget("Button", bw)
    btn:setId(id)
    btn:setText(label)
    btn:setFont("cipsoftFont")
    btn:setSize({width=14, height=14})
    btn:setColor("white")
    btn:setBackgroundColor("#222222")
    -- posiciona antes dos botoes nativos
    if id == "resizeMinus" then
      btn:setPosition({x = bw:getWidth() - 52, y = 3})
    else
      btn:setPosition({x = bw:getWidth() - 38, y = 3})
    end
    btn.onClick = function()
      local cur = bw:getWidth()
      local nw  = math.min(math.max(cur + dx, MIN_WIDTH), MAX_WIDTH)
      bw:setWidth(nw)
      -- reposiciona os dois botoes
      local bm = bw:recursiveGetChildById("resizeMinus")
      local bp = bw:recursiveGetChildById("resizePlus")
      if bm then bm:setPosition({x = bw:getWidth() - 52, y = 3}) end
      if bp then bp:setPosition({x = bw:getWidth() - 38, y = 3}) end
    end
  end

  addResizeBtn("resizeMinus", "-", -STEP)
  addResizeBtn("resizePlus",  "+",  STEP)
end
updateButtonsBot()

-- Carrega sistema de combo/fuga
--dofile("/combo_system.lua")
--dofile("/combo_tobirama.lua")

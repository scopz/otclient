minimapWidget = nil
minimapWindow = nil
otmm = true
preloaded = false
fullmapView = false
oldZoom = nil
oldPos = nil
originalMargin = nil

function init()
  minimapWindow = g_ui.loadUI('minimap', modules.game_interface.getRightPanel())
  minimapWindow:setContentMinimumHeight(64)

  minimapWidget = minimapWindow:recursiveGetChildById('minimap')

  local gameRootPanel = modules.game_interface.getRootPanel()
  g_keyboard.bindKeyPress('Alt+Left', function() minimapWidget:move(1,0) end, gameRootPanel)
  g_keyboard.bindKeyPress('Alt+Right', function() minimapWidget:move(-1,0) end, gameRootPanel)
  g_keyboard.bindKeyPress('Alt+Up', function() minimapWidget:move(0,1) end, gameRootPanel)
  g_keyboard.bindKeyPress('Alt+Down', function() minimapWidget:move(0,-1) end, gameRootPanel)
  g_keyboard.bindKeyDown('Ctrl+M', toggleFullMap)

  minimapWindow:setup()

  connect(g_game, {
    onGameStart = online,
    onGameEnd = offline,
  })

  connect(LocalPlayer, {
    onPositionChange = updateCameraPosition
  })

  if g_game.isOnline() then
    online()
  end
end

function terminate()
  if g_game.isOnline() then
    saveMap()
  end

  disconnect(g_game, {
    onGameStart = online,
    onGameEnd = offline,
  })

  disconnect(LocalPlayer, {
    onPositionChange = updateCameraPosition
  })

  local gameRootPanel = modules.game_interface.getRootPanel()
  g_keyboard.unbindKeyPress('Alt+Left', gameRootPanel)
  g_keyboard.unbindKeyPress('Alt+Right', gameRootPanel)
  g_keyboard.unbindKeyPress('Alt+Up', gameRootPanel)
  g_keyboard.unbindKeyPress('Alt+Down', gameRootPanel)
  g_keyboard.unbindKeyDown('Ctrl+M')

  minimapWindow:destroy()
end

function toggle()
  if minimapWindow:isVisible() then
    minimapWindow:close()
  else
    minimapWindow:open()
  end
end

function preload()
  loadMap(false)
  preloaded = true
end

function online()
  originalMargin = {
    minimapWidget:getMarginTop(),
    minimapWidget:getMarginRight(),
    minimapWidget:getMarginBottom(),
    minimapWidget:getMarginLeft()
  }

  loadMap(not preloaded)
  updateCameraPosition()

  if g_game.isOnline() then
    minimapWindow:setupOnStart()
  end
end

function offline()
  saveMap()
end

function loadMap(clean)
  local clientVersion = g_game.getClientVersion()

  if clean then
    g_minimap.clean()
  end

  if otmm then
    local minimapFile = '/minimap.otmm'
    if g_resources.fileExists(minimapFile) then
      g_minimap.loadOtmm(minimapFile)
    end
  else
    local minimapFile = '/minimap_' .. clientVersion .. '.otcm'
    if g_resources.fileExists(minimapFile) then
      g_map.loadOtcm(minimapFile)
    end
  end
  minimapWidget:load()
end

function saveMap()
  local clientVersion = g_game.getClientVersion()
  if otmm then
    local minimapFile = '/minimap.otmm'
    g_minimap.saveOtmm(minimapFile)
  else
    local minimapFile = '/minimap_' .. clientVersion .. '.otcm'
    g_map.saveOtcm(minimapFile)
  end
  minimapWidget:save()
end

function updateCameraPosition()
  local player = g_game.getLocalPlayer()
  if not player then return end
  local pos = player:getPosition()
  if not pos then return end
  if not minimapWidget:isDragging() then
    if not fullmapView then
      minimapWidget:setCameraPosition(player:getPosition())
    end
    minimapWidget:setCrossPosition(player:getPosition())
  end
end

function toggleFullMap()
  if not fullmapView then
    fullmapView = true
    minimapWindow:hide()
    minimapWidget:setParent(modules.game_interface.getMapPanel())
    minimapWidget:setMargin(0)
    minimapWidget:fill('parent')
    minimapWidget:setAlternativeWidgetsVisible(true)
    oldPos = minimapWidget.cross.pos
  else
    fullmapView = false
    minimapWidget:setParent(minimapWindow:getChildById('contentsPanel'))
    minimapWidget:fill('parent')
    minimapWidget:setMarginTop(originalMargin[1])
    minimapWidget:setMarginRight(originalMargin[2])
    minimapWidget:setMarginBottom(originalMargin[3])
    minimapWidget:setMarginLeft(originalMargin[4])
    minimapWindow:show()
    minimapWidget:setAlternativeWidgetsVisible(false)
  end

  local zoom = oldZoom or minimapWidget:getZoom()
  local pos = oldPos or minimapWidget:getCameraPosition()
  oldZoom = minimapWidget:getZoom()
  oldPos = minimapWidget:getCameraPosition()
  minimapWidget:setZoom(zoom)
  minimapWidget:setCameraPosition(pos)
end

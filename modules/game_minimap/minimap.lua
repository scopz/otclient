local otmm = true
local oldPos = nil

local function updateCameraPosition()
    local player = g_game.getLocalPlayer()
    if not player then return end

    local pos = player:getPosition()
    if not pos then return end

    local minimapWidget = controller.widgets.minimapWidget
    if minimapWidget:isDragging() then return end

    if not minimapWidget.fullMapView then minimapWidget:setCameraPosition(pos) end

    minimapWidget:setCrossPosition(pos)
end

local function toggleFullMap()
    local minimapWindow = controller.widgets.minimapWindow
    local minimapWidget = controller.widgets.minimapWidget
    local zoom;
    local pos = minimapWidget:getCameraPosition()

    if minimapWidget.fullMapView then
        minimapWidget:setParent(minimapWindow:getChildById('contentsPanel'))
        minimapWidget:fill('parent')
        minimapWidget:setMarginTop(1)
        minimapWidget:setMarginRight(1)
        minimapWidget:setMarginBottom(1)
        minimapWidget:setMarginLeft(3)
        minimapWindow:show(true)
        zoom = minimapWidget.zoomMinimap
        if oldPos then pos = oldPos end
    else
        minimapWindow:hide(true)
        minimapWidget:setParent(modules.game_interface.getMapPanel())
        minimapWidget:setMargin(0)
        minimapWidget:fill('parent')
        zoom = minimapWidget.zoomFullmap
    end

    minimapWidget.fullMapView = not minimapWidget.fullMapView
    minimapWidget:setAlternativeWidgetsVisible(fullmapView)

    oldPos = minimapWidget:getCameraPosition()
    minimapWidget:setZoom(zoom)
    minimapWidget:setCameraPosition(pos)
end

local localPlayerEvent = EventController:new(LocalPlayer, {
    onPositionChange = updateCameraPosition
})

controller = Controller:new()
controller:attachExternalEvent(localPlayerEvent)

function controller:onInit()
    local minimapWindow = g_ui.loadUI('minimap')

    minimapWindow:setContentMinimumHeight(80)

    local minimapWidget = minimapWindow:recursiveGetChildById('minimap')

    local gameRootPanel = modules.game_interface.getRootPanel()
    self:bindKeyPress('Alt+Left', function() minimapWidget:move(1, 0) end, gameRootPanel)
    self:bindKeyPress('Alt+Right', function() minimapWidget:move(-1, 0) end, gameRootPanel)
    self:bindKeyPress('Alt+Up', function() minimapWidget:move(0, 1) end, gameRootPanel)
    self:bindKeyPress('Alt+Down', function() minimapWidget:move(0, -1) end, gameRootPanel)

    self:bindKeyDown('Ctrl+M', toggleFullMap)
    self:bindKeyDown('Alt+E', toggleFullMap)

    self:registerWidget('minimapWindow', minimapWindow)
    self:registerWidget('minimapWidget', minimapWidget)

    minimapWidget:getChildById('expand').onClick = toggleFullMap

    minimapWindow:setup()
    localPlayerEvent:connect()
end


function controller:onTerminate()
    g_keyboard.unbindKeyDown('Ctrl+M')
    g_keyboard.unbindKeyDown('Alt+E')
    localPlayerEvent:disconnect()
end

controller:onGameStart(function()
    controller.widgets.minimapWindow:setupOnStart() -- load character window configuration

    -- Load Map
    g_minimap.clean()

    local minimapFile = '/minimap'
    local loadFnc = nil

    if otmm then
        minimapFile = minimapFile .. '.otmm'
        loadFnc = g_minimap.loadOtmm
    else
        minimapFile = minimapFile .. '_' .. g_game.getClientVersion() .. '.otcm'
        loadFnc = g_map.loadOtcm
    end

    if g_resources.fileExists(minimapFile) then loadFnc(minimapFile) end

    local minimapWidget = controller.widgets.minimapWidget
    minimapWidget:load()
end)

controller:onGameEnd(function()
    controller.widgets.minimapWindow:setParent(nil, true)

    -- Save Map
    if otmm then
        g_minimap.saveOtmm('/minimap.otmm')
    else
        g_map.saveOtcm('/minimap_' .. g_game.getClientVersion() .. '.otcm')
    end

    local minimapWidget = controller.widgets.minimapWidget
    minimapWidget:save()
end)

function onMiniWindowOpen()
    updateCameraPosition()
end
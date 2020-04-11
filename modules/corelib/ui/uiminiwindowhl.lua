-- @docclass
UIMiniWindowHeadLess = extends(UIWindow, "UIMiniWindow")

function UIMiniWindowHeadLess.create()
  local miniwindow = UIMiniWindowHeadLess.internalCreate()
  miniwindow.UIMiniWindowContainer = true
  return miniwindow
end

function UIMiniWindowHeadLess:open(dontSave)
  self:setVisible(true)

  if not dontSave then
    self:setSettings({closed = false})
  end

  signalcall(self.onOpen, self)
end


function UIMiniWindowHeadLess:setup()
  local oldParent = self:getParent()

  local settings = g_settings.getNode('MiniWindowsHL')
  if settings then
    local selfSettings = settings[self:getId()]
    if selfSettings then
      if selfSettings.parentId then
        local parent = rootWidget:recursiveGetChildById(selfSettings.parentId)
        if parent then
          if parent:getClassName() == 'UIMiniWindowContainer' and selfSettings.index and parent:isOn() then
            self.miniIndex = selfSettings.index
            parent:scheduleInsert(self, selfSettings.index)
          elseif selfSettings.position then
            self:setParent(parent, true)
            self:setPosition(topoint(selfSettings.position))
          end
        end
      end
    end
  end

  local newParent = self:getParent()

  self.miniLoaded = true

  if self.save then
    if oldParent and oldParent:getClassName() == 'UIMiniWindowContainer' then
      addEvent(function() oldParent:order() end)
    end
    if newParent and newParent:getClassName() == 'UIMiniWindowContainer' and newParent ~= oldParent then
      addEvent(function() newParent:order() end)
    end
  end

  self:fitOnParent()
end

function UIMiniWindowHeadLess:onVisibilityChange(visible)
  self:fitOnParent()
end

function UIMiniWindowHeadLess:onDragEnter(mousePos)
  local parent = self:getParent()
  if not parent then return false end

  if parent:getClassName() == 'UIMiniWindowContainer' then
    local containerParent = parent:getParent()
    parent:removeChild(self)
    containerParent:addChild(self)
    parent:saveChildren()
  end

  local oldPos = self:getPosition()
  self.movingReference = { x = mousePos.x - oldPos.x, y = mousePos.y - oldPos.y }
  self:setPosition(oldPos)
  self.free = true
  return true
end

function UIMiniWindowHeadLess:onDragLeave(droppedWidget, mousePos)
  if self.movedWidget then
    self.setMovedChildMargin(self.movedOldMargin or 0)
    self.movedWidget = nil
    self.setMovedChildMargin = nil
    self.movedOldMargin = nil
    self.movedIndex = nil
  end

  self:saveParent(self:getParent())
end

function UIMiniWindowHeadLess:onDragMove(mousePos, mouseMoved)
  local oldMousePosY = mousePos.y - mouseMoved.y
  local children = rootWidget:recursiveGetChildrenByMarginPos(mousePos)
  local overAnyWidget = false
  for i=1,#children do
    local child = children[i]
    if child:getParent():getClassName() == 'UIMiniWindowContainer' then
      overAnyWidget = true

      local childCenterY = child:getY() + child:getHeight() / 2
      if child == self.movedWidget and mousePos.y < childCenterY and oldMousePosY < childCenterY then
        break
      end

      if self.movedWidget then
        self.setMovedChildMargin(self.movedOldMargin or 0)
        self.setMovedChildMargin = nil
      end

      if mousePos.y < childCenterY then
        self.movedOldMargin = child:getMarginTop()
        self.setMovedChildMargin = function(v) child:setMarginTop(v) end
        self.movedIndex = 0
      else
        self.movedOldMargin = child:getMarginBottom()
        self.setMovedChildMargin = function(v) child:setMarginBottom(v) end
        self.movedIndex = 1
      end

      self.movedWidget = child
      self.setMovedChildMargin(self:getHeight())
      break
    end
  end

  if not overAnyWidget and self.movedWidget then
    self.setMovedChildMargin(self.movedOldMargin or 0)
    self.movedWidget = nil
  end

  return UIWindow.onDragMove(self, mousePos, mouseMoved)
end

function UIMiniWindowHeadLess:onMousePress()
  local parent = self:getParent()
  if not parent then return false end
  if parent:getClassName() ~= 'UIMiniWindowContainer' then
    self:raise()
    return true
  end
end

function UIMiniWindowHeadLess:onFocusChange(focused)
  if not focused then return end
  local parent = self:getParent()
  if parent and parent:getClassName() ~= 'UIMiniWindowContainer' then
    self:raise()
  end
end


function UIMiniWindowHeadLess:getSettings(name)
  if not self.save then return nil end
  local settings = g_settings.getNode('MiniWindowsHL')
  if settings then
    local selfSettings = settings[self:getId()]
    if selfSettings then
      return selfSettings[name]
    end
  end
  return nil
end

function UIMiniWindowHeadLess:setSettings(data)
  if not self.save then return end

  local settings = g_settings.getNode('MiniWindowsHL')
  if not settings then
    settings = {}
  end

  local id = self:getId()
  if not settings[id] then
    settings[id] = {}
  end

  for key,value in pairs(data) do
    settings[id][key] = value
  end

  g_settings.setNode('MiniWindowsHL', settings)
end

function UIMiniWindowHeadLess:eraseSettings(data)
  if not self.save then return end

  local settings = g_settings.getNode('MiniWindowsHL')
  if not settings then
    settings = {}
  end

  local id = self:getId()
  if not settings[id] then
    settings[id] = {}
  end

  for key,value in pairs(data) do
    settings[id][key] = nil
  end

  g_settings.setNode('MiniWindowsHL', settings)
end

function UIMiniWindowHeadLess:saveParent(parent)
  local parent = self:getParent()
  if parent then
    if parent:getClassName() == 'UIMiniWindowContainer' then
      parent:saveChildren()
    else
      self:saveParentPosition(parent:getId(), self:getPosition())
    end
  end
end

function UIMiniWindowHeadLess:saveParentPosition(parentId, position)
  local selfSettings = {}
  selfSettings.parentId = parentId
  selfSettings.position = pointtostring(position)
  self:setSettings(selfSettings)
end

function UIMiniWindowHeadLess:saveParentIndex(parentId, index)
  local selfSettings = {}
  selfSettings.parentId = parentId
  selfSettings.index = index
  self:setSettings(selfSettings)
  self.miniIndex = index
end

function UIMiniWindowHeadLess:disableResize()
  self:getChildById('bottomResizeBorder'):disable()
end

function UIMiniWindowHeadLess:enableResize()
  self:getChildById('bottomResizeBorder'):enable()
end

function UIMiniWindowHeadLess:fitOnParent()
  local parent = self:getParent()
  if self:isVisible() and parent and parent:getClassName() == 'UIMiniWindowContainer' then
    parent:fitAll(self)
  end
end

function UIMiniWindowHeadLess:setParent(parent, dontsave)
  UIWidget.setParent(self, parent)
  if not dontsave then
    self:saveParent(parent)
  end
  self:fitOnParent()
end

function UIMiniWindowHeadLess:setHeight(height)
  UIWidget.setHeight(self, height)
  signalcall(self.onHeightChange, self, height)
end

function UIMiniWindowHeadLess:setContentHeight(height)
  local contentsPanel = self:getChildById('contentsPanel')
  local minHeight = contentsPanel:getMarginTop() + contentsPanel:getMarginBottom() + contentsPanel:getPaddingTop() + contentsPanel:getPaddingBottom()

  local resizeBorder = self:getChildById('bottomResizeBorder')
  resizeBorder:setParentSize(minHeight + height)
end

function UIMiniWindowHeadLess:setContentMinimumHeight(height)
  local contentsPanel = self:getChildById('contentsPanel')
  local minHeight = contentsPanel:getMarginTop() + contentsPanel:getMarginBottom() + contentsPanel:getPaddingTop() + contentsPanel:getPaddingBottom()

  local resizeBorder = self:getChildById('bottomResizeBorder')
  resizeBorder:setMinimum(minHeight + height)
end

function UIMiniWindowHeadLess:setContentMaximumHeight(height)
  local contentsPanel = self:getChildById('contentsPanel')
  local minHeight = contentsPanel:getMarginTop() + contentsPanel:getMarginBottom() + contentsPanel:getPaddingTop() + contentsPanel:getPaddingBottom()

  local resizeBorder = self:getChildById('bottomResizeBorder')
  resizeBorder:setMaximum(minHeight + height)
end

function UIMiniWindowHeadLess:getMinimumHeight()
  local resizeBorder = self:getChildById('bottomResizeBorder')
  return resizeBorder:getMinimum()
end

function UIMiniWindowHeadLess:getMaximumHeight()
  local resizeBorder = self:getChildById('bottomResizeBorder')
  return resizeBorder:getMaximum()
end

function UIMiniWindowHeadLess:isResizeable()
  local resizeBorder = self:getChildById('bottomResizeBorder')
  return resizeBorder:isExplicitlyVisible() and resizeBorder:isEnabled()
end






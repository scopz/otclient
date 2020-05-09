-- @docclass
UIMiniWindowHeadLess = extends(UIMiniWindow, "UIMiniWindowHeadLess")

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

function UIMiniWindowHeadLess:close()
  -- CAN'T CLOSE
end

function UIMiniWindowHeadLess:setup()
  -- OVERRIDE UIMiniWindow setup function
end

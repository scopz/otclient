-- @docclass
UIMiniWindowNoBar = extends(UIMiniWindow, "UIMiniWindowNoBar")

function UIMiniWindowNoBar.create()
    local miniwindow = UIMiniWindowNoBar.internalCreate()
    miniwindow.UIMiniWindowContainer = true
    return miniwindow
end

function UIMiniWindowNoBar:close()
    -- CAN'T CLOSE
end

function UIMiniWindowNoBar:setup()
    -- OVERRIDE UIMiniWindow setup function
end

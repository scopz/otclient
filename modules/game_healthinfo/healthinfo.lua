
healthInfoWindow = nil
healthBar = nil
manaBar = nil
healthValue = nil
manaValue = nil
healthTooltip = 'Health %d out of %d'
manaTooltip = 'Mana %d out of %d'

function init()
  connect(LocalPlayer, { onHealthChange = onHealthChange,
                         onManaChange = onManaChange })

  connect(g_game, { onGameEnd = offline })

  healthInfoButton = modules.client_topmenu.addRightGameToggleButton('healthInfoButton', tr('Health Information'), '/images/topbuttons/healthinfo', toggle)
  healthInfoButton:setOn(true)

  healthInfoWindow = g_ui.loadUI('healthinfo', modules.game_interface.getRightPanel())
  healthInfoWindow:disableResize()
  healthBar = healthInfoWindow:recursiveGetChildById('healthBar')
  manaBar = healthInfoWindow:recursiveGetChildById('manaBar')
  healthValue = healthInfoWindow:recursiveGetChildById('healthValue')
  manaValue = healthInfoWindow:recursiveGetChildById('manaValue')


  if g_game.isOnline() then
    local localPlayer = g_game.getLocalPlayer()
    onHealthChange(localPlayer, localPlayer:getHealth(), localPlayer:getMaxHealth())
    onManaChange(localPlayer, localPlayer:getMana(), localPlayer:getMaxMana())
  end

  healthInfoWindow:setup()
end

function terminate()
  disconnect(LocalPlayer, { onHealthChange = onHealthChange,
                            onManaChange = onManaChange })

  disconnect(g_game, { onGameEnd = offline })

  healthInfoWindow:destroy()
  healthInfoButton:destroy()
end

function toggle()
  if healthInfoButton:isOn() then
    healthInfoWindow:close()
    healthInfoButton:setOn(false)
  else
    healthInfoWindow:open()
    healthInfoButton:setOn(true)
  end
end

function offline()
end

function onHealthChange(localPlayer, health, maxHealth)
  healthValue:setText(health)
  healthValue:setTooltip(tr(healthTooltip, health, maxHealth))
  healthBar:setValue(health, 0, maxHealth)
end

function onManaChange(localPlayer, mana, maxMana)
  manaValue:setText(mana)
  manaValue:setTooltip(tr(manaTooltip, mana, maxMana))
  manaBar:setValue(mana, 0, maxMana)
end


-- personalization functions
function setHealthTooltip(tooltip)
  healthTooltip = tooltip

  local localPlayer = g_game.getLocalPlayer()
  if localPlayer then
    healthBar:setTooltip(tr(healthTooltip, localPlayer:getHealth(), localPlayer:getMaxHealth()))
  end
end

function setManaTooltip(tooltip)
  manaTooltip = tooltip

  local localPlayer = g_game.getLocalPlayer()
  if localPlayer then
    manaBar:setTooltip(tr(manaTooltip, localPlayer:getMana(), localPlayer:getMaxMana()))
  end
end
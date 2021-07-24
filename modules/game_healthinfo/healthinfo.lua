healthInfoWindow = nil
healthBar = nil
manaBar = nil
healthValue = nil
manaValue = nil
healthTooltip = 'Health %d out of %d'
manaTooltip = 'Mana %d out of %d'

function init()
    connect(LocalPlayer, {
        onHealthChange = onHealthChange,
        onManaChange = onManaChange,
    })

    connect(g_game, {
        onGameStart = online,
        onGameEnd = offline
    })

    healthInfoWindow = g_ui.loadUI('healthinfo')
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
    if g_game.isOnline() then healthInfoWindow:setupOnStart() end
end

function terminate()
    disconnect(LocalPlayer, {
        onHealthChange = onHealthChange,
        onManaChange = onManaChange,
    })

    disconnect(g_game, {
        onGameStart = online,
        onGameEnd = offline
    })

    healthInfoWindow:destroy()

    healthInfoWindow = nil
    healthBar = nil
    manaBar = nil
    healthValue = nil
    manaValue = nil
end

function online()
    healthInfoWindow:setupOnStart() -- load character window configuration
end

function offline()
    healthInfoWindow:setParent(nil, true)
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

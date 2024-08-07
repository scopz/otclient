ConditionIcons = {
    [PlayerStates.Poison] = { tooltip = tr('You are poisoned'), path = '/images/game/states/poisoned', id = 'condition_poisoned' },
    [PlayerStates.Burn] = { tooltip = tr('You are burning'), path = '/images/game/states/burning', id = 'condition_burning' },
    [PlayerStates.Energy] = { tooltip = tr('You are electrified'), path = '/images/game/states/electrified', id = 'condition_electrified' },
    [PlayerStates.Drunk] = { tooltip = tr('You are drunk'), path = '/images/game/states/drunk', id = 'condition_drunk' },
    [PlayerStates.ManaShield] = { tooltip = tr('You are protected by a magic shield'), path = '/images/game/states/magic_shield', id = 'condition_magic_shield' },
    [PlayerStates.Paralyze] = { tooltip = tr('You are paralysed'), path = '/images/game/states/slowed', id = 'condition_slowed' },
    [PlayerStates.Haste] = { tooltip = tr('You are hasted'), path = '/images/game/states/haste', id = 'condition_haste' },
    [PlayerStates.Swords] = { tooltip = tr('You may not logout during a fight'), path = '/images/game/states/logout_block', id = 'condition_logout_block' },
    [PlayerStates.Stopped] = { tooltip = tr('You can\'t move'), path = '/images/game/states/stopped', id = 'condition_trapped' },
    [PlayerStates.AttackBuff] = { tooltip = tr('Your attack is strengthened'), path = '/images/game/states/attack_buff', id = 'condition_attack_buff' },
    [PlayerStates.Healing] = { tooltip = tr('Your are being healed'), path = '/images/game/states/healing', id = 'condition_healing' },
    [PlayerStates.DefenseBuff] = { tooltip = tr('Your defense is strengthened'), path = '/images/game/states/attack_buff', id = 'condition_defense_buff' },
    [PlayerStates.Food] = { tooltip = tr('You have eaten'), path = '/images/game/states/food', id = 'condition_food' },
}

InventorySlotStyles = {
    [InventorySlotHead] = 'HeadSlot',
    [InventorySlotNeck] = 'NeckSlot',
    [InventorySlotBack] = 'BackSlot',
    [InventorySlotBody] = 'BodySlot',
    [InventorySlotRight] = 'RightSlot',
    [InventorySlotLeft] = 'LeftSlot',
    [InventorySlotLeg] = 'LegSlot',
    [InventorySlotFeet] = 'FeetSlot',
    [InventorySlotFinger] = 'FingerSlot',
    [InventorySlotAmmo] = 'AmmoSlot'
}

inventoryWindow = nil
inventoryPanel = nil

fightOffensiveBox = nil
fightBalancedBox = nil
fightDefensiveBox = nil
chaseModeButton = nil
pickUpButton = nil
safeFightButton = nil
whiteDoveBox = nil
whiteHandBox = nil
yellowHandBox = nil
redFistBox = nil
mountButton = nil
pvpModesPanel = nil
fightModeRadioGroup = nil
pvpModeRadioGroup = nil

optionsButton = nil
spellsButton = nil

unusedLabel = nil
capLabel = nil

function init()
    inventoryWindow = g_ui.loadUI('inventory')
    inventoryWindow:disableResize()
    inventoryPanel = inventoryWindow:getChildById('contentsPanel')

    fightOffensiveBox = inventoryWindow:recursiveGetChildById('fightOffensiveBox')
    fightBalancedBox = inventoryWindow:recursiveGetChildById('fightBalancedBox')
    fightDefensiveBox = inventoryWindow:recursiveGetChildById('fightDefensiveBox')

    chaseModeButton = inventoryWindow:recursiveGetChildById('chaseModeBox')
    pickUpButton = inventoryWindow:recursiveGetChildById('pickUpButton')
    safeFightButton = inventoryWindow:recursiveGetChildById('safeFightBox')

    mountButton = inventoryWindow:recursiveGetChildById('mountButton')
    mountButton.onClick = onMountButtonClick

    pvpModesPanel = inventoryWindow:recursiveGetChildById('pvpModesPanel')

    whiteDoveBox = inventoryWindow:recursiveGetChildById('whiteDoveBox')
    whiteHandBox = inventoryWindow:recursiveGetChildById('whiteHandBox')
    yellowHandBox = inventoryWindow:recursiveGetChildById('yellowHandBox')
    redFistBox = inventoryWindow:recursiveGetChildById('redFistBox')

    optionsButton = inventoryWindow:recursiveGetChildById('optionsButton')
    optionsButton.onClick = function()
        modules.client_options:toggle()
    end

    spellsButton = inventoryWindow:recursiveGetChildById('spellsButton')
    spellsButton.onClick = function()
        modules.game_spells:toggle()
    end

    unusedLabel = inventoryWindow:recursiveGetChildById('unusedLabel')
    capLabel = inventoryWindow:recursiveGetChildById('capLabel')

    fightModeRadioGroup = UIRadioGroup.create()
    fightModeRadioGroup:addWidget(fightOffensiveBox)
    fightModeRadioGroup:addWidget(fightBalancedBox)
    fightModeRadioGroup:addWidget(fightDefensiveBox)

    pvpModeRadioGroup = UIRadioGroup.create()
    pvpModeRadioGroup:addWidget(whiteDoveBox)
    pvpModeRadioGroup:addWidget(whiteHandBox)
    pvpModeRadioGroup:addWidget(yellowHandBox)
    pvpModeRadioGroup:addWidget(redFistBox)

    -- load condition icons
    for k,v in pairs(ConditionIcons) do
        g_textures.preload(v.path)
    end

    connect(fightModeRadioGroup, { onSelectionChange = onSetFightMode })
    connect(pvpModeRadioGroup, { onSelectionChange = onSetPVPMode })
    connect(chaseModeButton, { onCheckChange = onSetChaseMode })
    connect(pickUpButton, { onCheckChange = onSetPickUpMode })
    connect(safeFightButton, { onCheckChange = onSetSafeFight })
    connect(g_game, {
        onGameStart = online,
        onGameEnd = offline,
        onFightModeChange = update,
        onChaseModeChange = update,
        onPickUpModeChange = update,
        onSafeFightChange = update,
        onPVPModeChange   = update,
        onWalk = check,
        onAutoWalk = check
    })

    connect(LocalPlayer, {
        onInventoryChange = onInventoryChange,
        onVocationChange = onVocationChange,
        onBlessingsChange = onBlessingsChange,
        onOutfitChange = onOutfitChange,
        onFreeCapacityChange = onFreeCapacityChange,
        onStatesChange = onStatesChange
    })

    online()
    inventoryWindow:setup()
end

function terminate()
    if g_game.isOnline() then
        offline()
    end

    fightModeRadioGroup:destroy()
    pvpModeRadioGroup:destroy()
    inventoryWindow:destroy()

    disconnect(g_game, {
        onGameStart = online,
        onGameEnd = offline,
        onFightModeChange = update,
        onChaseModeChange = update,
        onPickUpModeChange = update,
        onSafeFightChange = update,
        onPVPModeChange   = update,
        onWalk = check,
        onAutoWalk = check
    })

    disconnect(LocalPlayer, {
        onInventoryChange = onInventoryChange,
        onVocationChange = onVocationChange,
        onBlessingsChange = onBlessingsChange,
        onOutfitChange = onOutfitChange,
        onFreeCapacityChange = onFreeCapacityChange,
        onStatesChange = onStatesChange
    })
end

function toggleAdventurerStyle(hasBlessing)
    for slot = InventorySlotFirst, InventorySlotLast do
        local itemWidget = inventoryPanel:getChildById('slot' .. slot)
        if itemWidget then itemWidget:setOn(hasBlessing) end
    end
end

function update()
    local fightMode = g_game.getFightMode()
    if fightMode == FightOffensive then
        fightModeRadioGroup:selectWidget(fightOffensiveBox)
    elseif fightMode == FightBalanced then
        fightModeRadioGroup:selectWidget(fightBalancedBox)
    else
        fightModeRadioGroup:selectWidget(fightDefensiveBox)
    end

    local chaseMode = g_game.getChaseMode()
    chaseModeButton:setChecked(chaseMode == ChaseOpponent)

    local pickUpMode = g_game.getPickUpMode()
    pickUpButton:setChecked(pickUpMode == PickUpAmmo)

    local safeFight = g_game.isSafeFight()
    safeFightButton:setChecked(not safeFight)

    if g_game.getFeature(GamePVPMode) then
        local pvpMode = g_game.getPVPMode()
        local pvpWidget = getPVPBoxByMode(pvpMode)
        if pvpWidget then
            pvpModeRadioGroup:selectWidget(pvpWidget)
        end
    end
end

function online()
    local player = g_game.getLocalPlayer()

    for i = InventorySlotFirst, InventorySlotPurse do
        if g_game.isOnline() then
            onInventoryChange(player, i, player:getInventoryItem(i))
        else
            onInventoryChange(player, i, nil)
        end
        toggleAdventurerStyle(player and Bit.hasBit(player:getBlessings(), Blessings.Adventurer) or false)
    end
    

    if g_game.isOnline() then
        local char = g_game.getCharacterName()

        local lastCombatControls = g_settings.getNode('LastCombatControls')

        if not table.empty(lastCombatControls) then
            if lastCombatControls[char] then
                g_game.setFightMode(lastCombatControls[char].fightMode)
                g_game.setChaseMode(lastCombatControls[char].chaseMode)
                g_game.setPickUpMode(lastCombatControls[char].pickUpMode)
                g_game.setSafeFight(lastCombatControls[char].safeFight)
                if lastCombatControls[char].pvpMode then
                    g_game.setPVPMode(lastCombatControls[char].pvpMode)
                end
            end
        end

        if g_game.getFeature(GamePlayerMounts) then
            mountButton:setVisible(true)
            mountButton:setChecked(player:isMounted())
        else
            mountButton:setVisible(false)
        end

        pvpModesPanel:setVisible(g_game.getFeature(GamePVPMode))

        onFreeCapacityChange(player, player:getFreeCapacity())
        onStatesChange(player, player:getStates(), 0)

        inventoryWindow:setupOnStart()

        update()
    end

end

function offline()
    inventoryWindow:setParent(nil, true)

    local lastCombatControls = g_settings.getNode('LastCombatControls')
    if not lastCombatControls then
        lastCombatControls = {}
    end

    inventoryWindow:recursiveGetChildById('conditionPanel'):destroyChildren()

    local player = g_game.getLocalPlayer()
    if player then
        local char = g_game.getCharacterName()
        lastCombatControls[char] = {
            fightMode = g_game.getFightMode(),
            chaseMode = g_game.getChaseMode(),
            pickUpMode = g_game.getPickUpMode(),
            safeFight = g_game.isSafeFight()
        }

        if g_game.getFeature(GamePVPMode) then
            lastCombatControls[char].pvpMode = g_game.getPVPMode()
        end

        -- save last combat control settings
        g_settings.setNode('LastCombatControls', lastCombatControls)
    end
end

function check()
    if modules.client_options.getOption('autoChaseOverride') then
        if g_game.isAttacking() and g_game.getChaseMode() == ChaseOpponent then
            g_game.setChaseMode(DontChase)
        end
    end
end

function toggleConditionIcon(bitChanged)
    local content = inventoryWindow:recursiveGetChildById('conditionPanel')

    local icon = content:getChildById(ConditionIcons[bitChanged].id)
    if icon then
        icon:destroy()
    else
        icon = loadConditionIcon(bitChanged)
        icon:setParent(content)
    end
end

function loadConditionIcon(bitChanged)
    local icon = g_ui.createWidget('ConditionWidget', content)
    icon:setId(ConditionIcons[bitChanged].id)
    icon:setImageSource(ConditionIcons[bitChanged].path)
    icon:setTooltip(ConditionIcons[bitChanged].tooltip)
    return icon
end


-- hooked events
function onInventoryChange(player, slot, item, oldItem)
    if slot >= InventorySlotPurse then return end

    local itemWidget = inventoryPanel:getChildById('slot' .. slot)
    if item then
        itemWidget:setStyle('InventoryItem')
        itemWidget:setItem(item)
    else
        itemWidget:setStyle(InventorySlotStyles[slot])
        itemWidget:setItem(nil)
    end
end

function onBlessingsChange(player, blessings, oldBlessings)
    local hasAdventurerBlessing = Bit.hasBit(blessings, Blessings.Adventurer)
    if hasAdventurerBlessing ~= Bit.hasBit(oldBlessings, Blessings.Adventurer) then
        toggleAdventurerStyle(hasAdventurerBlessing)
    end
end

function onVocationChange(player, vocation, oldVocation)
    pickUpButton:setVisible(vocation == Vocation.Paladin or vocation == Vocation.None)
end

function onFreeCapacityChange(player, freeCapacity)
    if freeCapacity >= 1000 then
        capLabel:setText(string.format("%d", freeCapacity))
    else
        capLabel:setText(string.format("%.1f", freeCapacity))
    end
end

function onStatesChange(localPlayer, now, old)
    if now == old then return end

    local bitsChanged = bit32.bxor(now, old)
    for i = 1, 32 do
        local pow = math.pow(2, i-1)
        if pow > bitsChanged then break end
        local bitChanged = bit32.band(bitsChanged, pow)
        if bitChanged ~= 0 then
            toggleConditionIcon(bitChanged)
        end
    end
end

function onMountButtonClick(self, mousePos)
    local player = g_game.getLocalPlayer()
    if player then
        player:toggleMount()
    end
end

function onOutfitChange(localPlayer, outfit, oldOutfit)
    if outfit.mount == oldOutfit.mount then
        return
    end

    mountButton:setChecked(outfit.mount ~= nil and outfit.mount > 0)
end

function onSetFightMode(self, selectedFightButton)
    if selectedFightButton == nil then return end
    local buttonId = selectedFightButton:getId()
    local fightMode
    if buttonId == 'fightOffensiveBox' then
        fightMode = FightOffensive
    elseif buttonId == 'fightBalancedBox' then
        fightMode = FightBalanced
    else
        fightMode = FightDefensive
    end
    g_game.setFightMode(fightMode)
end

function toggleChaseMode()
    chaseModeButton:setChecked(not chaseModeButton:isChecked())
end

function onSetChaseMode(self, checked)
    local chaseMode
    if checked then
        chaseMode = ChaseOpponent
    else
        chaseMode = DontChase
    end
    g_game.setChaseMode(chaseMode)
end

function onSetPickUpMode(self, checked)
    local pickUpMode
    if checked then
        pickUpMode = PickUpAmmo
    else
        pickUpMode = DontPickUp
    end
    g_game.setPickUpMode(pickUpMode)
end

function onSetSafeFight(self, checked)
    g_game.setSafeFight(not checked)
end

function onSetPVPMode(self, selectedPVPButton)
    if selectedPVPButton == nil then
        return
    end

    local buttonId = selectedPVPButton:getId()
    local pvpMode = PVPWhiteDove
    if buttonId == 'whiteDoveBox' then
        pvpMode = PVPWhiteDove
    elseif buttonId == 'whiteHandBox' then
        pvpMode = PVPWhiteHand
    elseif buttonId == 'yellowHandBox' then
        pvpMode = PVPYellowHand
    elseif buttonId == 'redFistBox' then
        pvpMode = PVPRedFist
    end

    g_game.setPVPMode(pvpMode)
end
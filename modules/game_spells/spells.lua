spellsWindow = nil
spellsList = nil
scrollBar = nil
availableMoneyLabel = nil

filterTextInput = nil
filterLearnedButton = nil
filterAchievableButton = nil
filterUnavailableButton = nil

currentMoney = 0
pendingConfirm = {}
pendingCurrentMoney = currentMoney

function init()
    spellsWindow = g_ui.displayUI('spells')

    spellsList = spellsWindow:getChildById('spellsList')
    scrollBar = spellsWindow:getChildById('moduleListScrollBar')
    availableMoneyLabel = spellsWindow:getChildById('availableMoney')

    filterTextInput = spellsWindow:getChildById('filterText')
    filterLearnedButton = spellsWindow:getChildById('filterLearnedButton')
    filterAchievableButton = spellsWindow:getChildById('filterAchievableButton')
    filterUnavailableButton = spellsWindow:getChildById('filterUnavailableButton')

    g_keyboard.bindKeyDown('Ctrl+P', toggle)

    connect(g_game, {
        onSendSpells = loadSpells,
        onAddSpell = addSpell,
    })

    connect(LocalPlayer, {
        onBankMoneyUpdate = updateMoneyAvailable,
    })

    hide()
end

function terminate()
    disconnect(g_game, {
        onSendSpells = loadSpells,
        onAddSpell = addSpell,
    })
    disconnect(LocalPlayer, {
        onBankMoneyUpdate = updateMoneyAvailable,
    })
    g_keyboard.unbindKeyDown('Ctrl+P')
    hide()
end

function updateMoneyAvailable(localPlayer, bankMoney)
    local moneyDiff = currentMoney - pendingCurrentMoney
    currentMoney = bankMoney
    pendingCurrentMoney = bankMoney - moneyDiff
    availableMoneyLabel:setText("Money in bank: " .. comma_value(pendingCurrentMoney))
end

function loadSpells(spellSets)
    for index, spellDefinition in pairs(spellsList:getChildren()) do
        spellsList:removeChild(spellDefinition)
    end
    for index, array in pairs(spellSets) do
        addData(array)
    end
end

function addSpell()
end

function confirm()
    local spellsToBuy = {}
    for index, array in pairs(pendingConfirm) do
        local spellDefinition = spellsList:getChildByIndex(index)
        local data = spellDefinition.data

        for k, level in pairs(array) do
            local req = data.spells[level]
            table.insert(spellsToBuy, req.name)
        end
    end

    g_game.buySpells(spellsToBuy)
    hide()
end

function show()
    if not g_game.isOnline() then
        return
    end
    pendingConfirm = {}
    pendingCurrentMoney = currentMoney
    availableMoneyLabel:setText("Money in bank: " .. comma_value(currentMoney))

    scrollBar:setValue(0)
    for index, spellDefinition in pairs(spellsList:getChildren()) do
        local data = spellDefinition.data
        data.selectedLevel = data.currentLevel>1 and data.currentLevel or 1
        updateData(spellDefinition, index)
    end

    spellsWindow:show()
    spellsWindow:raise()
    spellsWindow:focus()
    filterTextInput:focus()
end

function hide()
    filterLearnedButton:setChecked(false)
    filterAchievableButton:setChecked(false)
    filterUnavailableButton:setChecked(false)
    filterTextInput:setText('')

    spellsWindow:hide()
end


function toggle()
    if spellsWindow:isVisible() then
        hide()
    else
        show()
    end
end

function addSpellToPendingConfirm(spellDefinition, index)
    local level = spellDefinition.data.selectedLevel
    local cost = spellDefinition.data.spells[level].cost


    if cost > pendingCurrentMoney then return false end

    pendingCurrentMoney = pendingCurrentMoney - cost
    availableMoneyLabel:setText("Money in bank: " .. comma_value(pendingCurrentMoney))

    local array = pendingConfirm[index]
    if not array then
        pendingConfirm[index] = {}
        array = pendingConfirm[index]
    end

    table.insert(array, level)

    updateData(spellDefinition, index)
end

function addData(data)
    data.selectedLevel = data.currentLevel>1 and data.currentLevel or 1

    local spellDefinition = g_ui.createWidget('SpellDefinition', spellsList)
    spellDefinition.data = data
    spellDefinition.defaultHeight = spellDefinition:getHeight()
    local index = #spellsList:getChildren()
    local icon = data.type
    spellDefinition:getChildById("icon"):setImageClip(torect((icon * 16) .. ' 0 16 16'))

    spellDefinition:getChildById("nextButton").onClick = function()
        data.selectedLevel = data.selectedLevel+1
        updateData(spellDefinition, index)
        filterTextInput:focus()
    end

    spellDefinition:getChildById("prevButton").onClick = function()
        data.selectedLevel = data.selectedLevel-1
        updateData(spellDefinition, index)
        filterTextInput:focus()
    end

    spellDefinition:getChildById("upgradeSpell").onClick = function()
        addSpellToPendingConfirm(spellDefinition, index)
        filterTextInput:focus()
    end

    updateData(spellDefinition)
end


function updateData(spellDefinition, index)
    local data = spellDefinition.data

    local maxlevel = #data.spells

    if maxlevel > 1 then 
        spellDefinition:getChildById("nextButton"):setEnabled(data.selectedLevel ~= maxlevel)
        spellDefinition:getChildById("prevButton"):setEnabled(data.selectedLevel > 1)
        spellDefinition:getChildById("level"):setText("Level: " .. data.selectedLevel .. "/" .. maxlevel)
    else
        spellDefinition:getChildById("nextButton"):hide()
        spellDefinition:getChildById("prevButton"):hide()
        spellDefinition:getChildById("level"):hide()
    end

    local meetRequirements = updateRequirementsPanel(spellDefinition, data.spells[data.selectedLevel])

    local upgradeSpellBtn = spellDefinition:getChildById("upgradeSpell")

    if isPending(index, data.selectedLevel) then
        upgradeSpellBtn:setText("Just bought")
        upgradeSpellBtn:disable()

    elseif data.selectedLevel <= data.currentLevel then
        upgradeSpellBtn:setText("Learned")
        upgradeSpellBtn:disable()

    elseif meetRequirements and data.currentLevel == 0 and data.selectedLevel == 1 then
        upgradeSpellBtn:setText("Buy")
        upgradeSpellBtn:enable()

    elseif meetRequirements and (data.selectedLevel-1 == data.currentLevel or isPending(index, data.selectedLevel-1)) then
        upgradeSpellBtn:setText("Upgrade")
        upgradeSpellBtn:enable()

    else
        upgradeSpellBtn:setText("Can't learn")
        upgradeSpellBtn:disable()
    end
end

function updateRequirementsPanel(spellDefinition, spell)
    spellDefinition:recursiveGetChildById("levelRequired"):setText("Level required: " .. spell.lvl)
    spellDefinition:recursiveGetChildById("magicLevelRequired"):setText("Magic Level required: " .. spell.mlvl)
    spellDefinition:recursiveGetChildById("cost"):setText("Cost: " .. spell.cost)

    spellDefinition:getChildById("spellName"):setText(spell.name)
    spellDefinition:getChildById("spellWords"):setText(spell.words)
    spellDefinition:getChildById("mana"):setText("Mana: " .. spell.mana)

    local player = g_game.getLocalPlayer()
    if not player then return false end

    local canLearn = true
    if player:getLevel() < spell.lvl then
        canLearn = false
        spellDefinition:recursiveGetChildById("levelRequired"):setColor("red")
    else
        spellDefinition:recursiveGetChildById("levelRequired"):setColor("#888888")
    end

    if player:getMagicLevel() < spell.mlvl then
        canLearn = false
        spellDefinition:recursiveGetChildById("magicLevelRequired"):setColor("red")
    else
        spellDefinition:recursiveGetChildById("magicLevelRequired"):setColor("#888888")
    end

    if pendingCurrentMoney < spell.cost then
        canLearn = false
        spellDefinition:recursiveGetChildById("cost"):setColor("red")
    else
        spellDefinition:recursiveGetChildById("cost"):setColor("#888888")
    end

    return canLearn
end

function isPending(index, level)
    local array = pendingConfirm[index]

    if not array then
        return false
    end

    for k,v in pairs(array) do
        if v == level then
            return true
        end
    end

    return false
end


-- #####################
-- #####################
-- #### FILTER FUNCTIONS

function canLearn(spell) 
    local player = g_game.getLocalPlayer()
    if not player then return false end

    if player:getLevel() < spell.lvl then
        return false
    end

    if player:getMagicLevel() < spell.mlvl then
        return false
    end

--  if pendingCurrentMoney < spell.cost then
--    return false
--  end

    return true
end

function filter(button, checked)
    if checked then
        if button==1 then -- LEARNED SPELLS
            filterAchievableButton:setChecked(false)
            filterUnavailableButton:setChecked(false)

            for index, spellDefinition in pairs(spellsList:getChildren()) do
                local found = false
                local data = spellDefinition.data

                if data.currentLevel > 0 then
                    data.selectedLevel = data.currentLevel
                    updateData(spellDefinition,index)
                    found = true
                end

                if found then
                    showDefinition(spellDefinition)
                else
                    hideDefinition(spellDefinition)
                end
            end

        elseif button==2 then -- ACHIEVABLE SPELLS
            filterLearnedButton:setChecked(false)
            filterUnavailableButton:setChecked(false)

            for index, spellDefinition in pairs(spellsList:getChildren()) do
                local found = false
                local data = spellDefinition.data
                local maxlevel = #data.spells

                if data.currentLevel < maxlevel then
                    local spell = data.spells[data.currentLevel+1]
                    if canLearn(spell) then
                        data.selectedLevel = data.currentLevel+1
                        updateData(spellDefinition,index)
                        found = true
                    end
                end

                if found then
                    showDefinition(spellDefinition)
                else
                    hideDefinition(spellDefinition)
                end
            end

        elseif button==3 then -- UNAVAILABLE SPELLS
            filterLearnedButton:setChecked(false)
            filterAchievableButton:setChecked(false)

            for index, spellDefinition in pairs(spellsList:getChildren()) do
                local found = false
                local data = spellDefinition.data
                local maxlevel = #data.spells

                if data.currentLevel < maxlevel then
                    for i=data.currentLevel+1, maxlevel, 1 do
                        local spell = data.spells[i]
                        if not canLearn(spell) then
                            data.selectedLevel = i
                            updateData(spellDefinition,index)
                            found = true
                            break
                        end
                    end
                end

                if found then
                    showDefinition(spellDefinition)
                else
                    hideDefinition(spellDefinition)
                end
            end

        end
        filterTextInput:setText('')

    elseif not filterLearnedButton:isChecked() and not filterAchievableButton:isChecked() and
            not filterUnavailableButton:isChecked() and #filterTextInput:getText() == 0 then

        for index, spellDefinition in pairs(spellsList:getChildren()) do
            local data = spellDefinition.data
            data.selectedLevel = data.currentLevel>1 and data.currentLevel or 1
            updateData(spellDefinition,index)
            showDefinition(spellDefinition)
        end
    end

    return false
end

function filterText(text)
    if #text > 0 then
        filterLearnedButton:setChecked(false)
        filterAchievableButton:setChecked(false)
        filterUnavailableButton:setChecked(false)

        text = text:lower()

        for index, spellDefinition in pairs(spellsList:getChildren()) do
            local found = false
            local data = spellDefinition.data

            for level,spell in pairs(data.spells) do
                if string.find(spell.name:lower(), text) or string.find(spell.words:lower(), text) then
                    found = true
                    data.selectedLevel = level
                    updateData(spellDefinition,index)
                    break
                end
            end

            if found then
                showDefinition(spellDefinition)
            else
                hideDefinition(spellDefinition)
            end
        end

    elseif not filterLearnedButton:isChecked() and not filterAchievableButton:isChecked() and
            not filterUnavailableButton:isChecked() then

        for index, spellDefinition in pairs(spellsList:getChildren()) do
            local data = spellDefinition.data
            data.selectedLevel = data.currentLevel>1 and data.currentLevel or 1
            updateData(spellDefinition,index)
            showDefinition(spellDefinition)
        end
    end
end

function hideDefinition(spellDefinition)
    if spellDefinition:isVisible() then
        spellDefinition:hide()
        spellDefinition:setHeight(0)
        spellDefinition:setMarginTop(1)
    end
end

function showDefinition(spellDefinition)
    if not spellDefinition:isVisible() then
        spellDefinition:setHeight(spellDefinition.defaultHeight)
        spellDefinition:setMarginTop(10)
        spellDefinition:show()
    end
end
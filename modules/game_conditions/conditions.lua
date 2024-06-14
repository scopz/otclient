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

conditionWindow = nil
conditionsToUpdate = {}
runningThread = false
timeoutThread = nil

function init()
    connect(LocalPlayer, {
        onStateTicksChange = onStateTicksChange,
    })
    connect(g_game, {
        onGameStart = online,
        onGameEnd = offline
    })

    conditionWindow = g_ui.loadUI('conditions')

    g_keyboard.bindKeyDown('Alt+B', toggle)

    conditionWindow:setup()
    if g_game.isOnline() then
        conditionWindow:setupOnStart()
    end
end


function terminate()
    disconnect(LocalPlayer, {
        onStateTicksChange = onStateTicksChange,
    })
    disconnect(g_game, {
        onGameStart = online,
        onGameEnd = offline
    })

    offline()

    g_keyboard.unbindKeyDown('Alt+B')
    conditionWindow:destroy()

    conditionWindow = nil
end

function onStateTicksChange(localplayer, states, oldstates, modes, ticks)
    local idx = 0
    local requiresUpdate = false

    local bitsChanged = bit32.bxor(states, oldstates)
    for i = 1, 32 do
        local pow = math.pow(2, i-1)
        if pow > states and pow > oldstates then break end
        
        local add = bit32.band(states, pow) > 0
        if add then idx = idx + 1 end

        local bitChanged = bit32.band(bitsChanged, pow)
        if add or bitChanged ~= 0 then
            local mode = modes[idx]

            if add then
                if mode == 2 then
                    requiresUpdate = true
                end
                toggleConditionIcon(pow, add, mode, ticks[idx])

            else
                toggleConditionIcon(pow, add)
            end
        end
    end

    if requiresUpdate then
        if not timeoutThread then
            startThread()
        end
    else
        stopThread()
    end
end


function toggleConditionIcon(bitChanged, add, mode, tick)
    local content = conditionWindow:recursiveGetChildById('conditionPanel')

    if add then
        local icon = content:getChildById(ConditionIcons[bitChanged].id)

        if icon then
            local button = icon:getChildById('conditionButton')
            local label = button:getChildById('label')

            if mode == 1 then
                label:setText(tick)
                conditionsToUpdate[bitChanged] = nil
            elseif mode == 2 then
                if tick > 0 then
                    conditionsToUpdate[bitChanged] = (tick) - 1
                end
            elseif mode == 3 then
                label:setText(toTime(tick))
                conditionsToUpdate[bitChanged] = nil
            else
                label:setText('U')
                conditionsToUpdate[bitChanged] = nil
            end
        else
            local icon = g_ui.createWidget('ConditionRow', content)
            icon:setId(ConditionIcons[bitChanged].id)
            icon:setParent(content)
        
            local button = icon:getChildById('conditionButton')
            local image = button:getChildById('image')
            local label = button:getChildById('label')

            button:setTooltip(ConditionIcons[bitChanged].tooltip)

            if mode == 1 then
                label:setText(tick)
            elseif mode == 2 then
                label:setText(toTime(tick))
                conditionsToUpdate[bitChanged] = tick
            elseif mode == 3 then
                label:setText(toTime(tick))
            else
                label:setText('U')
            end

            image:setImageSource(ConditionIcons[bitChanged].path)
        end
    else
        conditionsToUpdate[bitChanged] = nil

        local icon = content:getChildById(ConditionIcons[bitChanged].id)
        if icon then
            icon:destroy()
        end
    end
end

function online()
    conditionWindow:setupOnStart() -- load character window configuration
end

function offline()
    conditionWindow:setParent(nil, true)
    conditionsToUpdate = {}
    if timeoutThread then
        timeoutThread:cancel()
        timeoutThread = nil
    end


    local content = conditionWindow:recursiveGetChildById('conditionPanel')
    content:destroyChildren()
end


function toggle()
    if conditionWindow:isVisible() then
        conditionWindow:close()
    else
        conditionWindow:open()
    end
end


function startThread()
    if not runningThread then
        runningThread = true
        
        if timeoutThread then
            timeoutThread:cancel()
            timeoutThread = nil
        end

        loopThread()
    end
end

function stopThread()
    if timeoutThread then
        timeoutThread:cancel()
        timeoutThread = nil
    end
    conditionsToUpdate = {}
    runningThread = false
end


function loopThread()
    if not runningThread then
        return
    end

    for bitChanged, tick in pairs(conditionsToUpdate) do
        local content = conditionWindow:recursiveGetChildById('conditionPanel')
        local icon = content:getChildById(ConditionIcons[bitChanged].id)

        if icon then
            local button = icon:getChildById('conditionButton')
            local label = button:getChildById('label')

            label:setText(toTime(tick))

            if tick <= 0 then
                conditionsToUpdate[bitChanged] = nil
            else
                conditionsToUpdate[bitChanged] = tick - 1
            end
        end
    end

    timeoutThread = scheduleEvent(loopThread, 1000)
end


function toTime(seconds)
    local hh = math.floor(seconds / 3600)
    local mm = math.floor((seconds % 3600) / 60)
    local ss = math.floor(seconds % 60)

    if hh > 0 then
        return string.format("%d:%02d:%02d", hh, mm, ss)
    else
        return string.format("%d:%02d", mm, ss)
    end
end
spellsWindow = nil
spellsList = nil
scrollBar = nil
availablePointsLabel = nil

currentPoints = 300
pendingConfirm = {}
pendingCurrentPoints = currentPoints

function init()
  spellsWindow = g_ui.displayUI('spells')

  spellsList = spellsWindow:getChildById('spellsList')
  scrollBar = spellsWindow:getChildById('moduleListScrollBar')
  availablePointsLabel = spellsWindow:getChildById('availablePoints')

  connect(g_game, {
    onSendSpells = loadSpells,
    onAddSpell = addSpell,
  })

  hide()
end

function terminate()
  disconnect(g_game, {
    onSendSpells = loadSpells,
    onAddSpell = addSpell,
  })
  hide()
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
  for index, array in pairs(pendingConfirm) do
    local spellDefinition = spellsList:getChildByIndex(index)
    local data = spellDefinition.data

    for k, level in pairs(array) do
      local req = data.spells[level]
      print(req.name .. ' - ' .. level)
    end
  end

  hide()
end


function show()
  if not g_game.isOnline() then
    return
  end
  pendingConfirm = {}
  pendingCurrentPoints = currentPoints
  availablePointsLabel:setText("Points: " .. currentPoints)

  scrollBar:setValue(0)
  for index, spellDefinition in pairs(spellsList:getChildren()) do
    local data = spellDefinition.data
    data.selectedLevel = data.currentLevel>1 and data.currentLevel or 1
    updateData(spellDefinition, index)
  end

  spellsWindow:show()
  spellsWindow:raise()
  spellsWindow:focus()
end

function hide()
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

  if cost > pendingCurrentPoints then return false end

  pendingCurrentPoints = pendingCurrentPoints - cost
  availablePointsLabel:setText("Points: " .. pendingCurrentPoints)

  local array = pendingConfirm[index]
  if not array then
    pendingConfirm[index] = {}
    array = pendingConfirm[index]
  end

  table.insert(array, level)

  spellDefinition:getChildById("upgradeSpell"):setText("Learned")
  spellDefinition:getChildById("upgradeSpell"):disable()
end

function addData(data)
  data.selectedLevel = data.currentLevel>1 and data.currentLevel or 1

  local spellDefinition = g_ui.createWidget('SpellDefinition', spellsList)
  spellDefinition.data = data
  local index = #spellsList:getChildren()

  if index > 1 then
    spellDefinition:addAnchor(AnchorTop, 'prev', AnchorBottom)
  else
    spellDefinition:setMarginTop(0)
  end

  spellDefinition:getChildById("nextButton").onClick = function()
    data.selectedLevel = data.selectedLevel+1
    updateData(spellDefinition, index)    
  end

  spellDefinition:getChildById("prevButton").onClick = function()
    data.selectedLevel = data.selectedLevel-1
    updateData(spellDefinition, index)    
  end

  spellDefinition:getChildById("upgradeSpell").onClick = function()
    addSpellToPendingConfirm(spellDefinition, index)
  end

  updateData(spellDefinition)
end


function updateData(spellDefinition, index)
  local data = spellDefinition.data

  local maxlevel = #data.spells

  spellDefinition:getChildById("nextButton"):setEnabled(data.selectedLevel ~= maxlevel)
  spellDefinition:getChildById("prevButton"):setEnabled(data.selectedLevel > 1)

  spellDefinition:getChildById("level"):setText("Level: " .. data.selectedLevel .. "/" .. maxlevel)

  local meetRequirements = updateRequirementsPanel(spellDefinition, data.spells[data.selectedLevel])

  local upgradeSpellBtn = spellDefinition:getChildById("upgradeSpell")

  if data.currentLevel == 0 then
    upgradeSpellBtn:setText("Must buy")
    upgradeSpellBtn:disable()
    upgradeSpellBtn:setBorderColor("red")
    upgradeSpellBtn:setBorderWidth(1)

  elseif data.selectedLevel <= data.currentLevel or isPending(index, data.selectedLevel) then
    upgradeSpellBtn:setText("Learned")
    upgradeSpellBtn:disable()
    upgradeSpellBtn:setBorderColor("green")
    upgradeSpellBtn:setBorderWidth(1)

  elseif data.selectedLevel-1 == data.currentLevel and meetRequirements then
    upgradeSpellBtn:setText("Upgrade")
    upgradeSpellBtn:enable()
    upgradeSpellBtn:setBorderWidth(0)


  else
    upgradeSpellBtn:setText("Can't learn")
    upgradeSpellBtn:disable()
    upgradeSpellBtn:setBorderColor("red")
    upgradeSpellBtn:setBorderWidth(1)
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

--  if pendingCurrentPoints < spell.cost then
--    canLearn = false
--    spellDefinition:recursiveGetChildById("cost"):setColor("red")
--  else
--    spellDefinition:recursiveGetChildById("cost"):setColor("#888888")
--  end

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
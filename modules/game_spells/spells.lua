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

  addDummyData()
  addDummyData()
  addDummyData()
  addDummyData()
  addDummyData()
  addDummyData()
  addDummyData()

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

function loadSpells()
end

function addSpell()
end

function confirm()
  for index, array in pairs(pendingConfirm) do
    local spellDefinition = spellsList:getChildByIndex(index)
    local data = spellDefinition.data

    for k, level in pairs(array) do
      local req = data.requirements[level]
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
  local cost = spellDefinition.data.requirements[level].cost

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


function addDummyData()
  local data = { icon=1, currentLevel=1, selectedLevel=1,
    requirements={
      {
        name= "Light" .. #spellsList:getChildren(),
        words= "utevo lux",
        lvl= 8,
        mlvl= 0,
        cost= 30,
        mana= 20
      },{
        name= "Intense Light" .. #spellsList:getChildren(),
        words= "utevo gran lux",
        lvl= 10,
        mlvl= 2,
        cost= 40,
        mana= 30
      },{
        name= "Blinding Light" .. #spellsList:getChildren(),
        words= "utevo vis lux",
        lvl= 40,
        mlvl= 60,
        cost= 100,
        mana= 100
      },{
        name= "Conjure Explosive Arrow" .. #spellsList:getChildren(),
        words= "adevo mas grav flam",
        lvl= 40,
        mlvl= 60,
        cost= 100,
        mana= 100
      }
    }
  }

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

  local maxlevel = #data.requirements

  spellDefinition:getChildById("nextButton"):setEnabled(data.selectedLevel ~= maxlevel)
  spellDefinition:getChildById("prevButton"):setEnabled(data.selectedLevel > 1)

  spellDefinition:getChildById("level"):setText("Level: " .. data.selectedLevel .. "/" .. maxlevel)

  local meetRequirements = updateRequirementsPanel(spellDefinition, data.requirements[data.selectedLevel])

  local upgradeSpellBtn = spellDefinition:getChildById("upgradeSpell")

  if data.currentLevel == 0 then
    upgradeSpellBtn:setText("Must buy")
    upgradeSpellBtn:disable()

  elseif data.selectedLevel <= data.currentLevel or isPending(index, data.selectedLevel) then
    upgradeSpellBtn:setText("Learned")
    upgradeSpellBtn:disable()

  elseif data.selectedLevel-1 == data.currentLevel and meetRequirements then
    upgradeSpellBtn:setText("Upgrade")
    upgradeSpellBtn:enable()

  else
    upgradeSpellBtn:setText("Can't learn")
    upgradeSpellBtn:disable()
  end
end

function updateRequirementsPanel(spellDefinition, requirements)
  spellDefinition:recursiveGetChildById("levelRequired"):setText("Level required: " .. requirements.lvl)
  spellDefinition:recursiveGetChildById("magicLevelRequired"):setText("Magic Level required: " .. requirements.mlvl)
  spellDefinition:recursiveGetChildById("cost"):setText("Cost: " .. requirements.cost)

  spellDefinition:getChildById("spellName"):setText(requirements.name)
  spellDefinition:getChildById("spellWords"):setText(requirements.words)
  spellDefinition:getChildById("mana"):setText("Mana: " .. requirements.mana)

  local player = g_game.getLocalPlayer()
  if not player then return false end

  local canLearn = true
  if player:getLevel() < requirements.lvl then
    canLearn = false
    spellDefinition:recursiveGetChildById("levelRequired"):setColor("red")
  else
    spellDefinition:recursiveGetChildById("levelRequired"):setColor("#888888")
  end

  if player:getMagicLevel() < requirements.mlvl then
    canLearn = false
    spellDefinition:recursiveGetChildById("magicLevelRequired"):setColor("red")
  else
    spellDefinition:recursiveGetChildById("magicLevelRequired"):setColor("#888888")
  end

  if pendingCurrentPoints < requirements.cost then
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
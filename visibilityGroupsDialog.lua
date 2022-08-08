-- This script helps the artist to hide or show arbitrary groups of layers

if app.activeSprite == nil then
  print("Error: No active sprite")
  return
end
local spr = app.activeSprite

-- Global groups:
if visibilityGroups == nil then
  visibilityGroups = {}
  for i=1,10 , 1 do
    table.insert(visibilityGroups, {})
  end
end
if groupNames == nil then
  groupNames = {}
  for i=1,10 , 1 do
    table.insert(groupNames, {})
    groupNames[i] = "No name"
  end
end
local show = "O"
local hide = "-"
local buttonText = {show, show, show, show}
local dlg = Dialog("Visibility")
local radioIds = {"r1", "r2", "r3", "r4"}
local buttonIds = {"b1", "b2", "b3", "b4",}

function changeGroupName(index)
  dlg:modify{ id=radioIds[index],
              text=dlg.data.entry }
end

function setButtonText(index, showText)
  dlg:modify{ id=buttonIds[index],
              text=showText }
  buttonText[index] = showText
end

function buttonShowState(index)
  return buttonText[index] == show
end

-- Global last active visibility group
if activeVisibilityGroupIndex == nil then
  activeVisibilityGroupIndex = 1
end

-- 1
for k=1, 4, 1 do
  dlg:radio{ id=radioIds[k],
              text=groupNames[k],
              onclick=
                function()
                  local selectedLayers = app.range.layers
                  activeVisibilityGroupIndex = k
                  if #selectedLayers == 0 then
                    print("Error: no selected layers. You must select layers on the editor first.")
                    return
                  end
                  visibilityGroups[k] = selectedLayers
                  local group = visibilityGroups[k]
                  for i=1, #group, 1 do
                    group[i].isVisible = true
                  end
                  setButtonText(k, show)
                  app.refresh()
                end }
  dlg:button{ id=buttonIds[k],
              text=buttonText[k],
              onclick=
                function()
                  local group = visibilityGroups[k]
                  if group == nil then
                    print("Error: first you have to Set a Layer Group")
                    return
                  end
                  local groupStateShowed
                  if buttonText[k] == "O" then
                    groupStateShowed = true
                    buttonText[k] = hide
                  else
                    groupStateShowed = false
                    buttonText[k] = show
                  end
                  for i=1, #group, 1 do
                    if group[i] ~= nil then
                      group[i].isVisible = not groupStateShowed
                    end
                  end
                  setButtonText(k, buttonText[k])
                  app.refresh()
                end }
  dlg:newrow()
  dlg:separator()
end
dlg:entry{ id="entry",
           text="No Name",
           onchange=function()
             changeGroupName(activeVisibilityGroupIndex)
             app.refresh()
           end }
dlg:show{
  wait=false
}
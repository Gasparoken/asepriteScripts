function init(plugin)
  plugin.preferences.activeFormats = {true, false, false, false,
                                      true, false, false, false,
                                      false, false, false, false,
                                      false, false}
  plugin.preferences.formats = {"ase", "bmp", "flc", "fli",
                                "gif", "ico", "jpeg", "jpg",
                                "pcx", "pcc", "png", "svg",
                                "tga", "webp"}
  function saveCopies()
    local activeFormats = plugin.preferences.activeFormats
    local formats = plugin.preferences.formats
    local sprite = app.activeSprite
    if sprite == nil then
      app.alert("Error: there isn't an active sprite")
      return
    end
    local path = sprite.filename
    local isSaved = (string.find(path, "/") ~= nil or string.find(path, "\\") ~= nil)
    if isSaved then
      app.command.SaveFile {
        ui=false,
      }
    else
      app.command.SaveFileAs {
        ui=true,
      }
    end
    path = app.activeSprite.filename
    isSaved = (string.find(path, "/") ~= nil or string.find(path, "\\") ~= nil)
    if not(isSaved) then
      return
    end
    local filenameWithoutExt = path:match("(.+)%..+$")
    for i=1,#activeFormats, 1 do
      if activeFormats[i] then
        app.command.SaveFileCopyAs {
          ui=false,
          filename=filenameWithoutExt .. "." .. formats[i]
        }
      end
    end
  end
  --
  plugin:newCommand{
    id="defineFormats",
    title="Save +Copies...",
    group="file_save",
    onclick=function()
      local toggleStates = plugin.preferences.activeFormats
      local formats = plugin.preferences.formats
      local dlg = Dialog("Save +Copies formats")
      for i=1,#formats, 1 do
        dlg:check {
          id=formats[i],
          text="." .. formats[i],
          selected=toggleStates[i],
          onclick=function()
            toggleStates[i] = not toggleStates[i]
          end
        }
        if i%2 == 0 then
          dlg:newrow()
        end
      end
      dlg:button {
        id="save",
        text="Save",
        focus=true,
        onclick=function()
          plugin.preferences.activeFormats = toggleStates
          saveCopies()
          dlg:close()
        end
      }
      dlg:button {
        id="close",
        text="Close",
        onclick=function()
          plugin.preferences.activeFormats = toggleStates
          dlg:close()
        end
      }
      dlg:show()
    end
  }
  plugin:newCommand{
    id="SaveXtrCopies",
    title="Save +Copies",
    group="file_save",
    onclick=function()
      saveCopies()
    end
  }
end

function exit(plugin)
end
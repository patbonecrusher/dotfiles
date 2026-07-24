-- Hammerspoon config — managed by chezmoi (source: dot_hammerspoon/init.lua → ~/.hammerspoon/init.lua)
-- Requires Accessibility permission (System Settings → Privacy & Security → Accessibility).

-- Universal Control recovery ------------------------------------------------
-- The shared cursor sometimes crosses to the other Mac and gets trapped: you
-- can't drag it back because the keyboard/pointer now belong to the far Mac.
-- Press Ctrl+Alt+Cmd+U on whichever Mac holds the stuck cursor to restart the
-- UniversalControl daemon (it relaunches itself) and free it. Bind the SAME
-- hotkey on both Macs so it works no matter which one is trapped.
-- -9 (SIGKILL) is required: UniversalControl traps SIGTERM and survives a plain
-- kill. launchd relaunches it immediately, which frees the trapped cursor.
hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "U", function()
  hs.execute("killall -9 UniversalControl", true)
  hs.alert.show("↩︎ Universal Control reset")
end)

-- Force display to sleep now -------------------------------------------------
-- Ctrl+Alt+Cmd+S sleeps the display immediately, even when an app (e.g.
-- Factorio via SDL_DisableScreenSaver) holds a PreventUserIdleDisplaySleep
-- assertion that blocks the normal timeout / screen saver. `pmset` lives in
-- /usr/bin, which isn't on Hammerspoon's PATH, so call it by absolute path.
hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "S", function()
  hs.execute("/usr/bin/pmset displaysleepnow")
  hs.alert.show("󰤄 Display sleeping")
end)

-- Auto-reload this config whenever a .lua file here changes ------------------
hs.configWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", function(files)
  for _, f in ipairs(files) do
    if f:sub(-4) == ".lua" then
      hs.reload()
      return
    end
  end
end):start()

hs.alert.show("Hammerspoon config loaded")

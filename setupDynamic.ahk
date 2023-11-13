#Requires AutoHotkey v2.0
#Include utils.ahk
#Include toggleWnd.ahk

setupDynamic(entry) {
  if (!entry["enable"]) {
    return
  }
  for key in entry["key_list"] {
    _setupDynamicBinding(key, entry)
  }
}

_setupDynamicBinding(key, entry) {
  mainShortcut := entry["mod_main"] . key
  bindShortcut := entry["mod_main"] . entry["mod_bind"] . key
  id := false
  Hotkey(bindShortcut, (key) {
    id := WinGetID("A")
  })
  Hotkey(mainShortcut, (key) {
    if (id && WinExist(id)) {
      toggleWnd(id)
    }
  })
}
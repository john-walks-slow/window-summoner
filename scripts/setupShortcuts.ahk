#Include toggleWnd.ahk
#Include utils.ahk


setupShortcuts(shortcutConfig) {
  for entry in shortcutConfig {
    _setupShortcut(entry)
  }
}
_setupShortcut(entry) {
  global config
  if (entry["hotkey"] == "") {
    return
  }
  ; store the window Id in closure
  wndId := false
  ; Hotkey handler
  onPress(key) {
    ; If already waiting for an action to complete, return

    if (config["misc"]["reuseExistingWindow"]) {
      ; If wndId invalid, try to match another existing window
      if (!(wndId && WinExist(wndId)) && entry["wnd_title"] !== "") {
        try {
          wndId := WinGetID(entry["wnd_title"])
        }
      }
    }
    wndId := toggleWnd(wndId, entry)

  }
  MyHotkey(entry["hotkey"], onPress)
}
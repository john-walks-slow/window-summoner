#Include toggleWnd.ahk
#Include utils.ahk


setupShortcuts(shortcutConfig) {
  for entry in shortcutConfig {
    _setupShortcut(entry)
  }
}
_setupShortcut(entry) {
  global config
  global activatedWnd
  if (entry["hotkey"] == "") {
    return
  }
  ; store the window Id in closure
  wndId := false
  ; Hotkey handler
  onPress(key) {
    ; If already waiting for an action to complete, return
    static pending := false
    if (pending) {
      return
    }
    pending := true
    if (config["misc"]["reuseExistingWindow"]) {
      ; If wndId invalid, try to match another existing window
      if (!(wndId && WinExist(wndId)) && entry["wnd_title"] !== "") {
        try {
          wndId := WinGetID(entry["wnd_title"])
        }
      }
    }
    ; If window exists, toggle it
    if (wndId && WinExist(wndId)) {
      toggleWnd(wndId)
    }
    ; Otherwise, run the program && record the wndId
    else {
      Run(entry["run"])
      if (entry["wnd_title"] !== "") {
        wndId := WinWait(entry["wnd_title"])
      } else {
        currentWnd := WinGetLatest()
        while (WinGetLatest() == currentWnd) {
          Sleep(50)
        }
        wndId := WinGetLatest()
      }
      activatedWnd := wndId
    }
    pending := false
  }
  MyHotkey(entry["hotkey"], onPress)
}
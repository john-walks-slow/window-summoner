#Requires AutoHotkey v2.0
#Include toggleWnd.ahk

setupBinding(key, entry) {
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
    ; If wndId invalid, try to match another existing window
    if (!(wndId && WinExist(wndId)) && entry["wnd_title"] !== "") {
      try {
        wndId := WinGetID(entry["wnd_title"])
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
        Sleep 300
        wndId := WinGetID("A")
      }
    }
    pending := false
  }
  Hotkey(key, onPress)
}
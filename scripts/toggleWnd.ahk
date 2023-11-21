#Include utils.ahk

wndHandlers := Map()
lastActive := 0
activatedWnd := 0
; Toggle between hidden and shown
toggleWnd(id) {
  try {
    global wndHandlers
    global activatedWnd
    global lastActive
    idStr := String(id)
    isVisible := WinGetStyle(id) & 0x10000000
    if (isVisible && WinActive(id)) {
      _hide(id)
    } else {
      _show(id)
    }
    _hide(id) {
      WinHide(id)
      activatedWnd := 0
      try {
        if (lastActive) {
          WinActivate(lastActive)
        }
      }
      ; Handle exit, try to reuse handler
      if (wndHandlers.Get(idStr, false)) {
        exitHandler := wndHandlers[idStr]
      } else {
        ; id is remembered in closure
        exitHandler := (e, c) {
          try {
            WinShow(id)
            WinActivate(id)
          }
        }
        ; Keep a record of bound exitHandlers
        wndHandlers.Set(idStr, exitHandler)
      }
      OnExit(exitHandler, 1)
      OnError(exitHandler, 1)
    }
    _show(id) {
      WinShow(id)
      WinActivate(id)
      lastActive := 0
      if (config["misc"]["singleActiveWindow"]) {
        if (activatedWnd)
          _hide(activatedWnd)
      }
      lastActive := WinGetID("A")


      activatedWnd := id
      ; Remove exit handler
      if (wndHandlers.Get(idStr, false)) {
        OnExit(wndHandlers[idStr], 0)
        OnError(wndHandlers[idStr], 0)
      }
    }
  } catch Error as e {
    throwError("Unexpected error while toggling window", e)
  }

}

clearWndHandlers() {
  global wndHandlers
  global activatedWnd
  global lastActive
  activatedWnd := 0
  lastActive := 0
  for id, handler in wndHandlers {
    try {
      handler("", "")
      OnExit(handler, 0)
      OnError(handler, 0)
    }
  }
  wndHandlers := Map()
}
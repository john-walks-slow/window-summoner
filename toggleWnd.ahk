#Requires AutoHotkey v2.0
#Include utils.ahk

; Toggle between hidden && shown
toggleWnd(id) {
  try {
    idStr := String(id)
    static lastActive := false
    static handlers := Map()
    isVisible := WinGetStyle(id) & 0x10000000
    if (isVisible && WinActive(id)) {
      WinHide(id)
      try {
        if (lastActive) {
          WinActivate(lastActive)
        }
      }
      ; Handle exit, try to reuse handler
      if (handlers.Get(idStr, false)) {
        exitHandler := handlers[idStr]
      } else {
        ; id is remembered in closure
        exitHandler := (e, c) {
          try {
            WinShow(id)
            WinActivate(id)
          }
        }
        ; Keep a record of bound exitHandlers
        handlers.Set(idStr, exitHandler)
      }
      OnExit(exitHandler, 1)
      OnError(exitHandler, 1)
    } else {
      lastActive := WinGetID("A")
      WinShow(id)
      WinActivate(id)
      ; Remove exit handler
      if (handlers.Get(idStr, false)) {
        OnExit(handlers[idStr], 0)
        OnError(handlers[idStr], 0)
      }
    }
  } catch Error as e {
    throwError(e, "Unexpected error while toggling window")
  }
}
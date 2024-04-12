#Include utils.ahk
#Include ../app.ahk

; id - onExitHandlers
wndHandlers := Map()

; 活跃的已唤起窗口
activatedWnd := false

; Toggle between hidden and shown
toggleWnd(id, entry := unset) {
  static pending := false
  ; Prevent concurrent actions only if singleActiveWindow is on
  ; * Every hotkey is running on a separate thread, so we need to use a static variable to keep track of the state
  if (config["misc"]["singleActiveWindow"] && pending) {
    return id
  }
  pending := true
  global wndHandlers
  global activatedWnd
  global config
  ; Try to capture window
  if (!id || !WinExist(id)) {
    id := _capture()
  }
  oldActivatedWnd := activatedWnd
  if (!id) {
    ; If still not found, run the program
    id := _run()
    _hideActive(oldActivatedWnd)
  } else {
    ; Otherwise, toggle it
    if (!config["misc"]["minimizeInstead"]) {
      ; Hide / Show
      isVisible := WinGetStyle(id) & 0x10000000
      if (isVisible && WinActive(id)) {
        _hide(id, true, true)
      } else {
        _hideActive(oldActivatedWnd)
        _show(id)
      }
    } else {
      ; Minimize / Restore
      if (WinActive(id)) {
        _minimize(id, true)
      } else {
        _hideActive(oldActivatedWnd)
        _restore(id)
      }
    }
  }
  pending := false
  return id

  _capture() {
    ; Try to match existing window
    if (entry && config["misc"]["reuseExistingWindow"] && entry["wnd_title"] && WinExist(entry["wnd_title"])) {
      return WinGetID(entry["wnd_title"])
    }
  }
  _run() {
    if (entry && entry["run"] != "") {
      currentWnd := WinGetTop()
      currentTime := A_TickCount
      Run(entry["run"], , , &pid)
      TIMEOUT := entry["wnd_title"] ? 30000 : 5000
      INTERVAL := 100
      ; If not found, wait for a new window
      while (A_TickCount - currentTime < TIMEOUT) {
        newWnd := WinGetTop()
        ; We only care about new windows
        if (newWnd && newWnd != currentWnd) {
          ; If wnd_title is provided, match it
          if ((!entry["wnd_title"] && IsUserWindow(newWnd)) ||
            WinGetTitle(newWnd) ~= entry["wnd_title"]) {
              CallAsync(WinActivate, newWnd)
              activatedWnd := newWnd
              return newWnd
          }
        }
        Sleep(INTERVAL)
      }
    }
  }

  _hide(id, restoreLastFocus := false, clearActivatedWnd := false) {
    ; OutputDebug(WinGetTitle(id) "`n")
    try {
      if (restoreLastFocus) {
        if (config["misc"]["transitionAnim"]) {
          CallAsync(WinMinimize, id)
          Sleep(150)
        } else
          Send("!{Esc}")
      }
      CallAsync(WinHide, id)
      if (clearActivatedWnd)
        activatedWnd := false
    }
    addWndHandler(id)
  }

  _show(id) {
    try {
      CallAsync(WinShow, id)
      Sleep(50)
      CallAsync(WinActivate, id)
      activatedWnd := id
    }
  }
  _minimize(id, clearActivatedWnd := false) {
    try {
      CallAsync(WinMinimize, id)
      if (clearActivatedWnd)
        activatedWnd := false
    }
  }
  _restore(id) {
    try {
      if (WinGetMinMax(id) == -1)
        CallAsync(WinRestore, id)
      CallAsync(WinActivate, id)
      activatedWnd := id
    }
  }
  _hideActive(target := activatedWnd) {
    if (config["misc"]["singleActiveWindow"] && target) {
      if (!config["misc"]["minimizeInstead"])
        _hide(target, false, false)
      else
        _minimize(target)
    }
  }
}

addWndHandler(id) {
  global wndHandlers
  ; Handle exit, try to reuse handler
  if (!wndHandlers.Has(String(id))) {
    ; id is remembered in closure
    exitHandler := (e, c) {
      try {
        isVisible := WinGetStyle(id) & 0x10000000
        if (!isVisible) {
          WinMinimize(id)
          WinShow(id)
        }
      }
    }
    ; Keep a record of bound exitHandlers
    wndHandlers.Set(String(id), exitHandler)
    OnExit(exitHandler, 1)
    OnError(exitHandler, 1)
  }
}
clearWndHandlers() {
  global wndHandlers
  global activatedWnd

  activatedWnd := false
  for id, handler in wndHandlers {
    try {
      OnExit(handler, 0)
      OnError(handler, 0)
      handler("", "")
    }
  }
  wndHandlers := Map()
}

popWndHandler(id) {
  if (wndHandlers.Has(String(id))) {
    handler := wndHandlers.Get(String(id))
    try {
      OnExit(handler, 0)
      OnError(handler, 0)
      handler("", "")
    }
  }
}
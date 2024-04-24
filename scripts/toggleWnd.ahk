#Include utils.ahk
#Include ../app.ahk

; id - onExitHandlers
wndHandlers := Map()

; 活跃的已唤起窗口
activatedWnd := false

; Toggle between hidden and shown
toggleWnd(id, entry := unset) {
  static pending := false
  static running := false
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
    running := false
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
    target := false
    if (entry && config["misc"]["reuseExistingWindow"]) {
      switch (entry["capture"]["mode"]) {
        case 2:
          try {
            target := WinGetUser(".+" " ahk_exe " entry["capture"]["process"])
          } catch Error as e {
            target := false
          }
        case 3:
          try {
            target := WinGetUser(entry["capture"]["title"] " ahk_exe " entry["capture"]["process"], false, false, false)
          } catch Error as e {
            target := false
          }
        default:
          target := false
      }
    }
    return target
  }
  _run() {
    if (running)
      return id
    running := true
    if (entry && entry["run"] != "") {
      currentTime := A_TickCount
      TIMEOUT := entry["capture"]["mode"] == 1 ? 5000 : 20000
      INTERVAL := 50
      Run(entry["run"], , , &pid)
      winTitle := ".+"
      ignoreMiscWindows := true
      switch (entry["capture"]["mode"]) {
        case 2:
          winTitle := ".+" " ahk_exe " entry["capture"]["process"]
        case 3:
          winTitle := entry["capture"]["title"] " ahk_exe " entry["capture"]["process"]
          ignoreMiscWindows := false
      }
      if (config["misc"]["alternativeCapture"]) {
        ; 旧方案：捕捉出现在上方的第一个有标题、非置顶新窗口
        currentWnd := WinGetUser(winTitle, ignoreMiscWindows, ignoreMiscWindows, ignoreMiscWindows)
        while (A_TickCount - currentTime < TIMEOUT) {
          newWnd := WinGetUser(winTitle, ignoreMiscWindows, ignoreMiscWindows, ignoreMiscWindows)
          if (newWnd && newWnd != currentWnd) {
            CallAsync(WinActivate, newWnd)
            activatedWnd := newWnd
            return newWnd
          }
          Sleep(INTERVAL)
        }
      } else {
        ;; 新方案：获取窗口列表，对比差异。
        ;; pro：如果程序没有启动到最上方，也能找到。
        ;; pro：启动过程中焦点改变，也能找到。
        currentWndList := WinGetUserList(winTitle, ignoreMiscWindows, ignoreMiscWindows, ignoreMiscWindows)
        while (A_TickCount - currentTime < TIMEOUT) {
          newWndList := WinGetUserList(winTitle, ignoreMiscWindows, ignoreMiscWindows, ignoreMiscWindows)
          ; if (newWndList.Length == currentWndList.Length) {
          ;   continue
          ; }
          ; if (newWndList.Length < currentWndList.Length) {
          ;   currentWndList := newWndList
          ;   continue
          ; }
          for (i, newWnd in newWndList) {
            if (currentWndList.IndexOf(newWnd) == 0) {
              CallAsync(WinActivate, newWnd)
              activatedWnd := newWnd
              return newWnd
            }
          }
          Sleep(INTERVAL)
        }
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
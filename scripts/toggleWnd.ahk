#Include utils.ahk

; id - onExitHandlers
wndHandlers := Map()

; 上一个活跃的非唤起窗口
lastUserWnd := 0

; 活跃的已唤起窗口
activatedWnds := []

; 暂时禁用，对性能的影响待观察
updateLastActive() {
  global activatedWnds
  global lastUserWnd
  if (activatedWnds) {
    try {
      currentWnd := WinGetID("A")
      if (!hasVal(activatedWnds, currentWnd)) {
        lastUserWnd := currentWnd
      }
    }
  }
}
startTimer() {
  ; SetTimer(updateLastActive, 500)
}
stopTimer() {
  ; SetTimer(updateLastActive, 0)
}


; Toggle between hidden and shown
toggleWnd(id, entry := unset) {
  static pending := false
  ; if (pending) {
  ;   return id
  ; }
  pending := true
  global wndHandlers
  global activatedWnds
  global lastUserWnd

  ; Id valid
  if (id && WinExist(id)) {
    if (!config["misc"]["minimizeInstead"]) {
      ; Hide / Show
      isVisible := WinGetStyle(id) & 0x10000000
      if (isVisible && WinActive(id)) {
        _hide(id)
      } else {
        _show(id)
      }
    } else {
      ; Minimize / Restore
      if (WinActive(id)) {
        _minimize(id)
      } else {
        _restore(id)
      }
    }
  }
  ; Id invalid & entry provided
  else if (IsSet(entry)) {
    if (config["misc"]["singleActiveWindow"] && activatedWnds.Length > 0) {
      if (!config["misc"]["minimizeInstead"])
        ; 默认 activatedWnds 长度为1
        _hide(activatedWnds[1], false)
      else
        _minimize(activatedWnds[1])
    }
    _run()
  }

  _run() {
    Run(entry["run"])
    ; Retrieve id
    if (entry["wnd_title"] !== "") {
      id := WinWait(entry["wnd_title"])
    } else {
      currentWnd := WinGetLatest()
      while (WinGetLatest() == currentWnd) {
        Sleep(50)
      }
      id := WinGetLatest()
    }
    ; Update activatedWnds
    if (id) {
      activatedWnds.push(id)
    }
  }

  _hide(id, restoreLastActive := true) {
    ; Delete from activatedWnds anyway
    deleteVal(activatedWnds, id)
    try {
      WinHide(id)
    }
    ; Restore focus
    if (restoreLastActive) {
      try {
        isActivated := false
        while (activatedWnds.Length > 0) {
          lastActivatedWnd := activatedWnds.Pop()
          if (lastActivatedWnd && lastActivatedWnd !== id && WinExist(lastActivatedWnd)) {
            WinActivate(lastActivatedWnd)
            isActivated := true
            break
          }
        }
        if (!isActivated && lastUserWnd)
          WinActivate(lastUserWnd)
      }
    }
    ; Handle exit, try to reuse handler
    if (!wndHandlers.Has(String(id))) {
      ; id is remembered in closure
      exitHandler := (e, c) {
        try {
          isVisible := WinGetStyle(id) & 0x10000000
          if (!isVisible) {
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

  _show(id) {
    ; If succeed, push to the end of activatedWnd
    deleteVal(activatedWnds, id)
    activatedWnds.Push(id)

    ; Update lastUserWnd
    try {
      currentWnd := WinGetID("A")
      if (!hasVal(activatedWnds, currentWnd)) {
        lastUserWnd := currentWnd
      }
    }
    ; Hide other active windows
    if (config["misc"]["singleActiveWindow"] && activatedWnds.Length > 0 && activatedWnds[1] !== id) {
      _hide(activatedWnds[1], false)
    }
    try {
      WinShow(id)
      WinActivate(id)

    }
  }
  _minimize(id) {
    try {
      deleteVal(activatedWnds, id)
      WinMinimize(id)
    }
  }
  _restore(id) {
    try {
      if (config["misc"]["singleActiveWindow"]) {
        if (activatedWnds.Has(1) && activatedWnds[1] !== id) {
          _minimize(activatedWnds[1])
        }
      }
    }
    try {
      activatedWnds := [id]
      if (WinGetMinMax(id) == -1)
        WinRestore(id)
      WinActivate(id)
    }
  }
  pending := false
  return id
}
clearWndHandlers() {
  global wndHandlers
  global activatedWnds
  global lastUserWnd
  activatedWnds := []
  lastUserWnd := 0
  for id, handler in wndHandlers {
    try {
      OnExit(handler, 0)
      OnError(handler, 0)
      handler("", "")
    }
  }
  wndHandlers := Map()
}
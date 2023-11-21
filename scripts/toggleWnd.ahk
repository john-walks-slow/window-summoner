#Include utils.ahk

wndHandlers := Map()
lastActive := 0
activatedWnd := 0

timerCallback() {
  global activatedWnd
  global lastActive
  if (activatedWnd) {
    try {
      currentWnd := WinGetID("A")
      if (activatedWnd !== currentWnd) {
        lastActive := currentWnd
      }
    }
  }
}
startTimer() {
  SetTimer(timerCallback, 500)
}
stopTimer() {
  SetTimer(timerCallback, 0)
}


; Toggle between hidden and shown
toggleWnd(id, entry := unset) {
  global wndHandlers
  global activatedWnd
  global lastActive
  if (id && WinExist(id)) {
    isVisible := WinGetStyle(id) & 0x10000000
    if (isVisible && WinActive(id)) {
      _hide(id)
    } else {
      _show(id)
    }
  }
  else if (IsSet(entry)) {
    if (activatedWnd) {
      _hide(activatedWnd)
    }
    Run(entry["run"])
    if (entry["wnd_title"] !== "") {
      id := WinWait(entry["wnd_title"])
    } else {
      currentWnd := WinGetLatest()
      while (WinGetLatest() == currentWnd) {
        Sleep(50)
      }
      id := WinGetLatest()
    }
    activatedWnd := id
  }
  _hide(id, restoreLastActive := true) {
    try {
      WinHide(id)
    }
    activatedWnd := 0
    try {
      if (restoreLastActive && lastActive) {
        WinActivate(lastActive)
      }
    }
    lastActive := lastActive
    ; Handle exit, try to reuse handler
    if (wndHandlers.Get(String(id), false)) {
      exitHandler := wndHandlers[String(id)]
    } else {
      ; id is remembered in closure
      exitHandler := (e, c) {
        try {
          WinShow(id)
          WinActivate(id)
        }
      }
      ; Keep a record of bound exitHandlers
      wndHandlers.Set(String(id), exitHandler)
    }
    OnExit(exitHandler, 1)
    OnError(exitHandler, 1)
  }
  _show(id) {
    lastlastActive := lastActive
    lastActive := WinGetID("A")
    WinShow(id)
    WinActivate(id)
    if (config["misc"]["singleActiveWindow"]) {
      if (activatedWnd && activatedWnd !== id) {
        _hide(activatedWnd, false)
        lastActive := lastlastActive
      }
    }


    activatedWnd := id
    ; Remove exit handler
    if (wndHandlers.Get(String(id), false)) {
      OnExit(wndHandlers[String(id)], 0)
      OnError(wndHandlers[String(id)], 0)
    }
  }

  return id
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
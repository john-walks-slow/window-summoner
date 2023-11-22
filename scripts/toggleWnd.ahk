#Include utils.ahk

wndHandlers := Map()
lastActive := 0
activatedWnds := []

timerCallback() {
  global activatedWnds
  global lastActive
  if (activatedWnds) {
    try {
      currentWnd := WinGetID("A")
      if (!hasVal(activatedWnds, currentWnd)) {
        lastActive := currentWnd
      }
    }
  }
}
startTimer() {
  ; SetTimer(timerCallback, 500)
}
stopTimer() {
  ; SetTimer(timerCallback, 0)
}


; Toggle between hidden and shown
toggleWnd(id, entry := unset) {
  global wndHandlers
  global activatedWnds
  global lastActive
  if (id && WinExist(id)) {
    if (!config["misc"]["minimizeInstead"]) {
      isVisible := WinGetStyle(id) & 0x10000000
      if (isVisible && WinActive(id)) {
        _hide(id)
      } else {
        _show(id)
      }
    } else {
      if (WinActive(id)) {
        _minimize(id)
      } else {
        _restore(id)
      }
    }
  }
  else if (IsSet(entry)) {
    if (config["misc"]["singleActiveWindow"] && activatedWnds.Length > 0) {
      if (!config["misc"]["minimizeInstead"])
        _hide(activatedWnds[1], false)
      else
        _minimize(activatedWnds[1])
    }
    _run(id, entry)
  }
  _run(id, entry) {

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
    activatedWnds.push(id)
  }
  _hide(id, restoreLastActive := true) {
    try {
      WinHide(id)
      deleteVal(activatedWnds, id)
      try {
        if (restoreLastActive) {
          if (activatedWnds.Length > 0) {
            WinActivate(activatedWnds[1])
          }
          else if (lastActive)
            WinActivate(lastActive)
        }
      }

      ; Handle exit, try to reuse handler
      if (wndHandlers.Get(String(id), false)) {
        exitHandler := wndHandlers[String(id)]
      } else {
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
      }
      OnExit(exitHandler, 1)
      OnError(exitHandler, 1)
    }
  }
  _show(id) {
    try {
      try {
        currentWnd := WinGetID("A")
        if (!hasVal(activatedWnds, currentWnd)) {
          lastActive := currentWnd
        }
      }
      if (config["misc"]["singleActiveWindow"] && activatedWnds.Length > 0 && activatedWnds[1] !== id) {
        _hide(activatedWnds[1], false)
      }
      WinShow(id)
      WinActivate(id)

      pushDedupe(activatedWnds, id)
      ; Remove exit handler
      if (wndHandlers.Get(String(id), false)) {
        OnExit(wndHandlers[String(id)], 0)
        OnError(wndHandlers[String(id)], 0)
      }
    }
  }
  _minimize(id) {
    try {
      WinMinimize(id)
      if (config["misc"]["singleActiveWindow"]) {
        deleteVal(activatedWnds, id)
      }
    }
  }
  _restore(id) {
    try {
      ; lastActive := WinGetID("A")
      if (config["misc"]["singleActiveWindow"]) {
        if (activatedWnds.Has(1)) {
          if (activatedWnds[1] !== id) {
            _minimize(activatedWnds[1])
          }
        }
      }
    }
    try {
      if (WinGetMinMax(id) == -1)
        WinRestore(id)
      WinActivate(id)
      activatedWnds := [id]
    }
  }
  return id
}
clearWndHandlers() {
  global wndHandlers
  global activatedWnds
  global lastActive
  activatedWnds := []
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
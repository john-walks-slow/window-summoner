global currentWorkspace, workspaces

clearWorkspace()
clearWorkspace() {
  global currentWorkspace, workspaces
  currentWorkspace := "默认"
  workspaces := UMap("默认", [])
}

setupWorkspace(workspaceConfig) {
  global currentWorkspace, workspaces
  if (!workspaceConfig["enable"]) {
    return
  }
  for suffix in workspaceConfig["suffixs"] {
    _setupWorkspace(suffix, workspaceConfig)
  }
  _setupWorkspace(suffix, workspaceConfig) {
    switchShortcut := joinStrs(workspaceConfig["mod"]) . suffix
    workspaces.Set(suffix, { list: [], active: false })
    MyHotkey(switchShortcut, (key) {
      _switchToWorkspace(suffix)
    })
  }

  _switchToWorkspace(targetWorkspace) {

    if (targetWorkspace == currentWorkspace) {
      targetWorkspace := "默认"
    }
    if (workspaceConfig["showTip"])
      TimedTip("工作区: " targetWorkspace)

    global currentWorkspace
    global workspaces
    current := workspaces[currentWorkspace]
    target := workspaces[targetWorkspace]
    DetectHiddenWindows(false)
    current.list := WinGetUserList()
    DetectHiddenWindows(true)
    current.active := WinGetActiveID()
    for (wnd in current.list) {
      ; OutputDebug(wnd " | " WinGetClass(wnd) " | " WinGetTitle(wnd) "`n")
      CallAsync(WinHide, wnd)
      addWndHandler(wnd)
    }
    loop (target.list.Length) {
      ; wnd := target.list[A_Index]
      wnd := target.list[target.list.Length - A_Index + 1]
      CallAsync(WinShow, wnd)
    }
    Sleep(100)
    (target.active) && CallAsync(WinActivate, target.active)
    currentWorkspace := targetWorkspace
  }
}
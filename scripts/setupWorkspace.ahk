#Include toggleWnd.ahk

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
    workspaces.Set(suffix, [])
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
    DetectHiddenWindows(false)
    workspaces[currentWorkspace] := WinGetList(, , "\A\Z").Filter((wnd) =>
      ["DV2ControlHost", "TopLevelWindowForOverflowXamlIsland", "SysShadow", "Shell_TrayWnd", "IME", "NarratorHelperWindow", "tooltips_class32", "Progman", "MSCTFIME UI"].IndexOf(WinGetClass(wnd)) == 0)
    DetectHiddenWindows(true)
    for (wnd in workspaces[currentWorkspace]) {
      OutputDebug(wnd " | " WinGetClass(wnd) " | " WinGetTitle(wnd) "`n")
      NewThread("try{`nWinHide(" wnd ")`n}")
      addWndHandler(wnd)
    }
    loop (workspaces[targetWorkspace].Length) {
      wnd := workspaces[targetWorkspace][workspaces[targetWorkspace].Length - A_Index + 1]
      NewThread("try{`nWinShow(" wnd ")`n}")
    }
    currentWorkspace := targetWorkspace
  }
}
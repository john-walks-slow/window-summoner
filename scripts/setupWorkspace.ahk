global currentWorkspace, workspaces

clearWorkspace()
clearWorkspace() {
  global currentWorkspace, workspaces
  currentWorkspace := "默认"
  workspaces := UMap("默认", { list: [], active: false })
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
      _switchToWorkspace(suffix, workspaceConfig["fullRestore"])
    })
  }

  _switchToWorkspace(targetWorkspace, fullRestore := 0) {

    if (targetWorkspace == currentWorkspace) {
      targetWorkspace := "默认"
    }
    if (workspaceConfig["showTip"])
      TimedTip("工作区: " targetWorkspace)

    global currentWorkspace
    global workspaces
    current := workspaces[currentWorkspace]
    target := workspaces[targetWorkspace]

    switch fullRestore {
      case 0:
        current.list := WinGetUserList()
        current.active := WinGetActiveID()
        currentDiff := current.list.Clone()
        targetDiff := target.list.Clone()

        loop (target.list.Length) {
          targetI := target.list.Length - A_Index + 1
          targetWnd := target.list[targetI]
          currentI := current.list.IndexOf(targetWnd)
          if (currentI > 0) {
            currentDiff.Delete(currentI)
            targetDiff.Delete(targetI)
            continue
          }
          CallAsync(WinShow, targetWnd)

          if (fullRestore)
            Sleep(10)
        }
        if (target.active) {
          CallAsync(WinActivate, target.active)
        }
        for (targetWnd in currentDiff) {
          try {
            CallAsync(WinHide, targetWnd)
          }
        }
        ; Other sideeffects
        for (targetWnd in currentDiff) {
          try {
            addWndHandler(targetWnd)
            addHiddenSubmenu(targetWnd)
          }
        }
        for (targetWnd in targetDiff) {
          try {
            removeHiddenSubmenu(targetWnd)
          }
        }

      case 1:
        current.list := WinGetUserList().Map((id) {
          WinGetPos(&x, &y, &w, &h, id)
          return { id: id, x: x, y: y, w: w, h: h, minMax: WinGetMinMax(id) }
        })
        current.active := WinGetActiveID()
        currentDiff := current.list.Clone()
        targetDiff := target.list.Clone()
        currentOverlap := []
        loop (current.list.Length) {
          currentI := A_Index
          currentWnd := current.list[currentI]
          targetI := target.list.FindIndex((w) => w.id == currentWnd.id)
          if (!targetI) {
            try {
              CallAsync(WinHide, currentWnd.id)
            }
          } else {
            currentOverlap.Push(currentWnd)
            currentDiff.Delete(currentI)
            targetDiff.Delete(targetI)
          }
        }
        loop (target.list.Length) {
          ; targetI := target.list.Length - A_Index + 1
          targetI := A_Index
          targetWnd := target.list[targetI]
          currentI := currentOverlap.FindIndex((w) => w.id == targetWnd.id)
          skipMove := 0
          skipMinMax := 0
          skipShow := 0
          if (currentI) {
            currentWnd := currentOverlap[currentI]
            skipShow := 1
            skipMove := currentWnd.x == targetWnd.x && currentWnd.y == targetWnd.y && currentWnd.w == targetWnd.w && currentWnd.h == targetWnd.h
            skipMinMax := currentWnd.minMax == targetWnd.minMax
          }
          if targetWnd.minMax != 0
            skipMove := 1
          ; if (targetWnd.id != current.active)
          ; CallAsync(WinSetTransparent, 100, targetWnd.id)

          ; winSetMinMax includes winShow
          if !skipMinMax
            skipShow := 1
          if !skipMinMax
            CallAsync(WinSetMinMax, targetWnd.id, targetWnd.minMax)
          if !skipMove
            CallAsync(WinMove, targetWnd.x, targetWnd.y, targetWnd.w, targetWnd.h, targetWnd.id)
          if !skipShow
            CallAsync(WinShow, targetWnd.id)

          ; if (target.active == targetWnd.id)
          ; CallAsync(WinMoveTop, targetWnd.id)
          ; Sleep(1)
          ; CallAsync(WinMoveBottom, targetWnd.id)
        }
        if target.active {
          CallAsync(WinMoveTop, target.active)
          CallAsync(WinActivate, target.active)

        }


        ; Other sideeffects
        for (currentWnd in currentDiff) {
          try {
            addWndHandler(currentWnd.id)
            addHiddenSubmenu(currentWnd.id)
          }
        }
        for (targetWnd in targetDiff) {
          try {
            removeHiddenSubmenu(targetWnd.id)
          }
        }

        ; current.list := WinGetUserList().Map((id) {
        ;   WinGetPos(&x, &y, &w, &h, id)
        ;   return { id: id, x: x, y: y, w: w, h: h, minMax: WinGetMinMax(id) }
        ; })
        ; current.active := WinGetActiveID()
        ; currentDiff := current.list.Clone()
        ; targetDiff := target.list.Clone()

        ; loop (target.list.Length) {
        ;   targetI := target.list.Length - A_Index + 1
        ;   targetI := A_Index
        ;   targetWnd := target.list[targetI]
        ;   currentI := current.list.FindIndex((w) => w.id == targetWnd.id)
        ;   skipMove := 0
        ;   skipMinMax := 0
        ;   skipShow := 0
        ;   if (currentI > 0) {
        ;     currentWnd := current.list[currentI]
        ;     currentDiff.Delete(currentI)
        ;     targetDiff.Delete(targetI)
        ;     skipShow := 1
        ;     skipMove := currentWnd.x == targetWnd.x && currentWnd.y == targetWnd.y && currentWnd.w == targetWnd.w && currentWnd.h == targetWnd.h
        ;     skipMinMax := currentWnd.minMax == targetWnd.minMax
        ;   }
        ;   if targetWnd.minMax != 0
        ;     skipMove := 1
        ;   ; if (targetWnd.id != current.active)
        ;   ; CallAsync(WinSetTransparent, 100, targetWnd.id)

        ;   ; winSetMinMax includes winShow
        ;   if !skipMinMax
        ;     skipShow := 1
        ;   if !skipMinMax
        ;     CallAsync(WinSetMinMax, targetWnd.id, targetWnd.minMax)
        ;   if !skipMove
        ;     CallAsync(WinMove, targetWnd.x, targetWnd.y, targetWnd.w, targetWnd.h, targetWnd.id)
        ;   if !skipShow
        ;     CallAsync(WinShow, targetWnd.id)

        ;   ; if (target.active == targetWnd.id)
        ;   ; CallAsync(WinMoveTop, targetWnd.id)
        ;   ; Sleep(1)
        ;   ; CallAsync(WinMoveBottom, targetWnd.id)
        ; }
        ; if target.active {
        ;   CallAsync(WinMoveTop, target.active)
        ;   CallAsync(WinActivate, target.active)

        ; }

        ; for (currentWnd in current.list) {
        ;   try {
        ;     CallAsync(WinHide, currentWnd.id)
        ;   }
        ; }
        ; ; Other sideeffects
        ; for (currentWnd in currentDiff) {
        ;   try {
        ;     addWndHandler(currentWnd.id)
        ;     addHiddenSubmenu(currentWnd.id)
        ;   }
        ; }
        ; for (targetWnd in targetDiff) {
        ;   try {
        ;     removeHiddenSubmenu(targetWnd.id)
        ;   }
        ; }

    }


    currentWorkspace := targetWorkspace
  }

}
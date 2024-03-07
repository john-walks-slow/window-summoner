#Include utils.ahk
#Include toggleWnd.ahk

setupDynamic(dynamicConfig) {
  if (!dynamicConfig["enable"]) {
    return
  }
  for suffix in dynamicConfig["suffixs"] {
    _setupDynamicBinding(suffix, dynamicConfig)
  }
}

_setupDynamicBinding(suffix, dynamicConfig) {
  mainShortcut := JoinStrs(dynamicConfig["mod_main"]) . suffix
  bindShortcut := JoinStrs(dynamicConfig["mod_bind"]) . suffix
  id := false
  MyHotkey(bindShortcut, (suffix) {
    try {
      oldId := id
      id := WinGetActiveID()
    }
    if (dynamicConfig["showTip"])
      TimedTip("绑定 " FormatHotkeyShorthand(mainShortcut) " 至 " WinGetTitle(id) || WinGetClass(id))
    if (oldId) {
      popWndHandler(oldId)
      WinActivate(id)
    }
  })
  MyHotkey(mainShortcut, (key) {
    if (id && WinExist(id)) {
      toggleWnd(id)
    }
  })
}
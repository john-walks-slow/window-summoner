#Include utils.ahk
#Include toggleWnd.ahk

setupDynamic(dynamicConfig) {
  if (!dynamicConfig["enable"]) {
    return
  }
  for key in dynamicConfig["suffixs"] {
    _setupDynamicBinding(key, dynamicConfig)
  }
}

_setupDynamicBinding(key, dynamicConfig) {
  mainShortcut := joinStrs(dynamicConfig["mod_main"]) . key
  bindShortcut := joinStrs(dynamicConfig["mod_bind"]) . key
  id := false
  MyHotkey(bindShortcut, (key) {
    try {
      id := WinGetID("A")
    }
  })
  MyHotkey(mainShortcut, (key) {
    if (id && WinExist(id)) {
      toggleWnd(id)
    }
  })
}
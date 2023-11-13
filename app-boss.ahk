#Requires AutoHotkey v2.0

; Setup ahk
DetectHiddenWindows(true)
SetTitleMatchMode("RegEx")

; Load config
config := FileRead(A_ScriptDir "\config.txt", "UTF-8")

; Setup dynamic shortcuts
RegExMatch(config, "\[dynamic\]\R(((?!\[).*\R?)*)", &dynamicMatch)
dynamicStrs := StrSplit(dynamicMatch[1], "`n")
dynamicConfig := Map("enable", "true", "mod_main", "#", "mod_bind", "+", "key_list", "-")
for entry in dynamicStrs {
  configureDynamic(entry)
}
setupDynamic()

; Setup bindings
RegExMatch(config, "\[bindings\]\R(((?!\[).*\R?)*)", &bindingMatch)
bindingStrs := StrSplit(bindingMatch[1], "`n")
for entry in bindingStrs {
  setupBinding(entry)
}

setupBinding(bindingEntry) {
  ; Match line with config scheme
  RegExMatch(bindingEntry, "^(\S*),\s*(.*?)(?:,\s*(.*))?$", &match)
  ; If not valid, return
  try {
    if (match[1] == "" or match[2] == "") {
      return
    }
  } catch {
    return
  }

  ; id is inside closure so handler remembers it
  id := false

  ; Hotkey handler
  onPress(key) {
    ; If already waiting for an action to complete, return
    static pending := false
    if (pending) {
      return
    }
    pending := true
    ; If id invalid, try to match an existing window
    if (!(id && WinExist(id)) && match[3] !== "") {
      try {
        id := WinGetID(match[3])
      }
    }
    ; If window exists, toggle it
    if (id && WinExist(id)) {
      toggleWnd(id)
    }
    ; Otherwise, run it && record the id
    else {
      Run(match[2])
      if (match[3] !== "") {
        id := WinWait(match[3])
      } else {
        Sleep 300
        id := WinGetID("A")
      }
    }
    pending := false
  }
  Hotkey(match[1], onPress)
}

; Toggle between hidden && shown
toggleWnd(id) {
  idStr := String(id)
  static lastActive := false
  static handlers := Map()
  isVisible := WinGetStyle(id) & 0x10000000
  if (isVisible && WinActive(id)) {
    WinHide(id)
    try {
      if (lastActive) {
        WinActivate(lastActive)
      }
    }
    ; Handle exit, try to reuse handler
    if (handlers.Get(idStr, false)) {
      exitHandler := handlers[idStr]
    } else {
      ; id is remembered in closure
      exitHandler := (e, c) {
        try {
          WinShow(id)
          WinActivate(id)
        }
      }
      ; Keep a record of bound exitHandlers
      handlers.Set(idStr, exitHandler)
    }
    OnExit(exitHandler, 1)
    OnError(exitHandler, 1)
  } else {
    lastActive := WinGetID("A")
    WinShow(id)
    WinActivate(id)
    ; Remove exit handler
    if (handlers.Get(idStr, false)) {
      OnExit(handlers[idStr], 0)
      OnError(handlers[idStr], 0)
    }
  }
}

configureDynamic(entry) {
  global dynamicConfig
  RegExMatch(entry, "^([a-zA-Z_]*):\s*(\S*)$", &configMatch)
  ; If not valid, return
  try {
    configMatch[1]
    configMatch[2]
    dynamicConfig.Set(configMatch[1], configMatch[2])
  }
}

setupDynamic() {
  global dynamicConfig
  if (dynamicConfig["enable"] !== "true") {
    return
  }
  keys := []
  matched := 1
  while (true) {
    matched := RegExMatch(dynamicConfig["key_list"], "((?<!{)[^{}](?!})|{\S*})", &keyMatch, matched)
    if (matched == 0) {
      break
    } else {
      keys.Push(keyMatch[1])
      matched += StrLen(keyMatch[1])
    }

  }
  for key in keys {
    setupDynamicShortcut(key)
  }
}

setupDynamicShortcut(key) {
  global dynamicConfig
  mainShortcut := dynamicConfig["mod_main"] . key
  bindShortcut := dynamicConfig["mod_main"] . dynamicConfig["mod_bind"] . key
  id := false
  Hotkey(bindShortcut, (key) {
    id := WinGetID("A")
  })
  Hotkey(mainShortcut, (key) {
    if (id && WinExist(id)) {
      toggleWnd(id)
    }
  })
}
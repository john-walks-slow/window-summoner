#Include toggleWnd.ahk
#Include utils.ahk


setupShortcuts(shortcutConfig) {
  for entry in shortcutConfig {
    _setupShortcut(entry)
  }
}
_setupShortcut(entry) {
  global config
  if (entry["hotkey"] == "") {
    return
  }
  ; store the window Id in closure
  wndId := false
  ; Hotkey handler
  onPress(key) {
    wndId := toggleWnd(wndId, entry)
  }
  MyHotkey(entry["hotkey"], onPress)
}

/* setupShortcuts(shortcutConfig) {
  entriesByHotkey := Map()
  for entry in shortcutConfig {
    if (entry["hotkey"] == "") {
      continue
    }
    if (entriesByHotkey.Has(entry["hotkey"])) {
      entriesByHotkey[entry["hotkey"]].Push(entry)
    } else {
      entriesByHotkey[entry["hotkey"]] := [entry]
    }
  }
  for hotkey, entries in entriesByHotkey {
    _setupShortcut(entries)
  }
}
_setupShortcut(entries) {
  global config
  ; store the window Id in closure
  wndIds := entries.Map(entry => false)
  ; Hotkey handler
  onPress(key) {
    entries.Map((entry, i) {
      wndIds[i] := toggleWnd(wndIds[i], entry)
    })
  }
  MyHotkey(entries[1]["hotkey"], onPress)
} */

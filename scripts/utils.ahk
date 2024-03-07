ThrowError(title, e?) {
  if (!A_IsCompiled) {
    if (IsSet(e)) {
      throw e
    } else {
      MsgBox(title, "Unexpected Error")
    }
  } else {
    ; if (IsSet(e)) {
    ;   MsgBox(e.Message, title)
    ; } else {
    ;   MsgBox(title, "Unexpected Error")
    ; }
  }
  ; ExitApp()
}

RegExMatchAll(str, regex, isGroup := true) {
  matches := []
  matchedIndex := 1
  while (true) {
    matchedIndex := RegExMatch(str, regex, &keyMatch, matchedIndex)
    if (matchedIndex == 0) {
      break
    } else {
      matches.Push(isGroup ? keyMatch : keyMatch[0])
      matchedIndex += keyMatch.Len()
    }
  }
  return matches
}


HasVal(array, val) {
  return array.IndexOf(val) ? 1 : 0
}

DeleteVal(array, val) {
  loc := array.IndexOf(val)
  if (loc)
    array.RemoveAt(loc)
  return array
}

PushDedupe(array, val) {
  if (!HasVal(array, val))
    array.Push(val)
  return array
}

InsertDedupe(array, val) {
  if (!HasVal(array, val))
    array.InsertAt(0, val)
  return array
}

Dedupe(array) {
  deduped := []
  for value in array
    InsertDedupe(deduped, value)
  return deduped
}

LastOf(array) {
  return array.Length > 0 ? array[array.Length] : 0
}

JoinStrs(array, delimiter := "") {
  str := ""
  for index, value in array
    str .= (index == 1) ? value : delimiter . value
  return str
}

S(style) {
  str := ""
  for key, value in style.OwnProps()
    str .= String(key) . String(value) . " "
  return SubStr(str, 1, -1)
}

usedKeys := []
MyHotkey(key, callback, opt?) {
  global usedKeys
  if (IsSet(opt)) {
    Hotkey(key, callback, opt)
  } else {
    Hotkey(key, callback, "On")
  }
  usedKeys.Push(key)
}

ClearHotkeys() {
  global usedKeys
  for key in usedKeys
    Hotkey(key, "Off")
  usedKeys := []
}

; Format hotkey shorthand to readable string
FormatHotkeyShorthand(shorthand) {
  static modDict := UMap("#", "Win", "^", "Ctrl", "!", "Alt", "+", "Shift")
  if (shorthand ~= "\A(#|\^|!|\+)*\S\Z")
    return StrSplit(shorthand).Map(v => modDict.Get(v, StrUpper(v))).Join("+")
  return shorthand
}

; Parse hotkey shorthand to object
ParseHotkeyShorthand(shorthand) {
  static modDict := UMap("#", "Win", "^", "Ctrl", "!", "Alt", "+", "Shift")
  if (shorthand ~= "\A(#|\^|!|\+)*\S\Z") {
    hotkeyObj := { mods: [], key: "" }
    for (c in StrSplit(shorthand)) {
      if (modDict.Has(c))
        hotkeyObj.mods.Push(c)
      else
        hotkeyObj.key := c
    }
    return hotkeyObj
  }
  return false
}

; Convert hotkey object to shorthand
ToShorthand(hotkeyObj) {
  return hotkeyObj.mods.Join("") . hotkeyObj.key
}

EscapeAmpersand(str) {
  return StrReplace(str, "&", "&&")
}

WinGetActiveID() {
  try {
    return WinGetID("A")
  } catch Error as e {
    return 0
  }
}

TimedTip(text, timeout := 1000) {
  ToolTip(text, A_ScreenWidth, A_ScreenHeight) && SetTimer(() => ToolTip(), -timeout)
}
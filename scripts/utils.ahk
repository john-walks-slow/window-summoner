﻿throwError(title, e?) {
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


hasVal(array, val) {
  return array.IndexOf(val) ? 1 : 0
}

deleteVal(array, val) {
  loc := array.IndexOf(val)
  if (loc)
    array.RemoveAt(loc)
  return array
}

pushDedupe(array, val) {
  if (!hasVal(array, val))
    array.Push(val)
  return array
}

insertDedupe(array, val) {
  if (!hasVal(array, val))
    array.InsertAt(0, val)
  return array
}

dedupe(array) {
  deduped := []
  for value in array
    insertDedupe(deduped, value)
  return deduped
}

lastOf(array) {
  return array.Length > 0 ? array[array.Length] : 0
}

joinStrs(array, delimiter := "") {
  str := ""
  for index, value in array
    str .= (index == 1) ? value : delimiter . value
  return str
}

s(style) {
  str := ""
  for key, value in style.OwnProps()
    str .= String(key) . String(value) . " "
  return SubStr(str, 1, -1)
}

WinGetLatest() {
  ; list := WinGetList("")
  ; return list.Length ? list[list.Length] : 0
  try {
    return WinGetID("A")
  } catch Error as e {
    return 0
  }
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

quote(s) => Chr(34) . s . Chr(34)


concat(i*) => i.join(" ")
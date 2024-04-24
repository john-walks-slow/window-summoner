SetTitleMatchMode("RegEx")
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
  for index, value in array {
    str .= (index == 1) ? value : delimiter . value
  }
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
    return false
  }
}

TimedTip(text, timeout := 1000, x := A_ScreenWidth, y := A_ScreenHeight) {
  ToolTip(text, x, y) && SetTimer(() => ToolTip(), -timeout)
}

CallAsync(func, args*) {
  return NewThread(
    "try {`n"
    func.Name "(" JoinStrs(args, ",") ")`n"
    "}"
  )
}

Call(func, args*) {
  return func.Call(args*)
}

; FILTERED_WINDOW_CLASS := ["DV2ControlHost", "TopLevelWindowForOverflowXamlIsland", "SysShadow", "Shell_TrayWnd", "IME", "NarratorHelperWindow", "tooltips_class32", "Progman", "MSCTFIME UI"]
FILTERED_WINDOW_CLASS := [
  "Progman", ;Program Manager
  "NotifyIconOverflowWindow", ;托盘
  "TopLevelWindowForOverflowXamlIsland", ;托盘
  "Microsoft.IME.UIManager.CandidateWindow.Host", ;输入法
]

USER_WINDOW_FILTER := " ahk_class ^(?!" JoinStrs(FILTERED_WINDOW_CLASS.Map(EscapeRegex), "|") ").*$"

; Check whether windows should be filtered / always on top
NotAOT(id) {
  ; return (FILTERED_WINDOW_CLASS.IndexOf(WinGetClass(id)) == 0)
  return !WinGetAlwaysOnTop(id)
}

NotSystem(id) {
  return FILTERED_WINDOW_CLASS.IndexOf(WinGetClass(id)) == 0
}

; # 关于是否忽略 aot
; 工作区忽略 aot
; 绑定可以捕捉 aot
; 进程+标题 可以捕捉 aot
; 其余模式忽略 aot

; Get the topmost user window (ignoring aot / hidden / system windows)
WinGetUser(title := ".+", ignoreAot := true, ignoreHidden := true) {
  wndList := WinGetUserList(title, ignoreAot, ignoreHidden)
  return wndList.Length > 0 ? wndList[1] : false
}

WinGetUserList(title := ".+", ignoreAot := true, ignoreHidden := true) {
  if (ignoreHidden)
    DetectHiddenWindows(false)
  wndList := WinGetList(title USER_WINDOW_FILTER)
  DetectHiddenWindows(true)
  if (ignoreAot)
    wndList := wndList.Filter(NotAOT)
  return wndList
}

ShallowClone(o) {
  if (IsObject(o)) {
    return o.Clone()
  } else return o
}

EscapeRegex(str) {
  static regexChars := ["\", ".", "*", "?", "+", "[", "{", "|", "(", ")", "^", "$"]
  for c in regexChars
    str := StrReplace(str, c, "\" c)
  return str
}


LogWindows(list) {
  for id in list
    LogWindow(id)
}

LogWindow(id) {
  OutputDebug(WinGetTitle(id) " | " WinGetClass(id) " | " WinGetProcessName(id) "`n")
}
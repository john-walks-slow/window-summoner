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
  DetectHiddenWindows(false)
  try {
    return WinGetID("A")
  } catch Error as e {
    return false
  }
  DetectHiddenWindows(true)
}

TimedTip(text, timeout := 1000, x := A_ScreenWidth, y := A_ScreenHeight) {
  ToolTip(text, x, y) && SetTimer(() => ToolTip(), -timeout)
}

CallAsync(func, args*) {
  return SetTimer(() {
    try {
      return func.Call(args*)
    }
  }, -1)
  ; return NewThread(
  ;   "try {`n"
  ;   func.Name "(" JoinStrs(args, ",") ")`n"
  ;   "}"
  ; )
}


; FILTERED_WINDOW_CLASS := ["DV2ControlHost", "TopLevelWindowForOverflowXamlIsland", "SysShadow", "Shell_TrayWnd", "IME", "NarratorHelperWindow", "tooltips_class32", "Progman", "MSCTFIME UI"]
FILTERED_WINDOW_CLASS := [
  "Progman", ;Program Manager
  "DV2ControlHost", ;开始菜单
  "NotifyIconOverflowWindow", ;旧版托盘
  "TopLevelWindowForOverflowXamlIsland", ;新托盘
  "Microsoft.IME.UIManager.CandidateWindow.Host", ;输入法
  "IME", ;输入法
  "MSCTFIME UI",
  ; "SysShadow", "Shell_TrayWnd", "IME", "NarratorHelperWindow", "tooltips_class32", "MSCTFIME UI"
  ; "Xaml_WindowedPopupCIass"
]

FILTERED_WINDOW_TITLE := [
  "DesktopWindowXamlSource"
]
FILTERED_WINDOW_EXE := []

EXE_FILTER := ""
CLASS_FILTER := "^(?!" JoinStrs(FILTERED_WINDOW_CLASS.Map(EscapeRegex), "|") ").*$"
TITLE_FILTER := "^(?!" JoinStrs(FILTERED_WINDOW_TITLE.Map(EscapeRegex), "|") ").+$"


NotAOT(id) {
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


WinGetUserList(exe := "", class := "", title := "", ignoreHidden?, ignoreAot?) {
  ignoreHidden := IsSet(ignoreHidden) ? ignoreHidden : !title
  ignoreAot := IsSet(ignoreAot) ? ignoreAot : !title
  exe := exe || EXE_FILTER
  class := class || CLASS_FILTER
  title := title || TITLE_FILTER

  if (ignoreHidden)
    DetectHiddenWindows(false)
  wndList := WinGetList(title " ahk_exe " exe " ahk_class " class)
  if (ignoreHidden)
    DetectHiddenWindows(true)
  if (ignoreAot)
    wndList := wndList.Filter(NotAOT)
  return wndList
}
; Get the topmost user window (ignoring aot / hidden / system windows)
WinGetUser(exe := "", class := "", title := "", ignoreHidden?, ignoreAot?) {
  ignoreHidden := IsSet(ignoreHidden) ? ignoreHidden : !title
  ignoreAot := IsSet(ignoreAot) ? ignoreAot : !class
  exe := exe || EXE_FILTER
  class := class || CLASS_FILTER
  title := title || TITLE_FILTER

  if (ignoreAot) {
    wndList := WinGetUserList(exe, class, title, ignoreHidden, ignoreAot)
    return wndList.Length > 0 ? wndList[1] : false
  } else {
    if (ignoreHidden)
      DetectHiddenWindows(false)
    wnd := WinGetID(title " ahk_exe " exe " ahk_class " class)
    if (ignoreHidden)
      DetectHiddenWindows(true)
    return wnd
  }
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

LimitStr(str, len := 40, suffix := "...") {
  return StrLen(str) > len ? (SubStr(str, 1, len) suffix) : str
}

WinSetMinMax(title, minMax) {
  switch minMax {
    case -1:
      WinMinimize(title)
    case 0:
      WinRestore(title)
    case 1:
      WinMaximize(title)
  }
}
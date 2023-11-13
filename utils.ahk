#Requires AutoHotkey v2.0

throwError(e, title) {
  MsgBox(e.Message, title)
  ExitApp()
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
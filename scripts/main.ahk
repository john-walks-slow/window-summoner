#Include configuration.ahk
#Include setupShortcuts.ahk
#Include setupDynamic.ahk
#include setupWorkspace.ahk
#Include utils.ahk
#Include ../app.ahk

global hookedKeys := []
main() {
  global config
  setupDynamic(config["dynamic"])
  setupShortcuts(config["shortcuts"])
  setupWorkspace(config["workspace"])
}
stopMain() {
  ClearHotkeys()
  clearWndHandlers()
}
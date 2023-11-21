#Include configuration.ahk
#Include setupShortcuts.ahk
#Include setupDynamic.ahk
#Include utils.ahk

global hookedKeys := []
main() {
  global config
  setupDynamic(config["dynamic"])
  setupShortcuts(config["shortcuts"])
}
stopMain() {
  ClearHotkeys()
  clearWndHandlers()
}
; Setup ahk
#Requires AutoHotkey v2.0
DetectHiddenWindows(true)
SetTitleMatchMode("RegEx")

#Include configuration.ahk
#Include setupBinding.ahk
#Include setupDynamic.ahk


config := readConfig()

for section, entry in config {
  if (section == "dynamic") {
    setupDynamic(entry)
  } else {
    setupBinding(section, entry)
  }
}
#Requires AutoHotkey >=2.0

#Include utils.ahk
#Include OrderedMap.ahk
#Include Yaml.ahk

CONFIG_PATH := A_ScriptDir . "\data\config.json"

CONFIG_DEFAULT := UMap(
  "dynamic", UMap(
    "enable", true,
    "showTip", true,
    "mod_bind", ["#", "+"],
    "mod_main", ["#"],
    "suffixs", [9, 0, "-", "="],
  ),
  "workspace", UMap(
    "enable", true,
    "showTip", true,
    "fullRestore", true,
    "mod", ["#"],
    "suffixs", ["[", "]"],
  ),
  "shortcuts", UArray(
    makeShortcut()
  ),
  "misc", UMap(
    "autoStart", false,
    "minimizeToTray", true,
    "runAsAdmin", false,
    "hideTray", false,
    "reuseExistingWindow", true,
    "singleActiveWindow", false,
    "minimizeInstead", false,
    "transitionAnim", true,
    "alternativeCapture", false
    ; "filteredWindowClasses", UArray(
    ; "DV2ControlHost", "TopLevelWindowForOverflowXamlIsland", "SysShadow", "Shell_TrayWnd", "IME", "NarratorHelperWindow", "tooltips_class32", "Progman", "MSCTFIME UI"
    ; )
  ),
)

makeShortcut() {
  return UMap(
    "hotkey", "",
    "run", "",
    "capture", UMap(
      "mode", 1, ;1:auto 2:process 3:process+title
      "process", "",
      "class", "",
      "title", "",
    )
  )
}

checkConfig(config) {

  _mergeConfig(config, CONFIG_DEFAULT)

  ; Migrate from wnd_title to capture.title
  for (s in config["shortcuts"]) {
    if (s.Get("wnd_title", "") !== "") {
      s["capture"]["mode"] := 3
      s["capture"]["title"] := s["wnd_title"]
    }
    s.Delete("wnd_title")
  }

  _mergeConfig(entry, default) {
    if (Type(entry) !== Type(default)) {
      entry := ShallowClone(default)
    } else if (Type(default) == "Map") {
      for (dk, dv in default) {
        if (!entry.Has(dk)) {
          entry[dk] := ShallowClone(dv)
        }
        else if (Type(dv) == "Map" || Type(dv) == "Array") {
          if (Type(dv) !== Type(entry[dk])) {
            entry[dk] := ShallowClone(dv)
          } else _mergeConfig(entry[dk], dv)
        }
      }
    } else if (Type(default) == "Array") {
      if (Type(default[1]) == "Map") {
        for (ek, ev in entry) {
          if (Type(ev) !== Type(default[1])) {
            entry.Delete(ek)
          } else _mergeConfig(ev, default[1])
        }
      }
    }


  }
}
readConfig() {
  try {
    if (!FileExist(CONFIG_PATH)) {
      writeConfig(CONFIG_DEFAULT)
    }
    config := Yaml(FileRead(CONFIG_PATH))
    checkConfig(config)
    return config
  } catch Error as e {
    ThrowError("Error reading config file", e)

  }
}
writeConfig(config) {
  try {
    checkConfig(config)
    FileOpen(CONFIG_PATH, "w").Write(Yaml(config, -4))
    if (config["misc"]["autoStart"]) {
      _createAutoStart()
    } else {
      _deleteAutoStart()
    }
  } catch Error as e {
    ThrowError("Error writing config file", e)
  }
}

SYMLNK_PATH := A_ScriptDir "\data\autostart.lnk"
AUTOSTART_PATH := A_Startup "\呼来唤去.lnk"
ICON_PATH := A_ScriptDir . "\data\icon.ico"

_createAutoStart() {
  global ICON_PATH
  global AUTOSTART_PATH
  if (!FileExist(AUTOSTART_PATH)) {
    FileCreateShortcut(A_ScriptFullPath, AUTOSTART_PATH, , "--no-gui", "呼来唤去自启", ICON_PATH)
    ; Create symlink of script in the startup folder
    ; command := concat(A_ComSpec, "/c",
    ;   quote(concat("mklink", "/H", quote(AUTOSTART_PATH), quote(A_ScriptFullPath)))
    ; )
    ; command := concat(A_ComSpec, "/c",
    ;   quote(concat("copy", quote(SYMLNK_PATH), quote(AUTOSTART_PATH),))
    ; )
    ; RunWait(command)
  }
}
_deleteAutoStart() {
  global AUTOSTART_PATH
  if (FileExist(AUTOSTART_PATH)) {
    FileDelete(AUTOSTART_PATH)
  }
}
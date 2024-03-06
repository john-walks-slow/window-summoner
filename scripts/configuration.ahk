#Requires AutoHotkey >=2.0

#Include utils.ahk
#Include OrderedMap.ahk
#Include Yaml.ahk

CONFIG_PATH := A_ScriptDir . "\data\config.json"

CONFIG_SCHEME := UMap(
  "dynamic", UMap(
    "enable", { default: true },
    "mod_bind", { default: ["#", "+"] },
    "mod_main", { default: ["#"] },
    "suffixs", { default: [9, 0, "-", "=", "[", "]"] },
  ),
  "shortcuts", Map("*", UMap(
    "hotkey", { default: "" },
    "run", { default: "" },
    "wnd_title", { default: "" },
  )),
  "misc", UMap(
    "autoStart", { default: false },
    "minimizeToTray", { default: true },
    "reuseExistingWindow", { default: true },
    "singleActiveWindow", { default: false },
    "minimizeInstead", { default: false },
    "fadeOutTransition", { default: true },
    "hideTray", { default: false },
  )
)
CONFIG_INITIAL := UMap(
  "dynamic", UMap(
    "enable", true,
    "mod_bind", ["#", "+"],
    "mod_main", ["#"],
    "suffixs", [9, 0, "-", "=", "[", "]"],
  ),
  "shortcuts", UArray(
    UMap(
      "hotkey", "",
      "run", "",
      "wnd_title", ""
    ),
  ),
  "misc", UMap(
    "autoStart", false,
    "minimizeToTray", true,
    "reuseExistingWindow", true,
    "singleActiveWindow", false,
    "minimizeInstead", false,
    "fadeOutTransition", true,
    "hideTray", false
  ),
)
checkConfig(config) {
  _checkConfigWithScheme(config["dynamic"], CONFIG_SCHEME["dynamic"])
  _checkConfigWithScheme(config["misc"], CONFIG_SCHEME["misc"], true)

  for cKey, cValue in config["shortcuts"] {
    _checkConfigWithScheme(cValue, CONFIG_SCHEME["shortcuts"]["*"])
  }

  _checkConfigWithScheme(config, scheme, merge := false) {
    for sKey, sValue in scheme {
      if (!sValue.HasProp("optional") || !sValue.optional) {
        if (!config.Has(sKey)) {
          if (!merge) {
            throwError("Invalid config")
          } else {
            config.Set(sKey, sValue.default)
          }
        }
      }
    }
  }
}
readConfig() {
  try {
    if (!FileExist(CONFIG_PATH)) {
      writeConfig(CONFIG_INITIAL)
    }
    config := Yaml(FileRead(CONFIG_PATH))
    checkConfig(config)
    return config
  } catch Error as e {
    throwError("Error reading config file", e)

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
    throwError("Error writing config file", e)
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
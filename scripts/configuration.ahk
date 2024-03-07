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
    "mod", ["#"],
    "suffixs", ["[", "]"],
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
    "hideTray", false,
    "reuseExistingWindow", true,
    "singleActiveWindow", false,
    "minimizeInstead", false,
    "transitionAnim", true,
  ),
)
checkConfig(config) {
  _normalizeConfig(config, "dynamic")
  _normalizeConfig(config, "workspace")
  _normalizeConfig(config, "misc")

  for (shortcutConfig in config.Get("shortcuts", [])) {
    _mergeConfig(shortcutConfig, CONFIG_DEFAULT["shortcuts"][1])
  }

  _normalizeConfig(config, key) {
    if (!config.Has(key)) {
      config.Set(key, CONFIG_DEFAULT[key])
    } else {
      _mergeConfig(config.Get(key), CONFIG_DEFAULT[key])
    }
  }
  _mergeConfig(entry, default) {
    for sKey, sValue in default {
      if (!entry.Has(sKey)) {
        entry.Set(sKey, sValue)
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
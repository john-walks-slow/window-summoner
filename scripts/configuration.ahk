#Requires AutoHotkey >=2.0

#Include utils.ahk
#Include OrderedMap.ahk
#Include Yaml.ahk

CONFIG_PATH := A_ScriptDir . "\data\config.json"

CONFIG_SCHEME := UMap(
  "dynamic", UMap(
    "enable", { default: true, gui_type: "checkbox", desc: "启用动态绑定" },
    "mod_bind", { default: "#+", gui_type: "mod_select", desc: "绑定修饰键" },
    "mod_main", { default: "#", gui_type: "mod_select", desc: "切换修饰键" },
    "suffixs", { default: "7890", gui_type: "suffix_input", desc: "后缀" },
  ),
  "shortcuts", Map("*", UMap(
    "hotkey", { default: "", gui_type: "hotkey", desc: "快捷键" },
    "run", { default: "", gui_type: "path", desc: "程序路径" },
    "wnd_title", { default: "", gui_type: "string", desc: "窗口标题（正则）" },
  )),
  "misc", UMap(
    "autoStart", { default: false, gui_type: "checkbox", desc: "开机自启动" },
    "reuseExistingWindow", { default: true, gui_type: "checkbox", desc: "复用已经打开的程序实例" },
    "singleActiveWindow", { default: false, gui_type: "checkbox", desc: "单一活动窗口" },
  )
)
CONFIG_INITIAL := UMap(
  "dynamic", UMap(
    "enable", true,
    "mod_bind", ["#", "+"],
    "mod_main", ["#"],
    "suffixs", [7, 8, 9, 0],
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
    "reuseExistingWindow", true,
    "singleActiveWindow", false
  ),
)
checkConfig(config) {
  _checkConfigWithScheme(config["dynamic"], CONFIG_SCHEME["dynamic"])

  for cKey, cValue in config["shortcuts"] {
    _checkConfigWithScheme(cValue, CONFIG_SCHEME["shortcuts"]["*"])
  }

  _checkConfigWithScheme(config, scheme) {
    for sKey, sValue in scheme {
      if (!sValue.HasProp("optional") || !sValue.optional) {
        if (!config.Has(sKey)) {
          throwError("Invalid config")
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
    FileCreateShortcut(A_ScriptFullPath, AUTOSTART_PATH, , , "呼来唤去自启", ICON_PATH)
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
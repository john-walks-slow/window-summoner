#Requires AutoHotkey v2.0
#Include utils.ahk

CONFIG_PATH := "config.ini"
CONFIG_SCHEME := Map(
  "dynamic", Map(
    "enable", { default: true, type: "boolean" },
    "mod_main", { default: "#", type: "mod_select" },
    "mod_bind", { default: "#+", type: "mod_select" },
    "key_list", { default: "7890", type: "keys" },
  ),
  "default", Map(
    "run", { default: "", type: "path" },
    "wnd_title", { default: "", type: "string" },
  )
)
PARSERS := Map(
  "boolean", (value) {
    if (value == "true") {
      return true
    } else if (value == "false") {
      return false
    } else {
      throwError(Error(), "Bad boolean value")
    }
  },
  "mod_select", (value) {
    if (true) {
      return value
    } else {
      throwError(Error(), "Bad mod_select value")
    }
  },
  "keys", (value) {
    return RegExMatchAll(value, "((?<!{)[^{}](?!})|{\S*})", false)
  },
  "path", (value) {
    return value
  },
  "string", (value) {
    return value
  }
)

readConfig() {
  global CONFIG_PATH, CONFIG_SCHEME
  return _parseConfigWithScheme(CONFIG_PATH, CONFIG_SCHEME)
}

_parseConfigWithScheme(path, scheme) {
  try {
    configs := Map()
    sectionNames := StrSplit(IniRead(path), "`n")
    for section in sectionNames {
      if (scheme.Has(section)) {
        parseKeyValue(section, scheme[section])
      } else {
        parseKeyValue(section, scheme["default"])
      }
    }
    parseKeyValue(section, scheme) {
      newConfig := Map()
      for k, v in scheme {
        value := IniRead(path, section, k, v.default)
        newConfig.Set(k, PARSERS[v.type](value))
      }
      configs.Set(section, newConfig)
    }
    return configs
  } catch Error as e {
    throwError(e, "Bad config")
  }
}

writeConfig(configs) {
  CONFIG_PATH := "config.ini"
  for section, config in configs {
    for key, value in config {
      IniWrite(value, CONFIG_PATH, section, key)
    }
  }
}
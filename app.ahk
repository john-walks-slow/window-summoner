#SingleInstance Force
DetectHiddenWindows(true)
SetTitleMatchMode("RegEx")
SetTitleMatchMode("Fast")
A_FileEncoding := "UTF-16"
VERSION_NUMBER := FileRead(A_ScriptDir "\data\version.txt", "utf-8")

#Include scripts\configuration.ahk
#Include scripts\utils.ahk
#Include scripts\main.ahk

config := readConfig()

class Configurator {
  __New() {
    global config
    this.config := config
  }
  createGui() {
    this._skeleton()
    this._menu()
    this._dynamicTab()
    this._miscTab()
    this._shortcutTab()
    this.gui.Show()
    this.gui.OnEvent("Close", (*) {
      this.gui.Destroy()
      this.gui := unset
      for gui in this.subGuis {
        gui.Destroy()
      }
      this.subGuis := []
      if (!this.config["misc"]["minimizeToTray"] || !this.isMainRunning) {
        ExitApp()
      }
    })
  }
  _skeleton() {
    this.guiWidth := 450
    this.guiHeight := 300
    this.titleRunning := "呼来唤去 - 运行中"
    this.titleIdle := "呼来唤去"
    guiSizeOpt := "MinSize" . this.guiWidth + 10 . "x" . this.guiHeight + 5
      . " MaxSize" . this.guiWidth + 10 . "x" . 9999
    ; Set gui Icon
    WS_MAXIMIZEBOX := 0x00010000
    WS_VSCROLL := 0x00200000
    this.gui := Gui("+Resize "
      "-" WS_MAXIMIZEBOX
      " " WS_VSCROLL
      " " guiSizeOpt
      ; " +Scroll",
      , this.isMainRunning ? this.titleRunning : this.titleIdle,)
    this.gui.MarginX := 2
    this.gui.MarginY := 5

    this.subGuis := []

    TCS_BUTTONS := 0x0100
    TCS_OWNERDRAWFIXED := 0x2000
    TCS_HOTTRACK := 0x0040
    TCS_FLATBUTTONS := 0x0008
    this.tab := this.gui.AddTab2(s({
      w: this.guiWidth,
      h: 19, %TCS_HOTTRACK%: "", %TCS_BUTTONS%: "", %TCS_FLATBUTTONS%: "",
      ; "Bottom": "",
      ; "Background": "White",
    }), ["热键", "绑定", "其它"])

    this.tab.UseTab(0)
    BS_FLAT := 0x8000
    btn := this.gui.AddButton(s({ x: this.guiWidth - 60.5, y: "s-3", }), "应用配置")
    btn.OnEvent(
      "Click", (gui, info) {
        ; writeConfig(this.config)
        if (this.isMainRunning) {
          this._stopMainScript()
            ; Sleep(100)
          writeConfig(this.config)
          this._startMainScript()
        }
        updateTrayVisibility()
        MsgBox("已应用新配置")
      }
    )
    ; this.gui.AddButton(s({ y: "p" }), "取消").OnEvent(
    ;   "Click", (gui, info) {
    ;     this.gui.Destroy()
    ;   }
    ; )
    this.gui.AddText("section y+-30", "")
    this.gui.MarginY := 0
  }
  _menu() {
    global VERSION_NUMBER
    aboutMenu := Menu()
    aboutMenu.Add("版本：" VERSION_NUMBER, (name, pos, menu) {
      Run("https://github.com/john-walks-slow/window-summoner")
    },)

    scriptMenu := Menu()
    scriptMenu.Add("运行", (name, pos, menu) {
    })
    scriptMenu.Add("重启", (name, pos, menu) {
    })
    scriptMenu.Add("停止", (name, pos, menu) {
    })
    this.gui.MenuBar := MenuBar()
    this.STATE_RUNNING := "⏹ 停止"
    this.STATE_IDLE := "▶️  启动"
    this.gui.MenuBar.Add(this.isMainRunning ? this.STATE_RUNNING : this.STATE_IDLE,
      (name, pos, menu) {
        try {
          if (this.isMainRunning) {
            this._stopMainScript()
          } else {
            writeConfig(this.config)
            this._startMainScript()
          }
        }
      }
    )
    this.gui.MenuBar.Add("关于", aboutMenu)
  }
  _dynamicTab() {
    this.tab.UseTab(2)
    this.gui.AddText("section x+10 y+10 w0 h0", "")
    dynamicConfig := this.config["dynamic"]
    this._addComponent(this.COMPONENT_CLASS.CHECKBOX, '启用绑定', dynamicConfig, "enable", "section xs ys")
    this._addComponent(this.COMPONENT_CLASS.LINK, '?', , , "ys").OnEvent("Click", (*) {
      MsgBox(
        "为当前活跃窗口绑定热键。`n"
        "例：浏览网页时按 Win + Shift + 0，之后按 Win + 0 就能显示 / 隐藏该浏览器窗口。`n"
        , "帮助")
    })
    this.gui.AddText("section xs y+10", "修饰键（绑定）  ")
    this._addComponent(this.COMPONENT_CLASS.MOD_SELECT, false, dynamicConfig, "mod_bind")
    this.gui.AddText("section xs y+10", "修饰键（切换）  ")
    this._addComponent(this.COMPONENT_CLASS.MOD_SELECT, false, dynamicConfig, "mod_main")
    this._addComponent(this.COMPONENT_CLASS.SUFFIX_INPUT, "后缀键", dynamicConfig, "suffixs")
    this.gui.AddLink(s({ x: "+5", y: "s" }), '<a href="/">?</a>').OnEvent(
      "Click", (*) {
        MsgBox(
          "可以用作后缀键的字符`n"
          , "帮助")
      }
    )
    this.gui.AddGroupBox(s({ section: "", w: this.guiWidth - 20, r: 2.5, x: 10, y: "+1" }))
    this.gui.AddText("section xs+5 ys+15 w270 c444444", "[绑定+后缀]: 绑定该后缀到当前活动窗口。`n[切换+后缀]: 显示/隐藏绑定的窗口。")
  }
  _shortcutTab() {
    this.tab.UseTab(1)
    this.gui.AddText("section x+10 y+10 w0 h0", "")
    shortcutConfig := this.config["shortcuts"]
    c1 := 10
    c2 := this.guiWidth * 0.3
    c3 := this.guiWidth * 0.62
    c4 := this.guiWidth - 20
    w1 := c2 - c1 - 7
    w2 := c3 - c2 - 7
    w3 := c4 - c3 - 7
    w4 := 20
    ; Headers
    this.gui.SetFont("c787878")
    this.gui.AddLink(s({ section: "", x: c1, y: "s" }), "程序 " '<a href="/">?</a>').OnEvent(
      "Click", (*) {
        MsgBox(
          "要启动的程序、文件或快捷方式`n"
          , "帮助")
      }
    )
    this.gui.AddLink(s({ x: c2, y: "s" }), "热键 " '<a href="/">?</a>').OnEvent(
      "Click", (*) {
        MsgBox(
          "用于唤起 / 隐藏该程序的热键`n"
          , "帮助")
      }
    )

    this.gui.AddLink(s({ x: c3, y: "s" }), "窗口标题正则 (高级) " '<a href="/">?</a>').OnEvent(
      "Click", (*) {
        MsgBox(
          "省略时，『呼来唤去』会自动捕获启动程序后出现的第一个新窗口。`n"
          "不为空时，『呼来唤去』会捕获第一个窗口标题与该正则匹配的窗口。`n`n"
          "在以下情况下本选项会有帮助：`n"
          "- 希望捕获并非由『呼来唤去』启动的程序窗口`n"
          "- 该程序有启动画面或需要忽略的弹窗`n"
          "- 需要提高稳定性`n"
          , "帮助")
      }
    )
    this.gui.SetFont("")

    ; this.gui.AddProgress(s({ Background: "AAAAAA", h: 1, w: this.guiWidth - 50, x: "s", y: "+5" }))

    this.gui.AddButton(s({ x: c4, y: "s-7", }), "+").OnEvent(
      "Click", (gui, info) {
        this.tab.UseTab(1)
        shortcutConfig.Push(UMap("hotkey", "", "run", "", "wnd_title", ""))
        shortcutRow(shortcutConfig.Length, shortcutConfig[shortcutConfig.Length], false)
      }
    )

    isFirst := false
    for index, entry in shortcutConfig {
      shortcutRow(index, entry, isFirst)
      isFirst := false
    }
    shortcutRow(index, entry, isFirst) {
      appSelectTxt() {
        RegExMatch(entry["run"], "([^\\]+?)(\.[^.]*)?$", &match)
        ; this.gui.AddText(s({ section: "", x: "s", y: isFirst ? "s" : "+10" }), match[1])
        return match ? match[1] : false
      }
      appSelect := this.gui.AddButton(s({ section: "", x: "s", y: isFirst ? "s" : "+-1", w: w1, r: 1, "-wrap -VScroll": "" }), appSelectTxt() || "选择")
      appSelect.OnEvent(
        "Click", (gui, info) {
          fileChoice := FileSelect(32)
          if (fileChoice) {
            entry["run"] := fileChoice
            gui.Text := appSelectTxt() || "选择"
          }
        }
      )
      NOPREFIX := 0x80
      hotkeyButton := this.gui.AddButton(s({ x: c2, y: "s", w: w2, r: 1, "-wrap -VScroll": "" }), EscapeAmpersand(FormatHotkeyShorthand(entry["hotkey"])) || "配置")
      hotkeyButton.onEvent("Click", (target, info) {
        customHotkeyWnd := Gui("-MinimizeBox -MaximizeBox", appSelect.Text == "选择" ? "配置热键" : "配置 " appSelect.Text " 的热键")
        this.subGuis.Push(customHotkeyWnd)
        customHotkeyWnd.MarginX := 10
        customHotkeyWnd.MarginY := 10
        parseResult := ParseHotkeyShorthand(entry["hotkey"])
        hotkeyObj := parseResult || { mods: [], key: "" }
        customHotkeyWnd.AddText("section y+10 w0 h0", "")
        this._addComponent(this.COMPONENT_CLASS.MOD_SELECT, "", hotkeyObj, "mods", false, customHotkeyWnd)
        oldKey := StrUpper(hotkeyObj["key"])
        customHotkeyWnd.AddEdit(s({ x: "+2", y: "s-3", w: 20 }), oldKey).OnEvent("Change", (target, info) {
          splited := StrSplit(target.Value)
          if (splited.Length > 0) {
            key := StrLower(splited.Get(splited.FindIndex(v => v != oldKey) || 1))
          } else {
            key := ""
          }
          hotkeyObj["key"] := key
          target.Value := StrUpper(key)
          oldKey := target.Value
        })
        customHotkeyWnd.AddText(s({ x: "s", y: "+20", section: "" }), "AHK (高级)")
        advancedEdit := customHotkeyWnd.AddEdit(s({ x: "+5", y: "s-3", w: 145 }), parseResult ? "" : entry["hotkey"])
        customHotkeyWnd.AddLink(s({ x: "+2" }), '<a href="/">?</a>').OnEvent(
          "Click", (*) {
            MsgBox(
              "使用 AHK 格式配置更高级的热键。会覆盖上方的设置"
              , "帮助")
          }
        )
        customHotkeyWnd.AddButton(s({ x: "s" }), "确定").OnEvent("Click", (gui, info) {
          if (advancedEdit.Text) {
            entry["hotkey"] := advancedEdit.Text
          } else {
            entry["hotkey"] := ToShorthand(hotkeyObj)
          }
          hotkeyButton.Text := EscapeAmpersand(FormatHotkeyShorthand(entry["hotkey"]))
          customHotkeyWnd.Destroy()
        })
        customHotkeyWnd.AddButton(s({ x: "+5" }), "取消").OnEvent("Click", (gui, info) {
          customHotkeyWnd.Destroy()
        })
        customHotkeyWnd.Show()
      })
      titleInput := this.gui.AddEdit(s({ y: "s+2", x: c3, w: w3, r: 1, "-wrap -VScroll": "" }), entry["wnd_title"])
      titleInput.onEvent("Change", (gui, info) {
        entry["wnd_title"] := gui.Value
      })
      removeBtn := this.gui.AddButton(s({ x: c4, y: "s" }), "-")
      removeBtn.OnEvent(
        "Click", (gui, info) {
          this.config["shortcuts"].RemoveAt(index)
          this._refreshGui()
        })
    }

  }
  COMPONENT_CLASS := {
    "CHECKBOX": "checkbox",
    "MOD_SELECT": "mod_select",
    "SUFFIX_INPUT": "suffix_input",
    "LINK": "link",
  }
  ; Create a component of a given type, and bind it to the data
  _addComponent(guiType, payload := "", data := 0, dataKey := 0, styleOpt := false, gui := this.gui) {
    if (IsObject(styleOpt)) {
      styleOpt := s(styleOpt)
    }
    if (data && dataKey) {
      dataValue := data[dataKey]
    }
    switch guiType {
      case this.COMPONENT_CLASS.LINK:
        return gui.AddLink(styleOpt || "ys", "<a>" payload "</a>")
      case this.COMPONENT_CLASS.CHECKBOX:
        checkbox := gui.AddCheckbox(styleOpt || "section xs y+10", payload)
        checkbox.Value := dataValue
        checkbox.OnEvent("Click", (gui, info) {
          data[dataKey] := gui.Value
        })
        return checkbox
      case this.COMPONENT_CLASS.MOD_SELECT:
        modDict := UMap("#", "Win", "^", "Ctrl", "!", "Alt", "+", "Shift")
        isFirst := true
        for modKey, modText in modDict {
          addMod(modKey, modText, isFirst)
          isFirst := false
        }
        addMod(modKey, modText, isFirst) {
          option := isFirst ? "ys x+0" : "ys x+0"
          checkbox := gui.AddCheckbox(option, modText)
          checkbox.Value := hasVal(dataValue, modKey)
          checkbox.OnEvent("Click", (gui, info) {
            if (gui.Value) {
              pushDedupe(dataValue, modKey)
            } else {
              deleteVal(dataValue, modKey)
            }
          })
        }
      case this.COMPONENT_CLASS.SUFFIX_INPUT:
        gui.AddText(styleOpt || "section xs y+15", payload)
        edit := gui.AddEdit("ys-5 x+5 w200", joinStrs(dataValue))
        edit.onEvent("Change", (gui, info) {
          data[dataKey] := dedupe(StrSplit(gui.Value))
            ; gui.Value := joinStrs(config[dataKey])
        })
      default:
    }
  }
  _miscTab() {
    this.tab.UseTab(3)
    this.gui.AddText("section x+10 y+10 w0 h0", "")
    miscConfig := this.config["misc"]
    this._addComponent(this.COMPONENT_CLASS.CHECKBOX, "开机自启动", miscConfig, "autoStart", "section xs ys")
    this._addComponent(this.COMPONENT_CLASS.CHECKBOX, "关闭到托盘", miscConfig, "minimizeToTray")
    this._addComponent(this.COMPONENT_CLASS.CHECKBOX, "捕获并非『呼来唤去』启动的程序窗口", miscConfig, "reuseExistingWindow")
    this.gui.AddLink(s({ x: "+0", y: "s" }), '<a href="/">?</a>').OnEvent(
      "Click", (*) {
        MsgBox(
          "勾选后，会根据『窗口标题正则』在现有窗口中尝试捕获目标窗口。`n"
          "若取消勾选，将仅仅捕获由『呼来唤去』启动的程序窗口。`n"
          , "帮助")
      }
    )
    this._addComponent(this.COMPONENT_CLASS.CHECKBOX, "唤起新窗口时隐藏当前唤起的窗口", miscConfig, "singleActiveWindow")
    this._addComponent(this.COMPONENT_CLASS.CHECKBOX, "最小化而不是隐藏窗口", miscConfig, "minimizeInstead")
    this._addComponent(this.COMPONENT_CLASS.CHECKBOX, "启用过渡动画", miscConfig, "transitionAnim")
    this._addComponent(this.COMPONENT_CLASS.CHECKBOX, "隐藏托盘图标", miscConfig, "hideTray")
    this.gui.AddLink(s({ x: "+0", y: "s+1" }), '(<a href="/">注意</a>)').OnEvent(
      "Click", (*) {
        MsgBox(
          "隐藏呼来唤去的托盘图标。`n"
          "你可以通过重新启动 呼来唤去.exe 调出本窗口。`n"
          "在 “停止” 状态下关闭本窗口，即可退出呼来唤去。`n"
          , "注意")
      }
    )
  }
  _refreshGui(opt?) {
    oldGui := this.gui
    ; oldGui.Visible := false
    ; oldGui.GetClientPos(&oldX, &oldY)
    ; oldGui.GetPos(&oldX, &oldY, &oldWidth, &oldHeight)
    this.createGui()
    this.gui.Show(
      ; "X" . oldX " Y" . oldY " W" . oldWidth " H" . oldHeight
    )
    oldGui.Destroy()
  }
  isMainRunning := false
  _startMainScript() {
    if (!this.isMainRunning) {
      main()
      this.isMainRunning := true
      if (this.HasProp("gui")) {
        this.gui.MenuBar.Rename(this.STATE_IDLE, this.STATE_RUNNING)
        WinSetTitle(this.titleRunning, this.gui)
      }
    }
  }
  _stopMainScript() {
    if (this.isMainRunning) {
      stopMain()
      this.isMainRunning := false
      if (this.HasProp("gui")) {
        this.gui.MenuBar.Rename(this.STATE_RUNNING, this.STATE_IDLE)
        WinSetTitle(this.titleIdle, this.gui)
      }
    }
  }
}

updateTrayVisibility()
setupTray()
instance := Configurator()
if (hasVal(A_Args, "--no-gui") && config["misc"]["minimizeToTray"]) {
} else {
  instance.createGui()
}
instance._startMainScript()


setupTray() {
  global ICON_PATH
  TraySetIcon(ICON_PATH)
  A_TrayMenu.Delete()
  openGui(*) {
    if (instance.HasProp("gui")) {
      instance._refreshGui()
    } else {
      instance.createGui()
    }
  }

  A_TrayMenu.Add("配置", openGui)
  A_TrayMenu.Add("还原窗口", (*) {
    clearWndHandlers()
  })
  A_TrayMenu.Add("退出", (*) {
    ExitApp()
  })
  OnMessage(0x404, (wParam, lParam, *) {
    ; user left-clicked tray icon
    if (lParam = 0x202) {
      return
    }
    ; user double left-clicked tray icon
    else if (lParam = 0x203) {
      openGui()
      return
    }
    ; user right-clicked tray icon
    if (lParam = 0x204) {
      return
    }
    ; user middle-clicked tray icon
    if (lParam = 0x208) {
      return
    }
  })
}

updateTrayVisibility() {
  if (config["misc"]["hideTray"] || !config["misc"]["minimizeToTray"]) {
    A_IconHidden := true
  } else {
    A_IconHidden := false
  }
}
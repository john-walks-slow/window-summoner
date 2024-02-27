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
      if (!this.isMainRunning) {
        ExitApp()
      }
    })
  }
  _skeleton() {
    this.guiWidth := 350
    this.guiHeight := 300
    guiSizeOpt := "MinSize" . this.guiWidth + 10 . "x" . this.guiHeight + 5
      . " MaxSize" . this.guiWidth + 10 . "x" . this.guiHeight + 5
    ; Set gui Icon
    WS_MAXIMIZEBOX := 0x00010000
    WS_VSCROLL := 0x00200000
    this.gui := Gui("+Resize "
      "-" WS_MAXIMIZEBOX
      " " WS_VSCROLL
      " " guiSizeOpt
      ; " +Scroll",
      , "呼来唤去",)
    this.gui.MarginX := 2
    this.gui.MarginY := 5

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
    btn := this.gui.AddButton(s({ x: this.guiWidth - 35, y: "s-5", }), "应用")
    btn.OnEvent(
      "Click", (gui, info) {
        ; writeConfig(this.config)
        if (this.isMainRunning) {
          this._stopMainScript()
            ; Sleep(100)
          writeConfig(this.config)
          this._startMainScript()
        }
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
    this._addControl(this.GUI_CLASS.CHECKBOX, '启用动态绑定', dynamicConfig, "enable", "section xs ys")
    this._addControl(this.GUI_CLASS.LINK, '?', , , "ys").OnEvent("Click", (*) {
      MsgBox(
        "例：在浏览文档时按 Win + Shift + 7，之后 Win + 7 就会显示/隐藏文档。`n"
        "后缀键列表指定了哪些字符可以用作后缀键。"
        , "帮助")
    })
    this._addControl(this.GUI_CLASS.MOD_SELECT, "修饰键（绑定）", dynamicConfig, "mod_bind")
    this._addControl(this.GUI_CLASS.MOD_SELECT, "修饰键（切换）", dynamicConfig, "mod_main")
    this._addControl(this.GUI_CLASS.SUFFIX_INPUT, "后缀键列表", dynamicConfig, "suffixs")

    this.gui.AddGroupBox(s({ section: "", w: this.guiWidth - 20, r: 2.5, x: 10, y: "+1" }))
    this.gui.AddText("section xs+5 ys+15 w270 c444444", "[绑定+后缀]: 绑定该后缀到当前活动窗口。`n[切换+后缀]: 显示/隐藏绑定的窗口。")
  }
  _shortcutTab() {
    this.tab.UseTab(1)
    this.gui.AddText("section x+10 y+10 w0 h0", "")
    shortcutConfig := this.config["shortcuts"]
    c1 := 10
    c2 := 95
    c3 := 170
    c4 := 330
    w1 := c2 - c1 - 10
    w2 := c3 - c2 - 10
    w3 := c4 - c3 - 10
    w4 := 20
    /** Headers */
    this.gui.SetFont("c787878")
    this.gui.AddLink(s({ section: "", x: c1, y: "s" }), "程序")
    this.gui.AddLink(s({ x: c2, y: "s" }), "热键 " '<a href="/">?</a>').OnEvent(
      "Click", (*) {
        MsgBox(
          "为程序设置热键。`n"
          "# 代表 Win，! 代表 Alt，^ 代表 Ctrl, + 代表 Shift。`n`n"
          "例：" "^!+q 表示 Ctrl + Alt + Shift + Q"
          , "帮助")
      }
    )

    this.gui.AddLink(s({ x: c3, y: "s" }), "窗口标题（可选）" '<a href="/">?</a>').OnEvent(
      "Click", (*) {
        MsgBox("帮助 ⌈呼来唤去⌋ 捕捉程序窗口。`n"
          "可填写正则表达式，或窗口标题的部分内容。"
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
        return match ? match[1] : "选择"
      }
      appSelect := this.gui.AddButton(s({ section: "", x: "s", y: isFirst ? "s" : "+-1", w: w1, r: 1, "-wrap -VScroll": "" }), appSelectTxt())
      appSelect.OnEvent(
        "Click", (gui, info) {
          fileChoice := FileSelect(32)
          if (fileChoice) {
            entry["run"] := fileChoice
            gui.Text := appSelectTxt()
          }
        }
      )
      hotkeyInput := this.gui.AddEdit(s({ x: c2, y: "s+2", w: w2, r: 1, "-wrap -VScroll": "" }), entry["hotkey"])
      hotkeyInput.onEvent("Change", (gui, info) {
        entry["hotkey"] := gui.Value
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
        }
      )
    }

  }
  GUI_CLASS := {
    "CHECKBOX": "checkbox",
    "MOD_SELECT": "mod_select",
    "SUFFIX_INPUT": "suffix_input",
    "LINK": "link",
  }
  ; Create a control of a given type, and bind it to the data
  _addControl(guiType, payload := "", data := 0, dataKey := 0, styleOpt := false) {
    if (IsObject(styleOpt)) {
      styleOpt := s(styleOpt)
    }
    if (data && dataKey) {
      dataValue := data[dataKey]
    }
    switch guiType {
      case this.GUI_CLASS.LINK:
        return this.gui.AddLink(styleOpt || "ys", "<a>" payload "</a>")
      case this.GUI_CLASS.CHECKBOX:
        checkbox := this.gui.AddCheckbox(styleOpt || "section xs y+10", payload)
        checkbox.Value := dataValue
        checkbox.OnEvent("Click", (gui, info) {
          data[dataKey] := gui.Value
        })
        return checkbox
      case this.GUI_CLASS.MOD_SELECT:
        this.gui.AddText(styleOpt || "section xs y+10", payload)
        modDict := UMap("#", "Win", "^", "Ctrl", "!", "Alt", "+", "Shift")
        isFirst := true
        for modKey, modText in modDict {
          addMod(modKey, modText, isFirst)
          isFirst := false
        }
        addMod(modKey, modText, isFirst) {
          option := isFirst ? "ys x+15" : "ys"
          checkbox := this.gui.AddCheckbox(option, modText)
          checkbox.Value := hasVal(dataValue, modKey)
          checkbox.OnEvent("Click", (gui, info) {
            if (gui.Value) {
              pushDedupe(dataValue, modKey)
            } else {
              deleteVal(dataValue, modKey)
            }
          })
        }
      case this.GUI_CLASS.SUFFIX_INPUT:
        this.gui.AddText(styleOpt || "section xs y+15", payload)
        edit := this.gui.AddEdit("ys-5 x+5 w200", joinStrs(dataValue))
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
    this._addControl(this.GUI_CLASS.CHECKBOX, "开机自启动", miscConfig, "autoStart", "section xs ys")
    this._addControl(this.GUI_CLASS.CHECKBOX, "优先使用已经启动的程序实例", miscConfig, "reuseExistingWindow")
    this._addControl(this.GUI_CLASS.CHECKBOX, "唤起新窗口时隐藏当前唤起的窗口", miscConfig, "singleActiveWindow")
    this._addControl(this.GUI_CLASS.CHECKBOX, "最小化而不是隐藏", miscConfig, "minimizeInstead")
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
      }
    }
  }
  _stopMainScript() {
    if (this.isMainRunning) {
      stopMain()
      this.isMainRunning := false
      if (this.HasProp("gui")) {
        this.gui.MenuBar.Rename(this.STATE_RUNNING, this.STATE_IDLE)
      }
    }
  }
}

setupTray()
instance := Configurator()
if (!hasVal(A_Args, "--no-gui")) {
  instance.createGui()
} else {
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
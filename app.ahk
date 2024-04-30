#SingleInstance Force
#Warn All, OutputDebug
#MaxThreads 32

DetectHiddenWindows(true)
SetTitleMatchMode("RegEx")
SetTitleMatchMode("Fast")
A_FileEncoding := "UTF-16"
VERSION_NUMBER := FileRead(A_ScriptDir "\data\version.txt", "utf-8")

#Include scripts\configuration.ahk
#Include scripts\utils.ahk
#Include scripts\main.ahk

config := readConfig()
hiddenWindowMap := Map()
hiddenWindowMenu := Menu()

class Configurator {
  __New() {
    global config
    this.config := config
  }
  createGui() {
    this._skeleton()
    this._menu()
    this._dynamicTab()
    this._workspaceTab()
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
    this.tab := this.gui.AddTab2(S({
      w: this.guiWidth,
      h: 19, %TCS_HOTTRACK%: "", %TCS_BUTTONS%: "", %TCS_FLATBUTTONS%: "",
      ; "Bottom": "",
      ; "Background": "White",
    }), ["召唤", "绑定", "工作区", "设置"])

    this.tab.UseTab(0)
    BS_FLAT := 0x8000
    btn := this.gui.AddButton(S({ x: this.guiWidth - 60.5, y: "s-3", }), "应用配置")
    btn.OnEvent(
      "Click", (gui, info) {
        ; writeConfig(this.config)
        if (this.isMainRunning) {
          this._stopMainScript()
            ; Sleep(100)
          writeConfig(this.config)
          this._startMainScript()
        }
        updateTray()
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
    ; this._addComponent(this.COMPONENT_CLASS.LINK, '?', , , "ys").OnEvent("Click", (*) {
    ;   MsgBox(
    ;     "为当前活跃窗口绑定老板键。`n"
    ;     "例：浏览网页时按 Win + Shift + 0，之后按 Win + 0 就能显示 / 隐藏该浏览器窗口。`n"
    ;     , "帮助")
    ; })
    this._addComponent(this.COMPONENT_CLASS.CHECKBOX, "绑定时显示提示框", dynamicConfig, "showTip")
    this.gui.AddText("section xs y+13", "修饰键（绑定）  ")
    this._addComponent(this.COMPONENT_CLASS.MOD_SELECT, false, dynamicConfig, "mod_bind")
    this.gui.AddText("section xs y+10", "修饰键（切换）  ")
    this._addComponent(this.COMPONENT_CLASS.MOD_SELECT, false, dynamicConfig, "mod_main")
    this._addComponent(this.COMPONENT_CLASS.SUFFIX_INPUT, "后缀键", dynamicConfig, "suffixs")
    this.gui.AddLink(S({ x: "+5", y: "s" }), '<a href="/">?</a>').OnEvent(
      "Click", (*) {
        MsgBox(
          "可以用作后缀的一组字符`n"
          , "帮助")
      }
    )
    this._addComponent(this.COMPONENT_CLASS.INFO_BOX,
      "绑定功能可以让你随时绑定需要控制的窗口。`n`n"
      "按下【修饰键（绑定）+任一后缀】将当前窗口与某一后缀绑定。`n"
      "按下【修饰键（切换）+任一后缀】切换到与该后缀绑定的窗口。`n`n"
      "例：Win+Shift+0 绑定一个窗口，然后用 Win+0 调起/隐藏该窗口。",
      , , "r6.3 y+10")
  }
  _workspaceTab() {
    this.tab.UseTab(3)
    this.gui.AddText("section x+10 y+10 w0 h0", "")
    workspaceConfig := this.config["workspace"]
    this._addComponent(this.COMPONENT_CLASS.CHECKBOX, '启用工作区', workspaceConfig, "enable", "section xs ys")
    this._addComponent(this.COMPONENT_CLASS.CHECKBOX, "切换工作区时显示提示框", workspaceConfig, "showTip")
    this._addComponent(this.COMPONENT_CLASS.CHECKBOX, "还原窗口位置与大小（较慢）", workspaceConfig, "fullRestore")
    this.gui.AddText("section xs y+13", "修饰键   ")
    this._addComponent(this.COMPONENT_CLASS.MOD_SELECT, false, workspaceConfig, "mod")
    this._addComponent(this.COMPONENT_CLASS.SUFFIX_INPUT, "后缀键", workspaceConfig, "suffixs")
    this.gui.AddLink(S({ x: "+5", y: "s" }), '<a href="/">?</a>').OnEvent(
      "Click", (*) {
        MsgBox(
          "可以用作后缀的一组字符`n"
          , "帮助")
      }
    )
    this._addComponent(this.COMPONENT_CLASS.INFO_BOX,
      "工作区允许你将当前所有窗口的显示状态保存到一个老板键上。`n`n"
      "除默认工作区外，每个后缀都指向一个不同的工作区。`n`n"
      "按下【修饰键+任一后缀】切换到指定的工作区。在工作区内再次按下相应老板键会回到默认工作区。`n`n"
      "例：老板来了按 Win+[，老板走了再按一下。",
      , , "r8.2 y+15")
  }
  _shortcutTab() {
    this.tab.UseTab(1)
    this.gui.AddText("section x+10 y+10 w0 h0", "")
    shortcutConfig := this.config["shortcuts"]
    c1 := 10
    c2 := this.guiWidth * 0.34
    c3 := this.guiWidth * 0.66
    c4 := this.guiWidth - 20
    w1 := c2 - c1 - 7
    w2 := c3 - c2 - 7
    w3 := c4 - c3 - 7
    w4 := 20
    ; Headers
    this.gui.AddLink(S({ section: "", x: c1, y: "s", c: "787878" }), "程序 "
      '<a href="/">?</a>'
    ).OnEvent(
      "Click", (*) {
        MsgBox(
          "也可以是文件或快捷方式`n"
          , "帮助")
      }
    )
    this.gui.AddLink(S({ x: c2, y: "s", c: "787878" }), "老板键 "
      '<a href="/">?</a>'
    ).OnEvent(
      "Click", (*) {
        MsgBox(
          "用于唤起 / 隐藏该程序的热键`n"
          , "帮助")
      }
    )

    this.gui.AddLink(S({ x: c3, y: "s", c: "787878" }), "窗口匹配方式 "
      '<a href="/">?</a>'
    ).OnEvent(
      "Click", (*) {
        MsgBox(
          "如何捕捉属于该程序的窗口`n"
          , "帮助")
      }
    )
    this.gui.SetFont("")

    ; this.gui.AddProgress(s({ Background: "AAAAAA", h: 1, w: this.guiWidth - 50, x: "s", y: "+5" }))

    this.gui.AddButton(S({ x: c4, y: "s-7", }), "+").OnEvent(
      "Click", (gui, info) {
        this.tab.UseTab(1)
        shortcutConfig.Push(makeShortcut())
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
      appSelect := this.gui.AddButton(S({ section: "", x: "s", y: isFirst ? "s" : "+-1", w: w1, r: 1, "-wrap -VScroll": "" }), appSelectTxt() || "选择")
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
      hotkeyButton := this.gui.AddButton(S({ x: c2, y: "s", w: w2, r: 1, "-wrap -VScroll": "" }), EscapeAmpersand(FormatHotkeyShorthand(entry["hotkey"])) || "配置")
      hotkeyButton.onEvent("Click", (target, info) {
        customHotkeyWnd := Gui("-MinimizeBox -MaximizeBox", appSelect.Text == "选择" ? "配置老板键" : "配置 " appSelect.Text " 的老板键")
        this.subGuis.Push(customHotkeyWnd)
        customHotkeyWnd.MarginX := 10
        customHotkeyWnd.MarginY := 10
        parseResult := ParseHotkeyShorthand(entry["hotkey"])
        hotkeyObj := parseResult || { mods: [], key: "" }
        customHotkeyWnd.AddText("section y+10 w0 h0", "")
        this._addComponent(this.COMPONENT_CLASS.MOD_SELECT, "", hotkeyObj, "mods", false, customHotkeyWnd)
        oldKey := StrUpper(hotkeyObj["key"])
        customHotkeyWnd.AddEdit(S({ x: "+2", y: "s-3", w: 20 }), oldKey).OnEvent("Change", (target, info) {
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
        customHotkeyWnd.AddText(S({ x: "s", y: "+20", section: "" }), "AHK (高级)")
        advancedEdit := customHotkeyWnd.AddEdit(S({ x: "+5", y: "s-3", w: 145 }), parseResult ? "" : entry["hotkey"])
        customHotkeyWnd.AddLink(S({ x: "+2" }), '<a href="/">?</a>').OnEvent(
          "Click", (*) {
            MsgBox(
              "使用 AHK 格式配置更高级的老板键。会覆盖上方的设置"
              , "帮助")
          }
        )
        customHotkeyWnd.AddButton(S({ x: "s" }), "确定").OnEvent("Click", (gui, info) {
          if (advancedEdit.Text) {
            entry["hotkey"] := advancedEdit.Text
          } else {
            entry["hotkey"] := ToShorthand(hotkeyObj)
          }
          hotkeyButton.Text := EscapeAmpersand(FormatHotkeyShorthand(entry["hotkey"]))
          customHotkeyWnd.Destroy()
        })
        customHotkeyWnd.AddButton(S({ x: "+5" }), "取消").OnEvent("Click", (gui, info) {
          customHotkeyWnd.Destroy()
        })
        customHotkeyWnd.Show()
      })
      entryCapture := entry["capture"]
      CAPTURE_MODES := ["自动", "进程+类名", "进程+类名+标题"]
      captureButton := this.gui.AddButton(S({ x: c3, y: "s", w: w3, r: 1, "-wrap -VScroll": "" }), CAPTURE_MODES[entryCapture["mode"]])
      captureButton.onEvent("Click", (target, info) {
        captureWnd := Gui("-MinimizeBox -MaximizeBox", "配置" (appSelect.Text == "选择" ? "" : " " appSelect.Text " 的") "匹配方式")
        this.subGuis.Push(captureWnd)
        captureWnd.MarginX := 10
        captureWnd.MarginY := 10
        captureWnd.AddText("section", "模式：")
        modeDropDown := captureWnd.AddDropDownList("ys-3 x+1", CAPTURE_MODES)
        modeDropDown.Value := entryCapture["mode"]
        modeDropDown.OnEvent("Change", (gui, info) {
          _updateAdditionals()
        })
        captureWnd.AddLink(S({ x: "+10", y: "s" }), '<a href="/">?</a>').OnEvent(
          "Click", (*) {
            MsgBox(
              "【自动】无需额外配置，捕捉新出现的有标题非置顶窗口。`n`n"
              "【进程+类名】更稳定且支持捕捉已存在的窗口。进程与类名可以用吸取工具自动填写。`n`n"
              "【进程+类名+标题】在前者基础上匹配窗口标题，适合网页应用等情况。`n`n`n"
              ; "只有【匹配进程,类名,标题】模式不会过滤 置顶/隐藏/系统 窗口。`n`n`n"
              "进程、类名、标题均为正则表达式，用 .* 表示任意长度的通配。"
              , "帮助")
          }
        )
        captureWnd.AddText("xs-3 y+10 w210 h1.2 Backgroundb5b5b5")
        SPY_TEXT_ON := "🧲 吸取中 ..."
        SPY_TEXT_OFF := "🧲 吸取窗口信息"
        spyButton := captureWnd.AddButton("section ys+30 xs w100 Center", SPY_TEXT_OFF)
        isSpying := false
        spyButton.OnEvent("Click", (gui, info) {
          if (isSpying) {
            isSpying := false
            spyButton.Text := SPY_TEXT_OFF
            ToolTip()
          }
          else {
            isSpying := true
            spyButton.Text := SPY_TEXT_ON
            currentExe := WinGetProcessPath("A")
              ; OutputDebug("ahk_exe ^(?!\Q" currentExe "\E).*$")
            SetTimer(() {
              TimedTip("请点击目标窗口", 5000, 10, 80)
              newWnd := WinWaitActive("ahk_exe ^(?!\Q" currentExe "\E).*$", , 20)
              if (!isSpying) {
                return
              }
              isSpying := false
              spyButton.Text := SPY_TEXT_OFF
              ToolTip()
              if (!newWnd) {
                MsgBox("窗口吸取失败！")
              } else {
                WinActivate(this.gui)
                WinActivate(captureWnd)
                titleEdit.Value := "^" EscapeRegex(WinGetTitle(newWnd)) "$"
                processEdit.Value := "^" EscapeRegex(WinGetProcessPath(newWnd)) "$"
                classEdit.Value := "^" EscapeRegex(WinGetClass(newWnd)) "$"
              }
            }, -1)
          }
        })
        processLabel := captureWnd.AddText("xs section", "进程：")
        processEdit := captureWnd.AddEdit("x+1 ys-3 h20 w220", entryCapture["process"])
        classLabel := captureWnd.AddText("xs section", "类名：")
        classEdit := captureWnd.AddEdit("x+1 ys-3 h20 w220", entryCapture["class"])
        titleLabel := captureWnd.AddText("xs section", "标题：")
        titleEdit := captureWnd.AddEdit("x+1 ys-3 h20 w220", entryCapture["title"])
        _updateAdditionals() {
          spyButton.Enabled := modeDropDown.Value >= 2
          processLabel.Enabled := modeDropDown.Value >= 2
          processEdit.Enabled := modeDropDown.Value >= 2
          classLabel.Enabled := modeDropDown.Value >= 2
          classEdit.Enabled := modeDropDown.Value >= 2
          titleLabel.Enabled := modeDropDown.Value >= 3
          titleEdit.Enabled := modeDropDown.Value >= 3
        }
        _updateAdditionals()
        captureWnd.AddButton(S({ x: "s" }), "确定").OnEvent("Click", (gui, info) {
          entryCapture["mode"] := modeDropDown.Value
          entryCapture["process"] := processEdit.Value
          entryCapture["class"] := classEdit.Value
          entryCapture["title"] := titleEdit.Value
          captureButton.Text := CAPTURE_MODES[entryCapture["mode"]]
          captureWnd.Destroy()
        })
        captureWnd.AddButton(S({ x: "+5" }), "取消").OnEvent("Click", (gui, info) {
          captureWnd.Destroy()
        })
        captureWnd.Show()
      })
      removeBtn := this.gui.AddButton(S({ x: c4, y: "s" }), "-")
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
    "INFO_BOX": "info_box",
  }
  ; Create a component of a given type, and bind it to the data
  _addComponent(guiType, payload := "", data := 0, dataKey := 0, styleOpt := false, gui := this.gui) {
    if (IsObject(styleOpt)) {
      styleOpt := S(styleOpt)
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
          checkbox.Value := HasVal(dataValue, modKey)
          checkbox.OnEvent("Click", (gui, info) {
            if (gui.Value) {
              PushDedupe(dataValue, modKey)
            } else {
              DeleteVal(dataValue, modKey)
            }
          })
        }
      case this.COMPONENT_CLASS.SUFFIX_INPUT:
        gui.AddText(styleOpt || "section xs y+15", payload)
        edit := gui.AddEdit("ys-5 x+5 w200", JoinStrs(dataValue))
        edit.onEvent("Change", (gui, info) {
          data[dataKey] := Dedupe(StrSplit(gui.Value))
            ; gui.Value := joinStrs(config[dataKey])
        })
      case this.COMPONENT_CLASS.INFO_BOX:
        gui.AddGroupBox(S({ section: "", w: this.guiWidth - 20, r: 2.5, x: 10, y: "+5", c: "111111" }) " " styleOpt)
        gui.AddText(S({ x: "s+5", y: "s+18", c: "333333", w: this.guiWidth - 40 }), payload)
        gui.SetFont("w500")
        gui.AddText(S({ x: "s+5", y: "s+1", c: "196ebf" }), " 帮助 ")
        gui.SetFont("")
      default:
    }
  }
  _miscTab() {
    this.tab.UseTab(4)
    this.gui.AddText("section x+10 y+10 w0 h0", "")
    miscConfig := this.config["misc"]
    this.gui.AddText("section xs ys c676767", "通用")
    this._addComponent(this.COMPONENT_CLASS.CHECKBOX, "开机自启动", miscConfig, "autoStart")
    this._addComponent(this.COMPONENT_CLASS.CHECKBOX, "后台运行", miscConfig, "minimizeToTray")
    this._addComponent(this.COMPONENT_CLASS.CHECKBOX, "后台运行时隐藏托盘图标", miscConfig, "hideTray")
    this.gui.AddLink(S({ x: "+0", y: "s+1" }), '(<a href="/">注意</a>)').OnEvent(
      "Click", (*) {
        MsgBox(
          "隐藏托盘图标后，你可以通过重新打开『呼来唤去』调出配置窗口。`n"
          "在 “停止” 状态下关闭配置窗口可退出『呼来唤去』。`n"
          , "注意")
      }
    )
    this.gui.AddText("xs y+20 c676767", "行为")
    this._addComponent(this.COMPONENT_CLASS.CHECKBOX, "启用过渡动画", miscConfig, "transitionAnim")
    this._addComponent(this.COMPONENT_CLASS.CHECKBOX, "召唤已经存在的窗口", miscConfig, "reuseExistingWindow")
    this.gui.AddLink(S({ x: "+0", y: "s" }), '<a href="/">?</a>').OnEvent(
      "Click", (*) {
        MsgBox(
          "勾选后，会尝试在现有窗口中匹配目标窗口，而非总是启动新的程序实例（仅在非自动模式中有效）。`n"
          , "帮助")
      }
    )
    this._addComponent(this.COMPONENT_CLASS.CHECKBOX, "唤起新窗口时隐藏当前唤起的窗口", miscConfig, "singleActiveWindow")
    this._addComponent(this.COMPONENT_CLASS.CHECKBOX, "最小化而不是隐藏窗口", miscConfig, "minimizeInstead")
    this._addComponent(this.COMPONENT_CLASS.CHECKBOX, "使用旧版匹配方式", miscConfig, "alternativeCapture")
    this.gui.AddLink(S({ x: "+0", y: "s" }), '<a href="/">?</a>').OnEvent(
      "Click", (*) {
        MsgBox(
          "启用时仅匹配最上方的窗口，关闭时遍历所有窗口。`n"
          , "帮助")
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

updateTray()
setupTray()
instance := Configurator()
if (HasVal(A_Args, "--no-gui") && config["misc"]["minimizeToTray"]) {
} else {
  instance.createGui()
}
instance._startMainScript()

addHiddenSubmenu(id) {
  global hiddenWindowMap
  if (!hiddenWindowMap.Has(id)) {
    name := LimitStr(WinGetTitle(id))
    hiddenWindowMap[id] := name
    hiddenWindowMenu.Add(name, (name, pos, menu) {
      popWndHandler(id)
    })
    updateHiddenSubmenu()
  }
}

removeHiddenSubmenu(id) {
  try {
    hiddenWindowMenu.Delete(hiddenWindowMap[id])
    hiddenWindowMap.Delete(id)
    updateHiddenSubmenu()
  }
}

updateHiddenSubmenu() {
  try {
    global hiddenWindowMap
    static currentName := "还原窗口"
    n := hiddenWindowMap.Count
    newName := "还原窗口（" n "）"
    A_TrayMenu.Rename(currentName, newName)
    currentName := newName

    if (n == 0) {
      A_TrayMenu.Disable(currentName)
    } else {
      A_TrayMenu.Enable(currentName)
    }
  }
}

setupTray() {
  global ICON_PATH
  global hiddenWindowMenu

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
  A_TrayMenu.Add("还原窗口", hiddenWindowMenu)
  hiddenWindowMenu.Add("全部还原", (*) {
    clearWndHandlers()
  })
  updateHiddenSubmenu()
  A_TrayMenu.Add("退出", (*) {
    ; Have to delete the menu before exiting, other wise it will cause a crash
    A_TrayMenu.Delete()
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

updateTray() {
  if (config["misc"]["hideTray"] || !config["misc"]["minimizeToTray"]) {
    A_IconHidden := true
  } else {
    A_IconHidden := false
  }
}
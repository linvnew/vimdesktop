﻿/*
    此插件仅供自用，依赖对 DC 代码的修改以及专门的配置

    ---

    DC 的优势

    开源，免费，跨平台，可以自由改代码定制功能，很好编译
    可以改代码让所有目录中的父目录（..）消失（已完成）
    可以把按键绑定到工具栏的子菜单上，然后再通过按键触发功能
    内建 lua 解释器，方便写一些高级功能（感觉功能有限，用处不大）
    主界面和配置界面更漂亮、好用
*/

DoubleCommander:
    global DC_Class := "TTOTAL_CMD"
    global DC := "ahk_class " . DC_Class
    global DC_Dir := "c:\mine\app\doublecmd"
    global DC_Path := "c:\mine\app\doublecmd\doublecmd.exe --no-splash"
    ; 用于记录文件打开对话框所属窗体
    global DC_CallerId := 0

    DC_Name := "DoubleCommander"

    Vim.SetWin(DC_Name, DC_Class, "doublecmd.exe")
    Vim.Mode("normal", DC_Name)

    Vim.BeforeActionDo("DC_ForceInsertMode", DC_Name)
return

DC_ForceInsertMode() {
    ControlGetFocus, Ctrl
    if (InStr(Ctrl, "Edit") || Ctrl == "Window1") {
        return true
    }

    WinGet, MenuID, ID, AHK_CLASS #32768
    if (MenuID != "") {
        return true
    }

    return false
}

DC_Run(Cmd) {
    ControlSetText, Edit1, % Cmd, % DC
    ControlSend, Edit1, {Enter}, % DC
}

DC_RunGet(Cmd, SaveClipboard := True) {
    if (SaveClipboard) {
        ClipSaved := ClipboardAll
    }

    Clipboard := ""

    DC_Run(Cmd)

    ClipWait, 1

    if (SaveClipboard) {
        Result := Clipboard

        Clipboard := ClipSaved
        ClipSaved := ""

        return Result
    }

    return Clipboard
}

; 返回值 [1]: left/right [2]: 左侧面板所占比例 0-100
DC_GetPanelInfo() {
    return StrSplit(DC_RunGet("cm_CopyPanelInfoToClip"), " ")
}

DC_ExecuteToolbarItem(ID) {
    DC_Run("cm_ExecuteToolbarItem ToolItemID=" . ID)
}

DC_OpenPath(Path, InNewTab := true, LeftOrRight := "") {
    LeftOfRight := DC_GetPanelInfo()[1]
    if (LeftOfRight == "right") {
        LeftOrRight := "-R"
    } else {
        LeftOrRight := "-L"
    }

    if (InNewTab) {
        Run, %DC_Path% -C -T "%LeftOrRight%" "%Path%"
    } else {
        Run, %DC_Path% -C "%LeftOrRight%" "%Path%"
    }
}

; funcend

<DC_Test>:
    ; DC_ExecuteToolbarItem("{700FF494-B939-48A3-B248-8823EB366AEA}")
    DC_Run("cm_About")
return

<DC_Restart>:
    WinClose, % DC
    WinWaitClose, % DC, , 2

    Run, % DC_Path

    WinWaitActive, % DC

    if (!WinExist(DC)) {
        MsgBox, 重启失败 %ErrorMessage%
    }
return

<DC_Toggle_50_100>:
    PanelInfo := DC_GetPanelInfo()

    if (Abs(50 - PanelInfo[2]) < 10) {
        if (PanelInfo[1] == "left") {
            DC_Run("cm_PanelsSplitterPerPos splitpct=100")
        } else {
            DC_Run("cm_PanelsSplitterPerPos splitpct=0")
        }
    } else {
        DC_Run("cm_PanelsSplitterPerPos splitpct=50")
    }
return

<DC_PrevParallelDir>:
    SleepTime := 50

    OldPwd := DC_RunGet("cm_CopyCurrentPathToClip")

    if (StrLen(OldPwd) == 3) {
        ; 在根分区

        return
    }

    DC_Run("cm_ChangeDirToParent")
    Sleep, % SleepTime

    ; 可能没跳转过去 TODO
    DC_Run("cm_GoToPrevEntry")
    Sleep, % SleepTime

    DC_Run("cm_EnterActiveDir")
    Sleep, % SleepTime
return

<DC_NextParallelDir>:
    SleepTime := 50

    OldPwd := DC_RunGet("cm_CopyCurrentPathToClip")

    if (StrLen(OldPwd) == 3) {
        ; 在根分区

        return
    }

    DC_Run("cm_ChangeDirToParent")
    Sleep, % SleepTime

    ; 可能没跳转过去 TODO
    DC_Run("cm_GoToNextEntry")
    Sleep, % SleepTime

    DC_Run("cm_EnterActiveDir")
    Sleep, % SleepTime

    Pwd := DC_RunGet("cm_CopyCurrentPathToClip", false)
    Sleep, % SleepTime

    if (OldPwd != Pwd && InStr(OldPwd, Pwd) == 1) {
        ; 下一个是文件
        DC_Run("cm_ViewHistoryPrev")
    }
return

<DC_CreateNewFile>:
    ControlGetFocus, TLB, % DC
    ControlGetPos, Xn, Yn, , , % TLB, % DC

    Menu, NewFileMenu, Add
    Menu, NewFileMenu, DeleteAll
    Menu, NewFileMenu, Add , S >> 快捷方式, <DC_CreateFileShortcut>
    Menu, NewFileMenu, Icon, S >> 快捷方式, %A_WinDir%\system32\Shell32.dll, 264
    Menu, NewFileMenu, Add

    Loop, % DC_Dir . "\shellnew\*.*" {
        Ft := SubStr(A_LoopFileName, 1, 1) . " >> " . A_LoopFileName
        Menu, NewFileMenu, Add, % Ft, DC_NewFileMenuAction
        Menu, NewFileMenu, Icon, % Ft, %A_WinDir%\system32\Shell32.dll
    }

    Menu, NewFileMenu, Show, % Xn, % Yn + 2
return

DC_NewFileMenuAction:
    Filename := RegExReplace(A_ThisMenuItem, ".\s>>\s")
    FilePath := DC_Dir . "\ShellNew\" . Filename

    Gui, Destroy
    Gui, Add, Text, x12 y20 w50 h20 +Center, 模板源
    Gui, Add, Edit, x72 y20 w300 h20 Disabled, % FilePath
    Gui, Add, Text, x12 y50 w50 h20 +Center, 新建文件
    Gui, Add, Edit, x72 y50 w300 h20, % Filename
    Gui, Add, Button, x162 y80 w90 h30 gDC_NewFileOk default, 确认(&S)
    Gui, Add, Button, x282 y80 w90 h30 gDC_NewFileClose , 取消(&C)
    Gui, Show, w400 h120, 新建文件

    if (InStr(Filename, ".")) {
        ; 只选定扩展名之外的文件名
        PostMessage, 0x0B1, 0, % InStr(Filename, ".") - 1, Edit2, A
    }
return

DC_NewFileClose:
    Gui, Destroy
return

DC_NewFileOK:
    GuiControlGet, SrcFilePath, , Edit1
    GuiControlGet, NewFilename, , Edit2

    DstPath := DC_RunGet("cm_CopyCurrentPathToClip")

    if (InStr(DstPath, "`r")) {
        DstPath := SubStr(DstPath, 1, InStr(DstPath, "`r") - 1)
    } else if (DstPath == "") {
        return
    }

    NewFilePath := DstPath . NewFilename
    if (FileExist(NewFilePath)) {
        MsgBox, 4, 新建文件, 新建文件已存在，是否覆盖？
        IfMsgBox No
            return
    }

    FileCopy, % SrcFilePath, % NewFilePath, 1

    ; 虽然不是完全匹配，基本也能用了
    DC_Run("cm_QuickSearch matchbeginning=on | text=" . NewFilename)

    Gui, Destroy
return

<DC_Toggle>:
    if (WinExist(DC)) {
        WinGet, Ac, MinMax, % DC
        if (Ac == -1) {
            WinActivate, % DC
        } else {
            if (!WinActive(DC)) {
                WinActivate, % DC
            } else {
                WinMinimize, % DC
            }
        }
    } else {
        Run, % DC_Path
        WinWait, % DC

        if (!WinActive(DC)) {
            WinActivate, % DC
        }
    }
return

<DC_MarkFile>:
    DC_Run("cm_EditComment")
    ; 不要在已有备注的文件使用
    Send, ^+{End}🖥{F2}
return

<DC_UnMarkFile>:
    DC_Run("cm_EditComment")
    ; 删除 DC_MarkFile 的文件标记，也可用于清空文件备注
    Send, ^+{End}{Del}{F2}
return

<DC_ToggleShowInfo>:
    Vim.GetWin(DC_Name).SetInfo(!Vim.GetWin(DC_Name).info)
return

<DC_CopyFileContent>:
    Fileread, Contents, % DC_RunGet("cm_CopyFullNamesToClip", false)
    Clipboard := Contents
return

<DC_CopyFilenamesOnly>:
    Result := DC_RunGet("cm_CopyFullNamesToClip")

    SplitPath, Result, OutFileName, , , OutFilenameNoExt

    if (InStr(FileExist(Result), "D")) {
        Clipboard := OutFileName
    } else if (InStr(Result, ".")) {
        Clipboard := OutFilenameNoExt
    }
return

<DC_CreateFileShortcut>:
    FilePath := DC_RunGet("cm_CopyFullNamesToClip")

    OutVar := FileExist(FilePath)
    if (InStr(OutVar, "D")) {
        FileCreateShortcut, % FilePath, % FilePath . ".lnk"
    } else if (OutVar != "") {
        FileCreateShortcut, % FilePath, % RegExReplace(FilePath, "\.[^.]*$", ".lnk")
    }
return

<DC_Focus>:
    IfWinExist, % DC
        Winactivate, % DC
    else {
        Run, % DC_Path
        WinWait, % DC
        IfWinNotActive, % DC
            WinActivate, % DC
    }
return

<DC_MapKeys>:
	Vim.Mode("normal", DC_Name)
    Vim.Map("<S-Enter>", "<DC_SelectedCurrentDir>", DC_Name)
    Vim.Map("<Esc>", "<DC_ReturnToCaller>", DC_Name)
return

<DC_UnMapKeys>:
	Vim.Mode("normal", DC_Name)
    Vim.Map("<S-Enter>", "<Default>", DC_Name)
    Vim.Map("<Esc>", "<Default>", DC_Name)
return

; 返回调用者
<DC_ReturnToCaller>:
    gosub <DC_UnMapKeys>

    WinActivate, ahk_id %DC_CallerId%

    DC_CallerId := 0
return

; 非 TC 窗口按下后激活 TC 窗口
; TC 窗口按下后复制当前选中文件返回原窗口后粘贴
<DC_OpenDCDialog>:
    WinGetClass, Name, A

    ; 在 DC 按下快捷键时，激活调用窗体并执行粘贴操作
    if (Name == DC_Class) {
        if (DC_CallerId != 0) {
            gosub <DC_Selected>
            return
		}
    } else {
        DC_CallerId := WinExist("A")
        if (DC_CallerId == 0) {
            return
		}

        gosub <DC_Focus>
        gosub <DC_MapKeys>
    }
return

<DC_Selected>:
    gosub <DC_UnMapKeys>

    if (DC_CallerId == 0) {
        return
    }

    ; 避免发送回车时受其他按键影响
    MsgBox, , , 处理中, 0.3

    Pwd := DC_RunGet("cm_CopyCurrentPathToClip", false)

    Filename := DC_RunGet("cm_CopyNamesToClip", false)

    WinActivate, ahk_id %DC_CallerId%
    WinWait, ahk_id %DC_CallerId%
    DC_CallerId := 0

    if (!InStr(Filename, "`n")) {
        Clipboard := Pwd . Filename
        Send, {Home}
        Send, ^v
        Send, {Enter}

        return
    }

    ; 多选

    Files := ""
    Loop, parse, FIlename, `n, `r
        Files .= """" . A_LoopField  . """ "

    ; 第一步：跳转到当前路径
    Clipboard := Pwd
    Send, ^a
    Send, ^v
    Send, {Enter}
    sleep, 100

    ; 第二步：提交文件名
    Clipboard := Files
    Send, ^v
    Send, {Enter}
return

<DC_SelectedCurrentDir>:
    gosub <DC_UnMapKeys>

    if (DC_CallerId == 0) {
        return
    }

    DC_Run("cm_CopyCurrentPathToClip")

    WinActivate, ahk_id %DC_CallerId%
    WinWait, ahk_id %DC_CallerId%
    DC_CallerId := 0

    Send, {Home}
    Send, ^v
    Send, {Enter}
return

﻿DoubleCommander:
    global DoubleCommander_name := "DoubleCommander"
    global DoubleCommander_class := "DClass"
    global DoubleCommander_exe := "doublecmd.exe"

    ; normal模式
    vim.SetWin(DoubleCommander_name, DoubleCommander_class, DoubleCommander_exe)
    vim.mode("normal", DoubleCommander_name)

    vim.map("h", "<left>", DoubleCommander_name)
    vim.map("j", "<down>", DoubleCommander_name)
    vim.map("k", "<up>", DoubleCommander_name)
    vim.map("l", "<enter>", DoubleCommander_name)
    vim.map("gg", "<DoubleCommander_GoToFirstFile>", DoubleCommander_name)
    vim.map("G", "<end>", DoubleCommander_name)
    vim.map("o", "<DoubleCommander_ContextMenu>", DoubleCommander_name)
    vim.map("<la-r>", "<DoubleCommander_Rename>", DoubleCommander_name)
    vim.map("<f2>", "<DoubleCommander_RenameFull>", DoubleCommander_name)
    vim.map("<c-f>", "<pgdn>", DoubleCommander_name)
    vim.map("<c-b>", "<pgup>", DoubleCommander_name)

    vim.BeforeActionDo("DoubleCommander_ForceInsertMode", DoubleCommander_name)
return

DoubleCommander_ForceInsertMode()
{
    ControlGetFocus, ctrl
    ;MsgBox % ctrl
    if RegExMatch(ctrl, "Edit")
        return true
    return false
}

<DoubleCommander_GoToFirstFile>:
    Send, {home}{down}
return

<DoubleCommander_ContextMenu>:
    Send, {appskey}
return

<DoubleCommander_Rename>:
    Send, {f2}{right}
return

<DoubleCommander_RenameFull>:
    Send, {f2}^a
return

/* 插件缺失功能：

   从模板创建新文件
   进入目录后自动定位到第一个文件
   切换 50% 100% cm_PanelsSplitterPerPos
   切换到上/下一个目录
*/

/* DC 缺失功能：

   查看回收站
   定制主菜单
*/

/* DC 现有问题：

   缩略图加载图片过慢
   内存占用较高
*/
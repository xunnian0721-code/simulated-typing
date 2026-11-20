#Requires AutoHotkey v2.0
#SingleInstance Force
#MaxThreadsPerHotkey 1

typing := false
stopRequested := false

window := Gui(, "模拟打字")
window.MarginX := 20
window.MarginY := 16
window.SetFont("s10", "Microsoft YaHei UI")
window.AddText("xm ym w90 h26 +0x200", "文本来源")
sourceMode := window.AddDropDownList("x+8 yp w182 Choose1", ["窗口中的文本", "系统剪贴板"])
sourceMode.OnEvent("Change", ChangeSource)
sourceEdit := window.AddEdit("xm y+12 w480 h170")

window.AddText("xm y+14 w200 h24 +0x200", "字符间隔（毫秒）")
keyDelayMin := window.AddEdit("x+8 yp w62 h24 Number Limit5", "50")
window.AddText("x+8 yp w22 h24 Center +0x200", "至")
keyDelayMax := window.AddEdit("x+8 yp w62 h24 Number Limit5", "250")

window.AddText("xm y+8 w200 h24 +0x200", "标点和换行额外停顿（毫秒）")
punctuationDelayMin := window.AddEdit("x+8 yp w62 h24 Number Limit5", "200")
window.AddText("x+8 yp w22 h24 Center +0x200", "至")
punctuationDelayMax := window.AddEdit("x+8 yp w62 h24 Number Limit5", "800")

window.AddText("xm y+8 w200 h24 +0x200", "错字率（%）")
typoPercent := window.AddEdit("x+8 yp w62 h24 Number Limit3", "2")
window.AddText("x+12 yp w198 h24 +0x200", "仅英文字母和假名，0 为关闭")

window.AddText("xm y+16 w480", "点进目标输入框后按 F8 开始，按 F9 停止。")
status := window.AddText("xm y+8 w344 h34 +0x200", "就绪")
window.AddButton("x+12 yp w124 h34", "收起窗口").OnEvent("Click", (*) => window.Minimize())
window.OnEvent("Close", (*) => ExitApp())
A_TrayMenu.Add("打开模拟打字", (*) => window.Show())
A_TrayMenu.Default := "打开模拟打字"
A_IconTip := "模拟打字"
window.Show()
sourceEdit.Focus()

F8 Up::StartTyping()

#HotIf typing
*F9::RequestStop()
#HotIf

RequestStop() {
    global stopRequested
    stopRequested := true
}

ChangeSource(control, *) {
    global sourceEdit
    sourceEdit.Enabled := control.Value = 1
}

StartTyping() {
    global typing, stopRequested
    global keyDelayMin, keyDelayMax, punctuationDelayMin, punctuationDelayMax, typoPercent
    global window, sourceMode, sourceEdit, status

    targetWindow := WinExist("A")
    if (!targetWindow || targetWindow = window.Hwnd) {
        ShowInputError("请先点进目标输入框。")
        return
    }
    source := sourceMode.Value = 1 ? sourceEdit.Value : A_Clipboard
    if (source == "") {
        ShowInputError("所选来源没有文本。")
        return
    }
    source := RegExReplace(source, "\r\n?", "`n")

    keyMin := keyDelayMin.Value
    keyMax := keyDelayMax.Value
    punctuationMin := punctuationDelayMin.Value
    punctuationMax := punctuationDelayMax.Value
    errorRate := typoPercent.Value
    if (!IsDelayRange(keyMin, keyMax) || !IsDelayRange(punctuationMin, punctuationMax)) {
        ShowInputError("请输入有效的停顿范围，下限不能高于上限。")
        return
    }
    if (!RegExMatch(errorRate, "\A[0-9]{1,3}\z") || errorRate > 100) {
        ShowInputError("错字率须为 0 到 100 的整数。")
        return
    }
    keyMin := Integer(keyMin)
    keyMax := Integer(keyMax)
    punctuationMin := Integer(punctuationMin)
    punctuationMax := Integer(punctuationMax)
    errorRate := Integer(errorRate)

    stopRequested := false
    typing := true
    completed := false
    status.Text := "正在输入…"
    try {
        position := 1
        sourceLength := StrLen(source)
        ; Match grapheme clusters to keep surrogate pairs and combining marks together.
        while (position <= sourceLength && CanType(targetWindow)) {
            if !RegExMatch(source, "\G\X", &match, position)
                break
            character := match[0]
            position += match.Len

            typo := ""
            if (errorRate > 0 && Random(1, 100) <= errorRate)
                typo := ChooseTypo(character)

            if (typo != "") {
                SendText typo
                if !WaitWhileTyping(Random(120, 300), targetWindow)
                    break
                Send "{Backspace}"
                if !WaitWhileTyping(Random(60, 140), targetWindow)
                    break
            }

            if !CanType(targetWindow)
                break
            if (character == "`t")
                Send "{U+0009}"
            else
                SendText character

            if (position > sourceLength) {
                completed := true
                break
            }
            delay := Random(keyMin, keyMax)
            if (character == "`n" || RegExMatch(character, "^\p{P}"))
                delay += Random(punctuationMin, punctuationMax)
            if !WaitWhileTyping(delay, targetWindow)
                break
        }
    } finally {
        typing := false
        status.Text := completed ? "输入完成" : "已停止"
    }
}

IsDelayRange(minimum, maximum) {
    return RegExMatch(minimum, "\A[0-9]{1,5}\z")
        && RegExMatch(maximum, "\A[0-9]{1,5}\z")
        && Integer(minimum) <= Integer(maximum)
}

ShowInputError(message) {
    global status
    status.Text := message
    ToolTip message
    SetTimer ClearTip, -2500
}

ClearTip() => ToolTip()

CanType(targetWindow) {
    global stopRequested
    return !stopRequested && WinActive("ahk_id " targetWindow)
}

WaitWhileTyping(delay, targetWindow) {
    deadline := DllCall("GetTickCount64", "UInt64") + delay
    while CanType(targetWindow) {
        remaining := deadline - DllCall("GetTickCount64", "UInt64")
        if (remaining <= 0)
            return true
        Sleep Min(remaining, 20)
    }
    return false
}

ChooseTypo(character) {
    ; Limit Backspace corrections to simple letters and kana.
    if RegExMatch(character, "\A[a-z]\z")
        alternatives := "abcdefghijklmnopqrstuvwxyz"
    else if RegExMatch(character, "\A[A-Z]\z")
        alternatives := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    else if RegExMatch(character, "\A[ぁ-ゖ]\z")
        alternatives := "あいうえおかきくけこさしすせそたちつてとなにぬねの"
    else if RegExMatch(character, "\A[ァ-ヺ]\z")
        alternatives := "アイウエオカキクケコサシスセソタチツテトナニヌネノ"
    else
        return ""

    alternatives := StrReplace(alternatives, character, "", true)
    return SubStr(alternatives, Random(1, StrLen(alternatives)), 1)
}

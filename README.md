# 模拟打字 (Simulated Typing)

把一段文字像真人一样逐字「打」进任意输入框：字与字之间有随机间隔，标点和换行后会多停一下，还可以偶尔打错再退格改正。直接发送 Unicode 文本，中文、日语都不用切换输入法。

## 下载

到 [Releases](../../releases/latest) 下载 `SimulatedTyping.exe`，双击就能用（64 位 Windows 10 / 11，不用安装任何东西）。

## 使用

1. 双击 `SimulatedTyping.exe`。
2. 把要输入的文本粘贴到程序窗口，或把文本来源切换为「系统剪贴板」。选择剪贴板时，程序在每次按 `F8` 时读取文本。
3. 点击目标输入框后按 `F8` 开始，按 `F9` 停止。切换到另一个窗口也会停止。可用「收起窗口」最小化程序，双击托盘图标重新打开，或关闭程序窗口退出。

在程序窗口中调整参数，下次按 `F8` 时生效。

| 设置 | 默认值 | 含义 |
| --- | --- | --- |
| 字符间隔 | 50–250 毫秒 | 字符间随机等待的范围 |
| 标点和换行额外停顿 | 200–800 毫秒 | 标点或换行之后额外等待的范围 |
| 错字率 | 2% | 单个英文字母或假名打错后再退格修正的概率，填 0 至 100 的整数，0 为关闭 |

换行会发送 Enter，输入多行时请选择支持 Enter 换行的文本框。制表符以 Unicode 字符发送，是否接收取决于输入框。按 `F9` 时，已输入的内容会留在输入框中，包括可能还没修正的错字。

## 源码与自己编译

程序源码是 [`simulated-typing.ahk`](simulated-typing.ahk)（AutoHotkey v2）。装好 [AutoHotkey v2](https://www.autohotkey.com/) 后可以直接双击运行源码，或用自带的 Ahk2Exe 编译成 exe。

## 许可

- 本项目的脚本以 [MIT 许可](LICENSE) 发布。
- exe 内置的运行环境是 AutoHotkey v2.0.31，许可证见 [`AutoHotkey-LICENSE.txt`](AutoHotkey-LICENSE.txt)，[运行环境源码](https://github.com/AutoHotkey/AutoHotkey/tree/v2.0.31)。

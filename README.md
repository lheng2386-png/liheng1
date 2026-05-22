# Kimi Terminal Starter

这是一个给学校 Windows 10 机房终端使用的 Kimi API PowerShell 小工具，适合 C++、算法题、OJ 题目复习和问答。

使用目标：

- 不需要浏览器登录。
- 不需要手机。
- 不需要 U 盘。
- 只要学校电脑能打开 Windows PowerShell 并联网，就可以从 GitHub Raw 下载脚本运行。
- API Key 只在运行时输入，不会写入仓库、本地文件、日志或回答文件。

## 使用方法

在学校电脑里打开 **Windows PowerShell**，优先复制下面这个短命令运行。

推荐短命令：

```powershell
[Net.ServicePointManager]::SecurityProtocol=3072;iex(iwr -UseBasicParsing https://raw.githubusercontent.com/lheng2386-png/liheng1/main/start_kimi.ps1).Content
```

这个命令会直接从 GitHub Raw 读取 `start_kimi.ps1` 并在当前 PowerShell 窗口运行，不需要记 `-OutFile k.ps1`、`Set-ExecutionPolicy`、`.\k.ps1`。

短命令和下面的备用命令运行的是同一个脚本，功能效果一样。区别是：短命令不保存脚本文件，备用命令会先下载成 `k.ps1` 再运行。

如果短命令不能用，再使用下面的备用方式。

备用多行版：

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
iwr -UseBasicParsing "https://raw.githubusercontent.com/lheng2386-png/liheng1/main/start_kimi.ps1" -OutFile k.ps1
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\k.ps1
```

备用一行版：

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; iwr -UseBasicParsing "https://raw.githubusercontent.com/lheng2386-png/liheng1/main/start_kimi.ps1" -OutFile k.ps1; Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; .\k.ps1
```

启动后会提示输入 Kimi API Key。输入时屏幕不会显示内容，这是正常的。

不要把 API Key 写进脚本，也不要上传到 GitHub。

## 常用命令

| 命令 | 作用 |
| --- | --- |
| `/help` | 查看全部命令 |
| `/clip` | 读取剪贴板文本并发送，适合复制长题目后使用 |
| `/shot` | 读取 Win + Shift + S 截图后的剪贴板图片，并让你补充问题 |
| `/code` | 切换到只输出完整 C++17 代码的模式，适合 OJ 直接提交 |
| `/chat` | 恢复普通中文解释模式，可以讲思路、关键点和代码 |
| `/fast` | 快速模式，尽量简洁回答 |
| `/quality` | 高质量模式，适合复杂题目详细分析 |
| `/reset` | 清空上下文，但保留当前 PowerShell 进程里的 API Key |
| `/model` | 查看当前模型、模式、thinking 状态和上下文数量 |
| `/open` | 用记事本打开上一次回答保存的 `last_answer.txt` |
| `/copy` | 把上一次回答复制到剪贴板 |
| `/clear` | 清屏 |
| `/exit` | 退出 |

## 推荐使用流程

普通问答：

```text
直接输入问题
```

复制长题目：

```text
1. 先复制题目文本
2. 在 PowerShell 里输入 /clip
```

截图题目：

```text
1. 按 Win + Shift + S 截图
2. 在 PowerShell 里输入 /shot
3. 按提示输入问题，例如 Please solve this problem
```

OJ 只要代码：

```text
1. 输入 /code
2. 复制题目后输入 /clip，或直接输入题目
3. 回答会尽量只给完整 C++17 代码，不写解释和 Markdown
```

恢复讲解模式：

```text
/chat
```

终端中文显示乱码：

```text
/open
```

它会用记事本打开当前目录里的 `last_answer.txt`。

## 测试方法

第一次在学校电脑上使用时，建议按下面顺序测试。

### 1. 启动测试

运行启动命令后，应该看到：

```text
Kimi terminal chat starter
Enter Kimi API Key
```

输入 API Key 后，应该进入聊天界面并显示命令帮助。

### 2. 帮助命令测试

输入：

```text
/help
```

应该能看到 `/clip`、`/shot`、`/code`、`/chat`、`/fast`、`/quality`、`/reset`、`/open`、`/copy`、`/model` 等命令。

### 3. 模型信息测试

输入：

```text
/model
```

应该看到当前模型：

```text
Model: kimi-k2.6
```

还应该能看到当前回答模式、thinking 状态和上下文消息数量。

### 4. 普通问答测试

输入：

```text
用中文解释一下 C++ 里的 vector 是什么
```

应该得到中文回答。

### 5. 剪贴板文本测试

先复制一段题目或代码，再输入：

```text
/clip
```

应该提示已读取剪贴板文本，并发送给 Kimi。

如果剪贴板为空，应该提示先复制题目文本，不应该退出程序。

### 6. 代码模式测试

输入：

```text
/code
```

然后输入一道简单题，例如：

```text
写一个 C++17 程序，输入两个整数，输出它们的和
```

回答应该只输出完整 C++17 代码，不应该带解释，也不应该出现 ```cpp 代码块。

### 7. 恢复聊天模式测试

输入：

```text
/chat
```

再问：

```text
解释一下刚才代码的思路
```

应该恢复中文讲解模式。

### 8. 重置上下文测试

输入：

```text
/reset
```

应该提示上下文已清空，但不会要求重新输入 API Key。

### 9. 截图测试

按 `Win + Shift + S` 截图后，输入：

```text
/shot
```

然后按提示输入：

```text
Please solve this problem
```

如果剪贴板里有图片，会把图片发送给 Kimi。

如果读取不到图片，应该给出英文提示，并且程序不会退出，`/clip` 仍然可以继续使用。

### 10. 保存和复制测试

成功得到一次回答后，当前目录应该生成：

```text
last_answer.txt
```

输入：

```text
/open
```

应该用记事本打开上一次回答。

输入：

```text
/copy
```

应该把上一次回答复制到剪贴板。

### 11. 多轮上下文测试

连续问很多轮问题，或者多次使用 `/clip` 后，程序不应该出现类似下面的错误：

```text
Collection was of a fixed size.
RemoveAt
```

如果上下文太长，脚本会自动保留 system prompt，并删除较早的 user/assistant 消息。

## 常见问题

### 下载脚本失败

可能原因：

- 学校网络访问 GitHub Raw 不稳定。
- 代理或校园网限制。
- TLS 设置没有生效。

可以重新复制完整启动命令再试一次。

### 输入命令后提示 401

HTTP 401 通常表示 API Key 不正确、过期，或没有权限。

退出后重新运行脚本，重新输入正确的 Kimi API Key。

### 请求很慢

可以输入：

```text
/fast
```

如果题目复杂，需要更详细分析，再输入：

```text
/quality
```

### 终端中文乱码

每次回答都会保存到 `last_answer.txt`。输入：

```text
/open
```

用记事本查看回答。

### 截图不能读取

先确认是用 `Win + Shift + S` 截图，并且截图后没有复制别的内容。

如果学校电脑限制图片剪贴板读取，可以改用复制题目文本，然后输入：

```text
/clip
```

## 安全说明

- 脚本不会把 API Key 写入 `last_answer.txt`。
- 脚本不会把 API Key 写入 README。
- 脚本不会把 API Key 写入日志。
- 脚本不会打印完整 Authorization header。
- 公开仓库中不要提交任何真实 API Key。

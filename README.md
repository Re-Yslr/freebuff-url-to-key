# Freebuff2API 一键获取 Key 工具

在 Windows 上双击一下，就能自动完成「登录授权 → 获取 Token → 启动本地服务」，最终得到一个可以接入任意 OpenAI 兼容客户端的 **Base URL + API Key**。

> 底层原理：把 Freebuff（AI 编程工具）的免费账号额度，通过本地代理转成标准的 OpenAI 兼容接口。本项目基于 [freebuff2api-wokers](https://github.com/pingmike2/freebuff2api-wokers) 的 Node 版服务。

---

## 一、环境要求

| 项目 | 要求 | 说明 |
|------|------|------|
| 系统 | Windows 10 / 11 | 64 位 |
| Node.js | v18 及以上 | 必装，见下方安装方法 |
| Python | 3.10 及以上 | 登录取 Token 用 |
| 网络 | **美国节点**（科学上网） | 必须，Freebuff 仅允许部分地区访问 |

> 注意：本项目**不适合用 Cloudflare Worker 等云函数部署**（官方已识别封号），请严格使用本地运行模式。

### Node.js 安装（如果没有）

1. 打开 https://nodejs.org 下载 **LTS 版本**（左侧绿色按钮）
2. 一路「下一步」安装完成（不要改默认选项）
3. 安装完重开命令行窗口，输入 `node --version` 能显示版本号即成功

### Python 安装（如果没有）

1. 打开 https://www.python.org/downloads/ 下载最新版
2. 安装时**务必勾选** `Add Python to PATH`
3. 装完重开命令行，输入 `python --version` 能显示版本号即成功

---

## 二、快速开始（3 步）

### 第 1 步：双击 `一键获取key.bat`

- 脚本会自动检查环境、下载项目代码
- **首次运行会自动打开登录流程**，屏幕会打印一个授权链接，例如：
  ```
  https://www.codebuff.com/login?auth_code=xxxxxxxxxxxx
  ```
- 打开这个链接，用 **Google 账号**登录并点「Continue」授权
- 脚本自动轮询，看到「登录成功！」即完成

> 如果窗口里已经有旧账号凭据，脚本会问你「直接复用该账号? (y=复用 / 其他=重新登录)」——按 `y` 回车即可跳过登录。

### 第 2 步：看到输出结果

授权成功后，脚本自动写入配置、启动服务，最后输出：

```
  Base URL : http://localhost:8877/v1
  API Key  : freebuff-api
```

**这两个值就是要分享/使用的接入信息。**

### 第 3 步：配置到你的客户端

以任意 OpenAI 兼容客户端（如 Cherry Studio、Chatbox、NextChat、LobeChat、dsh 等）为例：

| 配置项 | 值 |
|--------|-----|
| Base URL / 接口地址 | `http://localhost:8877/v1` |
| API Key | `freebuff-api` |
| 模型 | 见下方推荐列表 |

推荐模型（免费不限池）：

- `deepseek/deepseek-v4-flash`（推荐）
- `mimo/mimo-v2.5`（推荐）

完整模型列表可以看 `freebuff2api\MODELS.md`，或在客户端里点「获取模型列表」刷新。

---

## 三、日常使用

| 操作 | 方法 |
|------|------|
| 启动服务 | 双击 `一键获取key.bat`（已有账号会直接复用） |
| 停止服务 | 双击 `一键停止key.bat` |
| 换账号 | 双击 `一键获取key.bat`，提示复用时输入非 y 的任意字符，走新账号登录 |
| 验证服务 | 浏览器打开 `http://localhost:8877/healthz`，看到 `"status":"ok"` 即正常 |

**关键提醒：每次电脑重启后服务不会自动启动，需要重新双击 `一键获取key.bat`。**

### 我分享给别人怎么用？

把整个文件夹（`一键key` 文件夹）压缩打包发过去即可。对方电脑只要装了 Node.js + Python + 有美国节点，双击 `一键获取key.bat` 就能自己生成自己的 key。

> ⚠️ **重要**：打包前请确认 `freebuff2api\credentials` 文件夹里**没有** `account1.json`（自己的 Token 文件）。每个人的 Token 都是自己账号的凭据，分享 Token = 分享账号，**切勿把自己的 Token 给别人**。

---

## 四、常见问题（FAQ）

**Q1：双击后窗口一闪而过 / 提示缺少软件**
检查是否装了 Node.js 和 Python，装好后再试。安装后要重开命令行窗口（环境变量才会生效）。

**Q2：授权链接打不开 / 页面一直转圈**
确认科学上网节点已开启且为**美国节点**。

**Q3：授权时页面显示「Continue with GitHub / Google」但没有已登录的账号**
先用 Google 账号登录，再回来打开授权链接。

**Q4：登录后提示「登录成功」但脚本报错获取 Token 失败**
可能是授权窗口超时（300 秒限制）。重新双击 `一键获取key.bat`，选择重新登录再来一次。

**Q5：客户端连接报「Connection error」**
1. 服务没启动 → 双击 `一键获取key.bat`
2. 节点关了 → 打开美国节点
3. 用 `http://localhost:8877/healthz` 检查服务是否正常

**Q6：客户端报「API key is invalid / 401」**
确认 API Key 填的是 `freebuff-api`（注意不带引号、不带 Bearer 前缀）。

**Q7：报错 `403 {"status":"banned"}`**
账号已被 Freebuff 封禁（终态，不可恢复），只能换新 Google 账号重新登录。

**Q8：服务启动失败，怎么看原因？**
查看 `freebuff2api\server.err.log` 文件，把最后几行发给懂的人看。

---

## 五、封号红线（务必阅读）

Freebuff 有风控，以下行为**大概率封号**，封了只能换新 Google 账号：

1. **IP 地区频繁跳跃**：固定用美国节点，不要频繁切换国家
2. **一个账号同时给多个客户端/多台机器用**：Token 自己保管，一账号一会话
3. **高频请求 / 批量自动化**：正常聊天没问题，别拿来跑批量任务
4. **短时间内反复创建会话**：免费模型每天有 session 额度限制，别密集建会话
5. **用云函数（CF Worker）等部署**：官方已识别这类标记

免费额度说明：`deepseek/deepseek-v4-flash` 和 `mimo/mimo-v2.5` 不限池免费；其他模型每天 6 个会话（北京时间约 15:00 重置）。

---

## 六、目录结构

```
一键key/
├── 一键获取key.bat      # 入口：启动/重新获取 Key（双击这个）
├── 一键停止key.bat      # 停止服务入口（双击这个）
├── get-key.ps1          # 主逻辑脚本（自动下载项目、登录、启动，由 bat 调用）
├── stop-key.ps1         # 停止逻辑（由 bat 调用）
└── freebuff2api/        # 服务项目（首次运行自动下载，可预先放好）
    ├── server.js        # 本地服务主程序
    ├── worker.js        # 核心代理逻辑
    ├── credentials/     # 存放你的 Token（account1.json，勿外传！）
    ├── freebuff_tools/  # Token 获取工具（extract_freebuff.py）
    ├── server.log       # 运行日志
    └── server.err.log   # 错误日志（出问题看这里）
```

---

## 七、免责声明

本项目仅用于个人学习与合法用途。使用 Freebuff 服务需遵守其服务条款，请勿用于任何商业用途或大规模滥用。账号被封、服务变更等风险由使用者自行承担。

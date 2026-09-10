# 《洞见》Godot 开发执行规格书（DeepSeek Harness 版）

> **文档用途**：本文档是供 AI 开发代理（DeepSeek Harness / dsh）读取并执行的自包含规格书。代理看不到人类对话上下文，一切决策以本文档为准。
> **目标**：让代理在 Windows 上从零搭建 Godot 项目，实现《洞见》五关可玩版本（含穿越叙事、背景观赏性），并通过自动化验证。
> **整理日期**：2026-09-06

---

## 第 0 章 执行规则（必须遵守）

0.1 **本文档是唯一规格来源**。所有文件名、节点名、类名、行为、验收标准以本文档为准，不得自行改名、删减需求。
0.2 **按 Phase 顺序执行**：Phase 0 → 9。每个 Phase 完成且验证通过后，才能在 `DEV_LOG.md` 记录并进入下一个 Phase。
0.3 **验证即证据**：每个 Phase 结束必须运行该 Phase 的验证命令，输出保存到 `Build/Logs/<phase名>.log`，日志格式见 4.3。
0.4 **禁止等待美术资源**：所有占位用 **ColorRect / Polygon2D 色块节点**（由场景构建脚本创建，不依赖任何图片文件）；确需图片的项登记 `TODO.md`。
0.5 **出错处理**：命令失败先读报错、修根因；同一命令连续失败 2 次，换实现路径并在 `DEV_LOG.md` 记录原因与偏离。**不允许修改本文档规格来迁就失败**。
0.6 **环境**：Windows + PowerShell。Godot 可执行文件路径必须自行探测（见 3.1），不得假设固定路径。
0.7 **工作目录**：Godot 项目根目录（含 `project.godot`）。本文档复制到项目根目录 `SPEC.md` 保留备份。
0.8 每段可执行动作前，先确认前置产物存在（引用某个类/脚本前先确认文件已创建）。

---

## 第 1 章 游戏规格（自包含）

### 1.1 核心概念

- **游戏名**：《洞见》
- **类型**：横版冒险 + 剧情互动 + 解谜
- **时长**：主线 3-4 小时（本次实现目标为"可玩原型"，时长不限）
- **一句话**：一个只想拍照发朋友圈的年轻人，意外穿越进重庆的历史时空，在古镇的烟火与防空洞的硝烟中，重新学会"看路"。
- **主题句**："你以为你只是在旅游。其实你是在走一条路。"
- **宣传定位**：以重庆城市元素（洪崖洞吊脚楼、梯坎、两江、防空洞、磁器口）为场景主角，做"同一座城的不同时代"。

### 1.2 主角

| 项 | 内容 |
|---|---|
| 姓名 | 陈默 |
| 年龄 | 28 |
| 职业 | 互联网产品经理 |
| 初始状态 | 打卡式游客，对历史无兴趣，只想拍照发朋友圈 |
| 性格表现 | 不直说"不尊重历史"，通过抱怨路难走、敷衍 NPC、低头看手机、急着赶路体现 |
| 成长弧线 | 轻视 → 被迫动手 → 主动观察 → 承担责任 → 记住历史 |

### 1.3 五关结构总表

| 关 | 时代/地点 | 玩法 | 核心机制 | 失败条件 | 剧情要点 | 心境 |
|---|---|---|---|---|---|---|
| ① 洪崖洞·迷途 | 现代·洪崖洞 | 穿过人流到观景台 | **心烦值系统**（3 点血：碰传单阿姨 -1、人流穿行过久 -1、被堵超时 -1；游客/摊贩/柱子可作掩体） | 心烦值归零 → 主角放弃旅程，关卡重置，显示"你放弃了洪崖洞的旅程。但有些路，该走还是要走。" | 主角全程抱怨；对墙上历史木牌视而不见；踩到松动地砖坠入穿越通道；黑暗中传来声音"慢一点，看清楚再走。" | 轻视历史，急着离开 |
| ② 磁器口·生存之重 | 古代·磁器口窑场 | 窑场崩塌前"火烧水激"凿开岩壁引水改道 | **限时操作链**（约 3 分钟/一炷香）：生火烤岩壁 → 浇水冷却 → 铁楔凿击 → 重复 3-4 次直到岩壁裂开；操作失误浪费时间需重做 | 超时 → 从存档点重来 | 主角误以为拍戏问"摄像机在哪"；抬不动木头；喝糊粥时沉默；老匠人问"你们那儿的房子经得起洪水吗"答不上来；阿明塞给烤红薯 | 烦 → 累 → 好奇 |
| ③ 中山古镇·规矩与诚信 | 古代·中山古镇 | 把老掌柜货包送到码头交给老周 | **二元选择 + 货物状态**：走大路(安全)/走小巷(近但可能被拦)；茶馆遇胖掌柜可选实话/撒谎/反问；码头遇"帮工"可选让/不让帮忙；货物可能被偷/骗/抢，老周验货按完整度触发不同对话 | 无强制判定，只有后果 | 主角被套话、被偷、被试探；老周点破"这镇子看着简单，其实到处都是眼睛"；学会"看人" | 不服 → 接受 → 理解 |
| ④ 防空洞·黑暗中的脊梁 | 近代·抗战防空洞 | 带领离散人群穿过防空洞躲避轰炸抵达出口 | **队伍跟随**（队伍最长 6-8 人，人越多转弯/调整越难）；**轰炸预警**（呼啸声+红色屏幕警示+人群慌乱减速）；岔路口选错路会被炸；NPC 碰轰炸点或被炸 → 从存档点重来 | 主角或任一 NPC 被炸 → 从存档点重来 | 听到小孩哭声留下说"都跟我走"；对走不动的老人说"你搭着我肩膀，我带你走"；出口后人群感谢，他只说"前面的路还有一段，别停下来"；看自己的手"我以前拍个照都嫌累" | 自我保护 → 承担责任 |
| ⑤ 洪崖洞·归来 | 现代·洪崖洞 | 重走第一关路线，无敌人/无心烦值/无时间限制，自由探索 | **步行模拟 + 触发点**：旧木牌可驻足阅读；游客堵路处听老人讲吊脚楼历史；台阶上停步看江景；观景台可选择拍照或不拍 | 无失败条件 | 同样的场景不同心境；看传单阿姨内心 OS"她也是个打工的"；"这一张，比之前那一张，拍得好多了"；结尾独白"我以为历史是玻璃罩子里的东西。我错了。历史是那些台阶、那些砖、那些绳子、那些人的命。" | 逃离 → 回望 → 记住 |

### 1.4 设计原则（所有关卡实现必须遵守）

| 原则 | 具体做法 |
|---|---|
| 轻视不直说 | 通过抱怨路难走、低头看手机、敷衍 NPC、急着赶路等行为细节体现 |
| 成长不直说 | 通过选择停下来看、帮助别人、走路变慢等行为体现 |
| 玩法即叙事 | 第一关心烦值 = 主角烦躁；第四关带人 = 主角担当 |
| 失败即主题 | 第一关失败 = 放弃旅程（放弃历史）；第四关失败 = 有人因你而死 |
| 不说教 | 没有大段反思独白，成长全部通过细节动作呈现 |

---

## 第 2 章 技术栈

### 2.1 引擎与语言

- **引擎**：Godot 4.3 或更新（建议 4.3+；若探测到 4.2 及以下，将全文 `TileMapLayer` 替换为 `TileMap` 并在 `DEV_LOG.md` 记录）。
- **语言**：**GDScript**（Godot 原生脚本，无需编译，AI 生成最稳）。
- **渲染器**：默认 Forward+（桌面默认，2D 灯光完整可用）；**不**使用 Compatibility 渲染器（2D 灯光支持有限）。
- 无第三方插件依赖：对话系统用自研方案（第 6.4 章），所有功能用引擎内置节点实现。

### 2.2 引擎内置能力对照（本作使用的核心节点）

| 需求 | Godot 节点/机制 |
|---|---|
| 玩家 | `CharacterBody2D` + `move_and_slide()` |
| 瓦片地图 | `TileMapLayer`（4.3+；配置 `tile_set` 用程序生成占位瓦片集） |
| 相机 | `Camera2D`（`position_smoothing_enabled` 平滑跟随；震屏 = 抖动 `offset`） |
| 2D 灯光 | `PointLight2D`（点光源：霓虹/窑火/灯笼/煤油灯）+ `CanvasModulate`（全局色调/时代切换） |
| 后期氛围 | `WorldEnvironment`（glow 泛光、adjustments 色调、vignette） |
| 视差背景 | `ParallaxBackground` + `ParallaxLayer`（`motion_scale` 控制各层速度；`motion_mirroring` 做江水滚动） |
| 粒子 | `CPUParticles2D`（雾/烟/火星/灰烬，低配稳定，不用 GPU 粒子） |
| 动画 | `AnimatedSprite2D` + `SpriteFrames`（角色/NPC/飞鸟）；`AnimationPlayer`（UI/过场） |
| 音频 | `AudioStreamPlayer`（无资源时静音不报错） |
| UI | `CanvasLayer` + `Control` 体系（`ColorRect`/`Label`/`Button`） |
| 场景切换 | `get_tree().change_scene_to_file()` |

### 2.3 project.godot 关键设置（Phase 0 写入）

```ini
config_version=5

[application]
config/name="洞见"
run/main_scene="res://scenes/01_hongyadong.tscn"
config/features=PackedStringArray("4.3")

[autoload]
LevelManager="*res://autoload/level_manager.gd"
GameState="*res://autoload/game_state.gd"
DialogueSystem="*res://autoload/dialogue_system.gd"

[display]
window/size/viewport_width=480
window/size/viewport_height=270
window/stretch/mode="canvas_items"
window/stretch/aspect="keep"

[input]
move_left={ "deadzone": 0.2, "events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":65,"physical_keycode":0,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null) ] }
move_right={ "deadzone": 0.2, "events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":68,"physical_keycode":0,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null) ] }
jump={ "deadzone": 0.2, "events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":32,"physical_keycode":0,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null) ] }
interact={ "deadzone": 0.2, "events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":69,"physical_keycode":0,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null) ] }

[rendering]
textures/canvas_textures/default_texture_filter=0
2d/snap/snap_2d_transforms_to_pixel=true
2d/snap/snap_2d_vertices_to_pixel=true
```

> 说明：`default_texture_filter=0` 为 Nearest（像素风）；`snap_2d_*` 为像素对齐防抖（4.2+ 支持）；480×270 视口 + `canvas_items` 拉伸（2 倍 = 960×540）。input 用键码：A=65 / D=68 / Space=32 / E=69。若 Godot 版本无法解析该 input 写法，用 `InputMap` 在脚本里注册（`InputMap.add_action` / `add_key_event`），并记录偏离。

---

## 第 3 章 项目初始化（Phase 0）

### 3.1 探测 Godot 可执行文件（PowerShell）

```powershell
# 1) PATH 中的 godot
$cmd = Get-Command godot -ErrorAction SilentlyContinue
if ($cmd) { $cmd.Source }

# 2) 常见下载位置（取版本号最高的）
Get-ChildItem -Path "C:\", "$env:USERPROFILE\Downloads", "$env:USERPROFILE\Desktop" `
  -Filter "Godot*.exe" -Recurse -Depth 3 -ErrorAction SilentlyContinue |
  Sort-Object Name -Descending | Select-Object -First 5 FullName

# 3) 环境变量
$env:GODOT4
```

选择版本号最高（4.x）的一个，写入 `DEV_LOG.md`，记为 `$godotExe`。

### 3.2 创建项目（Godot 项目 = 文件夹 + project.godot）

```powershell
$proj = "<项目绝对路径，即本工作目录>"
New-Item -ItemType Directory -Force -Path "$proj\scenes","$proj\scripts","$proj\autoload","$proj\tools","$proj\assets\audio","$proj\Build\Logs"
```

按第 2.3 章写入 `project.godot`（覆盖默认文件）。**无需命令行创建项目**——Godot 项目就是文本配置。

### 3.3 首次初始化（资源导入 + 确认无报错）

```powershell
& $godotExe --headless --path $proj --quit-after 120 2>&1 | Out-File Build\Logs\phase0_init.log -Encoding utf8
```

- 该命令无头模式打开项目 120 帧后退出，触发资源导入。
- 验收：日志中无 `ERROR` / `SCRIPT ERROR`；以 `Godot Engine` 开头正常。

### 3.4 目录结构（必须严格一致）

```
project.godot
autoload/
  level_manager.gd      # 关卡状态/失败/重生/切换（全局单例）
  game_state.gd         # 跨关数据（货物完整度、历史领悟等）
  dialogue_system.gd    # 对话系统（自研）
scenes/
  01_hongyadong.tscn … 05_hongyadong_return.tscn
scripts/
  player/       player_controller.gd   player_animator.gd
  npc/          interactable.gd        npc_base.gd        group_follower.gd
  systems/      heart_system.gd        forge_sequence.gd   choice_system.gd
                goods_state.gd         bomb_warning.gd     scene_transition.gd
                checkpoint.gd
  background/   path_mover.gd          swing.gd            light_rig.gd
  ui/           ui_manager.gd          dialogue_panel.gd
tools/
  scene_builder.gd      # 场景生成器（extends SceneTree，命令行运行）
  scene_parts/          # 各关生成器片段：build_01.gd … build_05.gd、build_common.gd
  verify.gd             # 冒烟测试（extends SceneTree）
assets/
  audio/                # 音频占位说明（第 9 章）
Build/
  Logs/                 # 所有验证日志
DEV_LOG.md              # 代理执行日志（阶段、验证结果、偏离记录）
TODO.md                 # 待办与占位清单
```

---

## 第 4 章 操控与验证协议

### 4.1 Godot 命令行模板（所有自动化统一用此格式）

```powershell
# 运行工具脚本（验证/构建/生成）
& $godotExe --headless --path $proj --script res://tools/<脚本>.gd 2>&1 | Out-File Build\Logs\<阶段>.log -Encoding utf8

# 初始化/资源导入
& $godotExe --headless --path $proj --quit-after 120 2>&1 | Out-File Build\Logs\<阶段>.log -Encoding utf8
```

要点：
- 一律 `--headless`（无窗口）。
- 工具脚本必须 `extends SceneTree`，在 `_init()` 内执行逻辑并 `quit(退出码)`。
- 日志用 PowerShell 重定向写入 `Build/Logs/`，禁止只输出到控制台。

### 4.2 tools/scene_builder.gd（场景构建入口）

```gdscript
extends SceneTree

func _init() -> void:
    var code := 0
    for part in ["build_common", "build_01", "build_02", "build_03", "build_04", "build_05"]:
        var script := load("res://tools/scene_parts/%s.gd" % part)
        var built: bool = script.new().run(self)
        print("[%s] %s" % ["PASS" if built else "FAIL", part])
        if not built:
            code = 1
    print("[RESULT] " + ("PASS" if code == 0 else "FAIL"))
    quit(code)
```

### 4.3 日志格式规范（必须遵守）

- 每项检查一行：`[PASS] <内容>` 或 `[FAIL] <内容> <原因>`。
- 最后一行：`[RESULT] PASS` 或 `[RESULT] FAIL`。
- 阶段完成判定：日志存在 且 以 `[RESULT] PASS` 结尾。

### 4.4 场景构建协议（关键约束）

**所有 `.tscn` 场景文件必须由 `tools/` 下的脚本生成，禁止手写 `.tscn` YAML 文本**。

- `build_common.gd` 提供辅助函数（所有部分共用）：

```gdscript
class_name SceneBuilderCommon
extends RefCounted

func new_scene(name: String) -> Node2D:
    var root := Node2D.new()
    root.name = name
    return root

func add_node(parent: Node, type: String, node_name: String) -> Node:
    var n: Node = ClassDB.instantiate(type)
    n.name = node_name
    parent.add_child(n)
    return n

func save_scene(root: Node, path: String) -> bool:
    var packed := PackedScene.new()
    packed.pack(root)
    return ResourceSaver.save(packed, path) == OK

func make_color_rect(size: Vector2, color: Color, pos: Vector2 = Vector2.ZERO, parent: Node = null) -> ColorRect:
    var cr := ColorRect.new()
    cr.size = size
    cr.position = pos
    cr.color = color
    if parent != null:
        parent.add_child(cr)
    return cr
```

- 每个 `build_NN.gd`：`func run(tree: SceneTree) -> bool`，构建该关场景树（根 Node2D + 节点），`save_scene()` 到 `res://scenes/NN_*.tscn`。
- 对象命名（全项目统一前缀）：
  - `Player`：主角（CharacterBody2D）
  - `LevelManager` 不建节点（是 autoload）；每关放 `LevelRoot`（Node2D，挂本关逻辑脚本）
  - `UI_*`：UI 对象（CanvasLayer 下）
  - `BG_*`：背景层对象（ParallaxLayer 下）
  - `OBJ_*`：交互物（Area2D）
  - `NPC_*`：NPC（Area2D/CharacterBody2D）
  - `TransPortal`：穿越触发点（第 1/5 关）

### 4.5 占位素材协议

- 占位一律用 `ColorRect`（带颜色），由 builder 脚本创建，**不生成/不依赖图片文件**。
- 每关占位配色：① 金 `#E8B04B`；② 赭红 `#C96F4A`；③ 青灰 `#7E8B99`；④ 墨黑 `#3A3A42`；⑤ 晨光 `#F0D9A0`。
- 玩家占位：`ColorRect` 32×32 金块 + 顶部 4×4 白块指向右方（表示朝向）。

---

## 第 5 章 分阶段执行计划

### Phase 0 项目初始化
- 产出：`project.godot`（2.3 章）、目录结构（3.4）、autoload 三个脚本的空壳（`extends Node` + 注释声明职责）、`tools/scene_builder.gd` 与 `build_common.gd`、`verify.gd` 骨架
- 验证：3.3 初始化命令；`tools/verify.gd` 空跑输出 `[RESULT] PASS`
- 验收：日志 `[RESULT] PASS`

### Phase 1 核心框架
- 产出：
  - `scripts/player/player_controller.gd`（接口见 6.1）
  - `scripts/npc/interactable.gd`（`IInteractable` 等价：`func on_interact(player) -> void:`，交互提示圈用 `Sprite2D`+圆形占位或 `ColorRect`）
  - `autoload/level_manager.gd`（接口见 6.2）
  - `scripts/systems/checkpoint.gd`、`scripts/systems/scene_transition.gd`（CanvasLayer + ColorRect 黑屏渐变 + `change_scene_to_file`）
  - `Camera2D`（跟随 Player + `shake()` 接口）
  - `build_common.gd` 完成 + `build_01.gd` 最小骨架（Player + 地面 ColorRect + Camera2D）
- 验证：`scene_builder.gd` 生成 01 场景 → `verify.gd` 检查 `Player`、`Camera2D` 存在
- 验收：`[RESULT] PASS`

### Phase 2 对话系统
- 产出：
  - `autoload/dialogue_system.gd` + `scripts/ui/dialogue_panel.gd`（打字机 + 名字 + 选项按钮，规格见 6.4）
  - 对话数据：`assets/dialogue_level1.json`（第一关 3 句抱怨台词示例）
  - 场景 `01` 中加入测试 NPC（`NPC_Test`，交互触发对话）
- 验证：SmokeTest 检查 `DialoguePanel` 存在、JSON 可解析（在 verify.gd 里 `JSON.parse_string(FileAccess.get_file_as_string(...))` 判空）
- 验收：`[RESULT] PASS`

### Phase 3 第一关（洪崖洞·迷途）
- 产出：
  - `scripts/systems/heart_system.gd`（3 点心烦值）
  - `NPC_FlyerLady`（传单阿姨，碰到 -1）、人流区（`Area2D` 停留累计 2 秒 -1）、掩体（游客/摊贩/柱子 = 静止 ColorRect + Area2D）
  - `OBJ_InfoBoard`（历史木牌，交互出文本）、`OBJ_LooseTile`（松动地砖，踩到 → 穿越转场到 02）
  - 失败文本（1.3 表内）
- 验证：SmokeTest 检查 `HeartSystem`、`OBJ_LooseTile`、`NPC_FlyerLady`、`OBJ_InfoBoard` 存在
- 验收：全部 PASS

### Phase 4 第二关（磁器口·生存之重）
- 产出：
  - `scripts/systems/forge_sequence.gd`（状态机 `HEAT→QUENCH→CHISEL→重复 3 轮`；每步 1 秒操作耗时；岩壁 = 多块 ColorRect 逐轮变色/裂开）
  - 计时 UI（`Label` 倒计时 180 秒；超时 → `LevelManager.fail()`）
  - 木头交互（主角 `frozen` + 减速模拟抬不动）、糊粥碗、`NPC_AMing`（烤红薯文本）
- 验证：SmokeTest 检查 `ForgeSequence`、计时 `Label`、`OBJ_Wall` 存在
- 验收：全部 PASS

### Phase 5 第三关（中山古镇·规矩与诚信）
- 产出：
  - `autoload/game_state.gd` 中货物完整度字段（`goods_integrity: int = 100`；`apply_goods_event(name)`：stolen -30 / cheated -30 / robbed -40 / safe 0；`get_result_tier()`：≥70 完好 / 40-69 受损 / <40 严重受损）
  - `scripts/systems/choice_system.gd`（选项 → 回调 → 写 `GameState`）
  - 四个节点：`NPC_OldShopkeeper`(接包) → `NPC_FatTeahouse`(茶馆) → `NPC_Helper`(码头帮工) → `NPC_LaoZhou`(验货，按 tier 输出 3 档对话)
- 验证：SmokeTest 检查四个 NPC、`ChoiceSystem` 存在
- 验收：全部 PASS

### Phase 6 第四关（防空洞·黑暗中的脊梁）
- 产出：
  - `scripts/npc/group_follower.gd`（6-8 个 NPC 队列跟随：每个 NPC 保存 leader 的历史位置环形缓冲（采样间隔 0.5s），逐帧移向历史点；人数越多转弯越难，见 6.6）
  - `scripts/systems/bomb_warning.gd`（定时轰炸：Alert 音 → 红色 vignette 闪烁 → 落点 `Area2D` 高亮 1.5s → 爆炸；主角或任一 NPC 在落点内 → `fail()`；岔路口选错 → 该路封锁）
  - 光照：全局 `CanvasModulate` 极暗 + 唯一 `PointLight2D` 跟随队伍
  - 存档点：洞中途 1 个
- 验证：SmokeTest 检查 `GroupFollower`、`BombWarning`、存档点、`PointLight2D` 存在
- 验收：全部 PASS

### Phase 7 第五关（洪崖洞·归来）
- 产出：复制 01 场景（builder 内 `duplicate` 逻辑或独立 build），清敌人/心烦值/计时；触发点：`OBJ_InfoBoard`(读历史)、`NPC_OldMan`(讲吊脚楼)、`OBJ_ViewSpot`(看江)、`OBJ_PhotoSpot`(拍照/不拍二选一 → 结尾独白文本)
- 验证：SmokeTest 检查 4 个触发点对象存在
- 验收：全部 PASS

### Phase 8 背景系统（观赏性）
- 产出：
  - `ParallaxBackground` + `ParallaxLayer` 五层（天空/远景/中景/近景/前景，`motion_scale`：0.05/0.2/0.5/0.9/1.3；江水层用 `motion_mirroring` 滚动）
  - `scripts/background/path_mover.gd`（索道/航船沿路径点循环移动）
  - `scripts/background/swing.gd`（灯笼/旗帜 `rotation = sin(t*speed)*angle`，联动 `PointLight2D.energy`）
  - `scripts/background/light_rig.gd`（`CanvasModulate` 时代色调 + 点光源组，接口见 6.7）
  - `WorldEnvironment`（glow + adjustments + vignette，各关按时代开闭）
- 验证：SmokeTest 检查每关 `BG_*` 对象 ≥ 3 个、`WorldEnvironment`、LightRig 存在
- 验收：全部 PASS

### Phase 9 打磨与总验收
- 产出：音频占位（第 9 章）、失败/通关文本齐全、TODO 清零或记录、最终验证
- 验证：`verify.gd` 全 PASS；可选导出（见 4.6）
- 验收：第 10 章总清单

### 4.6 导出为 Windows 可执行文件（可选，若失败不阻塞验收）

```powershell
& $godotExe --headless --path $proj --export-release "Windows Desktop" "Build\Game\洞见.exe" 2>&1 | Out-File Build\Logs\phase9_export.log -Encoding utf8
```

- 前置：写 `export_presets.cfg`（preset 名 "Windows Desktop"，platform "Windows Desktop"），需要已安装 Export Templates。
- 若模板缺失（日志报 `Cannot export` 类错误），记录到 `TODO.md`，验收标准降级为"headless 冒烟测试全 PASS + 项目可被编辑器正常打开"。

---

## 第 6 章 系统规格（GDScript 接口）

> 每个类给"职责 + 关键成员 + 行为规格 + 验收标准"。实现可自由扩展，但公共接口与行为不得偏离。

### 6.1 PlayerController（`scripts/player/player_controller.gd`）

```gdscript
class_name PlayerController
extends CharacterBody2D

@export var move_speed: float = 130.0    # 像素/秒（480×270 视口）
@export var jump_velocity: float = -320.0
var frozen: bool = false

func set_look_dir(dir: int) -> void   # 1 右 / -1 左（翻转占位块朝向）
func freeze(v: bool) -> void
```
- 行为：`_physics_process` 中读取 `move_left/move_right/jump` 动作 + `move_and_slide()`；与 `Area2D` 交互物重叠时显示提示，按 `interact` 调用 `on_interact`。
- 验收：可在占位地面行走跳跃；`freeze(true)` 后输入无效。

### 6.2 LevelManager（`autoload/level_manager.gd`）

```gdscript
extends Node

var current_level: int = 1
var checkpoint_pos: Vector2 = Vector2.ZERO

func fail(reason: String) -> void    # 暂停 1.5s 显示失败文案 → respawn()
func complete() -> void              # 通关 → 下一场景（含穿越转场）
func register_checkpoint(pos: Vector2) -> void
func respawn() -> void               # 玩家回 checkpoint_pos，重置本关机制
```
- 行为：`fail` 用 `get_tree().paused` + UI 层显示文案；`complete` 调 `SceneTransition` 切场景。
- 验收：SmokeTest 检查 autoload 存在（`Engine.has_singleton` 不适用，改为 `tree.root.get_node_or_null("/root/LevelManager")` 判空）。

### 6.3 HeartSystem（`scripts/systems/heart_system.gd`）——第一关

```gdscript
class_name HeartSystem
extends Node

signal changed(current: int)
var current: int = 3

func take_damage(amount: int = 1) -> void
```
- 行为：碰传单阿姨 `take_damage()`；人流区停留累计 2s `take_damage()`；被堵超时 `take_damage()`；归零 → `LevelManager.fail("你放弃了洪崖洞的旅程。但有些路，该走还是要走。")` 并重置关卡。
- 验收：SmokeTest 检查组件存在；HUD 心形（`Label` 显示 ♥♥♥）随 `current` 变化。

### 6.4 对话系统（自研，无插件）

**`autoload/dialogue_system.gd`**：

```gdscript
extends Node

var dialogue_data: Dictionary = {}   # node_id -> { lines: [...], options: [...], goods_event: "" }

func load_data(path: String) -> bool   # 解析 JSON
func start_dialogue(node_id: String, speaker: String) -> void
func choose(index: int) -> void
```

**数据格式**（`assets/dialogue_levelN.json`）：

```json
{
  "start": {
    "lines": [ { "speaker": "老周", "text": "这镇子看着简单，其实到处都是眼睛。" } ],
    "options": [
      { "label": "实话实说", "next": "honest" },
      { "label": "撒谎", "next": "lie" }
    ],
    "goods_event": ""
  },
  "honest": { "lines": [ { "speaker": "老周", "text": "实在人。" } ], "options": [], "goods_event": "safe" }
}
```

- `choose(index)`：若该选项 `next` 指向节点则继续；节点带 `goods_event` 时调用 `GameState.apply_goods_event(name)`。
- `dialogue_panel.gd`：CanvasLayer 底部面板，打字机逐字显示（`Timer` 每 0.03s 一字），选项用 `Button` 列表；对话中 `PlayerController.freeze(true)`。
- **验收**：JSON 可解析；SmokeTest 检查 `DialoguePanel` 节点存在。

### 6.5 ForgeSequence（`scripts/systems/forge_sequence.gd`）——第二关

```gdscript
class_name ForgeSequence
extends Node

enum Step { HEAT, QUENCH, CHISEL }
var current_step: Step = Step.HEAT
var current_round: int = 0
var rounds_to_break: int = 3
var time_left: float = 180.0

func interact_heat() -> void
func interact_quench() -> void
func interact_chisel() -> void
```
- 行为：任一步顺序错误 → 重置该步骤 + 提示"顺序不对"（2s 惩罚）；3 轮后岩壁裂开 → `LevelManager.complete()`；`time_left <= 0` → `fail("一炷香燃尽了。")`。
- 验收：SmokeTest 检查组件与交互点存在。

### 6.6 GroupFollower（`scripts/npc/group_follower.gd`）——第四关

```gdscript
class_name GroupFollower
extends Node

var followers: Array[Node2D] = []       # 6-8 个 NPC
var history: Array[Vector2] = []        # leader 位置环形缓冲
var sample_interval: float = 0.5        # 采样间隔（秒）
var max_history: int = 40

func add_follower(npc: Node2D) -> void
func start_following() -> void
```
- 行为：每帧将玩家位置按 `sample_interval` 压入 `history`；每个 NPC 移向 `history[max(0, len-1-i*step)]`（`i` 为队伍序号），速度略低于玩家；转弯时人数越多，外侧 NPC 扫过的半径越大（越难）。
- 验收：SmokeTest 检查 `NPC_Group` ≥ 6 个 + 组件存在。

### 6.7 背景系统（Phase 8）

```gdscript
class_name LightRig
extends Node2D

func set_tone(global_color: Color, global_energy: float) -> void   # CanvasModulate
func add_point_light(pos: Vector2, color: Color, energy: float, radius: float) -> PointLight2D
```

- `ParallaxBackground` 五层：`ParallaxLayer.motion_scale = (0.05/0.2/0.5/0.9/1.3, 1)`；江水层 `motion_mirroring = (64, 0)` 循环滚动。
- `path_mover.gd`：`_process` 中沿 `points: Array[Vector2]` 循环 `move_toward`。
- `swing.gd`：`rotation = sin(t * speed) * angle`；绑定的 `PointLight2D.energy = 0.8 + sin(t * 1.7) * 0.15`。
- 每关时代色调（`set_tone` 参数）：
  - ① 金 `Color(1.0, 0.9, 0.75)` + 霓虹点光源（彩）
  - ② 橙红 `Color(1.0, 0.8, 0.6)` + 窑火点光源
  - ③ 青灰 `Color(0.85, 0.88, 0.9)` + 灯笼点光源
  - ④ 极暗 `Color(0.25, 0.25, 0.3)` + 煤油灯唯一光源 + 警报红 vignette
  - ⑤ 晨光 `Color(0.95, 0.93, 0.88)`

### 6.8 冒烟测试 verify.gd 骨架

```gdscript
extends SceneTree

const SCENES := {
    "res://scenes/01_hongyadong.tscn": ["Player", "HeartSystem", "NPC_FlyerLady", "OBJ_LooseTile", "OBJ_InfoBoard"],
    "res://scenes/02_ciqikou.tscn": ["Player", "ForgeSequence", "OBJ_Wall"],
    "res://scenes/03_zhongshan.tscn": ["Player", "ChoiceSystem", "NPC_LaoZhou"],
    "res://scenes/04_fangdong.tscn": ["Player", "GroupFollower", "BombWarning"],
    "res://scenes/05_hongyadong_return.tscn": ["Player", "OBJ_PhotoSpot", "NPC_OldMan"],
}

func _init() -> void:
    var failed := 0
    for path: String in SCENES:
        var packed: PackedScene = load(path)
        if packed == null:
            print("[FAIL] 无法加载 %s" % path)
            failed += 1
            continue
        var inst := packed.instantiate()
        root.add_child(inst)
        for node_name: String in SCENES[path]:
            if inst.find_child(node_name, true, false) == null:
                print("[FAIL] %s 缺少 %s" % [path, node_name])
                failed += 1
            else:
                print("[PASS] %s 含 %s" % [path, node_name])
        inst.queue_free()
    print("[RESULT] " + ("PASS" if failed == 0 else "FAIL"))
    quit(0 if failed == 0 else 1)
```

> 随 Phase 推进，将 `SCENES` 检查表扩充到第 7 章全部关键对象。

---

## 第 7 章 场景规格（builder 生成目标）

| 场景 | 存档点 | 关键对象（SmokeTest 必查） | 出口 |
|---|---|---|---|
| `01_hongyadong.tscn` | 起点后 1 个 | Player、HeartSystem、`NPC_FlyerLady`、`OBJ_LooseTile`、`OBJ_InfoBoard`、`BG_*`×5、WorldEnvironment、LightRig | 踩地砖 → 穿越到 02 |
| `02_ciqikou.tscn` | 岩壁前 1 个 | Player、ForgeSequence、`OBJ_Wall`、`OBJ_Wood`、`NPC_OldArtisan`、`NPC_AMing`、计时 Label、`BG_*`×5、LightRig | 岩壁裂开 → 03 |
| `03_zhongshan.tscn` | 无 | Player、ChoiceSystem、`NPC_OldShopkeeper`、`NPC_FatTeahouse`、`NPC_Helper`、`NPC_LaoZhou`、`OBJ_GoodsBag`、`BG_*`×5、LightRig | 老周验货后 → 04 |
| `04_fangdong.tscn` | 洞中途 1 个 | Player、GroupFollower、BombWarning、`NPC_Group`×6-8、`PointLight2D`、`BG_*`×3、存档点 | 出口 → 05 |
| `05_hongyadong_return.tscn` | 无 | Player、`OBJ_InfoBoard`、`NPC_OldMan`、`OBJ_ViewSpot`、`OBJ_PhotoSpot`、`BG_*`×5、LightRig | 拍照/不拍 → 结尾独白 → 重开 |

---

## 第 8 章 背景与美术规格

### 8.1 五层视差结构（所有关卡通用骨架）

| 层 | motion_scale | 内容（按关换装） | 动态元素 |
|---|---|---|---|
| 天空层 | (0.05, 1) | 天色渐变（晨/昏/夜） | 雾带（CPUParticles2D）、飞鸟（AnimatedSprite2D 4 帧） |
| 远景层 | (0.2, 1) | 江对岸山城剪影 / 远山窑烟 | 索道缆车、航船（PathMover） |
| 中景层 | (0.5, 1) | 吊脚楼群 / 窑炉棚架 / 排门店铺 / 洞壁 | 江水（motion_mirroring）、轻轨（现代关）、窑烟 |
| 近景层 | (0.9, 1) | 梯坎 / 街市 / 茶馆码头 / 避难人群 | 灯笼摆动（Swing） |
| 前景层 | (1.3, 1) | 飞檐 / 栏杆 / 树枝剪影（画框感） | 树枝摆动（Swing） |

### 8.2 每关"时代指纹"（换装表）

| 图层 | ①现代·夜 | ②古代·窑场 | ③古代·古镇 | ④近代·防空洞 | ⑤现代·晨 |
|---|---|---|---|---|---|
| 主色调 | 霓虹金×夜蓝 | 赭红×土黄 | 青灰×竹绿 | 墨黑×警报红 | 褪色晨光 |
| 天空 | 霓虹夜色渐变 | 落日余晖 | 阴天漫射 | 漆黑+警报红闪 | 晨光薄雾 |
| 远景 | 对岸灯海+大桥+索道 | 远山+窑烟 | 远山+梯田 | 山城剪影 | 对岸山城+晨雾 |
| 中景 | 吊脚楼+轻轨+江 | 窑炉棚架 | 排门店铺 | 洞壁+洞口光 | 吊脚楼原貌+江 |
| 近景 | 梯坎+摊贩+灯牌 | 柴堆+窑口 | 茶馆+码头 | 煤油灯+人群 | 梯坎+历史木牌 |
| 前景 | 霓虹栏杆 | 火星剪影 | 灯笼 | 阴影压迫 | 黄葛树枝叶 |

### 8.3 像素动画铁律

1. 循环动画帧率 6-12 fps（走路 8 帧、待机 4 帧、场景循环 8 fps）——`SpriteFrames` 中设置 `speed`。
2. 纹理过滤 Nearest（project.godot 已全局设置）；PPU 概念由视口 480×270 承担，素材按 1 像素 = 1 游戏单位绘制。
3. 像素对齐已开启（`snap_2d_*`）。
4. 动态优先"代码演出"：雾=CPUParticles2D、水=motion_mirroring、光=PointLight2D 闪烁；帧动画只给角色/飞鸟/火苗。

### 8.4 素材优先级（占位先行）

| 优先级 | 素材 | 说明 |
|---|---|---|
| P0 | 玩家占位块、NPC 占位块、各关色块背景层（ColorRect） | Phase 1-7 用 |
| P1 | 五关 tileset 占位（按主色色块拼接） | Phase 8 用 |
| P2 | 正式像素素材（后续人工替换，登记 TODO） | 不阻塞开发 |

---

## 第 9 章 音频规格（占位策略）

- BGM × 5：每关一个循环音轨。占位：`assets/audio/README.md` 说明曲目清单，代码用 `AudioStreamPlayer` + 空流（无资源则静音不报错）。
- 音效：脚步、交互确认、心碎、锤凿、轰炸呼啸、警报。占位同上。
- 环境音：人流嘈杂 / 窑火 / 茶馆人声 / 警报 / 清晨鸟鸣。

---

## 第 10 章 最终验收总清单

运行 `verify.gd`（命令见 4.1），逐项确认：

1. [ ] `Build/Logs/phase9_verify.log`：`[RESULT] PASS`
2. [ ] 五个场景全部可由 `scene_builder.gd` 重新生成（幂等，二次运行不报错）
3. [ ] 第一关心烦值 3 点逻辑：`take_damage` 可被传单阿姨/人流/堵塞触发，归零 `fail()`
4. [ ] 第二关操作链：3 轮"烤→浇→凿"后岩壁裂开通关；超时 `fail()`
5. [ ] 第三关：货物完整度 3 档结局对话文本齐全（JSON 数据内）
6. [ ] 第四关：队伍 ≥6 人跟随；轰炸落点判定；任一 NPC 被炸 → 存档点重生
7. [ ] 第五关：4 个触发点全部可交互，结尾独白文本完整
8. [ ] 穿越转场：01→02、02→03、03→04、04→05 均通过 `SceneTransition` 完成
9. [ ] 每关背景 ≥3 个视差层 + LightRig + WorldEnvironment 存在（Phase 8 验收）
10. [ ] `TODO.md` 中无 P0/P1 级未解决项（P2 正式美术可挂起）
11. [ ] `DEV_LOG.md` 完整记录各阶段验证结果与偏离
12. [ ] （可选）`Build/Game/洞见.exe` 导出成功；失败已记录原因

**最终交付物**：
- Godot 项目源码（工作目录本身）
- `Build/Logs/*.log`（全过程证据）
- `DEV_LOG.md`、`TODO.md`
- （可选）`Build/Game/洞见.exe`

---

*本文档由人类设计者整理，规格一经确认不再变更；执行过程中的合理实现细节由代理决定并记录。*

# 《洞见》项目交接文档（交接给 Codex）

> 由 DSH（DeepSeek Harness）会话完成主体开发后整理，目标是让 Codex **零上下文**接手即可继续而不踩坑。
> 项目根：`F:\游戏\cs2`　引擎：`F:\godot\Godot_v4.7.2-stable_win64.exe`（Godot 4.7.2 stable）
> 必读配套：`SPEC.md`、`assets/洞见-素材规格表-dsh执行版.md`、`assets/raw/素材2/洞见-素材库使用说明-dsh导入版.md`、`docs/命名与分类规范.md`、`美术接线手把手手册.md`、`DEV_LOG.md`

## 0. TL;DR
```powershell
& "F:\godot\Godot_v4.7.2-stable_win64.exe" --editor --path "F:\游戏\cs2"          # 首次：导入素材
& "F:\godot\Godot_v4.7.2-stable_win64.exe" --headless --path "F:\游戏\cs2" --script res://tools/scene_builder.gd
& "F:\godot\Godot_v4.7.2-stable_win64.exe" --headless --path "F:\游戏\cs2" --script res://tools/verify.gd
& "F:\godot\Godot_v4.7.2-stable_win64.exe" --path "F:\游戏\cs2"                    # 运行
```
**最容易踩的坑**：五关场景全部由 `tools/scene_builder.gd` 代码生成；编辑器手改 .tscn 会被重建覆盖 → 永久改动必须落在 `tools/scene_parts/*.gd`。

## 1. 技术基线
| 项 | 值 |
|---|---|
| 游戏 | 《洞见》横版冒险+剧情互动+解谜，五关 + 开始界面 |
| 引擎/语言 | Godot 4.7.2 stable / GDScript，无第三方插件 |
| 视口 | 640×360，`canvas_items` + `aspect="keep"` |
| 像素规范 | 1px=1 世界单位；Nearest；`snap_2d_*` 开启 |
| 主场景 | `res://scenes/kaishi.tscn` |
| 全局主题 | `res://assets/ui/theme.tres`（缝合像素字体 12px） |
| InputMap | move_left=A、move_right=D、jump=Space、interact=E |
| autoload | LevelManager、GameState、DialogueSystem、Skinner、McpInteractionServer(调试可删) |
| 导出 | 无 4.7.2 export templates；`export_presets.cfg` 已写好（Windows Desktop） |
| 日志 | `Build/Logs/*.log`；截图 `Build/Game/preview_*.png` |

## 2. 命令手册
| 脚本 | 作用 |
|---|---|
| `tools/scene_builder.gd` | 生成全部场景（common→start→zhujue→npcs→01..05） |
| `tools/verify.gd` | 结构冒烟 + 对话 JSON 解析 + 04 跟随者数量（输出 [RESULT] PASS/FAIL） |
| `tools/gen_art.gd` | 程序化占位美术（主角/NPC 占位、灯笼、bg_01..05 等） |
| `tools/normalize_frames.gd` | 主角帧表 → 8 帧动画条（`assets/player_frames_norm/`） |
| `tools/npc_frames.gd` | NPC 帧表 → 待机动画条 + `assets/npc_anim/meta.json` |
| `tools/build_theme.gd` | 重新生成 `assets/ui/theme.tres` |
| `--quit-after 60` | 无头跑主场景 60 帧自检 |

- **素材导入**：新增图片后非编辑器运行**不会自动导入** → 编辑器打开一次，或跑一次 `--export-release`（会因模板缺失失败，但导入已完成）。
- **网络**：github release 直连不稳，历史用 `https://gh-proxy.com/` 前缀代理成功；`registry.npmjs.org`、`cdn.jsdelivr.net`、`codeload.github.com` 可达。

## 3. 目录结构（关键）
```
project.godot / SPEC.md / DEV_LOG.md / TODO.md / 美术接线手把手手册.md
docs/命名与分类规范.md
autoload/ level_manager.gd game_state.gd dialogue_system.gd skinner.gd mcp_interaction_server.gd
scenes/kaishi.tscn ; scenes/guanqia/01..05*.tscn ; scenes/renwu/zhujue/zhujue.tscn ; scenes/renwu/npc/<拼音>/<拼音>.tscn(11)
scripts/player/ player_controller.gd hero_anim.gd player_animator.gd
scripts/npc/ interactable.gd npc_base.gd flyer_lady.gd laozhou.gd chaser_lady.gd group_follower.gd forge_wall.gd wood.gd photo_spot.gd
scripts/systems/ heart_system.gd forge_sequence.gd choice_system.gd bomb_warning.gd exit_portal.gd checkpoint.gd scene_transition.gd chase_manager.gd loose_tile.gd crowd_area.gd camera_rig.gd
scripts/background/ light_rig.gd swing.gd path_mover.gd ; scripts/ui/ dialogue_panel.gd kaishi_menu.gd
tools/ scene_builder.gd verify.gd gen_art.gd normalize_frames.gd npc_frames.gd build_theme.gd
tools/scene_parts/ build_common.gd build_start.gd build_zhujue.gd build_npcs.gd build_01..05.gd
assets/raw/素材2/(人物 帧表 背景 场景物件 光影 动态素材 + 5 py)
assets/portraits(12) player_frames(_norm) npc_src npc_anim(+meta.json) objects(4) generated ui/theme.tres fonts vendor audio/README.md
Build/Logs Build/Game
```

## 4. 架构核心
### 4.1 生成式场景
- 所有 .tscn 由脚本生成；手改场景会被覆盖。
- `scene_builder.gd` 顺序：build_common → build_start → build_zhujue → build_npcs → build_01..05（实例场景必须先于关卡）。
- part 约定：`extends RefCounted` + `func run(tree: SceneTree) -> bool`。

### 4.2 build_common.gd API
- `new_scene / add_node / save_scene`（**save_scene 内部递归设 owner**，否则子节点不序列化）/ `bind_script`
- `make_color_rect / make_label`；`make_crowd`（人群路障，物理阻挡+3 立绘，节点名 `diyiguan_renqun_%02d`）
- `make_background(root, cols) -> ParallaxBackground`（五层色带已全透明，仅留结构）
- `make_environment`（glow+adjustments；4.7 无 vignette 属性）
- `make_light_rig`（CanvasModulate 时代色调 + PointLight2D 列表）
- `add_scene_art(pbg, ground, era)`：**无缝背景三件套** —— 远景主背景(alpha .55、motion 0.06、mirroring) + 中景无缝单元(motion 0.5、mirroring) + 地形无缝单元(z=10 平铺 -700→2500)；用 `ERA_DIRS` 映射 `assets/raw/素材2/背景/0X...`，按关键字自动挑文件。
- `add_object_behind(ground, path, wx, h)`：地面后方摆件（吊脚楼/窑炉/门面/码头）。
- `_pick(files, keyword, ext)`：目录内按关键字选文件（兼容中文文件名）。

### 4.3 headless --script 三大禁忌
1) **无全局类缓存**：跨脚本禁用 `class_name` 依赖 → 用 `load("res://…gd")` + 路径 `extends`；场景脚本解析期不要引用 autoload 名，改运行期 `get_node_or_null("/root/X")`。
2) **类型推断陷阱**：`var x := <Variant>` 报 "Cannot infer type" → 显式标注（字典/数组取值尤其）。
3) SceneTree 脚本不要定义 `_process(delta)`（与虚函数冲突，会报签名不匹配）→ 改名如 `_process_key`；lambda 不能 `f()` 直呼，需 `.call()` 或写成方法。

### 4.4 project.godot 注意
- 编辑器可能把 `run/main_scene` 改写成 `uid://…`；改设置请按行读改写整行。
- 某些导入流程会丢 `window/stretch/aspect` 与 `theme/custom` → 重建后核对：640×360 / canvas_items+keep / theme.tres。

## 5. autoload
- **LevelManager**：`SCENES=[scenes/guanqia/01..05]`；`fail(reason)`（暂停 1.5s 显示文案→respawn）、`complete()`（下一关+黑屏过场）、`travel_to(level, caption)`、`register_checkpoint(pos)`、`respawn()`（实现为重载当前场景，见 DEV_LOG 偏离）；进入第三关自动 `GameState.reset_goods()`。
- **GameState**：`goods_integrity=100`；`apply_goods_event`：stolen -30 / cheated -30 / robbed -40 / safe 0；`get_result_tier`：≥70 完好 / 40–69 受损 / <40 严重受损。
- **DialogueSystem**：`load_data(path)`、`start_dialogue(node_id, speaker)`、`choose(index)`、信号 `ended`；**必须在 start_dialogue 里连接面板 `advance_requested`**（历史 bug：不连接则一句后按 E 卡死）。
- **Skinner**：换场景时按固定节点名把占位替换为 AnimatedSprite2D 待机动画（读 `npc_anim/meta.json` 的 fw/fh/count/fps），按帧高缩放到 48、底对齐；缺失回退 `generated/npc_*.png`。映射：chuandanayi→flyer_lady、laojiangren→old_artisan、aming→aming、laozhanggui→old_shopkeeper、pangzhanggui→fat_teahouse、banggong→helper、laozhou→laozhou、jianglishilaoren→old_man；`NPC_Group/NPC_Follower*` 按 helper/old_man/aming 循环。
- **McpInteractionServer**：DSH godot-bridge 调试 TCP(127.0.0.1:9090)，与游戏无关，发布可删。

## 6. 玩家
- `player_controller.gd`：move_speed 130 / jump_velocity -320 / GRAVITY 700；`frozen`；`nearby` 由交互区 `zhujue_jiaohuquyu` 维护；`freeze(v)`、`knock(vx)`、`set_look_dir(dir)`；按 interact 先播 `zhujue_donghua.trigger_interact()` 再调目标 `on_interact`。
- `hero_anim.gd`：`SHEETS` = idle(fw264,fh691,5fps) / walk(1152,1946,8) / jump(264,701,10) / interact(264,814,8)，`TARGET_H=48`；按 velocity/is_on_floor 自动切换；每个动画按自身帧高动态缩放并底对齐；`flip_h` 朝向；`trigger_interact` 播一次后回 idle。
- `camera_rig.gd`：平滑跟随 + `offset (0,-140)`；`shake(strength,duration)`。

## 7. 交互与对话
- `interactable.gd`：Area2D 基类，覆写 `on_interact(player)`；提示圈兼容 `Prompt` 与 `<拼音>_tishi`；玩家用鸭子类型判定（不依赖类名）。
- `npc_base.gd`：导出 `dialogue_file` / `dialogue_node`。
- 特化：`flyer_lady.gd`(01 对话→追逐) / `laozhou.gd`(03 按 tier 三档→complete) / `photo_spot.gd`(05 拍照二选一→独白→travel_to(1)) / `forge_wall.gd`+`wood.gd`(02) / `chaser_lady.gd`(01 追踪：<20px 扣心、冷却 1.2s、击退) / `group_follower.gd`(04 队列跟随：0.5s 采样、40 缓冲、速度 108-i*9 下限 42)。
- `dialogue_panel.gd`：**双立绘对话框**（左 NPC / 右 陈默）+ 底部文字框（名字 13 / 正文 12）+ 选项按钮；说话方 alpha 1.0、另一方 0.45，旁白两侧 0.5；打字机 0.03s/字；E 推进；新增说话人在 `PORTRAITS` 字典加一行即可。
- 对话数据：`assets/dialogue_level{1,2,3,5}.json`，节点结构 `{lines:[{speaker,text}], options:[{label,next}], goods_event}`；第 4 关无对话文件。

## 8. 五关玩法与数值
### 01 洪崖洞（现代夜）
世界宽 3200（x −700…2500），出生 (−680,200)，两端边界墙；
心烦值 3（`heart_system.gd`，归零 → fail 文案）；传单阿姨对话 → 4 名 `chaseayi_01..04` 追逐（速度 112 vs 玩家 130，接触扣心+击退）；
人群路障 4 组（x≈780/1000/1220/1460，宽 64–92 高 46–52，物理阻挡可跳/绕，`diyiguan_renqun_01..04`）；
`diyiguan_mupai`（对话）、`diyiguan_husongdizhuan`（→travel_to(2)，文案"……慢一点，看清楚再走。"）、`Checkpoint`。
### 02 磁器口
`di_erguan_yanbi`（交互）+ `di_erguan_yanbi_qiangti`（挡墙）；`forge_sequence`：HEAT→QUENCH→CHISEL ×3 轮、每步 1s、180s 超时 fail("一炷香燃尽了。")；
`di_erguan_mutou`（抬不动 freeze 1.6s）、`di_erguan_huzhou`、`laojiangren`、`aming`、`Checkpoint`、`UI_Timer`/`UI_Notice`。
### 03 中山古镇
`laozhanggui`→`pangzhanggui`（实话/撒谎/反问）→`banggong`（让/不让）→`laozhou`（3 档验货→通关）；`disanguan_huobao`；`ChoiceSystem` 节点在（逻辑在 DialogueSystem+JSON goods_event）；进关 `reset_goods`。
### 04 防空洞
CanvasModulate(0.25,0.25,0.3) + 玩家随身 PointLight2D；`NPC_Group`+`NPC_Follower1..6` 队列跟随；
`bomb_warning`：6–10s 间隔、预警 1.5s（`UI_BombFlash`+落点标记）、爆炸半径 34 判定玩家/跟随者→fail；`disiguan_chukou`→complete；中途 `Checkpoint`。
### 05 归来
无失败条件；`diwuguan_mupai`（读历史）/ `jianglishilaoren`（讲吊脚楼）/ `diwuguan_jingguandian`（看江）/ `diwuguan_zhaoxiangdian`（拍照→结尾独白→回 01）。

## 9. 命名规范摘要（权威：`docs/命名与分类规范.md`）
- 主角：`zhujue` + `zhujue_pengzhuangtiji / zhujue_donghua / zhujue_jiaohuquyu / zhujue_shexiangji / zhujue_anim_kongzhi`
- NPC：`chuandanayi youke tanfan jianglishilaoren laojiangren aming laozhanggui pangzhanggui banggong laozhou binanzhongqun`，子节点 `<拼音>_pengzhuangtiji / <拼音>_tishi`
- 关卡物件：`<关卡拼音>_<对象拼音>[_编号]`（diyiguan_husongdizhuan / di_erguan_yanbi / disanguan_huobao / disiguan_chukou / diwuguan_mupai / chaseayi_01 / diyiguan_renqun_01 …）
- **内部保留名（勿改，被脚本查找）**：NPC_Group、NPC_Follower*、HeartSystem、ForgeSequence、BombWarning、GroupFollower、ChaseManager、ChoiceSystem、UI_*、DialoguePanel、Checkpoint、PointLight2D、WorldEnvironment、LightRig、BG_*

## 10. 素材管线
- 素材库 `assets/raw/素材2/`：立绘 12（浅米底需抠）、帧表 20（主角 8+NPC 11+动态 3）、背景五关×7、物件 4、光影 4、py 脚本 5。
- **坑**：部分 `.png` 实为 JPEG（FFD8FF）→ Godot 拒载；用 System.Drawing 读入再 Save(Png) 转真 PNG（主角 idle/jump/interact 与 NPC 全部已处理）。
- 处理链：① 立绘抠图（色距<46 全透、46–62 羽化，缩到高 512 → `assets/portraits/`）② 主角帧表归一化（`normalize_frames.gd`：逐帧紧裁+底对齐+等宽单行）③ NPC 帧表归一化（`npc_frames.gd`：行带检测取第 1 行待机+列分段 → `npc_anim/`+`meta.json`）④ 物件抠图（阈值 44/62，缩到宽 1024 → `objects/`）⑤ 背景无需预处理（`add_scene_art` 运行时探测）⑥ 光影/动态帧**未接线**。
- 许可：Fusion Pixel Font(OFL)；Kenney(CC0)；OpenGameArt Minimalist Chinese Temple(**CC-BY，作者名待补**)；素材2 为 AI 生成非商用。

## 11. 已知问题与技术债
1) 关卡仍"内联角色"（renwu 实例场景已生成未使用）→ 迁移：`instantiate()` + 设置位置/对话属性后删除内联段。
2) 素材质量折损：抠图毛边；`old_man` 待机仅 1 帧、`vendor` 帧偏宽。
3) NPC 仅待机动画（帧表第 2/3 行走/交互未切）。
4) 光影与动态帧未接（`江水_3帧`/`灯笼摆动_3帧`/`窑火_4帧`、`glow_soft_*`、`window_light_*`）。
5) 人群立绘复用 NPC 图，正式版应换专用群演。
6) 对话面板仅支持左右两位立绘。
7) 无音频。
8) 导出未通（缺 export templates）。
9) `McpInteractionServer` 调试 autoload 残留。
10) 中文路径与网络代理注意（见 §2）。
11) 视觉验收曾不可靠（vision 429/超时），建议自建截图回归。
12) 历史事故：`chase_manager.gd`/`forge_sequence.gd` 曾因编辑写坏出现 "Expected end of file"，已重写干净版。

## 12. 建议路线（优先级）
1. 跑通基线（§0 命令 + F5 五关 + 失败/重生/转场）。
2. 写 `tools/capture.gd`（切关→等帧→`get_viewport().get_texture().get_image().save_png()`）做截图回归。
3. 五关角色**实例化迁移**（删内联、用 renwu 场景）。
4. 光影 + 动态帧接线（Sprite2D+CanvasItemMaterial(Add)；SpriteFrames 切帧）。
5. 地面 TileMap 化（32/64/16 瓦片规格，命名 `<关卡拼音>_dixing_###`）。
6. 动画补全（NPC 走/交互、主角跑/落地）。
7. UI/字体打磨；开始界面加背景图。
8. 音频接入（BGM+SFX，注意先导入）。
9. 导出 exe（装 templates）。
10. 存档（`user://save.json`）。

## 13. 交接验收清单
- [ ] `scene_builder` 9 个 part 全 PASS；`verify` PASS
- [ ] `kaishi.tscn` 启动 → 回车进入 01
- [ ] 01：与 `chuandanayi` 对话 → 追逐触发 → 踩 `diyiguan_husongdizhuan` 进 02
- [ ] 02：对 `di_erguan_yanbi` 连按 E 九次通关；超时失败重载
- [ ] 03：四 NPC 对话 → 老周按 tier 三档 → 进 04
- [ ] 04：6 人跟随；被炸失败重载；`disiguan_chukou` 进 05
- [ ] 05：四触发点；拍照→独白→回 01
- [ ] 对话立绘高亮/变暗正确、无卡死
- [ ] 命名与 `docs/命名与分类规范.md` 一致

## 14. 排错速查
| 症状 | 处理 |
|---|---|
| 素材不显示 | 编辑器打开一次 / 右键"重新导入" |
| 改了 builder 没变化 | 跑 `scene_builder.gd` |
| Identifier not declared | 改路径 `load` / 运行期取 autoload |
| Cannot infer the type | 显式类型标注 |
| Expected end of file | 括号/缩进破损，按编辑器行号重写该函数 |
| 场景子节点丢失 | 用 `save_scene`（内部设 owner） |
| 9090 被占用 | 关旧实例 / 删调试 autoload |
| 视口/stretch/主题"消失" | 复查 §4.4 三行 |
| 图片加载失败但文件在 | `.png` 实为 JPEG → 重存真 PNG |
| 构建 >130s 超时 | 关旧实例重跑；必要时分批生成 |

## 15. 常量速查
```
玩家 130 / -320 / 700；显示高 48；01 出生 (−680,200)
追逐 speed 112；判定 <20px；冷却 1.2s；击退 160
烦心值 3；锻造 3 轮×(1s+1s+1s)、限时 180s；轰炸 6–10s、预警 1.5s、半径 34
跟随 采样 0.5s、缓冲 40、速度 108-i*9（≥42）
视口 640×360；世界宽 3200（−700…2500）；地面顶 y=240
视差：远景 motion 0.06（mirroring=贴图宽）、中景 0.5、地形 z=10
主题 assets/ui/theme.tres（Fusion Pixel 12px）；InputMap A/D/Space/E
```

_本文档由 DSH 会话整理；如与代码冲突，以代码与 `docs/命名与分类规范.md` 为准，并请更新本文档。_

---

# 附篇 A：关键脚本逐文件说明

## A1. autoload/level_manager.gd
- `SCENES: Array[String]`（5 关路径，guanqia 前缀）；`current_level: int`；`checkpoint_pos: Vector2`；`_fail_layer/_fail_label`。
- `_ready()` 构建失败 UI（CanvasLayer layer=40、process_mode=ALWAYS、黑底 0.85、居中文字自动换行）。
- `fail(reason)`：显示文案 → `get_tree().paused = true` → Tween 1.5s（TWEEN_PAUSE_PROCESS）→ 关闭暂停/隐藏 → `respawn()`。
- `complete()`：`current_level += 1` → `_go(SCENES[current_level-1])`。
- `travel_to(level, caption)`：设 current_level 后 `_go()`（用于地砖穿越/重开/开始界面按钮）。
- `respawn()`：`get_tree().reload_current_scene()`（见 DEV_LOG 偏离：等价关卡重置，保留 register_checkpoint 接口）。
- `_go(path, caption)`：进入第三关前 `GameState.reset_goods()`；用 `load("res://scripts/systems/scene_transition.gd").new()`（**路径加载**，规避类缓存）挂到 `get_tree().root`，`tr.call("play", path, caption)`。

## A2. scripts/systems/scene_transition.gd
- `extends CanvasLayer`，layer=50，ALWAYS；构建全屏黑 ColorRect（alpha 0）+ 居中 caption Label。
- `play(to_path, caption)`：Tween 0.5s 变黑 → `change_scene_to_file.call_deferred(to_path)` → 0.2s → 0.5s 变亮；caption 同步淡入。

## A3. scripts/ui/dialogue_panel.gd（双立绘对话框）
- 常量：`BOX_TOP=270 / PT_W=116 / PT_H=158`；`PORTRAITS` 字典：`"说话人名": ["res://assets/portraits/xxx.png", is_hero]`。
- `_build_ui()`：底框（0.05,0.05,0.08,0.92）、左右 TextureRect（`EXPAND_IGNORE_SIZE`+`STRETCH_KEEP_ASPECT_CENTERED`；左 flip=false 朝右、右 flip=true 朝左）、名字 Label(13)、正文 Label(12, autowrap)、选项 VBox、Timer(0.03s)。
- `play_line(speaker,text)`：设名字 → `_set_portraits(speaker)` → 打字机启动。
- `_set_portraits`：说话方 alpha 1.0；另一方 0.45；未登记说话人（旁白/独白/历史木牌…）两侧 0.5。
- `_process`：interact/ui_accept → 打字中则立刻整句；已完成则发 `advance_requested`。
- `show_options(opts)`：生成 Button 列表，第一项 grab_focus；点击 `DialogueSystem.choose(i)`。
- `has_options()/hide_panel()` 供 DialogueSystem 查询/收尾。

## A4. scripts/ui/kaishi_menu.gd（开始界面）
- 纯代码 UI：深色底 + 4 条半透明色带 + 标题"洞 见"(56px 金) + 主题句 + "开始游戏（Enter）"按钮 + 操作提示。
- `_unhandled_input`：任意键/点击开始；`_start()` → `LevelManager.travel_to(1, "洪崖洞 · 迷途")`（异常时回退 `change_scene_to_file`）。

## A5. scripts/player/player_controller.gd
- `_physics_process`：frozen 直接归零返回；`Input.get_axis("move_left","move_right")` 控制 velocity.x（同时 set_look_dir）；离地加 GRAVITY；`jump` 且 `is_on_floor`；`move_and_slide()`；`interact` 触发 `_try_interact()`。
- `_try_interact()`：取 `nearby` 首个有 `on_interact` 的对象 → 先 `zhujue_donghua.trigger_interact()` → 调 `on_interact(self)`。
- 交互区进入/离开维护 `nearby`（仅收有 `on_interact` 的 Area2D）。

## A6. scripts/player/hero_anim.gd
- `_build_frames()`：对 `SHEETS` 每项 `load` 大条 → 用 `AtlasTexture` 按 `fw` 等宽切 8 帧 → 建 `SpriteFrames`（idle/walk/jump 循环，interact 不循环）→ `sprite_frames = sf`。
- `_apply_anim(name)`：`scale = 48/fh`（按各自帧高），`position = (-fw*scale/2, -fh*scale)`（底对齐、水平居中）→ `play(name)`。
- `_physics_process`：`_interacting>0` 时倒计时并强制 interact 状态；否则按 `parent.velocity / is_on_floor` 切 idle/walk/jump，`flip_h` 由移动方向决定。
- `trigger_interact()`：播放 interact 一次（1s）后回 idle。

## A7. scripts/npc/interactable.gd
- `_prompt()`：返回名字为 `Prompt` 或以 `_tishi` 结尾的子节点（兼容两种命名）。
- `_ready` 隐藏提示；`body_entered/exited` 用鸭子类型判断玩家并开关提示；子类覆写 `on_interact`。

## A8. scripts/npc/*.gd 其余
- `npc_base.gd`：`@export dialogue_file / dialogue_node`；交互 → `DialogueSystem.load_data + start_dialogue`。
- `flyer_lady.gd`：`_started` 防重入；对话 `flyer_lady` 结束（`ended`）→ 找当前场景 `ChaseManager` → `begin()`。
- `laozhou.gd`：读 `GameState.get_result_tier()` → 映射 `laozhou_good/damaged/bad`；`ended` → `LevelManager.complete()`（注意：先 disconnect 再切场景）。
- `photo_spot.gd`：对话 `photo`（含选项）→ `ended` → `LevelManager.travel_to(1, "（五关走完，重新出发）")`。
- `forge_wall.gd`：`on_interact` → `ForgeSequence.advance()`；`mark_heat/mark_quench` 切叠层显隐、`crack()` 每轮隐藏 `Seg{2n-1}`。
- `wood.gd`：`freeze(true)` + `UI_Notice` 文案 1.6s → 解冻。
- `chaser_lady.gd`：`activate(player)` 后追踪；重力 700；速度 112；距离 <20 扣心（冷却 1.2）+ `knock(-dir*160)`；依赖物理阻挡（人群/地形）。
- `group_follower.gd`：`_leader` 取 `zhujue`；容器 `NPC_Group` 内 `NPC_Follower*` 收集；0.5s 采样进 `history`（上限 40）；每帧 `move_toward`（速度 108-i*9，下限 42；目标索引 `max(0, size-1-i*3)`）。

## A9. scripts/systems/*.gd 其余
- `heart_system.gd`：`current=3`；`take_damage(n=1)` → 更新 `UI_Hearts`（♥重复）+ emit `changed`；归零 → `LevelManager.fail(放弃文案)`。
- `crowd_area.gd`（历史遗留，当前 01 用物理人群后未挂载）：停留 2s 扣心 + `covers` 组保护。
- `loose_tile.gd`：一次性触发 → `LevelManager.travel_to(2, "……慢一点，看清楚再走。")`。
- `checkpoint.gd`：玩家进入 → `LevelManager.register_checkpoint(global_position)`。
- `exit_portal.gd`：一次性 → `LevelManager.complete()`。
- `bomb_warning.gd`：`_phase` 状态机（0 冷却 / 1 预警 / 2 爆炸）；预警时红屏闪烁 + 落点标记；爆炸半径 34 判定玩家与 `NPC_Group` 子节点 → `fail(...)`；之后随机 6–10s 再来。
- `camera_rig.gd`：`shake` 用 `offset` 随机抖动并按剩余时间衰减。
- `choice_system.gd`：提供 `apply_event(name)` / `tier()` 两个薄封装（真实分支在 JSON+DialogueSystem）。

## A10. scripts/background/*.gd
- `light_rig.gd`：`set_tone(color, energy)` 改 CanvasModulate；`add_point_light(pos,color,energy,radius)` 动态加点光源。
- `swing.gd`：`rotation = sin(t*speed)*angle`，可绑定 `PointLight2D.energy` 呼吸。
- `path_mover.gd`：沿 `points` 循环 `move_toward`（索道/航船）。

---

# 附篇 B：开发历史与关键决策（为什么是这样）

## B1. 规格驱动的十阶段（Phase 0–9）已完成
- 依据 `SPEC.md` 从零搭：Phase0 初始化 → Phase1 核心框架（Player/Interactable/LevelManager/Checkpoint/SceneTransition/Camera）→ Phase2 对话系统 → Phase3 第一关 → Phase4 第二关 → Phase5 第三关 → Phase6 第四关 → Phase7 第五关 → Phase8 背景系统（5 层视差 + WorldEnvironment + LightRig）→ Phase9 打磨与总验收。
- 每阶段都跑 `scene_builder` + `verify` + 无头 init，并把日志写入 `Build/Logs/phase*.log`（历史证据可查）。
- 详细偏离记录在 `DEV_LOG.md`（强烈建议先读）。

## B2. 关键技术决策
1. **放弃 class_name 依赖**：原因见 §4.3（headless 无类缓存）；后果：`.gd` 之间用路径 `load`/`extends`，autoload 改运行期取。
2. **场景全代码生成**：可重复、可批量改；代价是手改会丢。
3. **失败=重载当前场景**：简化实现、确定性好；原始规格的"存档点重生"语义由 Checkpoint 节点+重载近似。
4. **帧动画按帧高动态缩放**：素材来自 AI，各动画条帧高不同（691/1946/701/814），统一"角色高 48"比统一缩放更稳。
5. **双立绘对话框**：需求"说话方亮、另一方暗"直接落到 `dialogue_panel._set_portraits`。
6. **远景用人类主背景**：旧的程序化色带/全幅背景被显式移除（在 builder 中删除 `BG_Backdrop` 块、色带 alpha 置 0），远景=每关 `*主背景*.jpg`（alpha 0.55 雾感、motion 0.06）。
7. **人群取代掩体**：01 关追逐战手感需要"会挡人的障碍"，用 StaticBody2D 群组 + 3 立绘实现（`make_crowd`）。
8. **命名规范化**：目录/节点/物件统一（`docs/命名与分类规范.md`），并把脚本里 6 处 `find_child("Player")` 等改成新名（zhujue / 拼音 / 关卡前缀）。

## B3. 素材接入历史
- 人类提供 `素材2` 素材库（73 文件）→ 复制进 `assets/raw/素材2/`（60MB）。
- 立绘 12 张抠图（发现 3 张"png 实为 jpeg"的坑）→ `portraits/`。
- 主角帧表 4 张 → 归一化 `player_frames_norm/` → `hero_anim.gd` 使用（替换了早期 Kenney 试连与程序化占位）。
- NPC 帧表 11 张 → 归一化 `npc_anim/` + meta → `skinner` 待机动画。
- 背景五关 → `add_scene_art` 自动探测接入（远景/中景/地形三层）。
- 物件 4 件 → 抠图 `objects/` → `add_object_behind` 摆放（01 吊脚楼 / 02 窑炉 / 03 茶馆门面+码头 / 05 码头）。
- 光影与动态帧：**人类素材已入库但未接线**（交接后待办）。

## B4. 已知的"人机协作"经验
- 人类在编辑器里直接粘贴大图会因**绘制顺序**覆盖角色与装饰 → 正确做法：改 `scene_parts` 代码或用 `z_index`。
- 一些 GitHub release 需代理；一些 png 实为 jpeg；Godot 导入需要"编辑器过一次"。
- DSH 会话的视觉校验通道不稳定，重要的美术验收最好由人类肉眼看截图。

---

# 附篇 C：素材文件清单（可直接对照）

## C1. 立绘 `assets/portraits/`（12）
chenmo、flyer_lady、tourist、vendor、old_man、old_artisan、aming、old_shopkeeper、fat_teahouse、helper、laozhou、crowd
（384×512 透明 PNG；key 与 `dialogue_panel.PORTRAITS` / `skinner.NPCS` 对应）

## C2. 主角动画 `assets/player_frames_norm/`
idle_n.png（2112×691，8×264）、walk_n.png（9216×1946，8×1152）、jump_n.png（2112×701）、interact_n.png（2112×814）

## C3. NPC 动画 `assets/npc_anim/` + meta.json
aming、crowd、fat_teahouse、flyer_lady、helper、laozhou、old_artisan、old_man、old_shopkeeper、tourist、vendor
（meta 字段：file/fw/fh/count/fps；`old_man` 当前 count=1）

## C4. 摆件 `assets/objects/`（4）
stilt（吊脚楼）、kiln（陶窑炉）、teahouse（茶馆门面）、dock（石板码头）——1024 宽透明 PNG。

## C5. 程序化占位 `assets/generated/`（历史产物，部分仍作为回退）
chenmo_idle、npc_*（8）、obj_lantern、obj_roof、bg_01..05（后者已不再使用）

## C6. 素材库原件 `assets/raw/素材2/`
- 人物/（12 立绘）、帧表/（主角 8 + NPC 11 + 场景动态 3）、背景/（01..05 各 7 件）、场景物件/（4）、光影/（4 透明 PNG）、动态素材/README.txt、5 个 `make_*.py`

---

# 附篇 D：DSH 会话特有注意事项（若继续用 DSH 而非纯编辑器）

1. **Godot 只能用 godot_* 工具启动**：DSH 文件沙箱会拦截 Godot 对 `user://` 的写入导致崩溃；`godot_run_project`/`godot_run_headless` 走的是不受限通道。
2. **插件写文件受限**：DSH 插件的文件写入被限制在会话工作区，历史上靠"先手动放好 autoload 脚本"绕过（`mcp_interaction_server.gd`）。
3. **导出尝试可用于触发导入**：跑一次 `godot_export_project`（会因缺模板失败）可完成资源导入。
4. **工作区**：会话工作区为 `F:\Deepsseekha`，项目在 `F:\游戏\cs2`（不在工作区内，但文件策略为 full-access）。
5. **日志与截图**：无头运行输出即日志；窗口运行可用 `godot_command screenshot` 抓 640×360 PNG。
6. **不要用 pwsh 直接跑 Godot**（历史崩溃）；用上面的 godot_* 工具或编辑器。

---

_附篇 A–D 与正文共同构成完整交接材料；建议 Codex 阅读顺序：本文正文 §0–§4 → DEV_LOG.md → 目录/命名规范 → 需要改哪块再读附篇 A 对应文件。_

---

# 附篇 E：逐关节点清单（接手时对照用）

> 说明：坐标为世界坐标（1px=1 单位），地面顶 y=240；世界横向 −700…2500（宽 3200）。

## E1. 01_hongyadong（第一关）
| 节点名 | 类型 | 位置 | 说明 |
|---|---|---|---|
| LevelRoot | Node2D | 0,0 | 场景根 |
| BG_Parallax | ParallaxBackground | — | 视差（色带已透明 + 远景/中景/地形艺术层） |
| Ground | StaticBody2D | (900,260) | 地面碰撞（3200×40）+ GroundFill 视觉 + TerrainTile 铺装(z=10) |
| EdgeWall ×2 | StaticBody2D | (−712,140) / (2512,140) | 两端边界墙 |
| zhujue | CharacterBody2D | (−680,200) | 主角（脚本 player_controller） |
| HeartSystem | Node | — | 心烦值 |
| UI_Base | CanvasLayer(10) | — | 含 UI_Hearts / UI_Notice / DialoguePanel |
| Checkpoint | Area2D | (140,215) | 存档点 |
| chuandanayi | Area2D | (250,210) | 传单阿姨（对话→追逐） |
| ChaseManager | Node | — | 追逐管理器 |
| chaseayi_01..04 | CharacterBody2D | (320,215)/(560,215)/(1350,215)/(1650,215) | 追赶阿姨 |
| diyiguan_renqun_01..04 | StaticBody2D | (780)/(1000)/(1220)/(1460) | 人群路障（宽 84/64/92/72，高 50/46/52/46） |
| OBJ_Lantern ×2 | Sprite2D | (600,96)/(1750,96) | 装饰灯笼 |
| diyiguan_mupai | Area2D | (1820,210) | 历史木牌（对话） |
| diyiguan_husongdizhuan | Area2D | (1930,240) | 松动地砖（→02） |
| WorldEnvironment / LightRig | — | — | 氛围与灯光（近景霓虹点光） |

## E2. 02_ciqikou（第二关）
| 节点名 | 类型 | 位置 | 说明 |
|---|---|---|---|
| Ground / EdgeWall ×2 | — | (900,260) / (−712,2512) | 同上 |
| zhujue | CharacterBody2D | (80,200) | 主角 |
| UI_Base | CanvasLayer | — | UI_Timer（⏳180）/ UI_Notice / DialoguePanel |
| ForgeSequence | Node | — | 锻造状态机（3 轮 / 180s） |
| laojiangren | Area2D | (300,210) | 老匠人（对话） |
| di_erguan_huzhou | Area2D | (430,210) | 糊粥碗（文本） |
| di_erguan_mutou | Area2D | (560,215) | 大木头（抬不动） |
| aming | Area2D | (720,210) | 阿明（烤红薯） |
| Checkpoint | Area2D | (1100,215) | 岩壁前存档点 |
| di_erguan_yanbi | Area2D | (1250,150) | 岩壁（E 推进锻造；含 Seg0..5 与 OverlayHeat/Quench） |
| di_erguan_yanbi_qiangti | StaticBody2D | (1250,150) | 岩壁实体挡墙 |
| kiln（摆件） | Sprite2D | x=1000, h=180 | 地面后方 |

## E3. 03_zhongshan（第三关）
| 节点名 | 类型 | 位置 | 说明 |
|---|---|---|---|
| zhujue | CharacterBody2D | (60,200) | 主角 |
| ChoiceSystem | Node | — | 选择系统薄封装 |
| laozhanggui / pangzhanggui / banggong | Area2D | (180)/(430)/(660) | 三段式 NPC |
| laozhou | Area2D | (920,210) | 验货（按 tier）→ 通关 |
| disanguan_huobao | Area2D | (300,215) | 货包（文本） |
| OBJ_Lantern ×3 | Sprite2D | 260/520/880 | 装饰 |
| teahouse / dock（摆件） | Sprite2D | x=430 h=205 / x=920 h=130 | 地面后方 |

## E4. 04_fangdong（第四关）
| 节点名 | 类型 | 位置 | 说明 |
|---|---|---|---|
| zhujue | CharacterBody2D | (80,200) | 主角（自带跟随 PointLight2D，暖色） |
| GroupFollower | Node | — | 队列跟随 |
| NPC_Group / NPC_Follower1..6 | Node2D | 队首 (50,212) 起每 14px 一个 | 6 名跟随者 |
| BombWarning | Node | — | 轰炸预警/爆炸判定 |
| UI_BombFlash | ColorRect | 全屏 | 红色警示 |
| Checkpoint | Area2D | (700,215) | 洞中途存档点 |
| disiguan_chukou | Area2D | (1320,215) | 出口（→05） |

## E5. 05_hongyadong_return（第五关）
| 节点名 | 类型 | 位置 | 说明 |
|---|---|---|---|
| zhujue | CharacterBody2D | (60,200) | 主角 |
| diwuguan_mupai | Area2D | (260,215) | 读历史 |
| jianglishilaoren | Area2D | (480,215) | 讲吊脚楼 |
| diwuguan_jingguandian | Area2D | (760,215) | 看江 |
| diwuguan_zhaoxiangdian | Area2D | (1080,215) | 拍照二选一 → 独白 → 回 01 |
| chuandanayi | Area2D | (640,215) | 内心 OS 触发点 |
| dock（摆件） | Sprite2D | x=1100 h=130 | 江岸装饰 |

---

# 附篇 F：对话数据全文（改文案直接改 JSON 即可）

## F1. assets/dialogue_level1.json
- `flyer_lady`：阿姨拉扫码 → "姐妹们，拦住他！" → 陈默"不妙，得赶紧溜！"（结束后触发追逐）
- `info_board`：木牌读历史 → 陈默敷衍 → "（脚下传来一声异响……）"
- `test_npc`：早期测试节点，可删

## F2. assets/dialogue_level2.json
- `old_artisan`：老匠人问"你是哪家窑上的" → 陈默"摄像机在哪" → "你们那儿的房子，经得起洪水吗？"（沉默）
- `aming`：塞烤红薯
- `porridge`：喝糊粥的沉默

## F3. assets/dialogue_level3.json（分支最多）
- `old_shopkeeper`：托付货包 → 选项【走大路 → `take_bag_main`(goods_event: safe) / 抄小巷 → `take_bag_alley`(stolen)】
- `teahouse`：胖掌柜套话 → 选项【实话 → `teahouse_honest`(safe) / 撒谎 → `teahouse_lie`(cheated) / 反问 → `teahouse_retort`(stolen)】
- `helper`：码头帮工 → 选项【让 → `helper_yes`(robbed) / 不让 → `helper_no`(safe)】
- `laozhou_good / laozhou_damaged / laozhou_bad`：三档验货台词（由 laozhou.gd 按 tier 选择）
- `goods_bag`：货包查看文本

## F4. assets/dialogue_level5.json
- `old_man`：吊脚楼历史
- `flyer_lady_os`：传单阿姨内心 OS
- `board`：重读木牌
- `view_spot`：台阶看江
- `photo`：选项【拍一张 → `photo_take` / 不拍了 → `photo_not`】，两者结尾都是独白"我以为历史是玻璃罩子里的东西。我错了。历史是那些台阶、那些砖、那些绳子、那些人的命。"

---

# 附篇 G：verify.gd 当前检查项（改节点名必须同步这里）

| 场景 | 必查节点 |
|---|---|
| 01 | zhujue、HeartSystem、chuandanayi、diyiguan_mupai、diyiguan_husongdizhuan、BG_*≥3、WorldEnvironment、LightRig |
| 02 | zhujue、ForgeSequence、di_erguan_yanbi、di_erguan_mutou、laojiangren、aming、UI_Timer、BG/Env/LightRig |
| 03 | zhujue、ChoiceSystem、laozhanggui、pangzhanggui、banggong、laozhou、disanguan_huobao、BG/Env/LightRig |
| 04 | zhujue、GroupFollower、BombWarning、NPC_Group、PointLight2D、Checkpoint、disiguan_chukou、NPC_Follower*≥6、BG/Env/LightRig |
| 05 | zhujue、diwuguan_mupai、jianglishilaoren、diwuguan_jingguandian、diwuguan_zhaoxiangdian、BG/Env/LightRig |
| 全局 | 扫描 assets/dialogue_level*.json 并 JSON.parse 判非空 |

---

# 附篇 H：五关色板（来自素材规格表，改色/做新素材时的基准）

## ① 现代·夜（洪崖洞）
霓虹金 #E8B04B（主）｜夜蓝 #2A2E4A｜灯牌红 #D94F4F｜玻璃青 #5A7A8A｜暖白 #F0E6C8｜暗金 #8A6A2F｜深蓝 #1A1C2E｜中性灰 #6B6B7A

## ② 古代·窑场（磁器口）
赭红 #C96F4A（主）｜土黄 #A9793F｜火橙 #F2A65A｜亮橙 #FFB066｜炭黑 #2B2320｜灰岩 #8A8578｜陶褐 #B08968｜焦褐 #6E4632

## ③ 古代·古镇（中山）
青灰 #7E8B99（主）｜竹绿 #7FA188｜苔绿 #6B8F71｜石白 #D8D3C8｜墨色 #33383E｜瓦灰 #5A6470｜木褐 #9C7B5C｜茶色 #B99B72

## ④ 近代·防空洞
墨黑 #1A1A1E（主）｜警报红 #B23A48｜煤油黄 #E8B04B｜苍白 #C9C4BA｜硝烟灰 #4A4A52｜血暗 #7A2A33｜煤褐 #3A322C

## ⑤ 现代·晨（归来）
晨光 #F0D9A0（主）｜雾白 #E8E2D2｜砖红 #A96B5E｜檐灰 #8A8A82｜江水蓝 #7FA8B5｜木原色 #B08A5E｜淡金 #E8C87A

> 瓦片规格：地形 32×32、建筑 64×64、装饰 16×16、前景剪影 128×64、远景剪影任意大图（2–3 色）。
> 动画帧率：待机 6fps / 走路 10fps / 跑步 12fps / 跳跃 10fps / 交互 8fps。

---

# 附篇 I：日志与截图索引

- `Build/Logs/phase0..9_build|verify|init.log`：十阶段的历史验证证据（每份末行 [RESULT] PASS）
- `Build/Logs/phase9_export.log`：导出失败记录（缺 templates）
- `Build/Game/preview_*.png`：各阶段实机截图（mainbg_*、layers_*、road_*、dialog_*、cd_* 等，可作回归对照基线）
- `Build/Game/`：预留导出目录（洞见.exe 尚未产出）

---

# 附篇 J：常见扩展任务怎么做（照着改）

## J1. 加一个新 NPC
1) `assets/portraits/` 放立绘（透明 PNG）→ `dialogue_panel.gd` 的 `PORTRAITS` 加一行
2) `assets/npc_anim/`：把新帧表放 `assets/npc_src/<拼音>.png` → 在 `tools/npc_frames.gd` 的 `KEYS` 里加 <拼音> → 跑该脚本 → 检查 meta.json
3) `autoload/skinner.gd` 的 `NPCS` 映射加 `"<拼音>": "<动画key>"`
4) 关卡 builder 里加节点（`b.add_node(root, "Area2D", "<拼音>")` + 碰撞 + `Prompt` 或 `<拼音>_tishi` + `dialogue_file/dialogue_node`）
5) 对话 JSON 加对应节点；`tools/verify.gd` 期望清单加该名字
6) 重建 + verify + 实机对话验证

## J2. 加一层背景装饰（如"隐约巨像"）
- 编辑器临时法：加 Sprite2D → 贴图 → 检查器 `Modulate` 把 A 拉到 0.3–0.5、RGB 提亮偏天空色 → 若要跟随镜头很慢：放进 `ParallaxLayer` 且 `Motion Scale=(0.05,1)`
- 永久法：在 `build_common.add_scene_art` 里再加一段（复制 far 那段，换文件名关键字与 alpha）
- 层级规则：**后画的盖先画的**；要压在最底 → 放进 `BG_Parallax` 的层里；要盖过同父其它节点 → 设 `z_index`（地形贴图就是这样做成 10）

## J3. 加一关（第 6 关）
1) `tools/scene_parts/build_06.gd`（照 `build_03.gd` 抄，改名/坐标）
2) `tools/scene_builder.gd` part 列表加 "build_06"
3) `autoload/level_manager.gd` 的 `SCENES` 追加路径（`scenes/guanqia/06_*.tscn`）
4) `tools/verify.gd` 加该场景期望清单
5) 重建 + verify

## J4. 换成 TileMap 地面
1) 编辑器建 TileSet（32×32），导入素材库 `背景/0X/地形_无缝单元`
2) 建 TileMapLayer 节点，命名 `<关卡拼音>_dixing`（如 `diyiguan_dixing`）
3) 在对应 `build_0X.gd` 里用代码铺（或先在编辑器铺好，再把关键参数抄进 builder 用脚本重建）
4) 保留原 `Ground` StaticBody2D 碰撞（TileMap 只做视觉时最简单）

## J5. 接入音频（最小闭环）
1) BGM/SFX 文件放 `assets/audio/`（BGM 用 .ogg 循环，SFX 用 .wav）
2) 关卡 builder 加 `AudioStreamPlayer`（BGM 自动播放、循环）；脚步/交互在脚本里 `play()`
3) 若要全局管理，可加 autoload `AudioManager`
4) 记得先在编辑器导入一次

---

_（附篇完）本文档与 `DEV_LOG.md`、`docs/命名与分类规范.md`、`assets/洞见-素材规格表-dsh执行版.md`、`美术接线手把手手册.md` 共同构成完整交接资料。_

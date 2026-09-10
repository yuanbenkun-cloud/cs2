# DEV_LOG（《洞见》Godot 执行日志）

- 项目根：F:\游戏\cs2
- Godot 可执行文件（$godotExe）：F:\godot\Godot_v4.7.2-stable_win64.exe（4.7.2 stable，满足 ≥4.3，使用 TileMapLayer 体系）
- 规格备份：SPEC.md（与 F:\游戏\cs2\洞见-Godot-DeepSeekHarness-执行规格书.md 同源）
- 启动方式：一律 --headless；工具脚本 extends SceneTree

| Phase | 结果 | 日志 | 备注 |
|---|---|---|---|
| Phase 0 | PASS | phase0_verify.log | 目录/project.godot/autoload空壳/builder+verify骨架；init 主场景未生成属预期（Phase1 后复跑干净） |
| Phase 1 | PASS | phase1_build/verify/init.log | Player/Interactable/LevelManager/Checkpoint/SceneTransition/CameraRig；build_01 最小骨架；02-05 先建桩保证 scene_builder 幂等 |
| Phase 2 | PASS | phase2_build/verify/init.log | DialogueSystem+DialoguePanel+JSON+NPC_Test；验证含 JSON 解析 |
| Phase 3 | PASS | phase3_build/verify/init.log | 01 完整：HeartSystem/NPC_FlyerLady/CrowdArea+掩体/OBJ_InfoBoard/OBJ_LooseTile(→02)/Checkpoint/HUD心形；实现细节：跨脚本用路径 extends+运行时 /root 查 autoload（headless 无类缓存的偏离，记录） |
| Phase 4 | PASS | phase4_build/verify/init.log | 02 完整：ForgeSequence(HEAT→QUENCH→CHISEL×3,180s)/OBJ_Wall色块裂开/OBJ_Wood抬不动/糊粥/老匠人/阿明/Checkpoint/UI_Timer+UI_Notice；对话 JSON level2 |
| Phase 5 | PASS | phase5_build/verify/init.log | 03 完整：GameState 货物完整度(stolen/cheated/robbed/safe, tier3档) + ChoiceSystem + 四 NPC（老掌柜/胖掌柜/帮工/老周验货3档→通关04）+ OBJ_GoodsBag；进入03自动 reset_goods |
| Phase 6 | PASS | phase6_build/verify/init.log | 04 完整：GroupFollower(6人环形缓冲跟随)+BombWarning(预警/高亮/爆炸判定→fail)+极暗+PointLight2D跟随+洞中途Checkpoint+OBJ_Exit(→05) |
| Phase 7 | PASS | phase7_*/phase9_verify.log | 05 完整：步行模拟 + OBJ_InfoBoard/NPC_OldMan/OBJ_ViewSpot/OBJ_PhotoSpot(拍照二选一→结尾独白→重开01)；传单阿姨内心OS |
| Phase 8 | PASS | phase8_*/phase9_verify.log | 背景系统：每关 5 层 ParallaxBackground(BG_Sky..BG_Fore, 江水 motion_mirroring) + WorldEnvironment(glow/adjustments) + LightRig(CanvasModulate时代色调+点光源)；swing/path_mover/light_rig 脚本就位 |
| Phase 9 | PASS | phase9_build/verify/init.log | 打磨与总验收：builder 二次运行幂等 PASS；verify 全场景 PASS；音频占位 README；TODO P0/P1 清零；可选导出失败（模板缺失，按规格降级并记录） |

## 实现偏离与说明（均已按 0.5 记录）
1. headless --script 运行不重建全局类缓存：跨脚本统一用路径 extends / load + 运行时 get_node_or_null("/root/X") 取 autoload（SPEC 6.x 接口行为不变）。
2. PackedScene.pack 需整树 owner=root，save_scene 内递归赋 owner（否则子节点不序列化）。
3. 场景 02–05 在未实现前先建桩，保证 scene_builder 全量幂等；随 Phase 逐个替换为真实现。
4. fail/respawn 采用"暂停1.5s显示文案→重载当前场景"（等价于关卡重置/存档点重来，checkpoint 接口保留）。
5. 相机 shake 接口放 scripts/systems/camera_rig.gd（spec 未给路径的合理实现细节）。
6. 4.7 移除 Environment.vignette_*：Phase 8 环境省略 vignette（记录后按可用 API 实现）。
7. 可选导出：官方 Export Templates(4.7.2) 未安装 → 记录 TODO，验收降级（冒烟全 PASS + 编辑器可打开）。

# 《洞见》正式美术方向

## Game frame

- Player fantasy: 作为现代重庆青年穿越不同年代，在行走、观察和帮助他人中改变。
- Core verbs: 行走、跳跃、观察、交互、搬运、带领。
- Engine and renderer: Godot 4.7，2D CanvasItem。
- Target platforms: Windows 桌面，键盘与手柄优先。
- Camera/view/facing: 640×360 横向侧视舞台，角色默认朝右。
- Native viewport and common display scale: 原生 640×360；整数倍显示。
- Typical asset size on screen: 主角约 64 px 高；NPC 52–68 px；交互物 24–96 px。

## Visual system

- Shape language: 清楚的大轮廓、略夸张的头肩和服装块面，避免写实细碎边缘。
- Silhouette priorities: 头部、背包、时代服装和手持物在缩小后仍可辨认。
- Value structure: 前景最深，中景中等对比，远景低对比；角色比相邻背景亮或暗至少一级。
- Palette roles and exact swatches: 夜蓝 `#17213B`、雾青 `#668188`、窑火橙 `#D96A32`、土褐 `#6B4632`、纸米 `#E7D6B5`、轮廓深褐 `#211817`。
- Materials and surface cues: 石阶用硬质断面，木构用纵向纹理，织物用大块褶皱，雾与水保持低频细节。
- Edge/line treatment: 像素启发式硬边与成簇明暗，深褐轮廓，不使用纯黑粗描边。
- Lighting direction and contrast: 主光默认左上；现代夜景冷环境暖灯光，古代窑场暖主光，防空洞高反差局部光，归来晨光低反差。
- Detail density and focal hierarchy: 角色与互动对象最高，地形次之，中远景只保留地标轮廓。
- Motion character: 角色脚底锚点稳定，动作先有预备再有主姿势；背包、衣摆作为克制的次级运动。
- Explicit exclusions: 假像素平滑边、每帧身份漂移、烘焙文字、手机常驻姿势、背景中的可交互假物件、与碰撞不一致的地面透视。

## Technical contract

- Asset dimensions/aspect: 角色动作先生成 2×2/2×3 多行网格，再输出 128×128 等格帧表；背景源景片统一为 1280×720，运行时以 640×360 显示。
- Background layer contract: 每关至少具有独立 `sky / far / mid` 图片层，远景与中景必须是真透明 PNG；近雾和前景雾可由 Godot 动态生成，但不得再用旧主背景整图冒充分层。
- Alpha/background: 角色和物件最终为真透明 PNG；生成原图可使用纯 `#FF00FF` 色键。
- Grid/tile/frame size: 主角 128×128/帧，脚底对齐；环境瓦片按现有关卡尺寸。
- Anchor/pivot/baseline: 人形统一 bottom-center/feet；互动道具按接地点或机械转轴。
- Filtering/mipmaps/compression: Nearest，关闭 mipmaps，lossless 导入。
- Color space: sRGB。
- Texture/poly/material budgets: 单动作 4–8 帧；宽攻击特效必须与身体帧拆分。
- Naming and folders: 正式资产统一位于 `assets/production/<family>/<asset>/`，保留 raw、透明帧表、单帧、预览、提示词和 QC 元数据。

## Visual target

- Approved seed/reference paths: `assets/production/hero/idle/`、`assets/production/backgrounds/01/layered-preview.png`、`assets/production/backgrounds/04/layered-preview.png`、`assets/production/backgrounds/05/layered-preview.png`。
- Required do/don't examples: 保持陈默橄榄绿外套与黑背包；不要把看手机当作所有状态的默认动作。
- Native-scale gameplay capture: 待首次接入后记录到 `Build/Game/`。
- Approval owner/date: Codex 依据用户授权自主选择，2026-09-12。

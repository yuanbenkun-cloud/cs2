# 洞见：主界面与五关音乐 / 强调音

本目录中的音乐为 OpenGameArt 作者以 CC0 发布的作品，经响度统一及 Ogg 转码后用于游戏；不是本项目原创作曲。铁锤音来自 Kenney CC0 音效包。第四关警报由项目已有的 Freesound CC0 录音裁剪、淡入淡出而成。保留本清单便于后续替换或致谢。

| 游戏文件 | 原曲 / 原录音 | 作者 | 来源 |
| --- | --- | --- | --- |
| `主界面-旧城灯火.ogg` | Orien | Tozan | https://opengameart.org/content/orien |
| `第1关-街巷追逐.ogg` | Determined Pursuit (epic orchestra loop) | Emma_MA | https://opengameart.org/content/determined-pursuit-epic-orchestra-loop |
| `第2关-窑火锻声.ogg` | Tyhosi Asian Sparrow 4 Kimono Market Zone | Tozan | https://opengameart.org/content/tyhosi-asian-sparrow-4-kimono-market-zone |
| `第3关-雨巷水乡.ogg` | Asianoriental1 | Tozan | https://opengameart.org/content/asianoriental1 |
| `第4关-防空洞暗潮.ogg` | Oriented | yd | https://opengameart.org/content/oriented |
| `第5关-洪崖晨光.ogg` | A New Day | SpiderDave | https://opengameart.org/content/a-new-day |
| `第2关-铁锤敲击01/02/03.ogg` | Impact Sounds / impactMetal_medium_000/002/004 | Kenney | https://kenney.nl/assets/impact-sounds |
| `第4关-间断防空警报.ogg` | Air Raid Siren Alarm | Poligonstudio | https://freesound.org/people/Poligonstudio/sounds/412171/ |
| `第4关-航弹轰炸.ogg` | Chunky Explosion + Muffled Distant Explosion | Joth + NenadSimic | https://opengameart.org/content/chunky-explosion ・ https://opengameart.org/content/muffled-distant-explosion |

音乐转码目标：-18 LUFS、最高真峰约 -1.5 dBTP；Godot 播放器再按场景和设置调整音量。间断铁锤采用三种短采样随机成组播放，警报每 12–17 秒播放约 5.5 秒，进出关卡自动停止。用户可在暂停设置中独立调节音乐、环境声和音效。

选曲意图：菜单保留“历史将要被看见”的悬念；第一关节奏紧迫；第二关东方器乐与实际窑火、铁锤分层；第三关器乐流动感配小雨；第四关低沉配乐让警报成为前景；第五关回到轻松的现代日常。

第四关航弹落地声把近距离爆响与低频远处轰鸣叠在一起，裁至约 2.9 秒并做尾音淡出。挡板吸收时在游戏内降音量、降音高；地面直击更响。其他剧情漫画使用的通用爆炸音保留不变。

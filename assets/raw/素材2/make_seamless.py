import os, sys
import numpy as np
from PIL import Image

BLEND = 96  # 接缝混合带宽（像素）

def edge_diff(arr):
    """左右边缘列的平均差异（越小越无缝）"""
    h, w, _ = arr.shape
    left = arr[:, 0, :].astype(np.int16)
    right = arr[:, w - 1, :].astype(np.int16)
    return float(np.mean(np.abs(left - right)))

def make_seamless(path_in, path_out):
    img = Image.open(path_in).convert("RGB")
    arr = np.array(img)
    h, w, _ = arr.shape
    half = w // 2
    before = edge_diff(arr)
    # 两半交换：新图左边缘=原图半幅列，右边缘=原图半幅-1列，天然相邻
    new = np.empty_like(arr)
    new[:, :half] = arr[:, half:]
    new[:, half:] = arr[:, :half]
    # 中间接缝混合（原图左右边缘相接处）
    xl = half - BLEND
    for i in range(BLEND):
        t = i / BLEND
        a = new[:, xl + i].copy()
        b = new[:, half + i].copy()
        new[:, xl + i] = (a * (1 - t) + b * t).astype(np.uint8)
        new[:, half + i] = (b * (1 - t) + a * t).astype(np.uint8)
    after = edge_diff(new)
    Image.fromarray(new).save(path_out, optimize=True)
    return w, before, after

jobs = [
    (r"C:\Users\Administrator\Desktop\素材2\背景\01洪崖洞-现代夜\中景_循环背景.jpg",  r"C:\Users\Administrator\Desktop\素材2\背景\01洪崖洞-现代夜\中景_无缝循环.png"),
    (r"C:\Users\Administrator\Desktop\素材2\背景\01洪崖洞-现代夜\地形_循环背景.jpg",  r"C:\Users\Administrator\Desktop\素材2\背景\01洪崖洞-现代夜\地形_无缝循环.png"),
    (r"C:\Users\Administrator\Desktop\素材2\背景\02磁器口-古代窑场\中景_循环背景.jpg", r"C:\Users\Administrator\Desktop\素材2\背景\02磁器口-古代窑场\中景_无缝循环.png"),
    (r"C:\Users\Administrator\Desktop\素材2\背景\02磁器口-古代窑场\地形_循环背景.jpg", r"C:\Users\Administrator\Desktop\素材2\背景\02磁器口-古代窑场\地形_无缝循环.png"),
    (r"C:\Users\Administrator\Desktop\素材2\背景\03中山古镇-古代\中景_循环背景.jpg",   r"C:\Users\Administrator\Desktop\素材2\背景\03中山古镇-古代\中景_无缝循环.png"),
    (r"C:\Users\Administrator\Desktop\素材2\背景\03中山古镇-古代\地形_循环背景.jpg",   r"C:\Users\Administrator\Desktop\素材2\背景\03中山古镇-古代\地形_无缝循环.png"),
    (r"C:\Users\Administrator\Desktop\素材2\背景\04防空洞-近代\中景_循环背景.jpg",     r"C:\Users\Administrator\Desktop\素材2\背景\04防空洞-近代\中景_无缝循环.png"),
    (r"C:\Users\Administrator\Desktop\素材2\背景\04防空洞-近代\地形_循环背景.jpg",     r"C:\Users\Administrator\Desktop\素材2\背景\04防空洞-近代\地形_无缝循环.png"),
    (r"C:\Users\Administrator\Desktop\素材2\背景\05洪崖洞-归来晨光\中景_循环背景.jpg", r"C:\Users\Administrator\Desktop\素材2\背景\05洪崖洞-归来晨光\中景_无缝循环.png"),
    (r"C:\Users\Administrator\Desktop\素材2\背景\05洪崖洞-归来晨光\地形_循环背景.jpg", r"C:\Users\Administrator\Desktop\素材2\背景\05洪崖洞-归来晨光\地形_无缝循环.png"),
]

print("文件 | 尺寸 | 边缘差异(前) | 边缘差异(后) | 提升")
for fin, fout in jobs:
    w, before, after = make_seamless(fin, fout)
    pct = (1 - after / before) * 100 if before > 0 else 0
    print(f"{os.path.basename(fout)} | {w}px | {before:.2f} | {after:.2f} | {pct:.1f}%")

import os
import numpy as np
from PIL import Image

BLEND = 48  # 单元尺度接缝混合带宽（1024 单元用 48px 足够）

def edge_diff(arr):
    h, w, _ = arr.shape
    left = arr[:, 0, :].astype(np.int16)
    right = arr[:, w - 1, :].astype(np.int16)
    return float(np.mean(np.abs(left - right)))

def make_seamless_unit(path_in, path_out, unit_w=1024):
    img = Image.open(path_in).convert("RGB")
    arr = np.array(img)
    h, w, _ = arr.shape
    # 裁中心 unit_w 宽
    x0 = (w - unit_w) // 2
    crop = arr[:, x0:x0 + unit_w, :].copy()
    before = edge_diff(crop)
    half = unit_w // 2
    # 两半交换
    new = np.empty_like(crop)
    new[:, :half] = crop[:, half:]
    new[:, half:] = crop[:, :half]
    # 接缝混合
    xl = half - BLEND
    for i in range(BLEND):
        t = i / BLEND
        a = new[:, xl + i].copy()
        b = new[:, half + i].copy()
        new[:, xl + i] = (a * (1 - t) + b * t).astype(np.uint8)
        new[:, half + i] = (b * (1 - t) + a * t).astype(np.uint8)
    after = edge_diff(new)
    Image.fromarray(new).save(path_out, optimize=True)
    return unit_w, before, after

base = r"C:\Users\Administrator\Desktop\素材2\背景"
jobs = [
    ("01洪崖洞-现代夜", "中景"), ("01洪崖洞-现代夜", "地形"),
    ("02磁器口-古代窑场", "中景"), ("02磁器口-古代窑场", "地形"),
    ("03中山古镇-古代", "中景"), ("03中山古镇-古代", "地形"),
    ("04防空洞-近代", "中景"), ("04防空洞-近代", "地形"),
    ("05洪崖洞-归来晨光", "中景"), ("05洪崖洞-归来晨光", "地形"),
]

print("文件 | 单元尺寸 | 边缘差异(前) | 边缘差异(后) | 提升")
for folder, layer in jobs:
    fin = os.path.join(base, folder, f"{layer}_循环背景.jpg")
    fout = os.path.join(base, folder, f"{layer}_无缝单元_1024.png")
    w, before, after = make_seamless_unit(fin, fout)
    pct = (1 - after / before) * 100 if before > 0 else 0
    print(f"{folder}/{layer} | {w}px | {before:.2f} | {after:.2f} | {pct:.1f}%")

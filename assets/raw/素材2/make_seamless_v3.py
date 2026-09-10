import os
import numpy as np
from PIL import Image

K = 64

def edge_fuse_unit(path_in, path_out, preview_out, unit_w=1024, k=K):
    img = Image.open(path_in).convert("RGB")
    arr = np.array(img)
    h, w, _ = arr.shape
    x0 = (w - unit_w) // 2
    crop = arr[:, x0:x0 + unit_w, :].copy()
    new = crop.copy()
    mid = ((crop[:, 0, :].astype(np.int16) + crop[:, -1, :].astype(np.int16)) // 2)
    for x in range(k):
        t = x / k
        new[:, x, :] = (mid * (1 - t) + crop[:, x, :].astype(np.int16) * t).astype(np.uint8)
        new[:, -1 - x, :] = (mid * (1 - t) + crop[:, -1 - x, :].astype(np.int16) * t).astype(np.uint8)
    tile = np.concatenate([new, new, new], axis=1)
    Image.fromarray(new).save(path_out, optimize=True)
    Image.fromarray(tile).save(preview_out, optimize=True)
    return crop.shape[1], crop.shape[0]

base = r"C:\Users\Administrator\Desktop\素材2\背景"
jobs = [
    ("01洪崖洞-现代夜", "地形"), ("02磁器口-古代窑场", "地形"),
    ("03中山古镇-古代", "地形"), ("04防空洞-近代", "地形"),
    ("05洪崖洞-归来晨光", "地形"),
]
for folder, layer in jobs:
    fin = os.path.join(base, folder, f"{layer}_循环背景_v3.jpg")
    fout = os.path.join(base, folder, f"{layer}_无缝单元_1024_v3.png")
    pout = os.path.join(base, folder, f"{layer}_平铺预览_v3.png")
    uw, uh = edge_fuse_unit(fin, fout, pout)
    print(f"{folder}: 单元 {uw}x{uh} 已生成")

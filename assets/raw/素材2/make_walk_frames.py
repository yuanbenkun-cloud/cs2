import numpy as np
from PIL import Image

SRC = r"C:\Users\Administrator\Desktop\素材2\人物\主角\陈默_主角.jpg"
OUT_R = r"C:\Users\Administrator\Desktop\素材2\帧表\主角\主角_行走右_跨步增强_8帧.png"
OUT_L = r"C:\Users\Administrator\Desktop\素材2\帧表\主角\主角_行走左_跨步增强_8帧.png"

img = Image.open(SRC).convert("RGB")
arr = np.array(img).astype(np.int16)
h, w, _ = arr.shape
corners = [tuple(arr[2,2]), tuple(arr[2,w-3]), tuple(arr[h-3,2]), tuple(arr[h-3,w-3])]
bg = tuple(int(round(sum(c[i] for c in corners)/4)) for i in range(3))

def is_bg(px):
    return abs(int(px[0])-bg[0]) < 25 and abs(int(px[1])-bg[1]) < 25 and abs(int(px[2])-bg[2]) < 25

rows_has = [any(not is_bg(arr[y, x]) for x in range(w)) for y in range(h)]
cols_has = [any(not is_bg(arr[y, x]) for y in range(h)) for x in range(w)]
top = rows_has.index(True); bottom = len(rows_has) - 1 - rows_has[::-1].index(True)
left = cols_has.index(True); right = len(cols_has) - 1 - cols_has[::-1].index(True)
char = arr[top:bottom+1, left:right+1, :].copy()
ch, cw, _ = char.shape
print(f"立绘角色 bbox: {cw}x{ch}")

split = int(ch * 0.62)
leg_top = split - 8
upper = char[:leg_top, :, :].copy()
legs  = char[leg_top:, :, :].copy()

def place(canvas, xoff, yoff, src):
    sh, sw, _ = src.shape
    for yy in range(sh):
        for xx in range(sw):
            px = src[yy, xx]
            if not is_bg(px):
                cx, cy = xoff + xx, yoff + yy
                if 0 <= cx < canvas.shape[1] and 0 <= cy < canvas.shape[0]:
                    canvas[cy, cx] = px

def make_pose(dx):
    cw_full = cw + 200
    ch_full = ch + 16
    canvas = np.full((ch_full, cw_full, 3), bg, dtype=np.int16)
    place(canvas, (cw_full - cw)//2, 8, upper)
    place(canvas, (cw_full - cw)//2 + dx, 8 + leg_top, legs)
    return canvas

# 4 姿态：右跨(+60) 并拢(0) 左跨(-60) 并拢(0)，循环 2 遍 = 8 帧
poses = [make_pose(60), make_pose(0), make_pose(-60), make_pose(0)]
frames8 = poses * 2
ph, pw, _ = poses[0].shape
sheet = np.full((ph, pw*8, 3), bg, dtype=np.int16)
for i, p in enumerate(frames8):
    sheet[:, i*pw:(i+1)*pw, :] = p
Image.fromarray(sheet.astype(np.uint8)).save(OUT_R, optimize=True)
print("行走右跨步增强:", f"{sheet.shape[1]}x{sheet.shape[0]}")
sheetL = sheet[:, ::-1, :].copy()
Image.fromarray(sheetL.astype(np.uint8)).save(OUT_L, optimize=True)
print("行走左跨步增强已输出")

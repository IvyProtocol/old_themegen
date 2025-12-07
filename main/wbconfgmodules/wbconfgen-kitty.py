#!/usr/bin/env python3
import os, numpy as np, cv2, colorsys

# ---------------- Helpers -----------------
def hex_to_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i+2],16) for i in (0,2,4))

def rgb_to_hex(rgb):
    return "#{:02X}{:02X}{:02X}".format(*[int(round(x)) for x in rgb])

def luminance(rgb):
    r,g,b = [x/255.0 for x in rgb]
    return 0.2126*r + 0.7152*g + 0.0722*b

def rgb_to_lab(rgb):
    r,g,b = [int(np.clip(x,0,255)) for x in rgb]
    arr = np.uint8([[[r,g,b]]])
    lab = cv2.cvtColor(arr, cv2.COLOR_RGB2LAB)[0,0]
    L = lab[0]*100/255.0
    a = lab[1]-128
    b = lab[2]-128
    return np.array([L,a,b])

def lab_delta(a,b):
    return np.linalg.norm(a-b)

def brighten(rgb, factor=1.1):
    r,g,b = rgb
    r = min(255,int(r*factor))
    g = min(255,int(g*factor))
    b = min(255,int(b*factor))
    return (r,g,b)

def saturate(rgb, factor=1.25):
    r,g,b = [x/255.0 for x in rgb]
    h,l,s = colorsys.rgb_to_hls(r,g,b)
    s = min(1.0, s*factor)
    r,g,b = colorsys.hls_to_rgb(h,l,s)
    return tuple(int(x*255) for x in (r,g,b))

def clamp_luminance(rgb, min_lum=0.07, max_lum=0.13):
    lum = luminance(rgb)
    if lum < min_lum:
        factor = min_lum / max(lum,0.001)
        rgb = tuple(min(255,int(c*factor)) for c in rgb)
    elif lum > max_lum:
        factor = max_lum / lum
        rgb = tuple(int(c*factor) for c in rgb)
    return rgb

# ---------------- Parsing -----------------
def parse_theme_dcol(path):
    modules=[]
    if not os.path.exists(path):
        print(f"{path} not found")
        return modules
    with open(path) as f:
        lines = f.readlines()
    current = {}
    for l in lines:
        l = l.strip()
        if not l or l.startswith("{color_wbgenconf_modules."):
            if current: modules.append(current)
            current = {}
            continue
        if "=" in l:
            k,v = l.split("=",1)
            k=k.strip(); v=v.strip()
            if "primary" in k: current["primary"] = v
            elif "text" in k: current["text"] = v
            elif "accent" in k: current.setdefault("accents",[]).append(v)
    if current: modules.append(current)
    return modules

# ---------------- Accent selection -----------------
def pick_accents(accents,n=9,delta_thresh=12):
    lab_list = [(rgb_to_lab(hex_to_rgb(a)),a) for a in accents]
    picked=[]
    for lab,a in lab_list:
        if all(lab_delta(lab,p[0])>delta_thresh for p in picked):
            picked.append((lab,a))
        if len(picked)>=n: break
    while len(picked)<n and lab_list:
        picked.append(lab_list[0])
    return [a for lab,a in picked]

# ---------------- Module scoring -----------------
def score_module(mod):
    bg_rgb = hex_to_rgb(mod["primary"])
    bg_rgb = clamp_luminance(bg_rgb)
    score = -luminance(bg_rgb)
    if mod.get("accents"):
        score += luminance(hex_to_rgb(mod["accents"][0]))
    return score

def pick_best_module(modules):
    best_score=-float("inf")
    best=None
    for m in modules:
        s = score_module(m)
        if s > best_score:
            best_score = s
            best = m
    return best

# ---------------- Post-processing -----------------
def postprocess_colors(primary, text, accents):
    bg_rgb = clamp_luminance(hex_to_rgb(primary))
    primary = rgb_to_hex(bg_rgb)

    processed = []
    for a in accents:
        a_rgb = saturate(hex_to_rgb(a),1.3)
        a_rgb = brighten(a_rgb,1.05)
        processed.append(rgb_to_hex(a_rgb))

    # Cursor: bright first accent
    cursor_rgb = brighten(hex_to_rgb(processed[0]) if processed else hex_to_rgb(text),1.1)
    cursor = rgb_to_hex(cursor_rgb)

    # For slots Pywal normally grays: enhance slightly
    neutral_override = rgb_to_hex(saturate(cursor_rgb,1.1))

    return primary, text, processed, cursor, neutral_override

# ---------------- Generate wallbash keys -----------------
def generate_wallbash_keys(module):
    primary, text, accents, cursor, neutral_override = postprocess_colors(
        module["primary"], module["text"], module.get("accents", [])
    )

    wallbash = {}
    wallbash["wallbash_bgx1"] = primary
    for i,a in enumerate(accents[:8],1):
        wallbash[f"wallbash_1xa{i}"] = a

    wallbash["wallbash_crx1"] = cursor
    wallbash["wallbash_atfx1"] = neutral_override
    wallbash["wallbash_atbx1"] = primary
    wallbash["wallbash_itfx1"] = neutral_override
    wallbash["wallbash_itbx1"] = primary
    wallbash["wallbash_apx1"] = accents[0] if accents else text
    wallbash["wallbash_appx1"] = primary
    wallbash["wallbash_bbx1"] = accents[1] if len(accents)>1 else text

    # color slots
    for i,c in enumerate([primary]+accents,1):
        val = c
        # For normally grayish Pywal slots, apply neutral_override
        if i in [7,15]:
            val = neutral_override
        wallbash[f"wallbash_pry{i}"] = val

    return wallbash

# ---------------- Write conf -----------------
def write_wallbash_conf(wallbash, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path,"w") as f:
        for k,v in wallbash.items():
            f.write(f"{k}={v}\n")
    print(f"Wallbash Pywal hybrid theme written to {path}")

# ---------------- Main -----------------
def main():
    home = os.path.expanduser("~")
    theme_dcol = os.path.join(home,".config/main/wallbash/theme.dcol")
    output_conf = os.path.join(home,".config/wallbash/templates/theme.conf")

    modules = parse_theme_dcol(theme_dcol)
    if not modules:
        print("No modules found, aborting")
        return

    best_module = pick_best_module(modules)
    wallbash = generate_wallbash_keys(best_module)
    write_wallbash_conf(wallbash, output_conf)

if __name__=="__main__":
    main()




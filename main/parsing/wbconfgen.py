#!/usr/bin/env python3
"""
wbconfgen.py
Produce multiple independent color groups from a wallpaper using perceptual (CIELAB) clustering.

Outputs:
  ~/.config/main/wallbash/theme.dcol   (hex values)
  ~/.config/main/wallbash/colors.dcol  (rgba with $ prefix)

Each module block is written as:
{color_wbgenconf_modules.N}
... key=value lines ...

Odd modules use dot-style keys (wallbash.pry1_primary) and even modules use underscore-style (wallbash_pry2_primary)
"""
import argparse, os, sys
import numpy as np
import cv2
from sklearn.cluster import KMeans
from math import sqrt
from multiprocessing import Pool

# ---------------- helpers ----------------
def rgb_to_hex(rgb):
    return "#{:02X}{:02X}{:02X}".format(*[int(round(x)) for x in rgb])

def rgba_str(rgb):
    r,g,b = [int(round(x)) for x in rgb]
    return f"rgba({r},{g},{b},1.0)"


def lab_from_rgb_uint8(rgb_arr):
    # rgb_arr shape (H,W,3) uint8 RGB
    lab = cv2.cvtColor(rgb_arr, cv2.COLOR_RGB2LAB).astype(np.float32)
    L = lab[...,0] * (100.0/255.0)
    a = lab[...,1] - 128.0
    b = lab[...,2] - 128.0
    out = np.stack([L,a,b], axis=-1)
    return out.reshape(-1,3)

def rgb_from_lab_array(lab_arr):
    # lab_arr Nx3 L*0..100 a* b*
    lab = np.empty_like(lab_arr, dtype=np.float32)
    lab[:,0] = lab_arr[:,0] * (255.0/100.0)
    lab[:,1] = lab_arr[:,1] + 128.0
    lab[:,2] = lab_arr[:,2] + 128.0
    lab_img = lab.reshape(1,-1,3).astype(np.uint8)
    rgb = cv2.cvtColor(lab_img, cv2.COLOR_LAB2RGB).reshape(-1,3)
    rgb = np.clip(rgb, 0, 255).astype(float)
    return rgb

def chroma(lab):
    return np.sqrt(lab[:,1]**2 + lab[:,2]**2)

def delta_e(a,b):
    return np.linalg.norm(np.array(a)-np.array(b))

def srgb_to_linear_val(c):
    c = c/255.0
    return c/12.92 if c <= 0.04045 else ((c+0.055)/1.055)**2.4

def rel_luminance(rgb):
    r,g,b = rgb
    lr = srgb_to_linear_val(r)
    lg = srgb_to_linear_val(g)
    lb = srgb_to_linear_val(b)
    return 0.2126*lr + 0.7152*lg + 0.0722*lb

def contrast_ratio_rgb(a,b):
    A,B = rel_luminance(a), rel_luminance(b)
    hi,lo = max(A,B), min(A,B)
    return (hi+0.05)/(lo+0.05)

# ---------------- core pipeline ----------------
def extract_candidates(img_path, sample_pixels=40000, k_global=256, min_L=2.0, max_L=98.0, min_chroma=6.0, seed=42):
    img = cv2.imread(img_path, cv2.IMREAD_COLOR)
    if img is None:
        raise SystemExit(f"Cannot read image: {img_path}")
    img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    H,W = img.shape[:2]
    maxdim = 1200
    if max(H,W) > maxdim:
        scale = maxdim / float(max(H,W))
        img = cv2.resize(img, (int(W*scale), int(H*scale)), interpolation=cv2.INTER_AREA)

    lab_all = lab_from_rgb_uint8(img.astype(np.uint8))   # (N,3)
    L = lab_all[:,0]
    c = chroma(lab_all)
    mask = (L >= min_L) & (L <= max_L)
    if min_chroma is not None:
        mask &= (c >= min_chroma)
    pts = lab_all[mask]
    if pts.shape[0] == 0:
        pts = lab_all.copy()

    # subsample
    rng = np.random.RandomState(seed)
    n = pts.shape[0]
    if n > sample_pixels:
        idx = rng.choice(n, size=sample_pixels, replace=False)
        pts_sample = pts[idx]
    else:
        pts_sample = pts

    # run KMeans globally to produce many candidate centroids
    k = min(k_global, max(1, int(pts_sample.shape[0] / 100)))  # safeguard
    km = KMeans(n_clusters=k, n_init=8, random_state=seed)
    km.fit(pts_sample)
    centers = km.cluster_centers_

    # assign all filtered pts to centers to compute prominence
    from sklearn.metrics import pairwise_distances_argmin_min
    labels, _ = pairwise_distances_argmin_min(pts, centers)
    counts = np.bincount(labels, minlength=centers.shape[0]).astype(float)
    centers_chroma = chroma(centers)
    scores = counts * (1.0 + centers_chroma)   # weight chroma

    rgb_centers = rgb_from_lab_array(centers)
    centroids = []
    for i, labc in enumerate(centers):
        centroids.append({
            "lab": labc,
            "rgb": rgb_centers[i],
            "hex": rgb_to_hex(rgb_centers[i]),
            "count": int(counts[i]) if i < len(counts) else 0,
            "chroma": float(centers_chroma[i]),
            "score": float(scores[i]) if i < len(scores) else 0.0,
            "lum": float(labc[0])
        })
    # sort by score descending
    centroids.sort(key=lambda x: x["score"], reverse=True)
    return centroids

def partition_centroids_to_groups(centroids_lab, num_groups, seed=42):
    # centroids_lab: Nx3 array in Lab
    # cluster centroids themselves into num_groups using KMeans in Lab
    if len(centroids_lab) < num_groups:
        # trivial: some groups will be empty; return simple mapping
        labels = np.arange(len(centroids_lab)) % num_groups
        return labels
    km = KMeans(n_clusters=num_groups, n_init=8, random_state=seed)
    km.fit(centroids_lab)
    return km.labels_

def pick_group_palette(centroids, labels_for_group, args):
    # centroids: full list dicts, labels_for_group gives indices included
    group_cands = [centroids[i] for i in np.where(labels_for_group)[0]] if isinstance(labels_for_group, np.ndarray) else \
                  [c for i,c in enumerate(centroids) if labels_for_group[i]]
    # but labels_for_group in my usage will be boolean mask. We'll call with mask.
    # Sort candidates by score desc
    group_cands.sort(key=lambda x: x["score"], reverse=True)
    # dedupe within group by deltaE
    dedup = []
    for c in group_cands:
        if all(delta_e(c["lab"], d["lab"]) > args.dedupe_deltaE for d in dedup):
            dedup.append(c)
    candidates = dedup if dedup else group_cands

    # pick primary: prefer mid-dark range
    prim = None
    for c in candidates:
        if args.primary_minL <= c["lum"] <= args.primary_maxL:
            prim = c
            break
    if prim is None:
        prim = candidates[0] if candidates else {"rgb": (0,0,0), "hex":"#000000", "lab": np.array([0,0,0])}

    # pick text: white/black if contrast ok else highest contrast
    white = (255,255,255); black=(0,0,0)
    if contrast_ratio_rgb(white, prim["rgb"]) >= args.text_contrast_threshold:
        txt = {"rgb": white, "hex":"#FFFFFF"}
    elif contrast_ratio_rgb(black, prim["rgb"]) >= args.text_contrast_threshold:
        txt = {"rgb": black, "hex":"#000000"}
    else:
        best = max(candidates, key=lambda x: contrast_ratio_rgb(x["rgb"], prim["rgb"]))
        txt = {"rgb": best["rgb"], "hex": best["hex"]}

    # accents: top N distinct by deltaE not equal to prim/txt
    accents = []
    for c in candidates:
        if c["hex"] == prim["hex"] or c["hex"] == txt["hex"]:
            continue
        if len(accents) >= args.num_accents:
            break
        if all(delta_e(c["lab"], a["lab"]) > args.accents_dedupe_deltaE for a in accents):
            accents.append(c)
    # pad if needed
    i_fallback = 0
    while len(accents) < args.num_accents:
        if i_fallback < len(group_cands):
            cand = group_cands[i_fallback]
            i_fallback += 1
            if cand["hex"] in [prim["hex"], txt["hex"]] or cand["hex"] in [a["hex"] for a in accents]:
                continue
            accents.append(cand)
        else:
            accents.append({"rgb": (0,0,0), "hex":"#000000", "lab": np.array([0,0,0])})
    # return structured
    return prim, txt, accents

def process_group(args_tuple):
    # Callable for multiprocessing Pool.
    (group_index, centroids, labels, args) = args_tuple
    # labels indicates group assignment array (len centroids)
    mask = (labels == group_index)
    prim, txt, accents = pick_group_palette(centroids, mask, args)
    # Build module block strings
    m = group_index + 1
    dot_style = (m % 2) == 1
    theme_lines = []
    colors_lines = []
    theme_lines.append(f"{{color_wbgenconf_modules.{m}}}")
    colors_lines.append(f"{{color_wbgenconf_modules.{m}}}")
    if dot_style:
        theme_lines.append(f"wallbash.pry{m}_primary={prim['hex']}")
        theme_lines.append(f"wallbash.txt{m}_text={txt['hex']}")
    else:
        theme_lines.append(f"wallbash_pry{m}_primary={prim['hex']}")
        theme_lines.append(f"wallbash_txt{m}_text={txt['hex']}")
    for idx,a in enumerate(accents, start=1):
        if dot_style:
            theme_lines.append(f"wallbash.{m}xa{idx}_accent={a['hex']}")
        else:
            theme_lines.append(f"wallbash_{m}xa{idx}_accent={a['hex']}")
    # colors (rgba) with $ prefix
    if dot_style:
        colors_lines.append(f"$wallbash.pry{m}_primary={rgba_str(prim['rgb'])}")
        colors_lines.append(f"$wallbash.txt{m}_text={rgba_str(txt['rgb'])}")
    else:
        colors_lines.append(f"$wallbash_pry{m}_primary={rgba_str(prim['rgb'])}")
        colors_lines.append(f"$wallbash_txt{m}_text={rgba_str(txt['rgb'])}")
    for idx,a in enumerate(accents, start=1):
        if dot_style:
            colors_lines.append(f"$wallbash.{m}xa{idx}_accent={rgba_str(a['rgb'])}")
        else:
            colors_lines.append(f"$wallbash_{m}xa{idx}_accent={rgba_str(a['rgb'])}")

    return (group_index, theme_lines, colors_lines, prim, txt, accents)

# ---------------- CLI & runner ----------------
def main():
    p = argparse.ArgumentParser(description="Generate independent color groups (CIELAB + KMeans)")
    p.add_argument("image", help="wallpaper path")
    p.add_argument("--outdir", default=os.path.expanduser("~/.config/main/wallbash"), help="output dir")
    p.add_argument("--groups", type=int, default=4, help="number of independent groups")
    p.add_argument("--accents", type=int, default=9, help="accents per group")
    p.add_argument("--k_global", type=int, default=256, help="global candidate clusters (higher->more variety)")
    p.add_argument("--sample", type=int, default=40000, help="pixel sample for candidate extraction")
    p.add_argument("--min_L", type=float, default=2.0)
    p.add_argument("--max_L", type=float, default=98.0)
    p.add_argument("--min_chroma", type=float, default=6.0)
    p.add_argument("--dedupe_deltaE", type=float, default=8.0)
    p.add_argument("--accents_dedupe_deltaE", type=float, default=12.0)
    p.add_argument("--primary_minL", type=float, default=6.0)
    p.add_argument("--primary_maxL", type=float, default=60.0)
    p.add_argument("--text_contrast_threshold", type=float, default=4.5)
    p.add_argument("--seed", type=int, default=42)
    p.add_argument("--workers", type=int, default=4)
    args = p.parse_args()

    os.makedirs(args.outdir, exist_ok=True)
    # Step 1: extract many candidate centroids (global)
    centroids = extract_candidates(
        args.image,
        sample_pixels=args.sample,
        k_global=args.k_global,
        min_L=args.min_L,
        max_L=args.max_L,
        min_chroma=args.min_chroma,
        seed=args.seed
    )
    if len(centroids) == 0:
        raise SystemExit("No centroids extracted")

    labs = np.array([c["lab"] for c in centroids])
    # partition centroid set into groups (so groups are independent)
    labels = partition_centroids_to_groups(labs, args.groups, seed=args.seed)

    # Prepare args for parallel per-group processing
    for_g = []
    for gi in range(args.groups):
        for_g.append((gi, centroids, labels, argparse.Namespace(
            dedupe_deltaE=args.dedupe_deltaE,
            accents_dedupe_deltaE=args.accents_dedupe_deltaE,
            primary_minL=args.primary_minL,
            primary_maxL=args.primary_maxL,
            text_contrast_threshold=args.text_contrast_threshold,
            num_accents=args.accents
        )))

    with Pool(processes=min(args.workers, args.groups)) as pool:
        results = pool.map(process_group, for_g)

    # sort by group_index and write final files atomically
    results.sort(key=lambda x: x[0])
    theme_tmp = os.path.join(args.outdir, "theme.dcol.tmp")
    colors_tmp = os.path.join(args.outdir, "colors.dcol.tmp")
    with open(theme_tmp, "w") as th, open(colors_tmp, "w") as co:
        for (_, theme_lines, colors_lines, prim, txt, accents) in results:
            for L in theme_lines:
                th.write(L + "\n")
            th.write("\n")
            for L in colors_lines:
                co.write(L + "\n")
            co.write("\n")
    # move into place atomically
    theme_final = os.path.join(args.outdir, "theme.dcol")
    colors_final = os.path.join(args.outdir, "colors.dcol")
    os.replace(theme_tmp, theme_final)
    os.replace(colors_tmp, colors_final)

    print(f"Wrote {theme_final} and {colors_final}")
    # short diagnostics
    for (gi, theme_lines, colors_lines, prim, txt, accents) in results:
        print(f"[group {gi+1}] primary={prim['hex']} text={txt['hex']} accents={[a['hex'] for a in accents[:3]]}...")

if __name__ == "__main__":
    main()


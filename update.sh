#!/bin/zsh
# Usage: ./update.sh [deb ...]
# Copies the given debs into repo/debs/, keeps only the newest version of each
# package and architecture, then rebuilds Packages and Release.
set -euo pipefail
debs=("${@:A}")
cd "${0:A:h}/repo"

for deb in "${debs[@]}"; do
	pkg=$(dpkg-deb -f "$deb" Package)
	arch=$(dpkg-deb -f "$deb" Architecture)
	for old in debs/${pkg}_*_${arch}.deb(N); do
		rm -f -- "$old"
	done
	cp -- "$deb" debs/
done

# The rootless builds have never run on a device, so their Description says so.
# A package with icons/<id>.png (at the site root, outside repo/) gets an Icon pointing there, replacing the deb's own.
icons=(../icons/*.png(N:t:r))
dpkg-scanpackages -m debs /dev/null 2>/dev/null | awk -v icons="${icons[*]}" '
BEGIN {
	RS = ""; ORS = "\n\n"
	split(icons, list, " ")
	for (k in list) hasfile[list[k]] = 1
}
{
	n = split($0, line, "\n")
	rootless = 0; pkg = ""; icon = 0
	for (i = 1; i <= n; i++) {
		if (line[i] == "Architecture: iphoneos-arm64") rootless = 1
		if (line[i] ~ /^Package: /) pkg = substr(line[i], 10)
		if (line[i] ~ /^Icon:/) icon = i
	}
	if (pkg in hasfile) {
		url = "Icon: https://cysxl.github.io/icons/" pkg ".png"
		if (icon) line[icon] = url; else line[++n] = url
	}
	out = ""; indesc = 0
	for (i = 1; i <= n; i++) {
		if (indesc && line[i] !~ /^ /) { out = out " Rootless build, not yet tested.\n"; indesc = 0 }
		out = out line[i] "\n"
		if (rootless && line[i] ~ /^Description:/) indesc = 1
	}
	if (indesc) out = out " Rootless build, not yet tested.\n"
	printf "%s\n", out
}' > Packages

# A package with changelogs/<id>.md gets a Sileo native depiction, which replaces Sileo's whole
# page body, so it carries the Description as the Details tab beside the Changelog tab.
# One file per architecture, since the rootless Description differs.
rm -rf depictions
python3 -I - <<'EOF'
import json, os, re

def changelog(path):
    views, body = [], []
    def flush():
        if body:
            views.append({"class": "DepictionMarkdownView", "markdown": "\n".join(body).strip()})
            body.clear()
    for line in open(path, encoding="utf-8"):
        m = re.match(r"## (.+)", line)
        if m:
            flush()
            views.append({"class": "DepictionHeaderView", "title": m.group(1).strip()})
        else:
            body.append(line.rstrip("\n"))
    flush()
    return views

def details(desc):
    lines = [desc[0]] + [l[1:] if l != " ." else "" for l in desc[1:]]
    out = ""
    for l in lines:
        if out:
            out += "\n" if l.startswith("* ") and out.split("\n")[-1].startswith("* ") else "\n\n"
        out += l
    return out

stanzas = open("Packages", encoding="utf-8").read().strip().split("\n\n")
out = []
for s in stanzas:
    lines = s.split("\n")
    field = {l.split(": ", 1)[0]: l.split(": ", 1)[1] for l in lines if not l.startswith(" ") and ": " in l}
    pkg, arch = field["Package"], field["Architecture"]
    src = f"../changelogs/{pkg}.md"
    if os.path.exists(src):
        i = next(n for n, l in enumerate(lines) if l.startswith("Description: "))
        j = i + 1
        while j < len(lines) and lines[j].startswith(" "):
            j += 1
        desc = [lines[i][len("Description: "):]] + lines[i + 1:j]
        name = pkg + (".rootless" if arch == "iphoneos-arm64" else "") + ".json"
        depiction = {
            "minVersion": "0.1",
            "class": "DepictionTabView",
            "tabs": [
                {"tabname": "Details", "class": "DepictionStackView",
                 "views": [{"class": "DepictionMarkdownView", "markdown": details(desc)}]},
                {"tabname": "Changelog", "class": "DepictionStackView", "views": changelog(src)},
            ],
        }
        os.makedirs("depictions", exist_ok=True)
        with open(f"depictions/{name}", "w", encoding="utf-8") as f:
            json.dump(depiction, f, ensure_ascii=False, indent=1)
            f.write("\n")
        lines.append(f"SileoDepiction: https://cysxl.github.io/repo/depictions/{name}")
    out.append("\n".join(lines))
open("Packages", "w", encoding="utf-8").write("\n\n".join(out) + "\n\n")
EOF
rm -f Packages.gz Packages.bz2 Packages.xz Packages.zst
gzip -9kn Packages
bzip2 -9k Packages
xz -9k Packages
zstd -19q Packages -o Packages.zst

{
	cat <<'EOF'
Origin: CySxL's Repo
Label: CySxL's Repo
Suite: stable
Version: 1.0
Codename: ios
Architectures: iphoneos-arm64 iphoneos-arm64e
Components: main
Description: Some coding practices, including original tweaks, rewritten and maintained forks.
EOF
	for algo in MD5Sum:md5 SHA256:sha256; do
		echo "${algo%%:*}:"
		for f in Packages Packages.gz Packages.bz2 Packages.xz Packages.zst; do
			sum=$(openssl dgst -"${algo##*:}" -r "$f" | cut -d' ' -f1)
			echo " $sum $(stat -f %z "$f") $f"
		done
	done
} > Release

# The source URL serves the root landing page, with paths resolved from the site root.
sed '/^<meta name="viewport"/a\
<base href="../">
' ../index.html > index.html

grep -c '^Package:' Packages | xargs printf '%s packages indexed\n'

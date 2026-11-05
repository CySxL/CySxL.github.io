#!/bin/zsh
# Usage: ./update.sh [deb ...]
# Copies the given debs into debs/, keeps only the newest version of each
# package and architecture, then rebuilds Packages and Release.
set -euo pipefail
debs=("${@:A}")
cd "${0:A:h}"

for deb in "${debs[@]}"; do
	pkg=$(dpkg-deb -f "$deb" Package)
	arch=$(dpkg-deb -f "$deb" Architecture)
	for old in debs/${pkg}_*_${arch}.deb(N); do
		rm -f -- "$old"
	done
	cp -- "$deb" debs/
done

dpkg-scanpackages -m debs /dev/null > Packages 2>/dev/null
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

grep -c '^Package:' Packages | xargs printf '%s packages indexed\n'

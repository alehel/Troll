#!/usr/bin/env bash
# Records the scripted trailer (tests/trailer.gd) with Godot's Movie Maker mode
# and encodes it to MP4.
#
#   tools/make_trailer.sh [output.mp4]
#
# Needs: a Godot 4 binary on PATH as `godot`, ffmpeg (or `pip install imageio-ffmpeg`),
# and a display (use xvfb-run on a headless machine).
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-trailer.mp4}"
FRAMES="$(mktemp -d)"
FFMPEG="${FFMPEG:-$(command -v ffmpeg || python3 -c 'import imageio_ffmpeg; print(imageio_ffmpeg.get_ffmpeg_exe())')}"

godot --headless --path . --import >/dev/null 2>&1 || true # make sure assets are imported
godot --path . --resolution 1280x720 --write-movie "$FRAMES/frame.png" --fixed-fps 30 -- --trailer

"$FFMPEG" -y -framerate 30 -i "$FRAMES/frame%08d.png" -i "$FRAMES/frame.wav" \
	-vf "scale=1280:720:flags=neighbor,format=yuv420p" \
	-c:v libx264 -preset slow -crf 20 -tune animation \
	-c:a aac -b:a 160k -shortest -movflags +faststart "$OUT"
rm -rf "$FRAMES"
echo "Wrote $OUT"

#!/usr/bin/env bash
# 重建保守档字表：通用规范汉字一级+二级 + 拉丁/常用标点

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
CHARSET_DIR="$ROOT/charset"
OUT_TEXT="$CHARSET_DIR/charset-6500.txt"
OUT_LIST="$CHARSET_DIR/charset-6500-list.txt"

python3 - "$CHARSET_DIR" "$OUT_TEXT" "$OUT_LIST" <<'PY'
import sys
from pathlib import Path

charset_dir = Path(sys.argv[1])
out_text = Path(sys.argv[2])
out_list = Path(sys.argv[3])

chars = []
seen = set()
for name in ("level-1.txt", "level-2.txt"):
    path = charset_dir / name
    if not path.exists():
        raise SystemExit(f"缺少字表文件: {path}")
    for line in path.read_text(encoding="utf-8").splitlines():
        ch = line.strip()
        if not ch:
            continue
        if ch not in seen:
            seen.add(ch)
            chars.append(ch)

extra = (
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    " ,.!?;:'\"`~@#$%^&*()-_=+[]{}\\|<>/"
    "，。！？、；：“”‘’（）【】《》〈〉—…·￥％＋－＝"
)
for ch in extra:
    if ch not in seen:
        seen.add(ch)
        chars.append(ch)

out_list.write_text("\n".join(chars) + "\n", encoding="utf-8")
out_text.write_text("".join(chars), encoding="utf-8")
print(f"已生成 {out_text.name} / {out_list.name}")
print(f"唯一字符数: {len(chars)}（其中一二级汉字应为 6500）")
PY

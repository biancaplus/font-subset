#!/usr/bin/env bash
# 合并通用字表（6500）与指定站点的站点用字表
# 输出到 charset-site/<SITE>/charset-merged.txt（及 list）

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

usage() {
  cat <<EOF
用法:
  SITE=<站点名> bash merge-charset.sh

将 charset/charset-6500.txt 与 charset-site/<SITE>/charset-site.txt 去重合并，
生成:
  charset-site/<SITE>/charset-merged.txt
  charset-site/<SITE>/charset-merged-list.txt

示例:
  SITE=site1 bash merge-charset.sh
  SITE=site1 CHARSET=merged bash subset.sh
EOF
}

SITE="${SITE:-}"
if [[ -z "$SITE" ]]; then
  echo "错误: 必须指定 SITE（站点目录名）"
  echo
  usage
  exit 1
fi

if [[ ! "$SITE" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "错误: SITE 含非法字符: $SITE（仅允许字母、数字、._-）"
  exit 1
fi

COMMON_FILE="${COMMON_FILE:-$ROOT/charset/charset-6500.txt}"
SITE_DIR="$ROOT/charset-site/$SITE"
SITE_FILE="${SITE_FILE:-$SITE_DIR/charset-site.txt}"
OUT_TEXT="$SITE_DIR/charset-merged.txt"
OUT_LIST="$SITE_DIR/charset-merged-list.txt"

if [[ ! -f "$COMMON_FILE" ]]; then
  echo "通用字表不存在: $COMMON_FILE"
  echo "可先运行: bash \"$ROOT/build-charset.sh\""
  exit 1
fi

if [[ ! -f "$SITE_FILE" ]]; then
  echo "站点用字表不存在: $SITE_FILE"
  echo "请先将扫描得到的站点用字表 charset-site.txt 放到: $SITE_DIR/"
  exit 1
fi

mkdir -p "$SITE_DIR"

python3 - "$COMMON_FILE" "$SITE_FILE" "$OUT_TEXT" "$OUT_LIST" <<'PY'
import sys
from pathlib import Path

common_file = Path(sys.argv[1])
site_file = Path(sys.argv[2])
out_text = Path(sys.argv[3])
out_list = Path(sys.argv[4])

chars = []
seen = set()
for path in (common_file, site_file):
    for ch in path.read_text(encoding="utf-8"):
        if ch in "\n\r\t":
            continue
        if ch not in seen:
            seen.add(ch)
            chars.append(ch)

out_text.write_text("".join(chars), encoding="utf-8")
out_list.write_text("\n".join(chars) + "\n", encoding="utf-8")
print(f"已生成 {out_text}")
print(f"已生成 {out_list}")
print(f"合并唯一字符数: {len(chars)}")
PY

echo
echo "下一步可用:"
echo "  SITE=$SITE CHARSET=merged bash \"$ROOT/subset.sh\""

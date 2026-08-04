#!/usr/bin/env bash
# 字体子集化脚本（保守档：通用规范汉字一二级 6500 + 拉丁/标点）
# 用法见同目录 README.md

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
CHARSET_FILE="${CHARSET_FILE:-$ROOT/charset/charset-6500.txt}"
SOURCE_DIR="${SOURCE_DIR:-$ROOT/source}"
OUTPUT_DIR="${OUTPUT_DIR:-$ROOT/output}"

mkdir -p "$SOURCE_DIR" "$OUTPUT_DIR"

# 优先使用本目录 .venv 中的 pyftsubset（目录改名后也不依赖全局 PATH）
if [[ -x "$ROOT/.venv/bin/pyftsubset" ]]; then
  PYFTSUBSET="$ROOT/.venv/bin/pyftsubset"
elif command -v pyftsubset >/dev/null 2>&1; then
  PYFTSUBSET="$(command -v pyftsubset)"
else
  echo "未找到 pyftsubset。请在本目录重建虚拟环境并安装依赖："
  echo "  cd \"$ROOT\""
  echo "  python3 -m venv .venv"
  echo "  source .venv/bin/activate"
  echo "  pip install -r requirements.txt"
  exit 1
fi

if [[ ! -f "$CHARSET_FILE" ]]; then
  # 相对路径时，按脚本所在目录解析
  if [[ "$CHARSET_FILE" != /* && -f "$ROOT/$CHARSET_FILE" ]]; then
    CHARSET_FILE="$ROOT/$CHARSET_FILE"
  else
    echo "字表不存在: $CHARSET_FILE"
    echo "可先运行: bash \"$ROOT/build-charset.sh\""
    exit 1
  fi
fi

shopt -s nullglob
inputs=()
for src in "$SOURCE_DIR"/*; do
  [[ -f "$src" ]] || continue
  ext="${src##*.}"
  ext_lc="$(printf '%s' "$ext" | tr 'A-Z' 'a-z')"
  case "$ext_lc" in
    ttf|otf|ttc|woff|woff2) inputs+=("$src") ;;
  esac
done
if [[ ${#inputs[@]} -eq 0 ]]; then
  echo "source/ 下没有字体文件。"
  echo "请将待子集化的源字体放到: $SOURCE_DIR"
  echo "例如: SourceHanSansSC-Regular.otf / SourceHanSansSC-Medium.otf"
  exit 1
fi

echo "字表: $CHARSET_FILE"
echo "输入目录: $SOURCE_DIR"
echo "输出目录: $OUTPUT_DIR"
echo

for src in "${inputs[@]}"; do
  base="$(basename "$src")"
  name="${base%.*}"
  ext="${src##*.}"
  ext_lc="$(printf '%s' "$ext" | tr 'A-Z' 'a-z')"
  extra_args=()
  if [[ "$ext_lc" == "ttc" ]]; then
    extra_args+=(--font-number="${FONT_NUMBER:-0}")
  fi

  out="$OUTPUT_DIR/${name}.subset.woff2"
  echo "→ 子集化: $base"
  "$PYFTSUBSET" "$src" \
    --text-file="$CHARSET_FILE" \
    --output-file="$out" \
    --flavor=woff2 \
    --layout-features='*' \
    --glyph-names \
    --symbol-cmap \
    --legacy-cmap \
    --notdef-glyph \
    --notdef-outline \
    --recommended-glyphs \
    --name-IDs='*' \
    --name-legacy \
    --name-languages='*' \
    "${extra_args[@]}"

  src_size=$(wc -c <"$src" | tr -d ' ')
  out_size=$(wc -c <"$out" | tr -d ' ')
  echo "  完成: $out"
  echo "  体积: ${src_size} → ${out_size} bytes"
  echo
done

echo "全部完成。请检查 $OUTPUT_DIR"

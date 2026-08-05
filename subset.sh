#!/usr/bin/env bash
# 按站点做字体子集化
# 用法见同目录 README.md

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

# 打印用法说明
usage() {
  cat <<EOF
用法:
  SITE=<站点名> [CHARSET=6500|site|merged] bash subset.sh

环境变量:
  SITE           必填。站点目录名，如 site1、site2
  CHARSET        可选。字表类型：6500（默认，通用）| site（站点用字）| merged（通用∪站点）
  CHARSET_FILE   可选。直接指定字表路径（覆盖 CHARSET）
  FONT_NUMBER    可选。ttc 字体序号，默认 0
  SOURCE_DIR     可选。覆盖默认 source/<SITE>
  OUTPUT_DIR     可选。覆盖默认 output/<SITE>

路径约定:
  源字体:     source/<SITE>/
  输出字体:   output/<SITE>/
  通用字表:   charset/charset-6500.txt
  站点用字:   charset-site/<SITE>/charset-site.txt
  合并字表:   charset-site/<SITE>/charset-merged.txt

使用示例命令:
  # 通用字表 → output/site1/
  SITE=site1 bash subset.sh
  # 仅站点用字
  SITE=site1 CHARSET=site bash subset.sh
  # 通用 ∪ 站点
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

SOURCE_DIR="${SOURCE_DIR:-$ROOT/source/$SITE}"
OUTPUT_DIR="${OUTPUT_DIR:-$ROOT/output/$SITE}"
CHARSET_MODE=""

# 解析字表：CHARSET_FILE 优先，否则按 CHARSET 模式映射到约定路径
if [[ -z "${CHARSET_FILE:-}" ]]; then
  CHARSET_MODE="${CHARSET:-6500}"
  case "$CHARSET_MODE" in
    6500|common|generic)
      CHARSET_FILE="$ROOT/charset/charset-6500.txt"
      ;;
    site)
      CHARSET_FILE="$ROOT/charset-site/$SITE/charset-site.txt"
      ;;
    merged)
      CHARSET_FILE="$ROOT/charset-site/$SITE/charset-merged.txt"
      ;;
    *)
      echo "未知 CHARSET: $CHARSET_MODE（可用 6500|site|merged）"
      exit 1
      ;;
  esac
fi

mkdir -p "$SOURCE_DIR" "$OUTPUT_DIR"

# 优先使用本目录 .venv 中的 pyftsubset
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
    if [[ "$CHARSET_MODE" == "6500" || "$CHARSET_MODE" == "common" || "$CHARSET_MODE" == "generic" ]]; then
      echo "可先运行: bash \"$ROOT/build-charset.sh\""
    elif [[ "$CHARSET_MODE" == "site" ]]; then
      echo "请将站点扫描得到的 charset-site.txt 放到: $ROOT/charset-site/$SITE/"
    elif [[ "$CHARSET_MODE" == "merged" ]]; then
      echo "可先运行: SITE=$SITE bash \"$ROOT/merge-charset.sh\""
    fi
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
  echo "source/$SITE/ 下没有字体文件。"
  echo "请将待子集化的源字体放到: $SOURCE_DIR"
  echo "例如: SourceHanSansSC-Regular.otf / SourceHanSansSC-Medium.otf"
  exit 1
fi

echo "站点: $SITE"
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

# 字体子集化（多站点）

本目录用于把完整中文字体按 **「通用规范汉字一二级 6500 + 拉丁/标点」** 或 **「站点用字」** 做字体子集。  
**输出格式默认与源字体一致**（`otf→.subset.otf`、`woff2→.subset.woff2` 等）；站点线上常用 woff2，可把源字体放在 `source/` 为 `.woff2`，或用 `OUTPUT_FORMAT=woff2` 从 otf/ttf 转出。  
支持按站点隔离：源字体、站点字表、输出产物都落在各自站点目录。

## 目录说明

```text
font-subset/
  charset/                         # 通用字表（入库）
    level-1.txt / level-2.txt / level-3.txt
    charset-6500.txt               # 合并后的通用字表（给 pyftsubset）
    charset-6500-list.txt          # 每行一字，方便查看
  charset-site/                    # 站点用字（不入库）
    <SITE>/
      charset-site.txt             # 自行扫描的站点全站用字
      charset-site-list.txt
      charset-merged.txt           # merge-charset.sh 生成：6500 ∪ 站点用字
      charset-merged-list.txt
  source/                          # 源字体（不入库）
    <SITE>/                        # 如 source/site1/*.otf
  output/                          # 子集产物（不入库）
    <SITE>/                        # 如 output/site1/*.subset.otf / *.subset.woff2
  build-charset.sh                 # 重建通用 charset-6500
  merge-charset.sh                 # 合并 6500 + 站点用字 → charset-merged
  subset.sh                        # 按站点子集化
  requirements.txt
```

`<SITE>` 为站点标识，例如：`site1`、`site2`。

## 字表来源

- 标准：[国务院公布《通用规范汉字表》](https://www.gov.cn/zhengce/zhengceku/2013-08/19/content_1289.htm)
- 文本转写：[shengdoushi/common-standard-chinese-characters-table](https://github.com/shengdoushi/common-standard-chinese-characters-table)
- 通用档：`charset/` 内 **一级 ∪ 二级 = 6500 字**，再加拉丁字母数字与常用中英文标点
- 站点档：自行扫描站点全站文字（不限 WordPress / Next.js 等任何站点），放入 `charset-site/<SITE>/`

## 使用步骤

### 0. Python 环境（WSL）

```bash
sudo apt update
sudo apt install -y python3-pip python3-venv
```

### 1. 安装依赖

```bash
cd font-subset

python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install -r requirements.txt
```

若目录曾改名导致旧 `.venv` 失效，删掉重建即可：

```bash
rm -rf .venv
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

`subset.sh` 会优先使用本目录 `.venv/bin/pyftsubset`。

### 2.（可选）重建通用字表

```bash
bash build-charset.sh
```

### 3. 准备站点目录与源字体

```bash
SITE=site1   # 换成你的站点名

mkdir -p "source/$SITE" "output/$SITE" "charset-site/$SITE"

# 拷贝源字体到对应站点目录
cp /path/to/SourceHanSansSC-Regular.otf "source/$SITE/"
cp /path/to/SourceHanSansSC-Medium.otf "source/$SITE/"
```

推荐使用可商用开源字体（如思源黑体 / Noto Sans SC）。PingFang 有授权风险，确认有权再处理。

### 4. 执行子集化（必须指定 SITE）

输出始终写入 `output/<SITE>/`，与用哪套字表无关。

```bash
# A. 仅用通用 6500 字表（默认）
SITE=site1 bash subset.sh

# B. 仅用站点用字表
# 先把扫描得到的 charset-site.txt / charset-site-list.txt
# 放到 charset-site/site1/
SITE=site1 CHARSET=site bash subset.sh

# C. 通用 ∪ 站点用字（推荐补漏）
SITE=site1 bash merge-charset.sh
SITE=site1 CHARSET=merged bash subset.sh
```

`.ttc` 合集可指定字体序号（默认 0）；子集结果为**单个**字体文件（默认 `.subset.otf`）：

```bash
SITE=site1 FONT_NUMBER=0 bash subset.sh
SITE=site1 TTC_OUTPUT_EXT=woff2 bash subset.sh
```

强制指定输出格式（覆盖「随源扩展名」）：

```bash
# 源为 otf，但产出 woff2 供线上使用
SITE=site1 OUTPUT_FORMAT=woff2 bash subset.sh
```

也可直接指定字表文件：

```bash
SITE=site1 CHARSET_FILE=charset/charset-6500.txt bash subset.sh
```

### 5. 取用产物

在 `output/<SITE>/` 查看 `*.subset.*`，替换该站点主题 `assets/fonts/` 与 OSS 字体，并同步改 `@font-face` / preload（`format()` 与扩展名一致）。

### 输出格式对照

| 源格式   | 默认子集输出                           | pyftsubset                      |
| -------- | -------------------------------------- | ------------------------------- |
| `.ttf`   | `.subset.ttf`                          | 无 `--flavor`                   |
| `.otf`   | `.subset.otf`                          | 无 `--flavor`                   |
| `.woff`  | `.subset.woff`                         | `--flavor=woff`                 |
| `.woff2` | `.subset.woff2`                        | `--flavor=woff2`（需 `brotli`） |
| `.ttc`   | `.subset.otf`（可调 `TTC_OUTPUT_EXT`） | 单字体抽出，非 ttc 合集         |

任意源格式均可通过 `OUTPUT_FORMAT=woff2` 等强制转成目标格式。

## 多站点示例

```bash
# 站点 A：通用字表
SITE=site1 bash subset.sh

# 站点 B：合并字表
SITE=site2 bash merge-charset.sh
SITE=site2 CHARSET=merged bash subset.sh
```

对应目录：

```text
source/site1/ ...          output/site1/ ...
source/site2/ ...            output/site2/ ...
charset-site/site1/ ...
charset-site/site2/ ...
```

## 注意

- 必须设置 `SITE`，脚本不会再读写根目录下扁平的 `source/` / `output/` 文件。
- `charset/` 只放通用字表；站点扫描结果放 `charset-site/<SITE>/`，且默认不进 git。
- 本脚本只做本地文件处理，不会自动改 WordPress 或上传 OSS。
- 表外汉字会回退到 `font-family` 后面的系统字体，一般可接受。
- 产出 `woff2` 时需安装 `brotli`（见 `requirements.txt`）；仅 `ttf/otf` 子集可不装 brotli。

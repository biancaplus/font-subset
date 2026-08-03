# 字体子集化（保守档）

本目录用于把完整中文字体按「通用规范汉字一二级 6500 + 拉丁/标点」做成 woff2 子集。

## 目录说明

```text
font/
  charset/
    level-1.txt              # 一级字 3500（来自《通用规范汉字表》转写）
    level-2.txt              # 二级字 3000
    level-3.txt              # 三级字 1605（保守档默认不用，需要时可并入）
    charset-6500.txt         # 合并后的字表（给 pyftsubset --text-file）
    charset-6500-list.txt    # 每行一字，方便人工查看
  source/                    # 放入待子集化的源字体（otf/ttf/ttc/woff2）
  output/                    # 脚本输出 *.subset.woff2
  build-charset.sh           # 重建 charset-6500
  subset.sh                  # 调用 fonttools 子集化
  requirements.txt
```

## 字表来源

- 标准：[国务院公布《通用规范汉字表》](https://www.gov.cn/zhengce/zhengceku/2013-08/19/content_1289.htm)
- 文本转写：[shengdoushi/common-standard-chinese-characters-table](https://github.com/shengdoushi/common-standard-chinese-characters-table)
- 保守档使用：**一级 ∪ 二级 = 6500 字**，再加拉丁字母数字与常用中英文标点

## 使用步骤

0. 在 WSL 终端执行的话需要确保有python环境
   在 WSL 终端执行：

```bash
sudo apt update
sudo apt install -y python3-pip python3-venv
```

1. 安装依赖

```bash
cd font

python3 -m venv .venv
source .venv/bin/activate

python3 -m pip install -r requirements.txt
```

2. （可选）重建字表

```bash
bash build-charset.sh
```

3. 把源字体放进 `source/`

推荐使用可商用开源字体（如思源黑体 / Noto Sans SC），再子集。  
PingFang 存在授权风险，确认有权再处理。

```bash
# 拷贝示例，字体文件已放好可以忽略
cp /path/to/SourceHanSansSC-Regular.otf source/
cp /path/to/SourceHanSansSC-Medium.otf source/
```

4. 执行子集化

```bash
bash subset.sh
```

若源文件是 `.ttc` 合集，可用环境变量指定字体序号（默认 0）：

```bash
FONT_NUMBER=0 bash subset.sh
```

5. 在 `output/` 查看 `*.subset.woff2`，替换主题 `assets/fonts/` 与 OSS 字体，并同步改 `@font-face` / preload。

## 注意

- 本脚本只做本地文件处理，不会自动改 WordPress 或上传 OSS。
- 表外汉字会回退到 `font-family` 后面的系统字体，一般可接受。
- 若以后要「6500 ∪ 站点用字」，把额外字符追加进字表后再跑 `subset.sh` 即可。

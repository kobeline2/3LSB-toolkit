# 3LSB-toolkit

ダムに固定した定点シングルビーム（3LSB）の記録を読み込み・可視化する MATLAB ツール群。

3LSB は毎秒の水深を `.log` に記録する。データをもらうたびに、サイトを選んで
[`main3LSB.m`](main3LSB.m) を実行すれば、読込 →（必要なら水位補正）→ 時系列プロットまで走る。
サイトごとの違いは [`src/siteConfig.m`](src/siteConfig.m) に集約してある。

## 使い方

1. MATLAB で本フォルダを開く。
2. [`main3LSB.m`](main3LSB.m) の先頭 `site = "..."` を対象サイトに変える。
3. 実行（セクション単位の実行も可）。

```matlab
init                  % src 以下をパスに追加（main3LSB の先頭で自動実行）
site = "oi";          % "oi" | "koshibu" | "raja" | "ngoiphat"
cfg  = siteConfig(site);
TT   = readLogFolder(cfg.logDir);     % 毎秒の水深 timetable（Value_m, SourceFile）
```

## サイト

| site キー | ダム | 水位補正 | 備考 |
|---|---|---|---|
| `oi` | 大井ダム | **あり** | 浮きの上に設置のため水位で補正（`sediment = wl - 水深`） |
| `koshibu` | 小渋ダム | なし | |
| `raja` | Rajamandala | なし | |
| `ngoiphat` | NgoiPhat | なし | 新規。データ配置後にフォルダ名を確認 |

サイト間の違いは基本的に「水位補正の要否」だけ。`.log` の形式は全サイト共通。
SEGY ウォーターカラムは全ダムへ展開予定のため、全サイト共通機能として扱う。

### サイトを追加するには
[`src/siteConfig.m`](src/siteConfig.m) の `switch` に `case` を1つ足すだけ。
`name` / `root` / `logDir` /（あれば）`segyDir` /`needsWaterLevel` を設定する。

## ディレクトリ構成

```
main3LSB.m            メインドライバ（site を選んで実行）
init.m                addpath(genpath('src'))
src/
  siteConfig.m        サイト設定（パス・水位補正の要否）
  readLogFile.m       .log を1ファイル読む（全サイト共通フォーマット）
  readLogFolder.m     フォルダ内 .log を再帰的に全読込 → timetable
  plotTimeSeries.m    時系列散布図
  ooi/                大井ダム専用（水位補正）
    applyWaterLevel.m   分データ ooi_min*.csv の水位で補正、sediment 列を付与
    readOoiMinuteCsv.m  ooi_min*.csv（水位・雨量・流入出・発電放流）を読む
    parseOoiWaterLevel.m  ooi_diary*.csv（毎時水位）を読む ※現状パイプライン未接続
  segy/               ウォーターカラム（SEGY）
    read3LSBSegy.m      SEGY を読む（little-endian / ASCII ヘッダ前提、EBCDIC 未対応）
    plotWaterColumn.m   SEGY 断面を表示
```

## データの場所

実データ（`.log`, `.csv`, `.sgy`, `.mat` など）は GitHub に入れず、Dropbox 共有
`data_shared/`（gitignore 済み）に置く。パスは [`src/siteConfig.m`](src/siteConfig.m) の
`dataRoot` で一元管理。期待する配置例（大井ダム）:

```
data_shared/ooi/
  log/   *.log              毎秒の水深
  sgy/   *.sgy              ウォーターカラム
  wl/    ooi_min*.csv       分データ（水位ほか）
  wl/hourly/ ooi_diary*.csv 日報の毎時水位
```

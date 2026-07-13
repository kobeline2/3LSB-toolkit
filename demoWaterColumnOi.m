%% demoWaterColumnOi — 大井ダム ウォーターカラムの表示パターン集
%  オプションが増えて分かりにくいので, 代表的な描き方を1か所にまとめた.
%  MATLAB エディタで %% セルごとに実行できる. 各パターンは独立した図を出す.
%
%  ── 2軸で整理 ──
%   [強度の出し方]  ＝ opts で切替
%     (A) 生 dB           : struct('rangeComp',false)     装置の生記録(未補償)
%     (B) 距離補償 相対Sv : 既定 / struct('rangeComp',true) 2TLを補償. 滑らかな曲線=ノイズ床(検出限界)
%     (C) 補償+ノイズ減算 : struct('subtractNoise',true)   清水を暗く濁度を浮かせる(ABS標準)
%     (D) 補償+SNRマスク  : struct('snrMask',6)            濃度=絶対値のまま, 低SNRを空白化(実務の定番)
%   [縦軸]  ＝ waterLevelDir で切替
%     (1) センサ深度      : waterLevelDir = ''(空)
%     (2) 絶対標高        : waterLevelDir = cfg.waterLevelDir   ※大井のみ(水位補正)
%
%  鉄則: 渡すのは必ず「生振幅」. 補償後の dB を再投入しない(=二重補償, x0 が変な値になる).

init
cfg      = siteConfig('oi');
saveFigs = false;                                  % true で PNG 保存
figDir   = fullfile(cfg.root, 'figs');

%% 対象ファイルと前処理（1回だけ実行すればよい）
f = dir(fullfile(cfg.segyDir, '*.sgy'));
[~, im] = max([f.bytes]);                          % 最大ファイル=中身のある収録
fn = fullfile(f(im).folder, f(im).name);
fprintf('対象: %s (%.1f MB)\n', f(im).name, f(im).bytes/1e6);

[data, depth, dt_us, ~, tt] = read3LSBSegy(fn);
[data, tt] = burstReduce(data, tt, 'trimmedRMS');  % 濁度向け. 'median' で画像/底ピック向き
wlNone = '';
wlElev = cfg.waterLevelDir;
figs   = gobjects(0);

%% (A1) 生 dB × 深度 ── 装置がそのまま記録した値（未補償）
figs(end+1) = plotWaterColumn(data, depth, dt_us, tt, wlNone, struct('rangeComp',false));

%% (B1) 距離補償 相対Sv × 深度 ── 既定. 滑らかな曲線がノイズ床（=検出限界）
figs(end+1) = plotWaterColumn(data, depth, dt_us, tt, wlNone, struct('rangeComp',true));

%% (C1) 補償+ノイズ減算 × 深度 ── 清水が暗くなり濁度が浮く
figs(end+1) = plotWaterColumn(data, depth, dt_us, tt, wlNone, struct('subtractNoise',true));

%% (B2) 距離補償 相対Sv × 絶対標高 ── 大井の本番ビュー
figs(end+1) = plotWaterColumn(data, depth, dt_us, tt, wlElev, struct('rangeComp',true));

%% (C2) 補償+ノイズ減算 × 絶対標高 ── 濁度を見るならこれ
figs(end+1) = plotWaterColumn(data, depth, dt_us, tt, wlElev, struct('subtractNoise',true));

%% (D2) 補償+SNRマスク × 絶対標高 ── バランス型(実務の定番). 検出限界以下は空白(淡色)
%   明るさ=濃度(距離補償済)を保ちつつ, SNR<閾値 の画素を伏せる.
%   閾値 snrMask は調整可: 大きいほど厳しく(大井の清水: 6→90%, 9→97%, 12→99% マスク).
figs(end+1) = plotWaterColumn(data, depth, dt_us, tt, wlElev, struct('snrMask',6));

%% 保存（任意）── saveFigs=true にして実行
if saveFigs
    if ~exist(figDir, 'dir'), mkdir(figDir); end
    names = {'A1_rawdB_depth','B1_relSv_depth','C1_noiseSub_depth', ...
             'B2_relSv_elev','C2_noiseSub_elev','D2_masked_elev'};
    for i = 1:numel(figs)
        print(figs(i), fullfile(figDir, names{i}), '-dpng', '-r150');
    end
    fprintf('保存先: %s\n', figDir);
end

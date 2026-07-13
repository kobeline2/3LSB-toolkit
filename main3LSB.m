%% main3LSB — 3LSB 定点シングルビームの読込・補正・可視化ドライバ
%  サイトを選んで、上から順に（またはセクションごとに）実行する。
%  サイト固有の設定は src/siteConfig.m に集約。

init                              % src 以下をパスに追加

%% 設定：サイトを選ぶ
site = "oi";                      % "oi" | "koshibu" | "raja" | "ngoiphat"
cfg  = siteConfig(site);
fprintf("サイト: %s\n", cfg.name);

%% 毎秒の水深を全読込（フォルダ内 .log を再帰的に）
TT = readLogFolder(cfg.logDir);
fprintf("読込: %d 行\n", height(TT));

%% 大井ダムのみ：水位で補正して堆積層厚 sediment を計算
if cfg.needsWaterLevel
    TT   = applyWaterLevel(TT, cfg.waterLevelDir);
    yvar = "sediment"; reverseY = false;
else
    yvar = "Value_m";  reverseY = true;
end

%% 保存（任意）
save(cfg.mergedMat, "TT");

%% 時系列プロット
plotTimeSeries(TT, yvar, reverseY);
% xlim([datetime(2026,4,1) datetime(2026,5,1)])   % 必要に応じて範囲指定
% print(gcf, fullfile(cfg.root,"ts.png"), "-dpng", "-r600")

%% ウォーターカラム(SEGY)を1枚見る（必要時にコメント解除）
% f = dir(fullfile(cfg.segyDir, '*.sgy'));
% if cfg.needsWaterLevel
%     plotWaterColumn(fullfile(f(end).folder, f(end).name), cfg.waterLevelDir);  % 絶対標高
% else
%     plotWaterColumn(fullfile(f(end).folder, f(end).name));                     % センサー相対深度
% end

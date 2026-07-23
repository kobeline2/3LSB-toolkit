function cfg = siteConfig(site)
%SITECONFIG サイトごとの設定（パス・水位補正の要否）を返す。
%   cfg = siteConfig("oi")
%   サイトを増やすときは、ここに case を1つ足すだけ。
%
%   差分はほぼ「水位補正の要否(needsWaterLevel)」だけ。
%   大井ダム(oi)は浮きの上に設置しているため水位データで補正が必要。
%   SEGY（ウォーターカラム）は全ダムに展開予定なので、全サイトに segyDir を持たせる。

    % data_shared は Dropbox 共有（gitignore 済み）。配置を変えたらここを直す。
    dataRoot = "/Users/takahiro/Library/CloudStorage/Dropbox/git_ignored/3LSB-toolkit/data_shared";

    switch lower(string(site))
        case "oi"        % 大井ダム: 浮き設置 → 水位補正あり
            cfg.name          = "大井ダム";
            cfg.root          = fullfile(dataRoot, "ooi");
            cfg.logDir        = fullfile(cfg.root, "log");
            cfg.segyDir       = fullfile(cfg.root, "sgy");
            cfg.needsWaterLevel = true;
            cfg.waterLevelDir = fullfile(cfg.root, "wl");   % ooi_min*.csv の場所

        case "koshibu"   % 小渋ダム
            cfg.name          = "小渋ダム";
            cfg.root          = fullfile(dataRoot, "koshibu");
            cfg.logDir        = cfg.root;
            cfg.segyDir       = fullfile(cfg.root, "sgy");
            cfg.needsWaterLevel = false;

        case "raja"      % Rajamandala ダム（固定設置. 2026-07 から SEGY あり）
            cfg.name          = "Rajamandala";
            cfg.root          = fullfile(dataRoot, "raja");
            cfg.logDir        = cfg.root;
            cfg.segyDir       = fullfile(cfg.root, "sgy");
            cfg.needsWaterLevel = false;
            % 2026-07-23 回収分は装置時計が1日遅れ（現地確認）→ +1日補正.
            % range は装置時刻. 次回回収でも遅れが残っていれば range を伸ばす/行を足す.
            cfg.clockShifts = struct( ...
                'range', [datetime(2026,6,9) datetime(2026,7,23)], ...
                'shift', days(1));

        case "ngoiphat"  % NgoiPhat ダム（データ配置後にフォルダ名を確認）
            cfg.name          = "NgoiPhat";
            cfg.root          = fullfile(dataRoot, "ngoiphat");
            cfg.logDir        = cfg.root;
            cfg.segyDir       = fullfile(cfg.root, "sgy");
            cfg.needsWaterLevel = false;

        otherwise
            error("siteConfig:unknownSite", "未知のサイト: %s", site);
    end

    if ~isfield(cfg, 'clockShifts'), cfg.clockShifts = []; end   % 既定: 時計補正なし

    cfg.site      = lower(string(site));
    cfg.mergedMat = fullfile(cfg.root, "merged_timeseries.mat");
end

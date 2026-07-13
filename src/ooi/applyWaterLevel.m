function TT = applyWaterLevel(TT, waterLevelDir)
%APPLYWATERLEVEL 大井ダム用：水位データで補正し、堆積層厚 sediment 列を加える。
%   TT = applyWaterLevel(TT, cfg.waterLevelDir)
%
%   大井ダムは浮きの上に設置しているため、毎秒の水深 Value_m そのままでは
%   水位変動の影響を受ける。提供される分データ ooi_min*.csv の水位 wl を使い
%       sediment = wl - Value_m
%   として堆積層の厚みを得る。あわせて雨量・流入出・発電放流も TT に同期する。
%
%   注: 毎時の日報 ooi_diary*.csv（parseOoiWaterLevel）は現状この計算には未使用。

    % --- 分データ（水位 wl, 雨量 rain, 流入 Qin, 放流 Qout, 発電放流 Qhp2）を連結 ---
    minFiles = dir(fullfile(waterLevelDir, "ooi_min*.csv"));
    if isempty(minFiles)
        error("applyWaterLevel:noCsv", "ooi_min*.csv が見つかりません: %s", waterLevelDir);
    end

    TThydro = [];
    for i = 1:numel(minFiles)
        tmp     = readOoiMinuteCsv(fullfile(minFiles(i).folder, minFiles(i).name));
        TThydro = [TThydro; tmp]; %#ok<AGROW>
    end
    TThydro = sortrows(unique(TThydro));

    % --- 毎秒の TT と同期し、分→秒の欠損を線形内挿 ---
    TT = synchronize(TT, TThydro);
    sp = TT.Properties.RowTimes;
    for v = ["wl","Qin","rain","Qout","Qhp2"]
        TT.(v) = fillmissing(TT.(v), 'linear', 'SamplePoints', sp);
    end

    % --- 堆積層厚 = 水位 - 水深 ---
    TT.sediment = TT.wl - TT.Value_m;
end

function fig = plotWaterColumn(fnOrData, arg2, dt_us, traceTimes, waterLevelDir, opts)
%PLOTWATERCOLUMN SEGY のウォーターカラム断面を表示する. 
%
%   既定では距離補償した「相対 体積後方散乱 Sv [dB]」を表示する
%   (本機はリニア・STCなしで記録するため,  2TL を解析側で足し戻す: rangeCompensate). 
%   生(未補償)の dB を見たいときは opts.rangeComp=false. 
%
%   ファイル名モード（後方互換）:
%     plotWaterColumn(fn)
%     plotWaterColumn(fn, waterLevelDir)
%     plotWaterColumn(fn, opts)
%     plotWaterColumn(fn, waterLevelDir, opts)
%
%   データ渡しモード（burstReduce など前処理後に使う）:
%     plotWaterColumn(data, depth, dt_us, traceTimes)
%     plotWaterColumn(data, depth, dt_us, traceTimes, waterLevelDir)
%     plotWaterColumn(data, depth, dt_us, traceTimes, waterLevelDir, opts)
%
%   opts（任意・構造体）:
%     .rangeComp : 距離補償する(既定 true). false で生 dB. 
%     .bg        : 背景 x0（既定 median(data(:))）. rangeCompensate 参照. 
%     .alphaW    : 片道水吸収 [dB/m]（既定 淡水400kHz,10℃）. 
%
%   典型的な使い方:
%     [data, depth, dt_us, ~, traceTimes] = read3LSBSegy(fn);
%     [data, traceTimes] = burstReduce(data, traceTimes);   % 既定 trimmedRMS
%     plotWaterColumn(data, depth, dt_us, traceTimes, cfg.waterLevelDir);

    if nargin < 6, opts = struct(); end
    % 末尾の構造体引数を opts として拾う（ファイル名モードで dt_us が上書きされる前に）
    if nargin >= 2 && isstruct(arg2),  opts = arg2;  end
    if nargin >= 3 && isstruct(dt_us), opts = dt_us; end

    if ischar(fnOrData) || isstring(fnOrData)
        % --- ファイル名モード ---
        fn = char(fnOrData);
        [data, depth, dt_us, ~, traceTimes] = read3LSBSegy(fn);
        [~, label] = fileparts(fn);
        wlDir = '';
        if nargin >= 2 && ~isempty(arg2) && ~isstruct(arg2), wlDir = char(arg2); end
    else
        % --- データ渡しモード ---
        data   = fnOrData;
        depth  = arg2;
        label  = '';
        wlDir  = '';
        if nargin >= 5 && ~isempty(waterLevelDir), wlDir = char(waterLevelDir); end
    end

    % --- dB 化（既定は距離補償した相対 Sv,  opts.rangeComp=false で生 dB）---
    if isfield(opts, 'rangeComp') && ~opts.rangeComp
        dB        = 20 * log10(max(data, 1e-6));
        cbLabel   = 'dB';
        profLabel = 'Mean echo [dB]';
        compTag   = '';
        climPct   = [5 95];
    else
        bgv = []; awv = []; subN = false; snrM = [];
        if isfield(opts, 'bg'),            bgv  = opts.bg;            end
        if isfield(opts, 'alphaW'),        awv  = opts.alphaW;        end
        if isfield(opts, 'subtractNoise'), subN = opts.subtractNoise; end
        if isfield(opts, 'snrMask'),       snrM = opts.snrMask;       end
        [dB, ci]  = rangeCompensate(data, depth, bgv, awv, subN, snrM);
        if ~isempty(snrM)
            cbLabel   = 'Rel. S_v [dB] (SNR-masked)';
            profLabel = 'Mean rel. S_v [dB]';
            compTag   = sprintf(' [rangeComp, mask SNR<%g dB (%.0f%%), x_0=%.2f]', ...
                                snrM, 100*ci.maskedFrac, ci.x0);
            climPct   = [25 99];
        elseif subN
            cbLabel   = 'Rel. S_v (noise-sub) [dB]';
            profLabel = 'Mean [dB]';
            compTag   = sprintf(' [rangeComp+noiseSub x_0=%.2f]', ci.x0);
            climPct   = [60 99.5];
        else
            cbLabel   = 'Rel. S_v [dB]';
            profLabel = 'Mean rel. S_v [dB]';
            compTag   = sprintf(' [rangeComp x_0=%.2f \\alpha_w=%.3f]', ci.x0, ci.alphaW);
            climPct   = [50 99];
        end
    end

    if ~isempty(wlDir)
        wlInterp = interpolateWaterLevel(traceTimes, wlDir);
        [plotData, yGrid, yLabel] = remapToAbsoluteElev(dB, depth, dt_us, wlInterp);
        titleSuffix = ' [絶対標高]';
        yDir = 'normal';      % 標高は上ほど高い → 水面=上, 湖底=下
    else
        plotData    = dB;
        yGrid       = depth;
        yLabel      = 'Depth from sensor (m)';
        titleSuffix = '';
        yDir = 'reverse';     % 深度は下ほど深い → 水面=上, 湖底=下
    end

    fig = figure('Visible', get(0,'DefaultFigureVisible'), 'Position', [0 0 1400 600]);

    ax1 = subplot(1, 3, [1 2]);
    imh = imagesc(traceTimes, yGrid, plotData);
    set(gca, 'YDir', yDir);
    xlabel('Time'); ylabel(yLabel);
    title(['Subbottom profile  ' label titleSuffix compTag]);
    colormap(ax1, gray);
    cb = colorbar; cb.Label.String = cbLabel;
    cl = prctile(plotData(:), climPct);
    if ~(cl(2) > cl(1)), cl = mean(cl, 'omitnan') + [-1 1]; end
    clim(cl);
    if any(isnan(plotData(:)))                 % マスク(NaN)は淡色で空白表示
        set(imh, 'AlphaData', ~isnan(plotData));
        set(ax1, 'Color', [0.85 0.88 0.95]);
    end

    subplot(1, 3, 3);
    plot(mean(plotData, 2, 'omitnan'), yGrid, 'b', 'LineWidth', 1.2);
    set(gca, 'YDir', yDir);
    xlabel(profLabel); ylabel(yLabel);
    title('平均鉛直プロファイル');
    grid on; axis tight;
end

% -----------------------------------------------------------------------
function [dataOut, elevGrid, yLabel] = remapToAbsoluteElev(dB, depth, dt_us, wlInterp)
    dz = dt_us * 1e-6 * 1500 / 2;
    wl_valid = wlInterp(~isnan(wlInterp));
    elev_max = max(wl_valid);
    elev_min = min(wl_valid) - max(depth);
    elevGrid = (elev_max : -dz : elev_min)';

    nTrace  = size(dB, 2);
    dataOut = NaN(numel(elevGrid), nTrace, 'single');
    for i = 1:nTrace
        if isnan(wlInterp(i)), continue; end
        absElev_i = wlInterp(i) - depth;
        dataOut(:, i) = interp1(absElev_i, dB(:, i), elevGrid, 'linear', NaN);
    end
    yLabel = 'Elevation (m, from datum)';
end

% -----------------------------------------------------------------------
function wl = interpolateWaterLevel(traceTimes, waterLevelDir)
    minFiles = dir(fullfile(waterLevelDir, 'ooi_min*.csv'));
    TThydro  = [];
    for i = 1:numel(minFiles)
        tmp     = readOoiMinuteCsv(fullfile(minFiles(i).folder, minFiles(i).name));
        TThydro = [TThydro; tmp]; %#ok<AGROW>
    end
    TThydro = sortrows(unique(TThydro));
    wl = interp1(datenum(TThydro.Properties.RowTimes), TThydro.wl, ...
                 datenum(traceTimes), 'linear', NaN);
end

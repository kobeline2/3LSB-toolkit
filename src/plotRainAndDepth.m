function plotRainAndDepth(TT, rain, yvar, reverseY)
%PLOTRAINANDDEPTH 上段に日雨量, 下段に水深の時系列を, 時間軸をそろえて描く.
%   plotRainAndDepth(TT, rain)                     % 既定: Value_m, 縦軸反転
%   plotRainAndDepth(TT, rain, "sediment", false)  % 大井の堆積層厚など
%
%   rain : rain 列（各時刻の区間雨量 [mm]. 毎時など）を持つ timetable. ここで日合計にする.
%   xlim / ylim / print は用途ごとに対話で触る前提なので, ここには入れない（x は上下連動）.

    if nargin < 3 || strlength(yvar) == 0, yvar = "Value_m"; end
    if nargin < 4, reverseY = true; end

    tl = tiledlayout(3, 1, 'TileSpacing', 'compact');

    ax1 = nexttile(tl, 1);
    daily = retime(rain(:, 'rain'), 'daily', 'sum');
    bar(ax1, daily.Properties.RowTimes, daily.rain, 1, 'FaceColor', [0.3 0.5 0.8], 'EdgeColor', 'none');
    ylabel(ax1, 'rain [mm/day]'); grid(ax1, 'on');

    ax2 = nexttile(tl, 2, [2 1]);
    plotTimeSeries(TT, yvar, reverseY, false);

    linkaxes([ax1 ax2], 'x');
    t = [TT.Properties.RowTimes; daily.Properties.RowTimes];
    xlim(ax2, [min(t) max(t)]);
end

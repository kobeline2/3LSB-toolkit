function plotTimeSeries(TT, yvar, reverseY, byFile)
%PLOTTIMESERIES TT の時系列を散布図で描く。
%   plotTimeSeries(TT)                            % 既定: Value_m, 縦軸反転, ファイル色分け
%   plotTimeSeries(TT, "sediment", false)         % 堆積層厚など
%   plotTimeSeries(TT, "Value_m",  true,  false)  % 単色（ファイル色分けなし）
%
%   xlim / ylim / print は用途ごとに対話で触る前提なので、ここには入れない。

    if nargin < 2 || strlength(yvar) == 0, yvar = "Value_m"; end
    if nargin < 3, reverseY = true; end
    if nargin < 4, byFile   = true; end

    x = TT.Properties.RowTimes;
    y = TT.(char(yvar));

    if byFile
        gscatter(x, y, categorical(TT.SourceFile));
        legend('off')   % 由来ファイルが多いと凡例が邪魔なので既定で消す
    else
        plot(x, y, '.', 'MarkerSize', 3, 'Color', [0 0.3 0.7]);
    end

    ax = gca;
    if reverseY, ax.YDir = 'reverse'; end
    axis tight
    grid on
    xlabel('time')
    ylabel('depth [m]')
end

%% %%%%%%%%%%%%%%%%  Dairy %%%%%%%%%%%%%%%%  
% 1. 既存の timetable を読み込む（例）
% load('your_TT.mat')   % 既に変数 TT が存在するならこの行は不要

% 2. CSVデータを読み込み
% ファイル一覧（必要に応じてパスを調整）
files = [
    "~/Dropbox/localcode/read3LSB/dat/ooi/rain/ooi_diary202507.csv"
    "~/Dropbox/localcode/read3LSB/dat/ooi/rain/ooi_diary202508.csv"
    "~/Dropbox/localcode/read3LSB/dat/ooi/rain/ooi_diary202509.csv"
];

TTw_all = timetable();  % 空のtimetableを用意

for i = 1:numel(files)
    fprintf("Reading %s ...\n", files(i));
    TTw_month = parse_ooi_waterlevel(files(i));  % ← 先ほどの関数を呼ぶ
    TTw_all = [TTw_all; TTw_month];              % 縦方向に連結
end

% タイムスタンプ順にソート
TTw_all = sortrows(TTw_all);

% 重複を除く（同じ時刻が再掲されていた場合）
TTw_all = unique(TTw_all);



%% %%%%%%%%%%%%%%%%  minute %%%%%%%%%%%%%%%% 

% ファイル名
fnList = {'~/Dropbox/localcode/read3LSB/dat/ooi/hydro/ooi_min202507.csv'...
          '~/Dropbox/localcode/read3LSB/dat/ooi/hydro/ooi_min202508.csv'...
          '~/Dropbox/localcode/read3LSB/dat/ooi/hydro/ooi_min202509.csv'};
TThydro = [];
for I = 1:3
    tmp = readOoiMinuteCsv(fnList{I});
    TThydro = [TThydro; tmp];
end




%% 5. 既存のTTと結合
TT = synchronize(TT, TThydro);

% 同期方式を指定したい場合はたとえば：
% TT = synchronize(TT, T_water, 'union', 'nearest');  % 時間が微妙にズレる場合

% 1. WaterLevel_m を補間する
% NaNを線形内挿
TT.wl = fillmissing(TT.wl, 'linear', 'SamplePoints', TT.allDT);
TT.Qin = fillmissing(TT.Qin, 'linear', 'SamplePoints', TT.allDT);
TT.rain = fillmissing(TT.rain, 'linear', 'SamplePoints', TT.allDT);
TT.Qout = fillmissing(TT.Qout, 'linear', 'SamplePoints', TT.allDT);
TT.Qhp2 = fillmissing(TT.Qhp2, 'linear', 'SamplePoints', TT.allDT);
TT.sediment = TT.wl - TT.Value_m;

%% plot
interval = 100;
x = TT.allDT(1:interval:end);
y = TT.sediment(1:interval:end);
% scatter(x, y, 1, 'filled', 'MarkerFaceAlpha', 0.1)
gscatter(x, y, categorical(TT.SourceFile(1:interval:end)));
xlim([datetime(2025, 7, 25), datetime(2025, 10, 15)])
% ylim([0, 12])
ax = gca;
% ax.YDir = 'reverse';
fig = gcf;
% setFig(fig, 18, 6, 9, 'T')
xlabel('time')
ylabel('depth [m]')
% print(gcf, '~/Desktop/raja_ts_pruned_2020509.png', '-dpng', '-r600');
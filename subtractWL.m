%% %%%%%%%%%%%%%%%%  Dairy %%%%%%%%%%%%%%%%  
% 1. 既存の timetable を読み込む（例）
% load('your_TT.mat')   % 既に変数 TT が存在するならこの行は不要
config = readyaml("config.yaml");
rootFolder = config.dirWl;  
% 2. CSVデータを読み込み
% ファイル一覧\
files = dir(fullfile(rootFolder, '*.csv'));
if isempty(files)
    error('ログファイルが見つかりませんでした: %s', rootFolder);
end

% TTw_all = timetable();  % 空のtimetableを用意
% 
% for i = 1:numel(files)
%     fn = files(i).folder;
%     fprintf("Reading %s ...\n", fn);
%     TTw_month = parse_ooi_waterlevel(fn);  % ← 先ほどの関数を呼ぶ
%     TTw_all = [TTw_all; TTw_month];              % 縦方向に連結
% end
% 
% % タイムスタンプ順にソート
% TTw_all = sortrows(TTw_all);
% 
% % 重複を除く（同じ時刻が再掲されていた場合）
% TTw_all = unique(TTw_all);
% 
% 

%% %%%%%%%%%%%%%%%%  minute %%%%%%%%%%%%%%%% 

TThydro = [];
for I = 1:numel(files)
    fn = fullfile(files(I).folder, files(I).name);
    tmp = readOoiMinuteCsv(fn);
    TThydro = [TThydro; tmp];
end
TThydro = sortrows(TThydro);
TThydro = unique(TThydro);



%% 5. 既存のTTと結合
TT = synchronize(TT, TThydro);

% 同期方式を指定したい場合はたとえば：
% TT = synchronize(TT, T_water, 'union', 'nearest');  % 時間が微妙にズレる場合

% 1. WaterLevel_m を補間する
% % if hourly 
% TT.WaterLevel_m = fillmissing(TT.WaterLevel_m, 'linear', 'SamplePoints', TT.allDT);
% TT.sediment = TT.WaterLevel_m - TT.Value_m;
% if mitutely
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
% xlim([datetime(2025, 7, 25), datetime(2025, 10, 15)])
% ylim([0, 12])
ax = gca;
% ax.YDir = 'reverse';
fig = gcf;
% setFig(fig, 18, 6, 9, 'T')
xlabel('time')
ylabel('depth [m]')
% print(gcf, '~/Desktop/raja_ts_pruned_2020509.png', '-dpng', '-r600');
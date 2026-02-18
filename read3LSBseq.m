%% available at least for Ooi, Raja
%% 設定
config = readyaml("config.yaml");
rootFolder = config.dirLog;  
outputMAT  = fullfile(rootFolder, "merged_timeseries.mat"); 

%% .logファイルを再帰的に探索
files = dir(fullfile(rootFolder, '**', '*.log'));
if isempty(files)
    error('ログファイルが見つかりませんでした: %s', rootFolder);
end

allDT  = datetime.empty(0,1);  % 全ファイルの時刻を格納
allVal = [];                   % 値（m）
allSrc = strings(0,1);         % どのファイル起源か（任意）

%% 各ファイルを読み込み
for k = 1:numel(files)
    fn = fullfile(files(k).folder, files(k).name);
    [dt, val, src] = read3LSBRaja(fn);
    % --- 全体に追加
    allDT  = [allDT ; dt];
    allVal = [allVal ; val];
    allSrc = [allSrc ; src];
end

%% 連結した時系列を timetable に
TT = timetable(allDT, allVal, allSrc, 'VariableNames', {'Value_m','SourceFile'});

% 時刻ソート
TT = sortrows(TT);

% （任意）重複時刻があれば平均などで集約したい場合は以下を有効化：
% TT = retime(TT, 'regular', @mean, 'TimeStep', seconds(1));  % 1秒刻みで平均
% もしくは：TT = retime(TT, 'daily', @mean); 等

%% 確認
disp(TT(1:min(5,height(TT)), :));
disp(TT(max(1,height(TT)-4):height(TT), :));

%% 保存（任意）
save(outputMAT, 'TT');
fprintf('連結時系列を %s に保存しました（行数: %d）\n', outputMAT, height(TT));

%% plot
interval = 100;
x = TT.allDT(1:interval:end);
y = 0-TT.Value_m(1:interval:end);
% scatter(x, y, 1, 'filled', 'MarkerFaceAlpha', 0.1)
gscatter(x, y, categorical(TT.SourceFile(1:interval:end)));
xlim([datetime(2025, 9, 1), datetime(2026, 3, 1)])
% ylim([-15, 0])
ax = gca;
% ax.YDir = 'reverse';
fig = gcf;
% setFig(fig, 18, 6, 9, 'T')
xlabel('time')
ylabel('depth [m]')
% print(gcf, '~/Desktop/raja_ts_pruned_2020509.png', '-dpng', '-r600');

%% plot interval
% 期間（10/20〜10/30）で抽出
t1 = datetime(2025,10,21,0,0,0);
t2 = datetime(2025,11,2 ,23,59,59);

TTsub = TT(timerange(t1, t2, "closed"), :);

% scatterプロット（timetableならそのまま渡せる）
figure
scatter(TTsub.allDT, 0-TTsub.Value_m, 1, 'filled')   % 6は点サイズ
grid on
xlabel('DateTime')
ylabel('Value\_m')
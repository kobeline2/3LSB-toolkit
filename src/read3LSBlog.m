% ファイル名を指定
filename = '/Users/koshiba/Dropbox/git/_local/read3LSB/dat_local/2411_koshibu/09_3LSB_241106/20240820132359.log';

% ファイルの内容を読み込む
fid = fopen(filename, 'r');
if fid == -1
    error('ファイルを開けませんでした');
end

% データを格納するための変数の初期化
datetimeArray = [];
valueArray = [];

% ファイルを1行ずつ読み込む
while ~feof(fid)
    line = fgetl(fid);
    if ischar(line)
        % 行をカンマで分割
        parts = strsplit(line, ',');
        
        % 日時の解析
        datetimeStr = strcat(parts{1}, ' ', parts{2});
        datetimeValue = datetime(datetimeStr, 'InputFormat', 'yyyy/MM/dd HH:mm:ss');
        
        % 値の解析
        value = str2double(parts{3});
        
        % データを配列に追加
        datetimeArray = [datetimeArray; datetimeValue]; %#ok<AGROW>
        valueArray = [valueArray; value]; %#ok<AGROW>
    end
end

% ファイルを閉じる
fclose(fid);

% タイムテーブルを作成
tt = timetable(datetimeArray, valueArray, 'VariableNames', {'Value'});

% タイムテーブルを表示
% disp(tt);
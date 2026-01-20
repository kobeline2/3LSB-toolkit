function [dt, val, src] = read3LSBRaja(fn)
    % 初期化（返すべき出力を空に）
    dt  = [];
    val = [];
    src = [];

    % --- ファイル名から基準時刻を取得（yyyyMMddHHmmss.log の最初の14桁）
    [~, fname, ~] = fileparts(fn);
    if numel(fname) < 14 || ~all(isstrprop(fname(1:14), 'digit'))
        warning('スキップ：ファイル名が期待形式でない: %s', fn);
        return;
    end
    tFile = datetime(fname(1:14), 'InputFormat','yyyyMMddHHmmss');

    % --- 読み込み：カンマ区切り、ヘッダなし
    % 形式: "YYYY/MM/DD, HH:MM:SS, 11.190, m"
    opts = delimitedTextImportOptions('Delimiter',',', 'NumVariables',4);
    opts.VariableNames = {'DateStr','TimeStr','Value','Unit'};
    opts.VariableTypes = {'string','string','double','string'};
    opts.ExtraColumnsRule = 'ignore';
    opts.ConsecutiveDelimitersRule = 'split';
    opts.Whitespace = ' ';
    T = readtable(fn, opts);

    if isempty(T) || height(T)==0
        return;
    end

    % 前後空白削除
    T.DateStr = strtrim(T.DateStr);
    T.TimeStr = strtrim(T.TimeStr);
    T.Unit    = strtrim(T.Unit);

    % --- 行の日時を組み立て
    % 通常行：YYYY/MM/DD + HH:MM:SS
    % 例外行：0001/01/01, 00:00:00 はファイル名の時刻 + (行番号-1)秒
    isPlaceholder = (T.DateStr == "0001/01/01") & (T.TimeStr == "00:00:00");

    % まず既知の日時を作成
    dt = NaT(height(T),1);  % タイムゾーン無しの NaT
    if any(~isPlaceholder)
        dt(~isPlaceholder) = datetime( ...
            T.DateStr(~isPlaceholder) + " " + T.TimeStr(~isPlaceholder), ...
            'InputFormat','yyyy/MM/dd HH:mm:ss');
    end

    % プレースホルダ行をファイル名基準で1秒インクリメント
    if any(isPlaceholder)
        idx = find(isPlaceholder);
        % 行順に0,1,2,...秒インクリメント
        dt(idx) = tFile + seconds((0:numel(idx)-1)).';
    end

    % 列方向の形を揃える（列ベクトル化）
    dt  = dt(:);
    val = T.Value(:);           % 数値列
    src = repmat(strcat(string(fname), ".log"), numel(dt), 1);
    
    % ---- 不良行を削除（ここが重要） ----
    % 日時が作れなかった行や値がNaNの行を落とす
    bad = isnat(dt) | isnan(val);
    dt(bad)  = [];
    val(bad) = [];
    src(bad) = [];
    
    % 念のため3者の長さを揃える（理論上一致しているはずだが保険）
    n = min([numel(dt), numel(val), numel(src)]);
    dt  = dt(1:n);
    val = val(1:n);
    src = src(1:n);
end
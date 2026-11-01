function TT = readRajaRainfall(rainDir)
%READRAJARAINFALL Rajamandala の雨量計（ARR Rajamandala）の xlsx を読み, 毎時雨量の timetable を返す.
%   TT = readRajaRainfall(cfg.rainDir)
%   列: rain（毎時雨量 [mm]. 元表の "Synthetic" 列）.
%
%   元表は A:時刻 / B:Raw / C:Synthetic（7行目までヘッダ, 末尾に AVERAGE 行. D 列以降の日集計は使わない）.
%   Raw は転倒ます(0.2 mm/回)の回数で, 2026-04 までは Synthetic = Raw×0.2 が全行で成立する.
%   2026-05 シートは Raw 列だけ各値が2行ずつ重複して時刻もずれているので, Synthetic を正とする.
%   納品は累積型（until Jan, Feb, ...）で月ごとにシートが増えるため全ファイル全シートを読み,
%   同時刻はサイズの大きいファイル（＝新しい納品）の値を採用する.

    files = dir(fullfile(rainDir, '*.xlsx'));
    [~, order] = sort([files.bytes], 'descend');
    files = files(order);

    t = datetime.empty(0,1); mm = [];
    for k = 1:numel(files)
        fn = fullfile(files(k).folder, files(k).name);
        for sh = sheetnames(fn).'
            C = readcell(fn, 'Sheet', sh);
            tk = cellfun(@toDatetime, C(:,1), 'UniformOutput', false);
            tk = vertcat(tk{:});
            ok = ~isnat(tk) & cellfun(@isNum, C(:,3));
            t  = [t;  tk(ok)];                 %#ok<AGROW>
            mm = [mm; cell2mat(C(ok,3))];      %#ok<AGROW>
        end
    end

    [t, ia] = unique(t, 'stable');             % 先に読んだ（大きい）ファイルを優先
    TT = sortrows(timetable(t, mm(ia), 'VariableNames', {'rain'}));
end

function t = toDatetime(x)
    if isdatetime(x)
        t = x;
    elseif (ischar(x) || isstring(x)) && ~isempty(regexp(char(x), '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$', 'once'))
        t = datetime(x, 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
    else
        t = NaT;
    end
end

function tf = isNum(x)
    tf = isnumeric(x) && isscalar(x) && ~isnan(x);
end

function TTw = parse_ooi_waterlevel(csvfile)
% 大井ダムから提供されたのooi_diaryyyyymm.csvを読む. 

    L = readlines(csvfile, 'Encoding','UTF-8');
    L = strtrim(L);
    L = L(L ~= "");

    isDateLine = ~cellfun(@isempty, regexp(L, '^\d{4}/\d{1,2}/\d{1,2},', 'once'));
    dateIdx = find(isDateLine);
    if isempty(dateIdx), error('日付行が見つかりません.'); end

    allDT = datetime.empty(0,1);
    allWL = [];

    for k = 1:numel(dateIdx)
        i0 = dateIdx(k);
        if k < numel(dateIdx), i1 = dateIdx(k+1)-1; else, i1 = numel(L); end

        % ブロックの基準日
        tok = regexp(L(i0), '^(\d{4}/\d{1,2}/\d{1,2}),', 'tokens','once');
        d0  = datetime(tok{1}, 'InputFormat','yyyy/M/d');

        blockLines = L((i0+1):i1);
        isHourHead = ~cellfun(@isempty, regexp(blockLines, '^(?:[0-9]|1[0-9]|2[0-4])\,', 'once'));
        candLines  = blockLines(isHourHead);

        hourV = []; wlevV = [];
        for j = 1:numel(candLines)
            parts = split(candLines(j), ',');
            if numel(parts) >= 2 && all(isstrprop(parts(1), 'digit'))
                h  = str2double(parts(1));
                wl = str2double(parts(2));
                if ~isnan(h) && h>=0 && h<=24 && ~isnan(wl)
                    hourV(end+1,1) = h; %#ok<AGROW>
                    wlevV(end+1,1) = wl; %#ok<AGROW>
                end
            end
        end

        if isempty(hourV), continue; end

        % 24時の重複処理：
        % 1) 先頭の24は当日00:00として採用
        % 2) 末尾の24は原則捨てる（最終ブロックだけ翌日00:00として採用）
        % 時刻と値のペアを並べ直し
        [hourV,ord] = sort(hourV);
        wlevV       = wlevV(ord);

        % 先頭24の位置
        idx24 = find(hourV==24);
        leading24 = false(size(hourV));
        trailing24 = false(size(hourV));
        if ~isempty(idx24)
            % 同一ブロック内に複数の24がある前提（先頭・末尾）
            % 最初の24を先頭, 最後の24を末尾とみなす
            leading24(idx24(1)) = true;
            trailing24(idx24(end)) = true;
            % ただし一個しか24が無いデータでも, その1個を「先頭」とみなす
            if numel(idx24)==1
                trailing24(:) = false;
            end
        end

        % 先頭24 → 当日00:00
        keepMask = (hourV>=1 & hourV<=23) | leading24;

        % 最終ブロックなら末尾24を翌日00:00として追加
        addNextMidnight = (k==numel(dateIdx)) && any(trailing24);

        % 追加分を先に作成
        DT_add = datetime.empty(0,1);
        WL_add = [];
        if addNextMidnight
            wl_last24 = wlevV(trailing24);
            DT_add = (d0 + days(1));   % 翌日00:00
            WL_add = wl_last24;
        end

        % 採用分（先頭24 & 1..23）
        DT_keep = d0 + hours(hourV(keepMask));
        WL_keep = wlevV(keepMask);

        % 連結
        allDT = [allDT; DT_keep; DT_add];
        allWL = [allWL; WL_keep; WL_add];
    end

    % 最後に重複タイムスタンプがあれば最新を残す（保険）
    [allDT, uniqIdx] = unique(allDT, 'stable');
    allWL = allWL(uniqIdx);

    TTw = timetable(allDT, allWL, 'VariableNames', {'WaterLevel_m'});
end
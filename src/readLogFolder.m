function TT = readLogFolder(logDir)
%READLOGFOLDER フォルダ内の *.log を再帰的に読み, 時刻順の timetable を返す。
%   TT = readLogFolder(cfg.logDir)
%   列: Value_m（水深[m]）, SourceFile（由来 .log）。
%   各ファイルの読込は readLogFile に委譲（全サイト共通フォーマット）。

    files = dir(fullfile(logDir, '**', '*.log'));
    if isempty(files)
        error("readLogFolder:noFiles", "ログファイルが見つかりません: %s", logDir);
    end

    % 同名ファイルは最大サイズの1つだけ読む.
    % （納品が累積型で同じログが複数フォルダに重複するため.
    %   ログは追記型なので, 同名なら大きい方が完全版）
    [~, order] = sort([files.bytes], 'descend');
    files = files(order);
    [~, ia] = unique({files.name}, 'stable');
    files = files(ia);

    allDT  = datetime.empty(0,1);
    allVal = [];
    allSrc = strings(0,1);

    for k = 1:numel(files)
        fn = fullfile(files(k).folder, files(k).name);
        [dt, val, src] = readLogFile(fn);
        allDT  = [allDT ; dt];   %#ok<AGROW>
        allVal = [allVal; val];  %#ok<AGROW>
        allSrc = [allSrc; src];  %#ok<AGROW>
    end

    TT = timetable(allDT, allVal, allSrc, 'VariableNames', {'Value_m','SourceFile'});
    TT = sortrows(TT);
end

% x: datetime vector, y,q: double vectors (same length)

T = table(string(x, "yyyy-MM-dd HH:mm:ss"), y(:), q(:), ...
    'VariableNames', {'time', 'y', 'q'});

outFile = fullfile(pwd, 'export.xlsx');
writetable(T, outFile, 'Sheet', 1);
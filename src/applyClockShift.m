function t = applyClockShift(t, clockShifts)
%APPLYCLOCKSHIFT 装置時計のずれを補正した時刻を返す.
%   t = applyClockShift(t, cfg.clockShifts)
%
%   t           : datetime 配列（log の行時刻や SEGY の traceTimes）
%   clockShifts : struct 配列. .range = [t0 t1)（装置時刻）, .shift = duration.
%                 [] なら何もしない. 設定は siteConfig に置く（生データは書き換えない）.

    for k = 1:numel(clockShifts)
        idx = t >= clockShifts(k).range(1) & t < clockShifts(k).range(2);
        t(idx) = t(idx) + clockShifts(k).shift;
    end
end

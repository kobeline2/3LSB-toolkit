function [TT, frozen] = removeFrozen(TT, minDur)
%REMOVEFROZEN 同じ水深値が minDur 以上続く区間（装置の値の固着）を除く.
%   [TT, frozen] = removeFrozen(TT)              % 既定: 6 時間以上同じ値なら固着
%   [TT, frozen] = removeFrozen(TT, hours(3))
%   frozen : 元の TT の各行が固着区間かどうか（論理値）.
%
%   時刻は進むのに値が変わらない故障がある（大井は浮き設置なので, 水位が動いても
%   水深が動かないことで固着と確認済み）. 正常時の同一値の連続は最長でも 3 時間弱.

    if nargin < 2, minDur = hours(6); end

    v = TT.Value_m;
    t = TT.Properties.RowTimes;
    starts = find([true; diff(v) ~= 0]);           % 値が変わった行 = 連の始まり
    ends   = [starts(2:end) - 1; numel(v)];
    bad    = find(t(ends) - t(starts) >= minDur);

    frozen = false(numel(v), 1);
    for k = bad(:).'
        frozen(starts(k):ends(k)) = true;
    end
    TT = TT(~frozen, :);
end

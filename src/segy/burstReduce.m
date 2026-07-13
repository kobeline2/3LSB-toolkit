function [dataOut, burstTimes] = burstReduce(data, traceTimes, method, maxGapMin)
%BURSTREDUCE バースト内のトレースを1本に縮約する（縮約法を選べる）.
%   [dataOut, burstTimes] = burstReduce(data, traceTimes)
%   [dataOut, burstTimes] = burstReduce(data, traceTimes, method)
%   [dataOut, burstTimes] = burstReduce(data, traceTimes, method, maxGapMin)
%
%   data       : [nSamples × nTraces] 生振幅 (read3LSBSegy 出力)
%   traceTimes : [nTraces × 1] datetime
%   method     : 'trimmedRMS'(既定) | 'rms' | 'mean' | 'median'
%   maxGapMin  : バースト区切りと判断する間隔[分]（既定 5）
%   dataOut    : [nSamples × nBursts] 縮約結果（振幅単位）
%   burstTimes : [nBursts × 1] datetime  バースト代表時刻（バースト内平均）
%
%   縮約法の選び方:
%     後方散乱(濁度)の定量では「強度平均」が正しい. 散乱体群のエコー包絡線は
%     右に裾を引く分布で, 強い戻りこそ信号エネルギー. median は外れ値に頑健な
%     反面その高振幅側を捨てるので後方散乱を過小評価する.
%       'trimmedRMS' : 背景を引き, MAD で外れ値(魚/気泡/スパイク)を除いてから
%                      二乗平均平方根(RMS=強度平均). 定量向けの既定.
%       'rms'        : 背景を引いて RMS（外れ値除去なし）.
%       'mean'       : 背景まわりの単純平均.
%       'median'     : 中央値. 外れ値に最も頑健で画像/底ピック向き. 定量は過小評価.
%   ※ いずれも dB化の前(リニア振幅)で縮約する. dB領域で平均してはいけない.
%   ※ 背景(下駄)は median(data) で推定し, 二乗の前に引いて戻す(下駄の二乗化を回避).
%      この後の rangeCompensate が改めて背景差引・距離補償を行う.

    if nargin < 3 || isempty(method),    method    = 'trimmedRMS'; end
    if nargin < 4 || isempty(maxGapMin), maxGapMin = 5;            end
    method = lower(string(method));
    k = 3;                                   % 外れ値除去のしきい値 [×MAD]

    bg = median(double(data(:)), 'omitnan');  % 一定背景(下駄). rangeCompensate と同じ推定

    gaps    = [inf; minutes(diff(traceTimes))];
    groupId = cumsum(gaps > maxGapMin);
    nGroups = max(groupId);

    nSamples   = size(data, 1);
    dataOut    = zeros(nSamples, nGroups, 'single');
    burstTimes = NaT(nGroups, 1);

    for g = 1:nGroups
        idx = groupId == g;
        sub = double(data(:, idx)) - bg;        % 背景を引いて中心化(信号+ノイズ)

        if method == "trimmedrms"               % MAD で外れ値を除去
            m0   = median(sub, 2, 'omitnan');
            mad0 = 1.4826 * median(abs(sub - m0), 2, 'omitnan');
            drop = abs(sub - m0) > k * mad0;
            drop(mad0 == 0, :) = false;         % ばらつき0の行は除去しない
            sub(drop) = NaN;
        end

        switch method
            case "median"
                r = median(sub, 2, 'omitnan');
            case "mean"
                r = mean(sub, 2, 'omitnan');
            case {"rms", "trimmedrms"}
                r = sqrt(mean(sub.^2, 2, 'omitnan'));   % 強度平均 → RMS振幅
            otherwise
                error("burstReduce:method", "未知の method: %s", method);
        end

        dataOut(:, g) = r + bg;                 % 下駄を戻して振幅単位に
        burstTimes(g) = mean(traceTimes(idx));
    end
end

function [dataOut, burstTimes] = burstMedian(data, traceTimes, maxGapMin)
%BURSTMEDIAN バースト中央値合成（後方互換ラッパー）.
%   burstReduce(data, traceTimes, 'median', maxGapMin) を呼ぶ.
%   定量(濁度)用途では burstReduce の 'trimmedRMS'/'rms' を推奨
%   （中央値は後方散乱を過小評価する. burstReduce 参照）.
    if nargin < 3, maxGapMin = 5; end
    [dataOut, burstTimes] = burstReduce(data, traceTimes, 'median', maxGapMin);
end

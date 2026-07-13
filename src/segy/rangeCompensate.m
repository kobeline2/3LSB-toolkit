function [compDB, info] = rangeCompensate(data, depth, bg, alphaW, subtractNoise, snrMaskDb)
%RANGECOMPENSATE 生ウォーターカラム振幅 → 距離補償した相対 体積後方散乱 [dB]. 
%
%   本機(3LSB/PDR-1200W)はリニア・STCなし(=距離補償なし)で記録するため,  
%   記録値には往復伝播損失 2TL(拡散 1/r + 吸収) がそのまま残っている. 
%   解析側で 2TL を足し戻し,  一定背景 x0 を引いて相対 Sv を得る:
%
%       Sv_rel(r) = 20*log10(x(r) - x0) + 20*log10(r) + 2*alphaW*r   [dB]
%                   \__背景を除いた振幅__/  \____ 往復伝播損失 2TL ____/
%
%   SL/G0/k_s を入れていないので絶対値ではなく「相対」. 鉛直濁度分布の
%   比較や「水が綺麗でも濁度がどこまで見えるか(深さ方向の検出限界)」用. 
%   ※低濃度を仮定し堆積物減衰 alphaS は無視(高濃度では §8.3 の反復が要る). 
%
%   [compDB, info] = rangeCompensate(data, depth)
%   [compDB, info] = rangeCompensate(data, depth, bg, alphaW, subtractNoise, snrMaskDb)
%     data   : [nSamples × nTraces] 生振幅 (read3LSBSegy 出力)
%     depth  : [nSamples × 1] センサからの距離 r [m]
%     bg     : 背景 x0. 既定 median(data(:))（平坦な水中背景/ノイズ床）
%     alphaW : 片道の水吸収 [dB/m]. 既定 淡水 400kHz,10℃ ≒0.053
%     subtractNoise : true で ABS標準のノイズ"パワー"減算（既定 false）.
%                     amp=sqrt(max((x-x0)^2 - sigma^2, 0)). 清水が暗くなり,
%                     ノイズ床の下駄が外れて濁度が強調される（検知力は深いほど低下）.
%     snrMaskDb : SNRしきい値[dB]. 指定すると距離補償Sv(ノイズ減算済)を出しつつ,
%                 画素ごとの SNR<snrMaskDb を NaN(空白)にする(=検出限界以下を伏せる).
%                 明るさ=濃度(絶対値)は保ったまま, 信頼できる所だけ表示する実務の定番
%                 (ABS/漁業音響. De Robertis & Higginbottom 2007. 例 3〜6 dB). 既定 [].
%     info   : 使用した x0, alphaW, sigma, subtractNoise, snrMaskDb, maskedFrac を返す構造体

    data = double(data);
    if nargin < 3 || isempty(bg),     bg     = median(data(:), 'omitnan'); end
    if nargin < 4 || isempty(alphaW), alphaW = freshwaterAbsorption(400, 10); end
    if nargin < 5 || isempty(subtractNoise), subtractNoise = false; end
    if nargin < 6 || isempty(snrMaskDb),     snrMaskDb     = [];    end

    r    = depth(:);
    rmin = min(r(r > 0));                  % r=0 のサンプルを置換する微小距離
    if isempty(rmin), rmin = 1; end
    r    = max(r, rmin);                   % r=0 で -Inf を避ける

    sigma  = 1.4826 * median(abs(data(:) - bg), 'omitnan');  % 背景ノイズの頑健な標準偏差(MAD)
    sigma  = max(sigma, eps);
    resid  = data - bg;                    % 背景を引いた振幅(信号+ノイズ)
    if subtractNoise || ~isempty(snrMaskDb)
        % ABS標準: 全パワー - ノイズパワー で信号振幅を得る. 清水≈0(暗くなる).
        ampSig = sqrt(max(resid.^2 - sigma.^2, 0));
        if isempty(snrMaskDb)
            amp = max(ampSig, 0.1 * sigma);    % 表示用の微小床(log(0)回避)
        else
            amp = max(ampSig, eps);            % マスク時は床不要(低SNRは後でNaN)
        end
    else
        amp = max(resid, sigma);           % ノイズ床 sigma で下限を切る(従来)
    end
    twoTL  = 20*log10(r) + 2*alphaW.*r;    % 往復伝播損失 [dB]（拡散 + 吸収, [ns×1]）
    compDB = 20*log10(amp) + twoTL;        % 相対 Sv [dB]（twoTL は列方向にブロードキャスト）

    maskedFrac = 0;
    if ~isempty(snrMaskDb)
        % 画素ごとの SNR[dB] = 信号振幅/ノイズ. 距離補償に依らない「飛び出し量」.
        snr_dB = 20*log10(amp) - 20*log10(sigma);
        mask   = snr_dB < snrMaskDb;       % 検出限界以下
        compDB(mask) = NaN;                % 伏せる(空白). 明るさ=濃度は保ったまま.
        maskedFrac   = mean(mask(:));
    end

    % subtractNoise=false: 信号<ノイズ の画素は距離依存の「ノイズ床ランプ」に乗る
    %   （= 深さ方向の検出限界. これより明るい所だけが意味のある濁度）.
    % subtractNoise=true : ノイズの下駄が外れ清水が暗くなる. 深いほど検知力低下(残差大).
    % snrMaskDb 指定 : 距離補償Sv(濃度=絶対値で正しい)を出しつつ低SNRを空白化(=実務の定番).
    info = struct('x0', bg, 'alphaW', alphaW, 'sigma', sigma, ...
                  'subtractNoise', subtractNoise, 'snrMaskDb', snrMaskDb, ...
                  'maskedFrac', maskedFrac);
end

% -----------------------------------------------------------------------
function aW = freshwaterAbsorption(fkHz, T)
%FRESHWATERABSORPTION 淡水の音響吸収 [dB/m]（純水の粘性吸収項; Francois & Garrison 1982）. 
%   alpha[dB/km] = 4.937e-4 * f^2 * (1 - 3.83e-2 T + 4.9e-4 T^2)   (T<=20℃, f[kHz])
%   400kHz,10℃ で約0.053 dB/m. 数十mでは 2次補正なので概算で十分. 
%   実測値があれば rangeCompensate の alphaW 引数で上書きする. 
    aW = (4.937e-4 * fkHz.^2 .* (1 - 3.83e-2*T + 4.9e-4*T.^2)) / 1000;  % dB/m
end

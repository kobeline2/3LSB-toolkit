function [data, depth, dt_us, meta] = read3LSBSegy(fn)
fid = fopen(fn, 'r', 'ieee-le');   % ★ endian を little に変更
assert(fid>0,'File open error');

% ---------------- 1. ヘッダ部 ----------------
textRaw = fread(fid, 3200, 'uint8=>char')';                    % 3200B
% ASCII/EBCDIC 判定（最初の 80byte が制御コード中心なら EBCDIC）
if all(textRaw(1:80) < 32), textRaw = ebcdic2ascii(textRaw); end
meta.textHeader = string(reshape(textRaw,80,[]).');            % 40×1
% ── 前処理: 40×1 string 配列を持っている前提 ──
lines = strtrim(meta.textHeader);         % 余分な空白を除去

% 正規表現パターン
% ① "Label: value unit" ② "Label: value" の 2 形を想定
pat = "^(?<key>[^:]+):\s*(?<val>[-\d\.]+)";

for s = lines.'
    tok = regexp(s, pat, 'names');        % 構造配列で取得
    if isempty(tok), continue, end        % ヒットしなければ次行へ

    % --- フィールド名をクリーンアップ ---
    key = tok.key;
    key = regexprep(key, '\s+',  '_');    % 空白→ _
    key = regexprep(key, '[^\w]', '');    % - / ( ) など削除
    key = matlab.lang.makeUniqueStrings(key);  % 衝突回避

    % --- 値を数値 or 文字列に変換 ---
    v = str2double(tok.val);
    if isnan(v)
        meta.(key) = tok.val;             % 数値化失敗→文字列
    else
        meta.(key) = v;                   % 数値として保存
    end
end

% ---------------- 2. trace header ----------------
binRaw = fread(fid, 400, 'uint8=>uint8')';                     % 400B
% ビッグエンディアンで解釈（規格どおり）
meta.binaryHeader = struct( ...
    'jobID',      typecast(binRaw(1:4)  ,'uint32'), ...
    'lineID',     typecast(binRaw(5:8)  ,'uint32'), ...
    'reelID',     typecast(binRaw(9:12) ,'uint32'), ...
    'sampleInt',  typecast(binRaw(17:18),'uint16'), ...  % dt(µs)
    'samples',    typecast(binRaw(21:22),'uint16'), ...  % ns
    'dataFormat', typecast(binRaw(25:26),'uint16'));     % fmt


% ---------------- 3. signal block ----------------
waves   = {};
dt_vals = [];
while ~feof(fid)
    th = fread(fid, 240, 'uint8=>uint8');
    if numel(th)<240, break, end

    ns_i = typecast(th(115:116), 'uint16');
    dt_i = typecast(th(117:118), 'uint16');
    dt_vals(end+1,1) = double(max(dt_i,1));    % 0→1 μs 仮置き

    samples = fread(fid, ns_i, 'single');      % little-endian IEEE float32
    if numel(samples)~=ns_i, break, end

    waves{end+1,1} = samples;                  %#ok<AGROW>
end
fclose(fid);

% 行列化（同じまま）
nsMax = max(cellfun(@numel, waves));
data  = NaN(numel(waves), nsMax, 'single');
for k = 1:numel(waves)
    data(k,1:numel(waves{k})) = waves{k};
end
data = data';


[nSamples, ~] = size(data);
dt_us = mode(dt_vals(dt_vals>0));
dt = dt_us * 1e-6;            % 秒
t = (0:nSamples-1)' * dt;     % 時間軸 (s)
c = 1500;                        % m/s
depth = t * c / 2;   

end



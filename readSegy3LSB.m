config = readyaml("config.yaml");
fn = config.fnSegy;  

[data, depth, dt_us, meta] = read3LSBSegy(fn);
imagesc(size(data, 1), depth, data);
set(gca, 'YDir', 'reverse');
xlabel('Trace number (time order)');
ylabel('Depth (m)');
colormap(gray);
colorbar;
title('Subbottom profile');
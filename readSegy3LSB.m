fn = 'dat/testInSenbon/251000_test_dev/20251025140436.sgy';
[data, depth, dt_us, meta] = read3LSBSegy(fn);
imagesc(size(data, 1), depth, data);
set(gca, 'YDir', 'reverse');
xlabel('Trace number (time order)');
ylabel('Depth (m)');
colormap(gray);
colorbar;
title('Subbottom profile');
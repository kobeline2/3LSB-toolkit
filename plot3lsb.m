d = tt;
isNoise = (d.Value<10 | d.Value > 20);
d.Value(isNoise) = NaN;

%% plot 
scatter(tt.datetimeArray, tt.Value, 1, 'filled')
%% plot 
scatter(d.datetimeArray, d.Value, 1, 'filled', 'MarkerFaceAlpha', 0.1)
yline(16.5, 'Color', 'r', 'LineWidth', 1)
yline(17.0, 'Color', 'r', 'LineWidth', 1)

%%
axis tight
xlabel('Time')
ylabel('depth [m]')
fig = gcf;
setFig(fig, 18, 8, 9, 'T')
% print(fig, '2408koshibu_pruned', '-dpng', '-r600')
function ctXsfReportTimeSpace(result, o)
%CTXSFREPORTTIMESPACE  Displacement space-time maps of the retained tail window.

if ~isfield(result, 'Y_tail') || isempty(result.Y_tail)
    return
end

z = result.z_paper;
D = result.params.D;

fig = figure('Name', 'Displacement space-time maps', ...
             'Color', 'w', 'Position', [120 120 1020 460]);
tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
imagesc(result.t_tail, z, result.Y_tail.'/D);
set(gca, 'YDir', 'normal');
xlabel('$t$ (s)', 'Interpreter', 'latex');
ylabel('$z/D$', 'Interpreter', 'latex');
title('$y(z,t)/D$', 'Interpreter', 'latex');
colorbar;

nexttile;
imagesc(result.t_tail, z, result.X_tail.'/D);
set(gca, 'YDir', 'normal');
xlabel('$t$ (s)', 'Interpreter', 'latex');
ylabel('$z/D$', 'Interpreter', 'latex');
title('$x(z,t)/D$', 'Interpreter', 'latex');
colorbar;

sgtitle('Displacement space-time maps in the retained tail window', ...
    'FontName', 'Times New Roman', 'FontSize', 12, 'Interpreter', 'none');
ctXsfSaveFig(fig, 'displacement_time_space', o);
end

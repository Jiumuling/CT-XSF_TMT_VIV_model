function ctXsfReportWake(result, o)
%CTXSFREPORTWAKE  RMS distribution of the wake-oscillator variables p and q.
%
%   p is the in-line (fluctuating drag) wake variable, q the cross-flow
%   (fluctuating lift) wake variable.

if ~isfield(result, 'p_tail') || isempty(result.p_tail)
    return
end

z = result.z_paper;

fig = figure('Name', 'Wake-oscillator RMS distribution', ...
             'Color', 'w', 'Position', [140 150 900 430]);
tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot(std(result.p_tail, 0, 1), z, 'k-', 'LineWidth', 1.4);
xlabel('$\mathrm{std}(p)$', 'Interpreter', 'latex');
ylabel('$z/D$', 'Interpreter', 'latex');
title('In-line wake variable', 'Interpreter', 'none');
ctXsfStyleAxes(gca);

nexttile;
plot(std(result.q_tail, 0, 1), z, 'k-', 'LineWidth', 1.4);
xlabel('$\mathrm{std}(q)$', 'Interpreter', 'latex');
ylabel('$z/D$', 'Interpreter', 'latex');
title('Cross-flow wake variable', 'Interpreter', 'none');
ctXsfStyleAxes(gca);

sgtitle('Wake-oscillator intensity along the span', ...
    'FontName', 'Times New Roman', 'FontSize', 12, 'Interpreter', 'none');
ctXsfSaveFig(fig, 'wake_rms', o);
end

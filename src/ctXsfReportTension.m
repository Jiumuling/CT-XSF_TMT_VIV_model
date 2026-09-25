function ctXsfReportTension(result, o)
%CTXSFREPORTTENSION  Dynamic axial-tension histories.
%
%   DeltaNxy(t) is the total vibration-induced additional axial tension,
%   DeltaNx / DeltaNy are its in-line and cross-flow contributions, and
%   Ntop_eff / Nbot_eff are the resulting effective end tensions.

if ~isfield(result, 'DeltaN') || isempty(result.DeltaN)
    return
end

tt = (1:numel(result.DeltaN)).' * result.params.dt;

fig = figure('Name', 'Dynamic axial-tension history', ...
             'Color', 'w', 'Position', [140 130 1000 560]);
tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot(tt, result.DeltaN,    'k-',  'LineWidth', 1.2); hold on;
plot(tt, result.DeltaNx_vector, 'k--', 'LineWidth', 1.0);
plot(tt, result.DeltaNy_vector, 'k-.', 'LineWidth', 1.0);
xlabel('$t$ (s)', 'Interpreter', 'latex');
ylabel('$\Delta N$ (N)', 'Interpreter', 'latex');
title('Vibration-induced additional axial tension', 'Interpreter', 'none');
legend({'$\Delta N_{xy}$', '$\Delta N_x$', '$\Delta N_y$'}, ...
       'Interpreter', 'latex', 'Location', 'best');
ctXsfStyleAxes(gca);

nexttile;
plot(tt, result.Ntop_eff_vector, 'k-',  'LineWidth', 1.2); hold on;
plot(tt, result.Nbot_eff_vector, 'k--', 'LineWidth', 1.2);
xlabel('$t$ (s)', 'Interpreter', 'latex');
ylabel('$N_{\mathrm{eff}}$ (N)', 'Interpreter', 'latex');
title('Effective end tensions', 'Interpreter', 'none');
legend({'top end', 'bottom end'}, 'Location', 'best');
ctXsfStyleAxes(gca);

sgtitle(sprintf('Axial-tension feedback, lambda_{DeltaN} = %.2f', ...
    result.params.lambda_DeltaN), ...
    'FontName', 'Times New Roman', 'FontSize', 12, 'Interpreter', 'tex');
ctXsfSaveFig(fig, 'dynamic_tension_history', o);
end

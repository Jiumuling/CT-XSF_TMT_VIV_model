function ctXsfReportInternalForce(result, o)
%CTXSFREPORTINTERNALFORCE  Internal-force figures of the mixed Timoshenko model.
%
%   Bending moment and shear force are recovered from the mixed [u, theta]
%   fields (M = -EI*theta_z, Q = kGA*(u_z - theta)).  The figures compare the
%   true Timoshenko internal forces with the displacement-based indicators
%   (M_u = -EI*u_zz, Q_u = dM_u/dz).

z = result.z_paper;

%% ---- 1) spanwise statistics -----------------------------------------
fig = figure('Name', 'Internal-force statistics', ...
             'Color', 'w', 'Position', [110 140 1020 430]);
tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot(result.std_MomentX, z, 'k-',  'LineWidth', 1.3); hold on;
plot(result.std_MomentY, z, 'k--', 'LineWidth', 1.3);
plot(result.std_Mres,    z, 'k-.', 'LineWidth', 1.6);
xlabel('$\mathrm{std}(M)$ (N m)', 'Interpreter', 'latex');
ylabel('$z/D$', 'Interpreter', 'latex');
title('Bending moment', 'Interpreter', 'none');
legend({'$M_x$', '$M_y$', '$M_{\mathrm{res}}$'}, 'Interpreter', 'latex', ...
       'Location', 'best');
ctXsfStyleAxes(gca);

nexttile;
plot(result.std_ShearX, z, 'k-',  'LineWidth', 1.3); hold on;
plot(result.std_ShearY, z, 'k--', 'LineWidth', 1.3);
plot(result.std_Qres,   z, 'k-.', 'LineWidth', 1.6);
xlabel('$\mathrm{std}(Q)$ (N)', 'Interpreter', 'latex');
ylabel('$z/D$', 'Interpreter', 'latex');
title('Shear force', 'Interpreter', 'none');
legend({'$Q_x$', '$Q_y$', '$Q_{\mathrm{res}}$'}, 'Interpreter', 'latex', ...
       'Location', 'best');
ctXsfStyleAxes(gca);

sgtitle('Spanwise statistics of the recovered internal forces', ...
    'FontName', 'Times New Roman', 'FontSize', 12, 'Interpreter', 'none');
ctXsfSaveFig(fig, 'internal_force_statistics', o);

%% ---- 2) envelopes: true vs displacement-based -----------------------
if isfield(result, 'maxMuResultant') && ~isempty(result.maxMuResultant)

    fig = figure('Name', 'Internal-force envelopes', ...
                 'Color', 'w', 'Position', [120 140 1020 430]);
    tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

    nexttile;
    plot(result.max_Mres,       z, 'k-',  'LineWidth', 1.5); hold on;
    plot(result.maxMuResultant, z, 'r--', 'LineWidth', 1.3);
    xlabel('$\max|M_{\mathrm{res}}|$ (N m)', 'Interpreter', 'latex');
    ylabel('$z/D$', 'Interpreter', 'latex');
    title('Resultant bending moment', 'Interpreter', 'none');
    legend({'mixed Timoshenko', 'displacement-based'}, 'Location', 'best');
    ctXsfStyleAxes(gca);

    nexttile;
    plot(result.max_Qres,       z, 'k-',  'LineWidth', 1.5); hold on;
    plot(result.maxQuResultant, z, 'r--', 'LineWidth', 1.3);
    xlabel('$\max|Q_{\mathrm{res}}|$ (N)', 'Interpreter', 'latex');
    ylabel('$z/D$', 'Interpreter', 'latex');
    title('Resultant shear force', 'Interpreter', 'none');
    legend({'mixed Timoshenko', 'displacement-based'}, 'Location', 'best');
    ctXsfStyleAxes(gca);

    sgtitle('True (mixed Timoshenko) versus displacement-based internal forces', ...
        'FontName', 'Times New Roman', 'FontSize', 12, 'Interpreter', 'none');
    ctXsfSaveFig(fig, 'internal_force_true_vs_assumed', o);

end

%% ---- 3) local difference of the two indicator families ---------------
if isfield(result, 'Mdiff_abs_std_tail') && ~isempty(result.Mdiff_abs_std_tail)

    fig = figure('Name', 'Difference between internal-force indicators', ...
                 'Color', 'w', 'Position', [160 160 980 430]);
    tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

    nexttile;
    plot(result.Mdiff_abs_std_tail, z, 'k-', 'LineWidth', 1.4);
    xlabel('$|\mathrm{std}(M_\theta)-\mathrm{std}(M_u)|$ (N m)', ...
           'Interpreter', 'latex');
    ylabel('$z/D$', 'Interpreter', 'latex');
    title('Moment STD difference', 'Interpreter', 'none');
    ctXsfStyleAxes(gca);

    nexttile;
    plot(result.Qdiff_abs_std_tail, z, 'k-', 'LineWidth', 1.4);
    xlabel('$|\mathrm{std}(Q)-\mathrm{std}(Q_u)|$ (N)', 'Interpreter', 'latex');
    ylabel('$z/D$', 'Interpreter', 'latex');
    title('Shear STD difference', 'Interpreter', 'none');
    ctXsfStyleAxes(gca);

    ctXsfSaveFig(fig, 'internal_force_indicator_difference', o);

end
end

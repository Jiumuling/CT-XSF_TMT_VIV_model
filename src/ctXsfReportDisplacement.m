function ctXsfReportDisplacement(result, o)
%CTXSFREPORTDISPLACEMENT  Displacement key-information figures.
%
%   Draws the displacement envelope, the RMS distributions, the time history
%   at the cross-flow RMS peak and the local trajectory / spectrum.  The
%   vertical axis is z/D with the bottom end at 0, as in the paper figures.

z = result.z_paper;
D = result.params.D;

%% ---- 1) envelopes and curvature STD ---------------------------------
fig = figure('Name', 'Displacement envelopes and curvature STD', ...
             'Color', 'w', 'Position', [120 160 1280 430]);
tiledlayout(1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot(result.X_min_nd,  z, 'k-',  'LineWidth', 1.2); hold on;
plot(result.X_mean_nd, z, 'k--', 'LineWidth', 1.2);
plot(result.X_max_nd,  z, 'k-',  'LineWidth', 1.2);
xlabel('$x/D$', 'Interpreter', 'latex');
ylabel('$z/D$', 'Interpreter', 'latex');
title('In-line displacement envelope', 'Interpreter', 'none');
legend({'$x_{\min}$', '$\bar{x}$', '$x_{\max}$'}, 'Interpreter', 'latex', ...
       'Location', 'best');
ctXsfStyleAxes(gca);

nexttile;
plot(result.Y_min_nd, z, 'k-', 'LineWidth', 1.2); hold on;
plot(result.Y_max_nd, z, 'k-', 'LineWidth', 1.2);
xlabel('$y/D$', 'Interpreter', 'latex');
ylabel('$z/D$', 'Interpreter', 'latex');
title('Cross-flow displacement envelope', 'Interpreter', 'none');
legend({'$y_{\min}$', '$y_{\max}$'}, 'Interpreter', 'latex', 'Location', 'best');
ctXsfStyleAxes(gca);

nexttile;
plot(result.sig_curv_X_nd, z, 'k-',  'LineWidth', 1.3); hold on;
plot(result.sig_curv_Y_nd, z, 'k--', 'LineWidth', 1.3);
xlabel('$\sigma_{c}(z)\,D$', 'Interpreter', 'latex');
ylabel('$z/D$', 'Interpreter', 'latex');
title('Curvature STD', 'Interpreter', 'none');
legend({'in-line', 'cross-flow'}, 'Location', 'best');
ctXsfStyleAxes(gca);

sgtitle(sprintf('L/D = %.0f, U_{top} = %.2f m/s, N_{top} = %.0f N, %s', ...
    result.params.L/result.params.D, result.params.U_top, result.params.N_top, ...
    strrep(result.params.boundary_preset, '_', '-')), ...
    'FontName', 'Times New Roman', 'FontSize', 12, 'Interpreter', 'tex');
ctXsfSaveFig(fig, 'displacement_envelope', o);

%% ---- 2) RMS distributions -------------------------------------------
fig = figure('Name', 'Displacement RMS distributions', ...
             'Color', 'w', 'Position', [150 160 620 520]);
plot(result.rms_Y_total/D, z, 'k-',  'LineWidth', 1.5); hold on;
plot(result.rms_Y_dyn/D,   z, 'k--', 'LineWidth', 1.3);
plot(result.rms_X_dyn/D,   z, 'k-.', 'LineWidth', 1.3);
xlabel('$x_{\mathrm{rms}}/D,\ y_{\mathrm{rms}}/D$', 'Interpreter', 'latex');
ylabel('$z/D$', 'Interpreter', 'latex');
title('Displacement RMS distribution', 'Interpreter', 'none');
legend({'$y_{\mathrm{rms}}$ (total)', '$y_{\mathrm{rms}}$ (dynamic)', ...
        '$x_{\mathrm{rms}}$ (dynamic)'}, 'Interpreter', 'latex', ...
       'Location', 'best');
ctXsfStyleAxes(gca);
ctXsfSaveFig(fig, 'displacement_rms', o);

%% ---- 3) time history at the cross-flow RMS peak ---------------------
if isfield(result, 'Y_tail') && ~isempty(result.Y_tail) && ...
        isfield(result, 'idx_cf_max') && ~isempty(result.idx_cf_max)

    idc = result.idx_cf_max;
    tt  = result.t_tail(:);

    fig = figure('Name', 'Time history at the cross-flow RMS peak', ...
                 'Color', 'w', 'Position', [140 140 900 520]);
    tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

    nexttile;
    plot(tt, result.Y_tail(:, idc)/D, 'k-', 'LineWidth', 1.0);
    ylabel('$y/D$', 'Interpreter', 'latex');
    title(sprintf('Cross-flow response at z/D = %.1f (RMS peak)', ...
        result.Z_cf_max_over_D), 'Interpreter', 'none');
    ctXsfStyleAxes(gca);

    nexttile;
    plot(tt, result.X_tail(:, idc)/D, 'k-', 'LineWidth', 1.0);
    xlabel('$t$ (s)', 'Interpreter', 'latex');
    ylabel('$x/D$', 'Interpreter', 'latex');
    title('In-line response at the same section', 'Interpreter', 'none');
    ctXsfStyleAxes(gca);

    ctXsfSaveFig(fig, 'displacement_time_history', o);

    %% ---- 4) trajectory and spectrum --------------------------------
    fig = figure('Name', 'Trajectory and spectrum at the cross-flow RMS peak', ...
                 'Color', 'w', 'Position', [160 150 980 440]);
    tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

    nexttile;
    plot(result.X_tail(:, idc)/D, result.Y_tail(:, idc)/D, 'k-', 'LineWidth', 1.0);
    xlabel('$x/D$', 'Interpreter', 'latex');
    ylabel('$y/D$', 'Interpreter', 'latex');
    title('Orbital trajectory', 'Interpreter', 'none');
    ctXsfStyleAxes(gca);

    nexttile;
    dtt = median(diff(tt));
    if numel(tt) > 8 && dtt > 0
        y   = result.Y_tail(:, idc) - mean(result.Y_tail(:, idc));
        n   = numel(y);
        n2  = 2^nextpow2(n);
        Yf  = abs(fft(y, n2)) * 2 / n;
        f   = (0:n2-1).' * (1/(dtt*n2));
        nH  = floor(n2/2);
        plot(f(2:nH), Yf(2:nH), 'k-', 'LineWidth', 1.3);
        xlabel('$f$ (Hz)', 'Interpreter', 'latex');
        ylabel('$|y|$ (m)', 'Interpreter', 'latex');
        title('Cross-flow spectrum', 'Interpreter', 'none');
        ctXsfStyleAxes(gca);
    end

    ctXsfSaveFig(fig, 'displacement_trajectory_spectrum', o);
end
end

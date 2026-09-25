function ctXsfReportFatigue(result, o)
%CTXSFREPORTFATIGUE  Beam-based stress (fatigue-demand) indicators.
%
%   Bending stress      sigma_b = M_res * (D/2) / I
%   Shear stress        tau_Q   = factor * Q_res / A
%   with factor = params.output.tau_shear_factor (4/3 for a solid circle).
%
%   The figures show the stress envelopes and the stress standard deviations
%   along the span, the stress space-time maps and a regional hotspot table
%   used for relative cyclic stress-demand screening.

z = result.z_paper;
D = result.params.D;

sigma_std = [];
tau_std   = [];
if isfield(result, 'sigma_b_tail') && ~isempty(result.sigma_b_tail)
    sigma_std = std(result.sigma_b_tail, 0, 1).';
    tau_std   = std(result.tau_Q_tail,   0, 1).';
end

%% ---- 1) envelopes and standard deviations ----------------------------
fig = figure('Name', 'Fatigue stress indicators', ...
             'Color', 'w', 'Position', [90 140 1240 480]);
tiledlayout(1, 4, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot(result.max_sigma_b, z, 'k-', 'LineWidth', 1.5);
xlabel('$\max|\sigma_b|$ (Pa)', 'Interpreter', 'latex');
ylabel('$z/D$', 'Interpreter', 'latex');
title('Bending stress envelope', 'Interpreter', 'none');
ctXsfStyleAxes(gca);

nexttile;
if ~isempty(sigma_std)
    plot(sigma_std, z, 'k-', 'LineWidth', 1.5);
end
xlabel('$\mathrm{std}(\sigma_b)$ (Pa)', 'Interpreter', 'latex');
ylabel('$z/D$', 'Interpreter', 'latex');
title('Bending stress STD', 'Interpreter', 'none');
ctXsfStyleAxes(gca);

nexttile;
plot(result.max_tau_Q, z, 'k-', 'LineWidth', 1.5);
xlabel('$\max|\tau_Q|$ (Pa)', 'Interpreter', 'latex');
ylabel('$z/D$', 'Interpreter', 'latex');
title('Shear stress envelope', 'Interpreter', 'none');
ctXsfStyleAxes(gca);

nexttile;
if ~isempty(tau_std)
    plot(tau_std, z, 'k-', 'LineWidth', 1.5);
end
xlabel('$\mathrm{std}(\tau_Q)$ (Pa)', 'Interpreter', 'latex');
ylabel('$z/D$', 'Interpreter', 'latex');
title('Shear stress STD', 'Interpreter', 'none');
ctXsfStyleAxes(gca);

sgtitle('Bending and shear stress indicators (relative cyclic demand)', ...
    'FontName', 'Times New Roman', 'FontSize', 12, 'Interpreter', 'none');
ctXsfSaveFig(fig, 'fatigue_stress_profiles', o);

%% ---- 2) stress space-time maps ---------------------------------------
if ~isempty(sigma_std)

    fig = figure('Name', 'Stress space-time maps', ...
                 'Color', 'w', 'Position', [110 120 1020 460]);
    tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

    nexttile;
    imagesc(result.t_tail, z, result.sigma_b_tail.');
    set(gca, 'YDir', 'normal');
    xlabel('$t$ (s)', 'Interpreter', 'latex');
    ylabel('$z/D$', 'Interpreter', 'latex');
    title('$\sigma_b(z,t)$', 'Interpreter', 'latex');
    colorbar;

    nexttile;
    imagesc(result.t_tail, z, result.tau_Q_tail.');
    set(gca, 'YDir', 'normal');
    xlabel('$t$ (s)', 'Interpreter', 'latex');
    ylabel('$z/D$', 'Interpreter', 'latex');
    title('$\tau_Q(z,t)$', 'Interpreter', 'latex');
    colorbar;

    sgtitle('Stress space-time maps in the retained tail window', ...
        'FontName', 'Times New Roman', 'FontSize', 12, 'Interpreter', 'none');
    ctXsfSaveFig(fig, 'fatigue_stress_maps', o);

end

%% ---- 3) regional stress hotspots -------------------------------------
T = ctXsfStressHotspotTable(result);
if ~isempty(T)
    fprintf('\n===== Stress hotspot regions (bottom->top z/D) =====\n');
    disp(T);
    if o.export
        xls = fullfile(o.out_dir, sprintf('%s_fatigue_stress_hotspots.xlsx', o.prefix));
        writetable(T, xls);
        fprintf('Stress hotspot table saved: %s\n', xls);
    end
end

%% ---- 4) rainflow-based relative cyclic stress-demand screening --------
fopts = ctXsfFatigueOptions(result, o);
if fopts.enable
    fatigue = ctXsfFatigueRainflow(result, o);
    ctXsfReportFatigueRainflow(fatigue, o);
end
end

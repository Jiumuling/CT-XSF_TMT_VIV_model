function ctXsfReportFatigueRainflow(fatigue, o)
%CTXSFREPORTFATIGUERAINFLOW  Figures and tables of the rainflow demand index.
%
%   Reproduces the three standalone fatigue figures of the study:
%     * relative bending-stress rainflow demand along the span
%     * relative equivalent-stress rainflow demand along the span
%     * normalised displacement and stress indicators
%   plus a regional bar chart, the printed summary and the Excel tables.

z    = fatigue.z_paper(:);
zmax = max(z, [], 'omitnan');
mVals = fatigue.m_values(:).';

colors = [0.30 0.47 0.65;
          0.78 0.45 0.42;
          0.39 0.62 0.57;
          0.58 0.51 0.72];

%% ---- 1) bending-stress rainflow demand -------------------------------
fig = figure('Name', 'Relative bending-stress rainflow demand', ...
             'Color', 'w', 'Units', 'centimeters', 'Position', [3 3 12 14]);
ax = axes(fig); hold(ax, 'on');
colororder(ax, colors);
for im = 1:numel(mVals)
    plot(ax, fatigue.Db_rel(:, im), z, 'LineWidth', 1.6, ...
        'DisplayName', sprintf('$D_{b,%g}^{rel}$', mVals(im)));
end
ctXsfFatigueAxis(ax, zmax, 'Relative bending-stress rainflow demand');
legend(ax, 'Interpreter', 'latex', 'Location', 'southoutside', ...
       'Orientation', 'horizontal', 'NumColumns', 2);
ctXsfSaveFig(fig, 'fatigue_bending_rainflow_demand', o);

%% ---- 2) equivalent-stress rainflow demand ----------------------------
fig = figure('Name', 'Relative equivalent-stress rainflow demand', ...
             'Color', 'w', 'Units', 'centimeters', 'Position', [3 3 12 14]);
ax = axes(fig); hold(ax, 'on');
colororder(ax, colors);
for im = 1:numel(mVals)
    plot(ax, fatigue.Deq_rel(:, im), z, 'LineWidth', 1.6, ...
        'DisplayName', sprintf('$D_{eq,%g}^{rel}$', mVals(im)));
end
ctXsfFatigueAxis(ax, zmax, 'Relative equivalent-stress rainflow demand');
legend(ax, 'Interpreter', 'latex', 'Location', 'southoutside', ...
       'Orientation', 'horizontal', 'NumColumns', 2);
ctXsfSaveFig(fig, 'fatigue_equivalent_rainflow_demand', o);

%% ---- 3) displacement and stress indicators ---------------------------
fig = figure('Name', 'Displacement and stress indicators', ...
             'Color', 'w', 'Units', 'centimeters', 'Position', [3 3 12 14]);
ax = axes(fig); hold(ax, 'on');
colororder(ax, colors);
if any(isfinite(fatigue.Y_rms_dyn_norm))
    plot(ax, fatigue.Y_rms_dyn_norm, z, 'LineWidth', 1.5, ...
        'DisplayName', '$Y_{rms}$ norm');
end
plot(ax, normByMax(fatigue.sigma_b_res_std), z, 'LineWidth', 1.5, ...
    'DisplayName', '$std(\sigma_b)$ norm');
plot(ax, normByMax(fatigue.tau_Q_std), z, 'LineWidth', 1.5, ...
    'DisplayName', '$std(\tau_Q)$ norm');
plot(ax, normByMax(fatigue.sigma_eq_std), z, 'LineWidth', 1.5, ...
    'DisplayName', '$std(\sigma_{eq})$ norm');
ctXsfFatigueAxis(ax, zmax, 'Normalised indicator');
legend(ax, 'Interpreter', 'latex', 'Location', 'southoutside', ...
       'Orientation', 'horizontal', 'NumColumns', 2);
ctXsfSaveFig(fig, 'fatigue_displacement_stress_indicators', o);

%% ---- 4) regional hotspots --------------------------------------------
T = fatigue.regionTable;
fig = figure('Name', 'Regional relative fatigue demand', ...
             'Color', 'w', 'Position', [140 140 820 460]);
if ~isempty(T)
    nR = height(T);
    vals = zeros(nR, 2);
    labs = cell(nR, 1);
    for r = 1:nR
        vals(r, 1) = T.Db_rel_peak(r);
        vals(r, 2) = T.Deq_rel_peak(r);
        labs{r} = sprintf('%s (m=%g)', strrep(T.Region{r}, '_', '-'), T.m(r));
    end
    bar(vals, 1.0);
    set(gca, 'XTick', 1:nR, 'XTickLabel', labs, 'XTickLabelRotation', 20);
    ylabel('Relative peak demand (normalised)', 'Interpreter', 'none');
    legend({'bending', 'equivalent'}, 'Location', 'best');
    grid on;
    set(gca, 'FontName', 'Times New Roman', 'FontSize', 10);
    title('Regional peaks of the relative rainflow demand', ...
        'Interpreter', 'none', 'FontWeight', 'normal');
end
ctXsfSaveFig(fig, 'fatigue_rainflow_regions', o);

%% ---- 5) printed summary and tables ------------------------------------
ctXsfFatigueSummary(fatigue);

if o.export
    outDir = o.out_dir;
    pfx    = o.prefix;
    writetable(fatigue.profileTable,  fullfile(outDir, sprintf('%s_relative_fatigue_profiles.xlsx', pfx)));
    writetable(fatigue.regionTable,   fullfile(outDir, sprintf('%s_relative_fatigue_region_summary.xlsx', pfx)));
    writetable(fatigue.hotspotTable,  fullfile(outDir, sprintf('%s_relative_fatigue_hotspots.xlsx', pfx)));
    writetable(fatigue.samplingTable, fullfile(outDir, sprintf('%s_relative_fatigue_sampling_check.xlsx', pfx)));
    save(fullfile(outDir, sprintf('%s_relative_fatigue_demand.mat', pfx)), 'fatigue', '-v7.3');
    fprintf('Relative fatigue-demand tables saved to: %s\n', outDir);
end
end

function ctXsfFatigueAxis(ax, zmax, xlab)
grid(ax, 'on');
xlim(ax, [0 1.05]);
ylim(ax, [0 zmax]);
set(ax, 'YDir', 'normal', 'FontName', 'Times New Roman', 'FontSize', 11, ...
    'LineWidth', 0.9, 'Box', 'on');
xlabel(ax, xlab, 'Interpreter', 'none');
ylabel(ax, '$z/D$', 'Interpreter', 'latex');
end

function y = normByMax(x)
x = x(:);
mx = max(abs(x), [], 'omitnan');
if isempty(mx) || ~isfinite(mx) || mx == 0
    y = nan(size(x));
else
    y = x ./ mx;
end
end

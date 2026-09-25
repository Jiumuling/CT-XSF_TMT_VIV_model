%EXAMPLE_03_BOUNDARY_COMPARISON  Influence of the end supports.
%
%   Pinned, semi-rigid and clamped supports are evaluated with identical
%   rod, fluid, flow and numerical settings.  The support stiffness changes
%   the end-region internal-force hotspots while the global displacement RMS
%   is only weakly affected.

clear; clc; close all;
ctXsfSetup;

FAST_DEMO = true;

cases = struct( ...
    'name',          {'pinned', 'semi_rigid', 'clamped'}, ...
    'preset',        {'pinned_pinned', 'semi_rigid_both', 'clamped_clamped'}, ...
    'KthetaFactor',  {0, 90, 1e6});

zD = []; yRMS = []; mSTD = []; qSTD = [];
summary = {};

for k = 1:numel(cases)

    params = ctXsfDefaultParams();
    params.boundary_preset       = cases(k).preset;
    params.bcPreset.KthetaFactor = cases(k).KthetaFactor;

    if FAST_DEMO
        params.Nz_total = 401;
        params.T_total  = 10;
        params.dt       = 0.01;
        params.nt       = ceil(params.T_total/params.dt);
    end

    params.output.out_dir    = fullfile(pwd, 'results', ['bc_', cases(k).name]);
    params.output.figure_dir = fullfile(params.output.out_dir, 'figures');
    params.output.figures    = {'displacement'};
    params.output.save_fig   = true;

    result = ctXsfSolveVIV(params);

    zD   = result.z_paper;
    yRMS = [yRMS, result.rms_Y_dyn/params.D];          %#ok<AGROW>
    mSTD = [mSTD, result.std_Mres];                    %#ok<AGROW>
    qSTD = [qSTD, result.std_Qres];                    %#ok<AGROW>

    summary(end+1, :) = {cases(k).name, ...
        max(result.rms_Y_dyn)/params.D, ...
        max(result.std_Mres), max(result.std_Qres), ...
        max(result.max_sigma_b), max(result.max_tau_Q)}; %#ok<AGROW>

    ctXsfReport(result, params.output);
end

names = {cases.name};
T = cell2table(summary, 'VariableNames', ...
    {'Case', 'MaxCFRMS_over_D', 'MaxStdMoment_Nm', 'MaxStdShear_N', ...
     'MaxBendingStress_Pa', 'MaxShearStress_Pa'});
disp(T);
writetable(T, fullfile(pwd, 'results', 'boundary_comparison_summary.xlsx'));

figure('Name', 'Boundary-condition comparison', 'Color', 'w', ...
       'Position', [120 140 1080 430]);
tiledlayout(1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot(yRMS, zD, 'LineWidth', 1.4);
xlabel('$y_{\mathrm{rms}}/D$', 'Interpreter', 'latex');
ylabel('$z/D$', 'Interpreter', 'latex');
title('Cross-flow RMS', 'Interpreter', 'none');
legend(names, 'Location', 'best'); ctXsfStyleAxes(gca);

nexttile;
plot(mSTD, zD, 'LineWidth', 1.4);
xlabel('$\mathrm{std}(M_{\mathrm{res}})$ (N m)', 'Interpreter', 'latex');
ylabel('$z/D$', 'Interpreter', 'latex');
title('Bending moment', 'Interpreter', 'none');
ctXsfStyleAxes(gca);

nexttile;
plot(qSTD, zD, 'LineWidth', 1.4);
xlabel('$\mathrm{std}(Q_{\mathrm{res}})$ (N)', 'Interpreter', 'latex');
ylabel('$z/D$', 'Interpreter', 'latex');
title('Shear force', 'Interpreter', 'none');
ctXsfStyleAxes(gca);

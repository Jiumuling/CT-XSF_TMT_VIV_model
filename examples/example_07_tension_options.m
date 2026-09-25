%EXAMPLE_07_TENSION_OPTIONS  Selectable static and dynamic axial-tension models.
%
%   The axial tension has two independent, user-selectable parts
%
%       N_eff(z,t) = N_static(z) + lambda_DeltaN * DeltaN(t)
%       N_static(z) = N_top - w*z
%       DeltaN(t)   = E*Ap/(2L) * integral_0^L ( X_z^2 + Y_z^2 ) dz
%
%   Switch 1 - static tension shape
%       params.include_submerged_weight = true   -> linear: N_top - w*z
%       params.include_submerged_weight = false  -> constant: N_top
%       (a user-defined gradient is also available:
%        params.use_user_defined_w = true; params.w_user_defined = ...)
%
%   Switch 2 - dynamic tension
%       params.use_variable_tension = true  -> DeltaN(t) is computed
%       params.lambda_DeltaN = 1            -> and fed back into the stiffness
%       params.lambda_DeltaN = 0            -> and reported but NOT fed back
%       params.use_variable_tension = false -> DeltaN is not computed at all
%                                              (output is zero, fastest run)
%
%   This example runs the four combinations and compares the response.

clear; clc; close all;
ctXsfSetup;

FAST_DEMO = true;

% name, include_submerged_weight, use_variable_tension, lambda_DeltaN
cases = { ...
    'weight_variable',      true,  true,  1.0; ...
    'weight_no_variable',   true,  false, 1.0; ...
    'constant_variable',    false, true,  1.0; ...
    'constant_report_only', false, true,  0.0};

zD = []; yRMS = []; mSTD = []; sSTD = [];
summary = {};
tension  = [];

for k = 1:size(cases, 1)

    name  = cases{k, 1};

    params = ctXsfDefaultParams();
    params.include_submerged_weight = cases{k, 2};
    params.use_variable_tension     = cases{k, 3};
    params.lambda_DeltaN            = cases{k, 4};

    if FAST_DEMO
        params.Nz_total = 401;
        params.T_total  = 10;
        params.dt       = 0.01;
        params.nt       = ceil(params.T_total/params.dt);
    end

    params.output.out_dir    = fullfile(pwd, 'results', ['tension_', name]);
    params.output.figure_dir = fullfile(params.output.out_dir, 'figures');
    params.output.figures    = {'tension'};
    params.output.save_fig   = true;

    result = ctXsfSolveVIV(params);

    zD   = result.z_paper;
    yRMS = [yRMS, result.rms_Y_dyn/params.D];      %#ok<AGROW>
    mSTD = [mSTD, result.std_Mres];                %#ok<AGROW>
    sSTD = [sSTD, result.max_sigma_b];             %#ok<AGROW>
    tension = [tension, result.DeltaN];            %#ok<AGROW>

    summary(end+1, :) = {name, ...
        params.include_submerged_weight, params.use_variable_tension, ...
        params.lambda_DeltaN, ...
        result.params.w, ...
        max(result.rms_Y_dyn)/params.D, ...
        max(result.std_Mres), max(result.max_sigma_b), ...
        max(result.DeltaN), mean(result.Ntop_eff_vector)}; %#ok<AGROW>

    ctXsfReport(result, params.output);
    close all;      % keep each case folder free of the previous case figures
end

T = cell2table(summary, 'VariableNames', ...
    {'Case', 'IncludeSubmergedWeight', 'UseVariableTension', 'lambda_DeltaN', ...
     'w_N_per_m', 'MaxCFRMS_over_D', 'MaxStdMoment_Nm', ...
     'MaxBendingStress_Pa', 'MaxDeltaN_N', 'MeanNtopEff_N'});

disp(T);
writetable(T, fullfile(pwd, 'results', 'tension_model_comparison.xlsx'));

%% ---- comparison figures ----------------------------------------------
names = cases(:, 1).';

figure('Name', 'Axial-tension model comparison', 'Color', 'w', ...
       'Position', [110 130 1180 460]);
tiledlayout(1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot(yRMS, zD, 'LineWidth', 1.4);
xlabel('$y_{\mathrm{rms}}/D$', 'Interpreter', 'latex');
ylabel('$z/D$', 'Interpreter', 'latex');
title('Cross-flow RMS', 'Interpreter', 'none');
legend(names, 'Location', 'best', 'Interpreter', 'none');
ctXsfStyleAxes(gca);

nexttile;
plot(mSTD, zD, 'LineWidth', 1.4);
xlabel('$\mathrm{std}(M_{\mathrm{res}})$ (N m)', 'Interpreter', 'latex');
ylabel('$z/D$', 'Interpreter', 'latex');
title('Bending moment', 'Interpreter', 'none');
ctXsfStyleAxes(gca);

nexttile;
plot(tension, 'LineWidth', 1.1);
xlabel('time step index', 'Interpreter', 'none');
ylabel('$\Delta N_{xy}$ (N)', 'Interpreter', 'latex');
title('Additional axial tension', 'Interpreter', 'none');
ctXsfStyleAxes(gca);

sgtitle('Effect of the static-tension shape and of the dynamic-tension feedback', ...
    'FontName', 'Times New Roman', 'FontSize', 12, 'Interpreter', 'none');

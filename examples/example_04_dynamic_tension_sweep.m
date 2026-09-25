%EXAMPLE_04_DYNAMIC_TENSION_SWEEP  Sensitivity to the axial-tension feedback.
%
%   The feedback coefficient lambda_DeltaN scales the vibration-induced
%   additional axial tension that is fed back into the structural matrix:
%
%       N_eff(z,t) = N_static(z) + lambda_DeltaN * DeltaN_xy(t)
%
%   lambda_DeltaN = 0 gives a constant-tension reference solution.

clear; clc; close all;
ctXsfSetup;

FAST_DEMO = true;
lambdas   = [0, 0.25, 0.5, 0.75, 1.0];

zD = []; yRMS = []; dN = [];
summary = {};

for k = 1:numel(lambdas)

    params = ctXsfDefaultParams();
    params.lambda_DeltaN = lambdas(k);

    if FAST_DEMO
        params.Nz_total = 401;
        params.T_total  = 10;
        params.dt       = 0.01;
        params.nt       = ceil(params.T_total/params.dt);
    end

    params.output.out_dir    = fullfile(pwd, 'results', sprintf('lambda_%0.2f', lambdas(k)));
    params.output.figure_dir = fullfile(params.output.out_dir, 'figures');
    params.output.figures    = {'tension'};
    params.output.save_fig   = true;

    result = ctXsfSolveVIV(params);

    zD   = result.z_paper;
    yRMS = [yRMS, result.rms_Y_dyn/params.D];              %#ok<AGROW>
    dN   = [dN, result.DeltaN];                            %#ok<AGROW>

    summary(end+1, :) = {lambdas(k), max(result.rms_Y_dyn)/params.D, ...
        max(result.DeltaN), max(result.std_Mres), max(result.max_sigma_b)}; %#ok<AGROW>

    ctXsfReport(result, params.output);
    close all;      % keep each case folder free of the previous case figures
end

T = cell2table(summary, 'VariableNames', ...
    {'lambda_DeltaN', 'MaxCFRMS_over_D', 'MaxDeltaN_N', ...
     'MaxStdMoment_Nm', 'MaxBendingStress_Pa'});
disp(T);
writetable(T, fullfile(pwd, 'results', 'lambda_sensitivity_summary.xlsx'));

figure('Name', 'Dynamic axial-tension feedback sensitivity', 'Color', 'w', ...
       'Position', [140 150 720 470]);
plot(dN, 'LineWidth', 1.3);
xlabel('time step index', 'Interpreter', 'none');
ylabel('$\Delta N_{xy}$ (N)', 'Interpreter', 'latex');
title('Additional axial tension, \lambda_{DeltaN} sweep', 'Interpreter', 'tex');
legend(arrayfun(@(x) sprintf('\\lambda = %.2f', x), lambdas, 'UniformOutput', false), ...
       'Location', 'best');
grid on; set(gca, 'FontName', 'Times New Roman', 'FontSize', 11);

%EXAMPLE_02_VIV_SHEAR_FLOW  Two-degree-of-freedom VIV in a sheared current.
%
%   Reference case of the paper: ultra-slender cylinder, L/D = 2000, linear
%   shear inflow, pinned-pinned supports and vibration-induced axial-tension
%   feedback.  The example shows how to select the exported information.

clear; clc; close all;
ctXsfSetup;

FAST_DEMO = true;      % false -> paper mesh / record length (long runtime)

params = ctXsfDefaultParams();

% ---- [A] rod, [B] fluid, [C] flow -----------------------------------
params.D  = 0.02;                       % rod diameter            [A]
params.L  = 40.0;                       % rod length, L/D = 2000  [A]
params.rho = 1000;                      % water density           [B]

params.flow_profile = 'linear_shear';   % flow shape              [C]
params.U_top = 0.5;                     % top current speed       [C]
params.beta  = 0.7;                     % shear intensity         [C]
params.U_bottom = (1 - params.beta) * params.U_top;

% ---- [D] boundary ----------------------------------------------------
params.boundary_preset = 'pinned_pinned';

% ---- [F] tension -----------------------------------------------------
params.N_top = 2.45e2;                  % top static tension (N)
params.use_variable_tension = true;
params.lambda_DeltaN = 1.0;             % full axial-tension feedback

% ---- [G] numerical ---------------------------------------------------
if FAST_DEMO
    params.Nz_total = 401;
    params.T_total  = 10;
    params.dt       = 0.01;
end
params.nt = ceil(params.T_total/params.dt);

% ---- [H] output selection --------------------------------------------
params.output.out_dir    = fullfile(pwd, 'results', 'viv_shear_flow');
params.output.figure_dir = fullfile(params.output.out_dir, 'figures');
params.output.save_fig   = true;
params.output.figures    = {'displacement', 'internal_force', 'fatigue', 'tension'};
% use {'all'} to obtain every figure group, or a subset such as
% {'fatigue'} when only the stress-demand information is needed.

% ---- run -------------------------------------------------------------
result = ctXsfSolveVIV(params);

fprintf('\n===== Key results =====\n');
fprintf('max in-line   RMS x/D   = %.4f\n', max(result.rms_X_dyn)/params.D);
fprintf('max cross-flow RMS y/D  = %.4f  at z/D = %.1f\n', ...
    max(result.rms_Y_dyn)/params.D, result.Z_cf_max_over_D);
fprintf('max std(M_res)          = %.6e N m\n', max(result.std_Mres));
fprintf('max std(Q_res)          = %.6e N\n',   max(result.std_Qres));
fprintf('max bending stress      = %.6e Pa\n',  max(result.max_sigma_b));
fprintf('max shear stress        = %.6e Pa\n',  max(result.max_tau_Q));

ctXsfReport(result, params.output);

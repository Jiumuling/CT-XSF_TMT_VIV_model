%EXAMPLE_05_CUSTOM_PARAMETERS  User-defined rod, fluid, flow and boundary data.
%
%   Demonstrates how a user replaces every physical input group of the model:
%   a hollow pipe, a different fluid, a non-uniform current profile and a
%   semi-rigid elastic support, with a reduced, selectable output set.

clear; clc; close all;
ctXsfSetup;

params = ctXsfDefaultParams();

% ---- [A] rod / pipe --------------------------------------------------
params.section_type = 'hollow';        % 'solid' or 'hollow'
params.D = 0.05;                        % outer diameter (m)
params.d = 0.04;                        % inner diameter (m)
params.L = 25.0;                        % length (m)
params.rhos = 7850;                     % steel
params.E    = 2.10e11;                  % Young's modulus (Pa)
params.nu   = 0.30;

% ---- [B] fluid -------------------------------------------------------
params.rho       = 1025;                % sea water (kg/m^3)
params.rho_inner = 1025;                % flooded pipe
params.eta       = 1.0;                 % added-mass coefficient

% ---- [C] flow / flow profile -----------------------------------------
params.flow_profile = 'custom';         % arbitrary measured profile
params.flow_profile_z = [0; 0.5*params.L; params.L];   % 0 = top end
params.flow_profile_U = [1.20; 0.85; 0.45];            % m/s
params.U_top    = params.flow_profile_U(1);            % reporting only
params.U_bottom = params.flow_profile_U(end);

% ---- [D] boundary ----------------------------------------------------
params.boundary_preset       = 'semi_rigid_both';
params.bcPreset.KthetaFactor = 15.0;    % end rotation stiffness = 15*EI/L
params.bcPreset.Ctheta       = 0.0;

% ---- [F] tension -----------------------------------------------------
params.N_top = 1.0e5;                   % top static tension (N)
params.include_submerged_weight = true; % static tension varies with depth
% params.include_submerged_weight = false;  % constant static tension instead

% ---- [G] numerical (reduced for a quick illustration) ----------------
params.Nz_total = 401;
params.T_total  = 10;
params.dt       = 0.01;
params.nt       = ceil(params.T_total/params.dt);

% ---- [H] output selection --------------------------------------------
params.output.out_dir    = fullfile(pwd, 'results', 'custom_pipe_case');
params.output.figure_dir = fullfile(params.output.out_dir, 'figures');
params.output.figures    = {'displacement', 'internal_force', 'fatigue'};
params.output.save_fig   = true;
params.output.export     = true;

% ---- modal check first, then the VIV response ------------------------
params.CL0 = 0;
modal = ctXsfSolveVIV(params);
fprintf('\nFirst natural frequency in still water: %.4f Hz\n', modal.freq_Hz(1));

params.CL0 = 0.3;
result = ctXsfSolveVIV(params);
ctXsfReport(result, params.output);

fprintf('\nmax cross-flow RMS y/D = %.4f\n', max(result.rms_Y_dyn)/params.D);
fprintf('max bending stress     = %.6e Pa\n', max(result.max_sigma_b));

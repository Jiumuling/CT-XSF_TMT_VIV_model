%EXAMPLE_06_FATIGUE_RAINFLOW  Selectable rainflow fatigue-demand screening.
%
%   Shows the fatigue post-processing module:
%     * which part of the record is used for the statistics and which part is
%       retained for the space-time / fatigue window;
%     * how to choose the S-N slopes, the circumferential resolution and the
%       spanwise regions of the relative cyclic stress-demand index;
%     * how to obtain only the fatigue figures/tables.
%
%   The index is a RELATIVE hotspot-ranking indicator.  It is not an absolute
%   fatigue life: no material S-N constant, mean-stress correction or
%   long-term environmental scatter is included.

clear; clc; close all;
ctXsfSetup;

%% ---- case definition --------------------------------------------------
params = ctXsfDefaultParams();

params.boundary_preset = 'semi_rigid_both';
params.bcPreset.KthetaFactor = 30;

% numerical settings (all user-selectable)
params.Nz_total = 401;        % spanwise grid
params.dt       = 0.01;       % time step (s)
params.T_total  = 10;         % simulated record length (s)
params.nt       = ceil(params.T_total/params.dt);

% post-processing windows
params.rms_tail_fraction  = 0.30;   % statistics: last 30% of the record
params.tail_time_fraction = 0.30;   % retained space-time window: last 30%
params.SaveStride         = 1;      % store every step of the tail window
% NOTE: the rainflow screening needs a sufficiently fine retained tail.
% The sampling check prints the required dt_save; a rule of thumb is
%   dt_save <= 1 / (20 * f_required),   f_required ~ St*U_max/D.

% ---- fatigue module options ------------------------------------------
params.fatigue.enable    = true;
params.fatigue.m_values  = [3 5];       % S-N slopes of the relative index
params.fatigue.n_phi     = 72;          % circumferential search resolution
params.fatigue.regions_z_over_D_paper = [0 100; 100 1900; 1900 2000];
params.fatigue.region_names = {'bottom_0_100D','mid_100_1900D','top_1900_2000D'};

% ---- output selection -------------------------------------------------
params.output.out_dir    = fullfile(pwd, 'results', 'fatigue_rainflow');
params.output.figure_dir = fullfile(params.output.out_dir, 'figures');
params.output.figures    = {'fatigue'};   % only the fatigue group
params.output.save_fig   = true;
params.output.export     = true;

%% ---- run the protected core solver ------------------------------------
result = ctXsfSolveVIV(params);

%% ---- standalone fatigue screening (same result, custom options) -------
fatigue = ctXsfFatigueRainflow(result, params);
fprintf('\nReturned fatigue fields: %s\n', strjoin(fieldnames(fatigue), ', '));

fprintf('\nRelative bending rainflow demand (m = %g):\n', fatigue.m_values(1));
fprintf('  peak at z/D = %.1f, critical circumferential angle = %.1f deg\n', ...
    fatigue.z_paper(find(fatigue.Db_rel(:,1) == max(fatigue.Db_rel(:,1)), 1)), ...
    fatigue.phi_critical_rad(find(fatigue.Db_rel(:,1) == max(fatigue.Db_rel(:,1)), 1),1)*180/pi);

disp(fatigue.regionTable);
disp(fatigue.samplingTable);

%% ---- report layer: fatigue figures and tables -------------------------
out = ctXsfReport(result, params.output);
fprintf('\nFatigue report figures and tables written to:\n  %s\n', out.figure_dir);

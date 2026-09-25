%EXAMPLE_01_MODAL_ANALYSIS  Natural frequencies of the mixed Timoshenko model.
%
%   Runs the modal branch of the solver (params.CL0 = 0), i.e. no time-domain
%   VIV calculation, and reports the first natural frequencies together with
%   the mode chart.
%
%   Both dry (in air) and still-water conditions are evaluated so that the
%   effect of the external added mass can be compared directly.

clear; clc; close all;
ctXsfSetup;

boundaries = {'pinned_pinned', 'clamped_clamped', 'semi_rigid_both'};

fprintf('\n===== Modal analysis of the mixed Timoshenko system =====\n');

for k = 1:numel(boundaries)

    params = ctXsfDefaultParams();
    params.CL0             = 0;                 % modal branch
    params.Nz_total        = 201;               % small grid is sufficient
    params.boundary_preset = boundaries{k};
    params.modal_environment = 'water';         % 'water' or 'air'
    params.modal_n_modes   = 5;

    params.output.out_dir    = fullfile(pwd, 'results', ['modal_', boundaries{k}]);
    params.output.figure_dir = fullfile(params.output.out_dir, 'figures');
    params.output.figures    = {'modal'};
    params.output.save_fig   = true;

    result = ctXsfSolveVIV(params);
    ctXsfReport(result, params.output);

    fprintf('\n%-16s first %d natural frequencies (Hz): ', ...
        boundaries{k}, numel(result.freq_Hz));
    fprintf('%.4f  ', result.freq_Hz);
    fprintf('\n');
end

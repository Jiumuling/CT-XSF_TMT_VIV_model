function files = ctXsfReportExport(result, o)
%CTXSFREPORTEXPORT  Write the key results to Excel and MAT files.
%
%   FILES = CTXSFREPORTEXPORT(RESULT, O) writes
%     <prefix>_key_metrics.xlsx        scalar metrics of the run
%     <prefix>_spanwise_profiles.xlsx  spanwise displacement / force profiles
%     <prefix>_fatigue_indicators.xlsx stress indicators along the span
%     <prefix>_axial_tension_history.xlsx  dynamic axial-tension histories
%     <prefix>_summary.mat             the complete result structure
%   and returns the list of created files.

files = {};
D     = result.params.D;

%% ---- key metrics -----------------------------------------------------
metrics = {};
metrics(end+1, :) = {'CaseID', result.case_id};                        %#ok<AGROW>
metrics(end+1, :) = {'Mode', result.mode};                             %#ok<AGROW>
if isfield(result, 'freq_Hz') && ~isempty(result.freq_Hz)
    metrics(end+1, :) = {'FirstNaturalFrequency_Hz', result.freq_Hz(1)};%#ok<AGROW>
else
    metrics(end+1, :) = {'L_over_D', result.params.L/D};               %#ok<AGROW>
    metrics(end+1, :) = {'BoundaryPreset', result.params.boundary_preset}; %#ok<AGROW>
    metrics(end+1, :) = {'BC_left', result.params.bc.left.type};       %#ok<AGROW>
    metrics(end+1, :) = {'BC_right', result.params.bc.right.type};     %#ok<AGROW>
    metrics(end+1, :) = {'FlowProfile', result.params.flow_profile};   %#ok<AGROW>
    metrics(end+1, :) = {'U_top_m_s', result.params.U_top};            %#ok<AGROW>
    metrics(end+1, :) = {'beta', result.params.beta};                  %#ok<AGROW>
    metrics(end+1, :) = {'N_top_N', result.params.N_top};              %#ok<AGROW>
    metrics(end+1, :) = {'lambda_DeltaN', result.params.lambda_DeltaN};%#ok<AGROW>
    metrics(end+1, :) = {'Nz_total', result.params.Nz_total};          %#ok<AGROW>
    metrics(end+1, :) = {'dt_s', result.params.dt};                    %#ok<AGROW>
    metrics(end+1, :) = {'T_total_s', result.params.T_total};          %#ok<AGROW>
    metrics(end+1, :) = {'rms_tail_fraction', result.params.rms_tail_fraction}; %#ok<AGROW>
    metrics(end+1, :) = {'MaxILRMS_over_D', max(result.rms_X_dyn)/D};  %#ok<AGROW>
    metrics(end+1, :) = {'MaxCFRMS_over_D', max(result.rms_Y_dyn)/D};  %#ok<AGROW>
    metrics(end+1, :) = {'zD_at_MaxCFRMS', result.Z_cf_max_over_D};    %#ok<AGROW>
    metrics(end+1, :) = {'MaxStdMoment_Nm', max(result.std_Mres)};     %#ok<AGROW>
    metrics(end+1, :) = {'MaxStdShear_N', max(result.std_Qres)};       %#ok<AGROW>
    metrics(end+1, :) = {'MaxBendingStress_Pa', max(result.max_sigma_b)}; %#ok<AGROW>
    metrics(end+1, :) = {'MaxShearStress_Pa', max(result.max_tau_Q)};  %#ok<AGROW>
    metrics(end+1, :) = {'MaxDeltaN_N', max(result.DeltaN)};           %#ok<AGROW>
    metrics(end+1, :) = {'MeanDeltaN_statWindow_N', ...
        mean(result.DeltaN(max(1, floor((1-result.params.rms_tail_fraction)*numel(result.DeltaN))):end))}; %#ok<AGROW>
end
metrics(end+1, :) = {'ElapsedTime_s', result.elapsed_time};            %#ok<AGROW>

T = cell2table(metrics, 'VariableNames', {'Metric', 'Value'});
xls = fullfile(o.out_dir, sprintf('%s_key_metrics.xlsx', o.prefix));
writetable(T, xls);
files{end+1} = xls;

%% ---- spanwise profiles ----------------------------------------------
T = table(result.z_paper, ...
          result.rms_X_dyn/D, result.rms_Y_total/D, result.rms_Y_dyn/D, ...
          result.std_MomentX, result.std_MomentY, result.std_Mres, ...
          result.std_ShearX,  result.std_ShearY,  result.std_Qres, ...
          result.max_Mres, result.max_Qres, result.max_sigma_b, result.max_tau_Q, ...
    'VariableNames', ...
    {'z_over_D', 'x_rms_dyn_over_D', 'y_rms_total_over_D', 'y_rms_dyn_over_D', ...
     'std_MomentX_Nm', 'std_MomentY_Nm', 'std_Moment_res_Nm', ...
     'std_ShearX_N', 'std_ShearY_N', 'std_Shear_res_N', ...
     'max_Moment_res_Nm', 'max_Shear_res_N', 'max_sigma_b_Pa', 'max_tau_Q_Pa'});
xls = fullfile(o.out_dir, sprintf('%s_spanwise_profiles.xlsx', o.prefix));
writetable(T, xls);
files{end+1} = xls;

%% ---- fatigue indicators ---------------------------------------------
if isfield(result, 'sigma_b_tail') && ~isempty(result.sigma_b_tail)
    T = table(result.z_paper, ...
              result.max_sigma_b, std(result.sigma_b_tail, 0, 1).', ...
              result.max_tau_Q,   std(result.tau_Q_tail, 0, 1).', ...
        'VariableNames', ...
        {'z_over_D', 'max_sigma_b_Pa', 'std_sigma_b_Pa', ...
         'max_tau_Q_Pa', 'std_tau_Q_Pa'});
    xls = fullfile(o.out_dir, sprintf('%s_fatigue_indicators.xlsx', o.prefix));
    writetable(T, xls);
    files{end+1} = xls;
end

%% ---- axial-tension history ------------------------------------------
if isfield(result, 'DeltaN') && ~isempty(result.DeltaN)
    tt = (1:numel(result.DeltaN)).' * result.params.dt;
    T = table(tt, result.DeltaNx_vector, result.DeltaNy_vector, ...
              result.DeltaNxy_vector, result.DeltaN_used_vector, ...
              result.Ntop_eff_vector, result.Nbot_eff_vector, ...
        'VariableNames', ...
        {'time_s', 'DeltaNx_N', 'DeltaNy_N', 'DeltaNxy_N', ...
         'DeltaN_used_N', 'Ntop_eff_N', 'Nbot_eff_N'});
    xls = fullfile(o.out_dir, sprintf('%s_axial_tension_history.xlsx', o.prefix));
    writetable(T, xls);
    files{end+1} = xls;
end

%% ---- regional internal-force hotspot table (if provided) -------------
if isfield(result, 'trueAssumedHotspotTable') && ~isempty(result.trueAssumedHotspotTable)
    xls = fullfile(o.out_dir, sprintf('%s_internal_force_hotspots.xlsx', o.prefix));
    writetable(result.trueAssumedHotspotTable, xls);
    files{end+1} = xls;
end

%% ---- complete result -------------------------------------------------
matf = fullfile(o.out_dir, sprintf('%s_summary.mat', o.prefix));
try
    save(matf, 'result', '-v7.3');
    files{end+1} = matf;
catch ME
    warning('ctXsfReportExport:mat', 'Could not save %s: %s', matf, ME.message);
end

fprintf('\nCTXSF report exports written to: %s\n', o.out_dir);
for k = 1:numel(files)
    fprintf('  %s\n', files{k});
end
end

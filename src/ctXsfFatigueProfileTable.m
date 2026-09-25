function T = ctXsfFatigueProfileTable(fatigue, f) %#ok<INUSD>
%CTXSFFATIGUEPROFILETABLE  Spanwise fatigue-demand profile table.

mVals = fatigue.m_values(:).';

sigma_b_norm  = normByMax(fatigue.sigma_b_res_std);
tau_Q_norm    = normByMax(fatigue.tau_Q_std);
sigma_eq_norm = normByMax(fatigue.sigma_eq_std);

vars = {fatigue.z_m, fatigue.z_over_D_internal, fatigue.z_paper, ...
        fatigue.sigma_b_res_std, fatigue.tau_Q_std, fatigue.sigma_eq_std, ...
        sigma_b_norm, tau_Q_norm, sigma_eq_norm, ...
        fatigue.Y_rms_dyn_over_D, fatigue.Y_rms_dyn_norm};
names = {'z_m', 'z_over_D_internal', 'z_over_D_paper_bottom0_topLD', ...
         'std_sigma_b_res_Pa', 'std_tau_Q_Pa', 'std_sigma_eq_Pa', ...
         'std_sigma_b_res_norm', 'std_tau_Q_norm', 'std_sigma_eq_norm', ...
         'Y_rms_dyn_over_D', 'Y_rms_dyn_norm'};

for im = 1:numel(mVals)
    tag = sprintf('m%g', mVals(im));
    vars{end+1}  = fatigue.Db_rel(:, im);                       %#ok<AGROW>
    names{end+1} = ['Db_rel_' tag];                             %#ok<AGROW>
    vars{end+1}  = fatigue.Deq_rel(:, im);                      %#ok<AGROW>
    names{end+1} = ['Deq_rel_' tag];                            %#ok<AGROW>
    vars{end+1}  = fatigue.phi_critical_rad(:, im) * 180/pi;    %#ok<AGROW>
    names{end+1} = ['phi_critical_deg_' tag];                   %#ok<AGROW>
end

T = table(vars{:}, 'VariableNames', names);
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

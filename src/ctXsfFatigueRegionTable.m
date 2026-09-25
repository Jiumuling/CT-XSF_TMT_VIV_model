function T = ctXsfFatigueRegionTable(fatigue, f)
%CTXSFFATIGUEREGIONTABLE  Regional summary of the relative fatigue demand.
%
%   For every spanwise region (given in paper coordinates, bottom = 0,
%   top = L/D) the table reports the regional peak of the normalised bending
%   and equivalent-stress rainflow demand for each S-N slope, the location of
%   that peak, and the normalised displacement and stress standard deviations.

regions = f.regions_z_over_D_paper;
names   = f.region_names;
mVals   = fatigue.m_values(:).';

z = fatigue.z_paper;

q_b   = normByMax(fatigue.sigma_b_res_std);
q_tau = normByMax(fatigue.tau_Q_std);
q_eq  = normByMax(fatigue.sigma_eq_std);

rows = {};
for ir = 1:size(regions, 1)
    m = z >= regions(ir,1) & z <= regions(ir,2);
    if ~any(m)
        continue
    end
    zl = z(m);

    for im = 1:numel(mVals)
        [vb, ib] = max(fatigue.Db_rel(m, im));
        [ve, ie] = max(fatigue.Deq_rel(m, im));

        rows(end+1, :) = {fatigue.case_id, names{ir}, mVals(im), ...
            regions(ir,1), regions(ir,2), ...
            vb, zl(ib), fatigue.phi_critical_rad(find(m,1)+ib-1, im)*180/pi, ...
            ve, zl(ie), ...
            max(q_b(m)),   max(q_tau(m)), max(q_eq(m)), ...
            max(fatigue.Y_rms_dyn_norm(m))}; %#ok<AGROW>
    end
end

T = cell2table(rows, 'VariableNames', ...
    {'CaseID', 'Region', 'm', 'zD_region_min', 'zD_region_max', ...
     'Db_rel_peak', 'zD_at_Db_peak', 'phi_critical_deg_at_Db_peak', ...
     'Deq_rel_peak', 'zD_at_Deq_peak', ...
     'std_sigma_b_norm_max', 'std_tau_Q_norm_max', 'std_sigma_eq_norm_max', ...
     'Y_rms_dyn_norm_max'});
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

function ctXsfFatigueSummary(fatigue)
%CTXSFFATIGUESUMMARY  Print the rainflow fatigue-demand summary.

fprintf('\n===== Rainflow-based relative fatigue-demand summary =====\n');
fprintf('Case: %s\n', fatigue.case_id);
fprintf('Tail window: %d samples, dt_save = %.6g s, spanwise nodes = %d\n', ...
    numel(fatigue.T_tail), fatigue.dt_save, numel(fatigue.z_m));
fprintf('%s\n', fatigue.description);
fprintf('\nSampling check: %s\n', fatigue.sampling.status);
fprintf('  f_required (max of vortex shedding and spectral content) = %.6g Hz\n', ...
    fatigue.sampling.f_required);
fprintf('  samples per shortest period = %.3f (rule: >= %d adequate, >= %d marginal)\n', ...
    fatigue.sampling.samples_per_shortest_period, ...
    fatigue.sampling.min_samples_per_period, ...
    fatigue.sampling.warning_samples_per_period);
if ~fatigue.sampling.is_adequate_20
    dt_needed = 1/(fatigue.sampling.min_samples_per_period * fatigue.sampling.f_required);
    fprintf(['  --> the 20-sample rule needs dt_save <= %.6g s; reduce params.dt\n' ...
             '      or params.SaveStride to store the tail more densely.\n'], dt_needed);
end

for im = 1:numel(fatigue.m_values)
    m = fatigue.m_values(im);
    [vb, ib] = max(fatigue.Db_rel(:, im));
    [ve, ie] = max(fatigue.Deq_rel(:, im));
    fprintf('\nm = %g:\n', m);
    fprintf('  bending      peak D_b^rel  = 1.000 at z/D = %.1f (critical angle %.1f deg)\n', ...
        fatigue.z_paper(ib), fatigue.phi_critical_rad(ib, im)*180/pi);
    fprintf('  equivalent   peak D_eq^rel = %.3f at z/D = %.1f\n', ve, fatigue.z_paper(ie));

    [~, iY] = max(fatigue.Y_rms_dyn_norm);
    if im == 1 && isfinite(fatigue.Y_rms_dyn_norm(iY))
        Db_at_Y = fatigue.Db_rel(iY, im);
        fprintf('  displacement peak Y_rms/D at z/D = %.1f, where D_b^rel = %.3f\n', ...
            fatigue.z_paper(iY), Db_at_Y);
    end
end
fprintf('\nNote: this index ranks cyclic stress-demand hotspots. It is not an\n');
fprintf('absolute fatigue life and does not include material S-N constants,\n');
fprintf('mean-stress correction or long-term environmental scatter.\n');
end

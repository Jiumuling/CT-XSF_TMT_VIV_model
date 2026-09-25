function T = ctXsfFatigueHotspotTable(fatigue, f)
%CTXSFFATIGUEHOTSPOTTABLE  Global and regional fatigue-demand hotspots.
%
%   One row per (indicator, S-N slope, region) with the peak of the normalised
%   rainflow demand, its location and the critical circumferential angle.

regions = f.regions_z_over_D_paper;
names   = f.region_names;
mVals   = fatigue.m_values(:).';
z       = fatigue.z_paper;

rows = {};

for im = 1:numel(mVals)
    % ---- global hotspots ------------------------------------------
    [vb, ib] = max(fatigue.Db_rel(:, im));
    rows(end+1, :) = {fatigue.case_id, 'bending', mVals(im), 'global', ...
        vb, z(ib), fatigue.phi_critical_rad(ib, im)*180/pi, ...
        'peak of the normalised bending-stress rainflow demand'}; %#ok<AGROW>

    [ve, ie] = max(fatigue.Deq_rel(:, im));
    rows(end+1, :) = {fatigue.case_id, 'equivalent', mVals(im), 'global', ...
        ve, z(ie), NaN, ...
        'peak of the normalised equivalent-stress rainflow demand'}; %#ok<AGROW>

    % ---- regional hotspots ----------------------------------------
    for ir = 1:size(regions, 1)
        m = z >= regions(ir,1) & z <= regions(ir,2);
        if ~any(m)
            continue
        end
        zl = z(m);

        [vb, ib] = max(fatigue.Db_rel(m, im));
        rows(end+1, :) = {fatigue.case_id, 'bending', mVals(im), names{ir}, ...
            vb, zl(ib), fatigue.phi_critical_rad(find(m,1)+ib-1, im)*180/pi, ...
            'regional peak of the bending-stress rainflow demand'}; %#ok<AGROW>

        [ve, ie] = max(fatigue.Deq_rel(m, im));
        rows(end+1, :) = {fatigue.case_id, 'equivalent', mVals(im), names{ir}, ...
            ve, zl(ie), NaN, ...
            'regional peak of the equivalent-stress rainflow demand'}; %#ok<AGROW>
    end
end

T = cell2table(rows, 'VariableNames', ...
    {'CaseID', 'Indicator', 'm', 'Region', 'PeakRelativeDemand', ...
     'zD_paper_at_peak', 'phi_critical_deg', 'Interpretation'});
end

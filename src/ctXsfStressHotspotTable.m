function T = ctXsfStressHotspotTable(result)
%CTXSFSTRESSHOTSPOTTABLE  Regional maxima of the stress indicators.
%
%   T = CTXSFSTRESSHOTSPOTTABLE(RESULT) returns a table with the maximum
%   bending and shear stress in the bottom, middle and top regions of the
%   span, in the paper style of the true-vs-assumed internal-force table.

T = table();
z = result.z_paper;

if ~isfield(result, 'max_sigma_b') || isempty(result.max_sigma_b)
    return
end

LoverD  = result.params.L / result.params.D;
regions = {'bottom', 'middle', 'top'};
edges   = [0, 100; 100, max(100, LoverD - 100); max(0, LoverD - 100), LoverD];

rows = {};
for r = 1:size(edges, 1)
    m = z >= edges(r,1) & z <= edges(r,2);
    if ~any(m); continue; end
    sig = result.max_sigma_b(m);
    tau = result.max_tau_Q(m);
    [sm, is] = max(sig);
    [tm, it] = max(tau);
    zl = z(m);
    rows(end+1, :) = {regions{r}, sm, zl(is), tm, zl(it)}; %#ok<AGROW>
end

if isempty(rows)
    return
end

T = cell2table(rows, 'VariableNames', ...
    {'Region', 'MaxBendingStress_Pa', 'zD_at_MaxSigma', ...
     'MaxShearStress_Pa', 'zD_at_MaxTau'});
end

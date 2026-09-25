function f = ctXsfFatigueOptions(result, opts)
%CTXSFFATIGUEOPTIONS  Normalise the options of the rainflow fatigue module.
%
%   The options may be given as params.fatigue, as a dedicated struct, or not
%   at all.  Defaults are taken from params.fatigue when available.

f = struct();
f.enable                 = true;
f.make_figures           = true;
f.m_values               = [3, 5];
f.n_phi                  = 36;
f.regions_z_over_D_paper = [];
f.region_names           = {};
f.min_samples_per_period = 20;
f.warning_samples_per_period = 10;
f.psd_power_threshold    = 0.05;

% ---- defaults carried by the run itself ------------------------------
if isfield(result, 'params') && isfield(result.params, 'fatigue') ...
        && isstruct(result.params.fatigue)
    f = mergeFields(f, result.params.fatigue);
end

% ---- explicit user options -------------------------------------------
if nargin >= 2 && ~isempty(opts)
    if isstruct(opts) && isfield(opts, 'fatigue') && isstruct(opts.fatigue)
        f = mergeFields(f, opts.fatigue);
    elseif isstruct(opts)
        f = mergeFields(f, opts);
    end
end

f.m_values = f.m_values(:).';
f.n_phi    = max(4, round(f.n_phi));

% ---- automatic spanwise regions --------------------------------------
if isempty(f.regions_z_over_D_paper)
    LoverD = result.params.L / result.params.D;

    % The end-region width follows the same user-selectable rule as the
    % internal-force hotspot table:
    %   params.hotspot_region_edge_zD   (explicit boundary, z/D)
    %   params.hotspot_region_fraction  (fraction of the span, default 2.5%)
    % With hotspot_region_fraction = 0.05 and L/D = 2000 the published
    % regions 0--100 / 100--1900 / 1900--2000 are recovered.
    params = ctXsfGetField(result, 'params', struct());
    if isfield(params, 'hotspot_region_edge_zD') && ~isempty(params.hotspot_region_edge_zD)
        edge = params.hotspot_region_edge_zD;
    else
        frac = 0.025;
        if isfield(params, 'hotspot_region_fraction') && ~isempty(params.hotspot_region_fraction)
            frac = params.hotspot_region_fraction;
        end
        edge = frac * LoverD;
    end
    edge = min(max(edge, 0), 0.49*LoverD);

    f.regions_z_over_D_paper = [0, edge; edge, LoverD - edge; LoverD - edge, LoverD];
end
if isempty(f.region_names)
    nR = size(f.regions_z_over_D_paper, 1);
    f.region_names = cell(1, nR);
    for r = 1:nR
        f.region_names{r} = sprintf('region_%d_%gD_to_%gD', r, ...
            f.regions_z_over_D_paper(r,1), f.regions_z_over_D_paper(r,2));
    end
end
end

function a = mergeFields(a, b)
names = fieldnames(b);
for k = 1:numel(names)
    if ~isempty(b.(names{k})) || ischar(b.(names{k})) || iscell(b.(names{k}))
        a.(names{k}) = b.(names{k});
    end
end
end

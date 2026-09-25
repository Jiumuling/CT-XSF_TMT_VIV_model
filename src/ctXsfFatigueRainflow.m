function fatigue = ctXsfFatigueRainflow(result, opts)
%CTXSFFATIGUERAINFLOW  Rainflow-based relative cyclic stress-demand screening.
%
%   FATIGUE = CTXSFFATIGUERAINFLOW(RESULT) analyses the retained tail window
%   of a VIV run and ranks the spanwise cyclic stress demand of
%
%     * the bending stress at the critical circumferential fibre,
%           sigma_b(phi) = (D/2)/I * ( Mx cos(phi) + My sin(phi) )
%     * the equivalent (von Mises-type) stress
%           sigma_eq = sqrt( sigma_b,res^2 + 3 tau_Q^2 )
%
%   using rainflow cycle counting, a Palmgren-Miner summation and S-N slopes
%   m = 3 and m = 5 by default.
%
%       D_b(m)  = sum over cycles of  count * range^m        (bending)
%       D_eq(m) = sum over cycles of  count * range^m        (equivalent)
%
%   Each index is normalised by its own maximum along the span, so the result
%   is a RELATIVE hotspot-ranking indicator.  It is not an absolute fatigue
%   life: no material constant, mean-stress correction, thickness correction
%   or scatter diagram is introduced.
%
%   FATIGUE = CTXSFFATIGUERAINFLOW(RESULT, OPTS) accepts
%
%       opts.fatigue.m_values               S-N slopes (default [3 5])
%       opts.fatigue.n_phi                  circumferential samples (default 36)
%       opts.fatigue.regions_z_over_D_paper spanwise regions, z/D bottom = 0
%       opts.fatigue.region_names           names of those regions
%       opts.fatigue.min_samples_per_period sampling rule (default 20)
%       opts.fatigue.psd_power_threshold    spectral significance threshold
%
%   See also CTXSFREPORTFATIGUE, CTXSFRAINFLOWRANGES.

f = ctXsfFatigueOptions(result, opts);

T_tail   = result.t_tail(:);
Z_plot   = result.z(:);
params   = result.params;

Mx = double(result.MomentX_tail);
My = double(result.MomentY_tail);
Qx = double(result.ShearX_tail);
Qy = double(result.ShearY_tail);

if size(Mx,1) < 8
    error('ctXsfFatigueRainflow:tooShort', ...
          'The retained tail window is too short for rainflow counting.');
end

r    = params.D/2;
I    = params.I;
A    = params.A;
chiQ = ctXsfGetField(ctXsfGetField(result, 'params', struct()), 'output', struct());
chiQ = ctXsfGetField(chiQ, 'tau_shear_factor', 4/3);

nT = size(Mx, 1);
Nz = numel(Z_plot);

z_internal_D = Z_plot / params.D;
z_paper      = (params.L - Z_plot) / params.D;

m_values = f.m_values(:).';
nM       = numel(m_values);
phi_vec  = linspace(0, 2*pi, f.n_phi + 1);
phi_vec(end) = [];

Mres_tail = sqrt(Mx.^2 + My.^2);
Qres_tail = sqrt(Qx.^2 + Qy.^2);

sigma_b_res_tail = Mres_tail * r / I;
tau_Q_tail       = chiQ * Qres_tail / A;
sigma_eq_tail    = sqrt(sigma_b_res_tail.^2 + 3*tau_Q_tail.^2);

fprintf('\n===== Rainflow-based relative fatigue-demand screening =====\n');
fprintf('Tail samples = %d, spanwise nodes = %d, circumferential samples = %d\n', ...
    nT, Nz, f.n_phi);
fprintf('S-N slopes of the relative demand index: %s\n', mat2str(m_values));

Db_raw        = zeros(Nz, nM);
Deq_raw       = zeros(Nz, nM);
phi_critical  = zeros(Nz, nM);

for iz = 1:Nz
    Mxsec = Mx(:, iz);
    Mysec = My(:, iz);

    bestDamage = zeros(1, nM);
    bestPhi    = zeros(1, nM);

    for ip = 1:f.n_phi
        phi = phi_vec(ip);
        sigma_b_signed = (r/I) * (Mxsec*cos(phi) + Mysec*sin(phi));
        [ranges_b, counts_b] = ctXsfRainflowRanges(sigma_b_signed);

        if ~isempty(ranges_b)
            for im = 1:nM
                damage = sum(counts_b .* (ranges_b.^m_values(im)));
                if damage > bestDamage(im)
                    bestDamage(im) = damage;
                    bestPhi(im)    = phi;
                end
            end
        end
    end

    Db_raw(iz, :)       = bestDamage;
    phi_critical(iz, :) = bestPhi;

    sig_eq = sigma_eq_tail(:, iz);
    sig_eq = sig_eq - mean(sig_eq, 'omitnan');
    [ranges_eq, counts_eq] = ctXsfRainflowRanges(sig_eq);

    if ~isempty(ranges_eq)
        for im = 1:nM
            Deq_raw(iz, im) = sum(counts_eq .* (ranges_eq.^m_values(im)));
        end
    end
end

Db_rel  = zeros(size(Db_raw));
Deq_rel = zeros(size(Deq_raw));
for im = 1:nM
    Db_rel(:, im)  = ctXsfNormalizeByMax(Db_raw(:, im));
    Deq_rel(:, im) = ctXsfNormalizeByMax(Deq_raw(:, im));
end

fatigue = struct();
fatigue.case_id  = ctXsfGetField(result, 'case_id', 'case');
fatigue.description = ['Rainflow-based relative cyclic stress-demand screening. ' ...
    'The index ranks spanwise hotspots only and is not an absolute fatigue-life prediction.'];
fatigue.T_tail              = T_tail;
fatigue.dt_save             = median(diff(T_tail));
fatigue.z_m                 = Z_plot;
fatigue.z_over_D_internal   = z_internal_D;
fatigue.z_paper             = z_paper;
fatigue.m_values            = m_values;
fatigue.n_phi               = f.n_phi;
fatigue.phi_vec             = phi_vec;
fatigue.Db_raw              = Db_raw;
fatigue.Deq_raw             = Deq_raw;
fatigue.Db_rel              = Db_rel;
fatigue.Deq_rel             = Deq_rel;
fatigue.phi_critical_rad    = phi_critical;
fatigue.sigma_b_res_std     = std(sigma_b_res_tail, 0, 1, 'omitnan').';
fatigue.tau_Q_std           = std(tau_Q_tail, 0, 1, 'omitnan').';
fatigue.sigma_eq_std        = std(sigma_eq_tail, 0, 1, 'omitnan').';

if isfield(result, 'rms_Y_dyn') && ~isempty(result.rms_Y_dyn)
    fatigue.Y_rms_dyn_over_D = result.rms_Y_dyn(:) / params.D;
    fatigue.Y_rms_dyn_norm   = ctXsfNormalizeByMax(fatigue.Y_rms_dyn_over_D);
else
    fatigue.Y_rms_dyn_over_D = nan(Nz, 1);
    fatigue.Y_rms_dyn_norm   = nan(Nz, 1);
end

fatigue.sampling     = ctXsfFatigueSampling(params, T_tail, Mx, My, z_paper, f);
fatigue.profileTable = ctXsfFatigueProfileTable(fatigue, f);
fatigue.regionTable  = ctXsfFatigueRegionTable(fatigue, f);
fatigue.hotspotTable = ctXsfFatigueHotspotTable(fatigue, f);
fatigue.samplingTable = ctXsfFatigueSamplingTable(fatigue);
end

function y = ctXsfNormalizeByMax(x)
x = x(:);
mx = max(x(isfinite(x)));
if isempty(mx) || mx <= 0
    y = zeros(size(x));
else
    y = x ./ mx;
end
end

function sampling = ctXsfFatigueSampling(params, T_tail, Mx, My, z_paper, f)
% Sampling adequacy of the retained tail window: the shortest period that has
% to be resolved by the stored samples is the largest of the local vortex
% shedding frequency and the significant spectral content of the data.

dt_save = median(diff(T_tail));
fs      = 1/dt_save;

f_vortex_max = params.St * max(params.U_profile(:)) / params.D;

Mres = sqrt(Mx.^2 + My.^2);
[~, iz_ref] = max(std(Mres, 0, 1, 'omitnan'));
sig = My(:, iz_ref);
if all(abs(sig - mean(sig, 'omitnan')) < eps)
    sig = Mres(:, iz_ref);
end

[f_peak, f_sig_max] = localSignificantFrequency(sig, dt_save, f.psd_power_threshold);

f_required = max([f_vortex_max, f_peak, f_sig_max]);
if ~isfinite(f_required) || f_required <= 0
    f_required = f_vortex_max;
end

samples_per_period = fs / f_required;

tol20 = max(1e-9, 1e-6*max(1, f.min_samples_per_period));
tol10 = max(1e-9, 1e-6*max(1, f.warning_samples_per_period));

is20 = samples_per_period >= (f.min_samples_per_period - tol20);
is10 = samples_per_period >= (f.warning_samples_per_period - tol10);

if is20
    status = 'ADEQUATE_20_SAMPLE_RULE';
elseif is10
    status = 'MARGINAL_10_TO_20_SAMPLE_RULE';
else
    status = 'INSUFFICIENT_FOR_RAINFLOW';
end

sampling = struct();
sampling.dt_save = dt_save;
sampling.fs = fs;
sampling.f_vortex_max = f_vortex_max;
sampling.f_peak_data = f_peak;
sampling.f_significant_max_data = f_sig_max;
sampling.f_required = f_required;
sampling.samples_per_shortest_period = samples_per_period;
sampling.min_samples_per_period = f.min_samples_per_period;
sampling.warning_samples_per_period = f.warning_samples_per_period;
sampling.is_adequate_20 = is20;
sampling.is_adequate_10 = is10;
sampling.status = status;
sampling.reference_section_z_over_D_paper = z_paper(iz_ref);
end

function [f_peak, f_sig_max] = localSignificantFrequency(x, dt, powerThreshold)
x = x(:);
x = x(isfinite(x));
f_peak = NaN;
f_sig_max = NaN;

if numel(x) < 8 || dt <= 0
    return
end

fs = 1/dt;
x  = x - mean(x);
n  = 2^nextpow2(numel(x));
win = localHann(numel(x));
X  = abs(fft(x .* win, n)).^2;
f  = (0:n-1).' * (fs/n);

nH = floor(n/2);
P  = X(1:nH);
f  = f(1:nH);

[Pmax, iPeak] = max(P);
if ~isfinite(Pmax) || Pmax <= 0
    return
end
f_peak = f(iPeak);

above    = P >= powerThreshold * Pmax;
f_sig_max = max(f(above));
end

function w = localHann(N)
% Base-MATLAB Hann window (the Signal Processing Toolbox HANN is avoided so
% that the fatigue module only needs core MATLAB).
if N <= 1
    w = ones(N, 1);
    return
end
n = (0:N-1).';
w = 0.5 * (1 - cos(2*pi*n/(N-1)));
end

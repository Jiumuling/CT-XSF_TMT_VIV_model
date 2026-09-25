# User guide

How to download the package, run your own case, and choose what is produced.

---

## 1. Requirements

* **MATLAB R2023a or newer.** The protected core is distributed as P-code, which
  is release-locked: files compiled with R2023a run in R2023a and in later
  releases, but not in earlier ones.
* **No toolbox is required.** The solver and the whole post-processing layer use
  base MATLAB only.
* The package is a few MB; the small examples run in well under a minute on a
  normal laptop.

## 2. Download and unzip

1. Open <https://github.com/Jiumuling/CT-XSF_TMT_VIV_model>
2. Click the green **Code** button and choose **Download ZIP**
   (or use `git clone https://github.com/Jiumuling/CT-XSF_TMT_VIV_model.git`)
3. Unzip it anywhere, for example `D:\CT-XSF_TMT_VIV_model`
4. In MATLAB, set the *Current Folder* to that directory

## 3. First run (four lines)

```matlab
ctXsfSetup;                          % 1. add lib/, src/ and examples/ to the path
params = ctXsfDefaultParams();       % 2. documented parameter set
result = ctXsfSolveVIV(params);      % 3. protected core solver
ctXsfReport(result, params.output);  % 4. selectable figures and tables
```

Then run one of the ready-made examples, for instance

```matlab
addpath('examples');
example_02_viv_shear_flow            % reference VIV case, linear sheared current
```

## 4. What you may edit

| Path | Controls | Editable |
|---|---|---|
| `src/ctXsfDefaultParams.m` | **all inputs** — the single parameter entry point | yes |
| your own script (copy an example) | per-run inputs and the output selection | yes |
| `src/ctXsfReport*.m` | the figures of each output group | yes |
| `src/ctXsfStyleAxes.m` | axis font / grid style shared by all figures | yes |
| `src/ctXsfReportExport.m` | which tables are exported and how they are named | yes |
| `src/ctXsfFatigue*.m` | rainflow fatigue screening and its tables | yes |
| `lib/*.p` | the numerical core solver | **no** (protected P-code) |

Typical workflow: copy `examples/example_02_viv_shear_flow.m` to `my_case.m`,
edit it, and run it. Change `src/ctXsfDefaultParams.m` instead when you want the
new value to be the *default for every script*.

## 5. Input parameters

All inputs are fields of the structure returned by `ctXsfDefaultParams`. The
full field-by-field reference is in
[parameter_reference.md](parameter_reference.md).

| Group | Meaning | Main fields (unit) |
|---|---|---|
| **A** rod | geometry and material | `D` (m), `d` inner diameter, `L` (m), `section_type` `'solid'`/`'hollow'`, `rhos` (kg/m^3), `E` (Pa), `nu`, `kappa` |
| **B** fluid | external / internal fluid | `rho`, `rho_inner` (kg/m^3), `eta` added-mass coefficient, `g` |
| **C** flow | current magnitude and shape | `flow_profile` `'uniform'`/`'linear_shear'`/`'custom'`, `U_top` (m/s), `beta`, `flow_profile_z/U`, `St` |
| **D** boundary | supports | `boundary_preset`, `bcPreset.KthetaFactor` (in units of `EI/L`), `bcPreset.KuFactor`, `bcPreset.Ctheta/Cu`, manual `bc.left/right.*` |
| **E** hydro / wake | empirical coefficients | `CL0` (**set 0 for a modal-only run**), `CD0`, `C_D`, `Ax`, `Ay`, `epsilon_x/y` |
| **F** tension | static and dynamic | `N_top` (N), `include_submerged_weight`, `use_user_defined_w`+`w_user_defined`, `use_variable_tension`, `lambda_DeltaN` |
| **G** numerical | mesh, time, windows | `Nz_total`, `dt` (s), `T_total` (s), `nt`, `rms_tail_fraction`, `tail_time_fraction`, `SaveStride` |
| **H** output | folders and selection | `output.out_dir`, `output.figure_dir`, `output.figures`, `output.save_fig`, `output.enable_export`, `output.make_plots`, `hotspot_region_fraction`, `case_id` |
| **I** reference data | optional DNS comparison | `dns.enable`, `dns.file`, `dns.cols`, `dns.z_mode` |
| **J** modal | eigenvalue analysis | `modal_n_modes`, `modal_environment` `'water'`/`'air'` |
| **K** fatigue | rainflow screening | `fatigue.enable`, `fatigue.m_values`, `fatigue.n_phi`, `fatigue.regions_z_over_D_paper` |

Boundary presets: `pinned_pinned`, `clamped_clamped`, `free_free`,
`guided_guided`, `semi_rigid_both`, `elastic_both`,
`cantilever_left_clamped_right_free`, `left_pinned_right_free`,
`left_clamped_right_pinned`, `manual`.

## 6. Selecting the output

```matlab
params.output.figures = {'displacement','internal_force','fatigue'};
```

| Group | Content |
|---|---|
| `'displacement'` | envelopes, RMS profiles, time history, trajectory, spectrum |
| `'internal_force'` | bending-moment / shear statistics and envelopes, true vs displacement-based comparison |
| `'fatigue'` | stress envelopes and STD, stress space-time maps, stress hotspots, rainflow relative cyclic demand |
| `'time_space'` | displacement space-time maps |
| `'wake'` | wake-oscillator intensity |
| `'tension'` | dynamic axial-tension histories |
| `'modal'` | natural frequencies |
| `'all'` | everything (default) |

Folders, exports and the optional clean single-report run:

```matlab
params.case_id           = 'myCase01';                          % file name prefix
params.output.out_dir    = fullfile(pwd,'my_results');          % '' -> CTXSF_outputs_<timestamp>
params.output.figure_dir = fullfile(params.output.out_dir,'figures');
params.output.save_fig   = true;    % save PNG + FIG
params.output.enable_export = true; % write Excel / MAT
params.output.make_plots = true;    % false -> figures stay off-screen (batch runs)

% produce only what you selected (skip the built-in full report files):
params.output.save_fig = false; params.output.enable_export = false;
params.output.make_plots = false;
result = ctXsfSolveVIV(params);
ctXsfReport(result, params.output);
```

## 7. Result files

Everything is written into `params.output.out_dir` (the prefix is the case id):

* `*_key_metrics.xlsx` — headline numbers of the run
* `*_spanwise_profiles.xlsx` — displacement, internal-force and stress profiles
* `*_fatigue_indicators.xlsx` — bending / shear stress maxima and standard deviations
* `*_axial_tension_history.xlsx` — dynamic tension and effective end tensions
* `*_relative_fatigue_*.xlsx` — rainflow demand profiles, regional summary, hotspots, sampling check
* `*_internal_force_hotspots.xlsx`, `*_true_vs_assumed_MQ_hotspot_regions.xlsx` — regional hotspot tables
* `figures/*.png` and `figures/*.fig` — every selected figure (FIG files can be edited in MATLAB)
* `*_summary.mat` — the complete `result` structure; `*_tail_fields.mat` — retained space-time fields

## 8. Copy-paste template

```matlab
%% my_case.m - my own case
clear; clc; close all;
ctXsfSetup;

params = ctXsfDefaultParams();

% ---- rod ----
params.section_type = 'hollow';
params.D = 0.05; params.d = 0.04; params.L = 25.0;
params.rhos = 7850; params.E = 2.10e11; params.nu = 0.30;

% ---- fluid ----
params.rho = 1025; params.rho_inner = 1025; params.eta = 1.0;

% ---- current and profile ----
params.flow_profile   = 'custom';
params.flow_profile_z = [0; 0.5*params.L; params.L];   % z = 0 at the top end
params.flow_profile_U = [1.20; 0.85; 0.45];            % m/s

% ---- boundary ----
params.boundary_preset = 'semi_rigid_both';
params.bcPreset.KthetaFactor = 15;

% ---- axial tension ----
params.N_top = 1.0e5;
params.include_submerged_weight = true;   % false -> constant static tension
params.use_variable_tension     = true;   % false -> ignore DeltaN completely
params.lambda_DeltaN            = 1.0;    % 0 -> compute but do not feed back

% ---- mesh / time / post-processing windows ----
params.Nz_total = 401; params.dt = 0.005; params.T_total = 5.0;
params.nt = ceil(params.T_total/params.dt);
params.rms_tail_fraction       = 0.30;    % statistics use the last 30 %
params.tail_time_fraction      = 0.40;    % retained space-time window
params.hotspot_region_fraction = 0.10;    % end regions = 10 % of the span each

% ---- output selection ----
params.case_id        = 'myCase01';
params.output.out_dir = fullfile(pwd,'my_results');
params.output.figures = {'displacement','internal_force','fatigue'};
params.output.save_fig = true;

% ---- run ----
result = ctXsfSolveVIV(params);           % protected core
ctXsfReport(result, params.output);       % public post-processing

fprintf('max y_rms/D = %.4f, max sigma_b = %.3e Pa, max DeltaN = %.1f N\n', ...
    max(result.rms_Y_dyn)/params.D, max(result.max_sigma_b), max(result.DeltaN));
```

For a modal analysis only, set `params.CL0 = 0`; the natural frequencies are then
returned in `result.freq_Hz`.

## 9. Examples

| Script | What it shows |
|---|---|
| `example_01_modal_analysis.m` | natural frequencies, several supports, air / still water |
| `example_02_viv_shear_flow.m` | reference VIV case with a linear sheared current |
| `example_03_boundary_comparison.m` | pinned vs semi-rigid vs clamped supports |
| `example_04_dynamic_tension_sweep.m` | sweep of the axial-tension feedback coefficient |
| `example_05_custom_parameters.m` | user-defined pipe, fluid, current profile and support |
| `example_06_fatigue_rainflow.m` | selectable rainflow fatigue screening and data windows |
| `example_07_tension_options.m` | the four static / dynamic tension combinations |

Every example starts with `FAST_DEMO = true`, which uses a coarse grid and a
short record; set it to `false` for the paper settings.

## 10. Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `Undefined function 'ctXsfSolveVIV'` | run `ctXsfSetup` first (it adds `lib/`, `src/`, `examples/`) |
| "packaged file" message from `help` | expected: the core is P-code, only callable |
| error about MATLAB version | the P-code needs R2023a or newer |
| `N_static_profile contains non-positive tension` | `N_top` too small for the span: increase it, or set `include_submerged_weight = false` |
| simulation length ignores your new `T_total` | also set `params.nt = ceil(params.T_total/params.dt)`; the solver warns and fixes it otherwise |
| `DeltaN` history is all zeros | `use_variable_tension = false` does not compute it; use `true` with `lambda_DeltaN = 0` to report without feeding back |
| `custom` profile error | provide both `flow_profile_z` and `flow_profile_U` |
| hollow section ignored | set `section_type = 'hollow'` and `d > 0`; `A`, `I`, `I_inner` are recomputed |
| DNS comparison file not found | `params.dns.enable` is off by default; place the spreadsheet in the working folder or give a full path |
| fatigue `INSUFFICIENT_FOR_RAINFLOW` | retained tail is too coarse: reduce `dt` or `SaveStride` (rule: >= 20 samples per period) |
| figure folders contain previous cases | call `close all` between cases (the loop examples do) |
| want the published hotspot regions | the default end window is 2.5 % of the span; set `params.hotspot_region_fraction = 0.05` for the `0--100 / 100--1900 / 1900--2000` table of the paper |

## 11. Adding your own figures or indicators

`ctXsfSolveVIV` returns everything in `result` (spanwise coordinates, envelopes,
RMS, internal forces, stress indicators, tension histories, space-time fields
and the hotspot table — see the table at the end of
[model_overview.md](model_overview.md)). A custom figure is a few lines:

```matlab
fig = figure('Color','w');
plot(result.std_Mres, result.z_paper, 'k-', 'LineWidth', 1.5);
xlabel('std(M_{res}) (N m)'); ylabel('z/D');
ctXsfStyleAxes(gca);                     % shared style
ctXsfSaveFig(fig, 'my_own_plot', ctXsfReportOptions(result, params.output));
```

Changing the **algorithms themselves** is not possible from the released
package: that part lives in `lib/*.p`. Contact the authors if you need the
sources for research collaboration.

## 12. Licence, citation and contact

MIT licence — see [LICENSE](../LICENSE). If you use the code, please cite the
associated paper and this repository, see [CITATION.cff](../CITATION.cff).
Contact details are in the [README](../README.md#contact).

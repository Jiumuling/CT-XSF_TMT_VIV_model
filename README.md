# CT-XSF_TMT_VIV_model

A two-degree-of-freedom **mixed Timoshenko beam - wake oscillator** framework for
vortex-induced vibration (VIV) of long flexible cylinders and risers, with
direct recovery of bending moment, shear force and beam-based stress
indicators.

The model solves the in-line and cross-flow displacements **and** the sectional
rotations as independent unknowns.  This makes it possible to recover

```
M = -EI * theta_z          bending moment
Q = kGA * (u_z - theta)    shear force
sigma_b = M_res * (D/2)/I  bending stress indicator
tau_Q   = f * Q_res / A    shear stress indicator
```

directly from the mixed `[u, theta]` fields instead of reconstructing them from
displacement derivatives only.  Supports, currents, dynamic axial tension and
the wake oscillators are all described by user-editable parameters.

This repository is the code release accompanying the manuscript
*"From displacement-based VIV prediction to internal-force assessment of
ultra-slender risers: A two-degree-of-freedom mixed Timoshenko Wake-oscillator
framework"* (Ocean Engineering).

---

## What is public and what is protected

| Component | File(s) | Form |
|---|---|---|
| Parameter interface | `src/ctXsfDefaultParams.m` | **open source**, fully documented |
| Selectable report / plotting layer | `src/ctXsfReport*.m`, `src/ctXsf*.m` | **open source**, editable |
| Examples | `examples/*.m` | **open source**, runnable |
| Core numerical solver (assembly, ghost-point boundaries, Newmark-beta / RK4 time integration, axial-tension feedback, internal-force and stress recovery) | `lib/*.p` | **protected MATLAB P-code** |

The core algorithms are distributed as MATLAB P-code (`.p`).  Users call them
through the documented parameter interface, may set every physical,
geometrical, flow, boundary and numerical input, and may choose which results
are produced; the protected files contain the numerical implementation itself.
See [docs/protected_code_notes.md](docs/protected_code_notes.md).

---

## Documentation

| Document | Language | Content |
|---|---|---|
| **[Usage guide](docs/usage_guide_en.md)** | English | download, first run, which files may be edited, all input groups, output selection, result files, template script, troubleshooting |
| **[使用指南](docs/usage_guide_zh.md)** | 中文 | 下载、上手四行代码、可编辑文件、参数分组、输出选择、结果文件、常见问题、可直接复制的模板 |
| [Parameter reference](docs/parameter_reference.md) | English | every parameter with its default value and meaning |
| [Model overview](docs/model_overview.md) | English | governing equations, boundary treatment, time integration, result fields |
| [Protected code notes](docs/protected_code_notes.md) | English | what is protected as P-code and the MATLAB release requirement |
| [Reproducing the study figures](docs/reproduce_paper_figures.md) | English | case settings of each figure of the paper |

**New here? Start with the [usage guide](docs/usage_guide_en.md)** (中文用户请读
[使用指南](docs/usage_guide_zh.md)).

---

## Requirements

* **MATLAB R2023a or newer.**
  P-code files are release-locked: files generated with R2023a run in R2023a and
  in later releases, but not in earlier ones.
* No toolbox is required for the solver.  The report layer uses base MATLAB
  graphics and `writetable` (base MATLAB since R2013b).

## Quick start

```matlab
ctXsfSetup;                              % add lib/, src/ and examples/ to the path

params = ctXsfDefaultParams();           % documented default parameter set
params.Nz_total = 401;                   % quick grid (paper case: 4001)
params.T_total  = 10;                    % quick record (paper case: 300 s)
params.nt       = ceil(params.T_total/params.dt);

params.boundary_preset = 'semi_rigid_both';
params.flow_profile    = 'linear_shear';

params.output.figures = {'displacement','internal_force','fatigue'};

result = ctXsfSolveVIV(params);          % protected core solver
ctXsfReport(result, params.output);      % public, selectable report
```

`ctXsfSolveVIV` returns a `result` structure (displacement statistics,
internal-force fields, stress indicators, dynamic axial-tension histories,
space-time data and the hotspot table).  `ctXsfReport` turns that structure
into figures and Excel/MAT exports, and can draw any subset of them.

## Parameter groups

All inputs live in the structure returned by `ctXsfDefaultParams` and are
grouped as follows (see [docs/parameter_reference.md](docs/parameter_reference.md)
for the complete field list).

| Group | Meaning | Representative fields |
|---|---|---|
| **A** | Rod / beam parameters | `D`, `d`, `L`, `section_type`, `rhos`, `E`, `nu`, `kappa` |
| **B** | Fluid parameters | `rho`, `rho_inner`, `eta`, `g` |
| **C** | Flow velocity and flow-profile parameters | `flow_profile`, `U_top`, `beta`, `U_bottom`, `flow_profile_z/U`, `St` |
| **D** | Boundary parameters | `boundary_preset`, `bcPreset.KthetaFactor`, `bcPreset.KuFactor`, `bc.left/right`, `boundary_*_in_time/modal` |
| **E** | Hydrodynamic and wake-oscillator coefficients | `CL0`, `CD0`, `C_D`, `Ax`, `Ay`, `epsilon_x`, `epsilon_y` |
| **F** | Static and dynamic axial tension | `N_top`, `include_submerged_weight`, `use_user_defined_w`, `w_user_defined`, `use_variable_tension`, `lambda_DeltaN` |
| **G** | Numerical parameters | `Nz_total`, `T_total`, `dt`, `nt`, `betaN`, `gammaN`, `kmax_couple`, `rms_tail_fraction`, `TailTime` |
| **H** | Output control | `output.out_dir`, `output.figure_dir`, `output.figures`, `output.save_fig`, `output.export`, `output.tau_shear_factor` |
| **I** | Optional reference data | `dns.enable`, `dns.file`, `dns.cols`, `dns.z_mode` |
| **J** | Modal analysis | `modal_n_modes`, `modal_environment`, `modal_recompute_weight` |
| **K** | Fatigue post-processing | `fatigue.enable`, `fatigue.m_values`, `fatigue.n_phi`, `fatigue.regions_z_over_D_paper`, `fatigue.min_samples_per_period` |

Two switches select the analysis:

```matlab
params.CL0 = 0;      % modal analysis of the mixed [u, theta] system
params.CL0 = 0.3;    % time-domain two-degree-of-freedom VIV simulation
```

### Rod, fluid and flow examples

```matlab
% hollow flooded pipe
params.section_type = 'hollow';
params.D = 0.05;  params.d = 0.04;  params.rhos = 7850;  params.E = 2.1e11;
params.rho = 1025;  params.rho_inner = 1025;

% uniform current
params.flow_profile = 'uniform';
params.U_top = 1.0;

% linear sheared current, top end fastest
params.flow_profile = 'linear_shear';
params.U_top = 0.5;  params.beta = 0.7;

% measured / arbitrary profile (z = 0 at the top end)
params.flow_profile   = 'custom';
params.flow_profile_z = [0; 0.5*params.L; params.L];
params.flow_profile_U = [1.20; 0.85; 0.45];

% constant static tension instead of a weight-induced gradient
params.include_submerged_weight = false;
```

### Boundary presets

`pinned_pinned`, `clamped_clamped`, `free_free`, `guided_guided`,
`semi_rigid_both`, `elastic_both`,
`cantilever_left_clamped_right_free`, `left_pinned_right_free`,
`left_clamped_right_pinned`, and `manual`.

```matlab
params.boundary_preset = 'semi_rigid_both';
params.bcPreset.KthetaFactor = 90;   % end rotation stiffness = 90 * EI/L
params.bcPreset.Ctheta       = 0;    % rotational damper
params.boundary_stiffness_in_time = true;   % stiffness in the Newmark operator
params.boundary_stiffness_in_modal = true;  % stiffness in the eigenvalue problem
```

## Numerical settings and post-processing window

Mesh, time step, record length and the data window used for the statistics are
all user-selectable:

```matlab
params.Nz_total = 4001;        % spanwise grid: dz/D = (L/D)/(Nz_total-1)
params.dt       = 5e-4;        % time step (s)
params.T_total  = 300;         % simulated record length (s)
params.nt       = ceil(params.T_total/params.dt);   % time steps

params.rms_tail_fraction  = 0.30;   % statistics: mean/RMS/STD from the last 30%
params.tail_time_fraction = 0.30;   % retained space-time window: last 30%
params.SaveStride         = 10;     % store every SaveStride-th step of that window
```

`params.tail_time_fraction = []` (default) keeps the explicit `params.TailTime`
instead, i.e. the original behaviour `TailTime = min(10 s, 0.30 T_total)`.
The solver prints the statistics window and the retained tail window at start-up,
and automatically keeps `nt` consistent with `T_total/dt`.

## Selecting the output

### Axial-tension options

The axial tension has two independent, user-selectable parts:

```text
N_eff(z,t)  = N_static(z) + lambda_DeltaN * DeltaN(t)
N_static(z) = N_top - w*z
DeltaN(t)   = E*Ap/(2L) * integral_0^L ( X_z^2 + Y_z^2 ) dz
```

| Choice | How to select it |
|---|---|
| Linear static tension from submerged weight: `N_top - w*z` | `params.include_submerged_weight = true` (default) |
| Constant static tension `N_top` along the span | `params.include_submerged_weight = false` |
| User-defined gradient `w` | `params.use_user_defined_w = true; params.w_user_defined = ...` |
| Dynamic tension fed back into the stiffness | `params.use_variable_tension = true; params.lambda_DeltaN = 1` |
| Dynamic tension computed and reported, but not fed back | `params.use_variable_tension = true; params.lambda_DeltaN = 0` |
| Dynamic tension ignored completely (fastest, matrix factorised once) | `params.use_variable_tension = false` |

`params.use_variable_tension = false` does not compute `DeltaN(t)`, so its
history is zero; keep the switch on with `lambda_DeltaN = 0` when the additional
tension should still be reported.  The solver prints the active tension
configuration and the static tension range at start-up, and
`examples/example_07_tension_options.m` compares the four combinations.

### End-region hotspot windows

The regional hotspot tables (true-vs-displacement-based internal forces and the
fatigue regions) split the span into bottom / middle / top with a
user-selectable end window:

```matlab
params.hotspot_region_fraction = 0.025;  % end window = 2.5% of the span (default)
params.hotspot_region_edge_zD  = [];     % or set the boundary explicitly in z/D
```

The rule is `edge = hotspot_region_fraction * L/D`, giving the regions
`0--edge`, `edge--L/D-edge` and `L/D-edge--L/D`, with names generated from the
actual boundaries.  The published tables of the paper used
`0--100 / 100--1900 / 1900--2000` at `L/D = 2000`, i.e. a 5 % end window; set
`params.hotspot_region_fraction = 0.05` to reproduce them exactly.
`params.fatigue.regions_z_over_D_paper` can still be given explicitly and takes
precedence inside the fatigue module.

`params.output.figures` (or the same field inside the options passed to
`ctXsfReport`) selects what is produced:

| Group | Content |
|---|---|
| `'displacement'` | displacement envelopes, RMS distributions, time history, trajectory, spectrum |
| `'internal_force'` | bending-moment and shear-force statistics, envelopes, true vs displacement-based indicators |
| `'fatigue'` | bending / shear stress envelopes and standard deviations, stress space-time maps, stress hotspot table, and the rainflow-based relative cyclic stress-demand screening |
| `'time_space'` | displacement space-time maps |
| `'wake'` | wake-oscillator RMS distributions |
| `'tension'` | dynamic axial-tension histories and effective end tensions |
| `'modal'` | natural frequencies (modal runs) |
| `'all'` | every group |

```matlab
ctXsfReport(result, struct('figures', {{'fatigue'}}, 'export', true));
```

The solver itself also contains the complete paper figure set used during the
study (`params.output.builtin_report = true`, `params.output.make_plots`), and
writes Excel/MAT files into `params.output.out_dir` when
`params.output.enable_export = true`.

## Public API

| Function | Purpose |
|---|---|
| `ctXsfSetup` | add `lib/`, `src/`, `examples/` to the MATLAB path |
| `ctXsfDefaultParams` | documented default parameter structure |
| `ctXsfSolveVIV` | protected core solver (modal or time-domain) returning `result` |
| `ctXsfReport` | selectable figures, stress/force tables and MAT export |
| `ctXsfStressHotspotTable` | regional bending / shear stress maxima |
| `ctXsfFatigueRainflow` | rainflow-based relative cyclic stress-demand screening |
| `ctXsfRainflowRanges` | rainflow cycle counting of a scalar time series |

## Fatigue post-processing

The fatigue module ranks the spanwise cyclic stress demand of the retained tail
window using rainflow counting and a Palmgren-Miner summation,

```text
sigma_b(phi) = (D/2)/I * ( Mx cos(phi) + My sin(phi) )        critical fibre
sigma_eq     = sqrt( sigma_b,res^2 + 3 tau_Q^2 )              equivalent stress
D(m)         = sum over cycles of  count * range^m             demand index
D_rel        = D(m) / max_z D(m)                               relative index
```

with the S-N slopes `params.fatigue.m_values` (default `[3 5]`) and a search
over `params.fatigue.n_phi` circumferential angles.  The module also checks the
sampling adequacy of the retained window (samples per shortest period) and
reports the required `dt_save` when the record is too coarse.

```matlab
params.fatigue.enable    = true;
params.fatigue.m_values  = [3 5];
params.fatigue.n_phi     = 72;
params.fatigue.regions_z_over_D_paper = [0 100; 100 1900; 1900 2000];
% leave regions_z_over_D_paper = [] for automatic regions:
%   edge = min(100, L/D/3)  ->  [0 edge; edge L/D-edge; L/D-edge L/D]

result  = ctXsfSolveVIV(params);
fatigue = ctXsfFatigueRainflow(result, params);   % standalone use
ctXsfReport(result, struct('figures', {{'fatigue'}}));  % figures + tables
```

`D_rel` is a **relative** screening indicator for hotspot ranking; it is not an
absolute fatigue life (no material S-N constant, mean-stress correction, thickness
correction or long-term sea-state scatter is introduced).

## Examples

| Script | Description |
|---|---|
| `examples/example_01_modal_analysis.m` | natural frequencies for several supports, air / still water |
| `examples/example_02_viv_shear_flow.m` | reference VIV case with a linear sheared current |
| `examples/example_03_boundary_comparison.m` | pinned vs semi-rigid vs clamped supports |
| `examples/example_04_dynamic_tension_sweep.m` | sweep of the axial-tension feedback coefficient |
| `examples/example_05_custom_parameters.m` | user-defined pipe, fluid, current profile and support |
| `examples/example_06_fatigue_rainflow.m` | selectable rainflow fatigue-demand screening and windows |
| `examples/example_07_tension_options.m` | static-tension shape and dynamic-tension feedback options |

Each example starts with `FAST_DEMO = true`, which uses a coarse grid and a
short record.  Setting it to `false` reproduces the mesh and record length used
for the paper cases, at a correspondingly longer runtime.

## Repository layout

```text
CT-XSF_TMT_VIV_model/
├── README.md
├── LICENSE                     MIT
├── CITATION.cff
├── ctXsfSetup.m                path setup
├── src/                        open-source interface + report layer
│   ├── ctXsfDefaultParams.m
│   ├── ctXsfReport.m
│   ├── ctXsfReportDisplacement.m
│   ├── ctXsfReportInternalForce.m
│   ├── ctXsfReportFatigue.m
│   ├── ctXsfReportTension.m
│   ├── ctXsfReportWake.m
│   ├── ctXsfReportTimeSpace.m
│   ├── ctXsfReportModal.m
│   ├── ctXsfReportExport.m
│   └── ctXsfStressHotspotTable.m
├── lib/                        protected core (MATLAB P-code)
├── examples/                   runnable examples
├── docs/                       model, parameter and code-protection notes
└── data/                       optional reference-data placement
```

## Model summary

For each transverse direction the mixed Timoshenko beam - wake oscillator
system is

```text
m u_tt + C u_t - (N_eff u_z)_z - kGA u_zz + kGA theta_z = F
J theta_tt - EI theta_zz - kGA u_z + kGA theta = 0
```

with the internal forces `M = -EI theta_z`, `Q = kGA (u_z - theta)` and
`R = N_eff u_z + Q`.  End conditions are imposed through ghost points combined
with central differences, which gives one uniform implementation of pinned,
clamped, free, guided, semi-rigid and elastic supports.

The wake subsystem consists of acceleration-coupled Van der Pol oscillators;
the fluid forces follow the standard forced-oscillator projection
`F_D = 0.5 rho D U^2 C_D + 0.25 rho D U^2 C_D0 p`,
`F_L = 0.25 rho D U^2 C_L0 q`.  The additional axial tension caused by
vibration-induced centreline stretching is

```text
DeltaN(t) = E*Ap/(2L) * integral_0^L ( X_z^2 + Y_z^2 ) dz
N_eff(z,t) = N_static(z) + lambda_DeltaN * DeltaN(t)
```

The time integration is staggered: the wake oscillators are advanced by RK4
and the structural subsystem by the average-acceleration Newmark-beta method,
with strong coupling iterations inside every time step.  Full details are
given in [docs/model_overview.md](docs/model_overview.md).

## Citation

If you use this code, please cite the associated paper and this repository; see
[CITATION.cff](CITATION.cff).

```bibtex
@article{Feng2026CTXSF,
  title   = {From displacement-based VIV prediction to internal-force assessment
             of ultra-slender risers: A two-degree-of-freedom mixed Timoshenko
             wake-oscillator framework},
  author  = {Feng, Zexin and Zhang, Lin and Lv, Shuang and Nan, Yue and
             Zhang, Zichun and Huo, Kebing and Guo, Xin and Jiang, Nan},
  journal = {Ocean Engineering},
  year    = {2026}
}
```

## License

Released under the MIT License; see [LICENSE](LICENSE).  The MIT terms apply to
the open-source interface, examples and documentation distributed in this
repository, and to the use of the protected P-code as a library.  The core
numerical sources are not distributed; see
[docs/protected_code_notes.md](docs/protected_code_notes.md).

## Contact

| Name | Affiliation | Contact |
|---|---|---|
| Zexin Feng | School of Mechanical Engineering, Tianjin University | `zexinfeng@tju.edu.cn` |
| Lin Zhang | College of Computer Science, Nankai University | `2120240759@mail.nankai.edu.cn` |
| Shuang Lv | College of Computer Science, Inner Mongolia University | `13504537325@163.com` |

For questions about the model formulation, the parameter set, or collaboration,
please open an issue or contact the authors.

# Parameter reference

All inputs are fields of the structure returned by `ctXsfDefaultParams`.
Values listed below are the defaults.  Groups follow the headings used in
`src/ctXsfDefaultParams.m`.

## A. Rod / beam parameters

| Field | Default | Meaning |
|---|---|---|
| `D` | `0.02` | outer diameter (m) |
| `d` | `0.0` | inner diameter (m); `0` = solid section |
| `L` | `40.0` | length (m); the reference case has `L/D = 2000` |
| `section_type` | `'solid'` | `'solid'` or `'hollow'`; sets `A`, `I`, `Ap`, `I_inner` |
| `rhos` | `2546.5` | structure density (kg/m^3) |
| `E` | `2.045e9` | Young's modulus (Pa) |
| `nu` | `0.30` | Poisson's ratio |
| `kappa` | `3/4` | Timoshenko shear correction factor |
| `A`, `I`, `Ap`, `I_inner`, `G`, `kGA`, `dd` | derived | section and stiffness quantities computed from the fields above |

## B. Fluid parameters

| Field | Default | Meaning |
|---|---|---|
| `rho` | `1000` | external fluid density (kg/m^3) |
| `rho_inner` | `0` | internal fluid density (kg/m^3) |
| `eta` | `1.0` | external added-mass coefficient, `m_a = eta * rho * pi * D^2/4` |
| `g` | `9.8` | gravity acceleration (m/s^2), used for the submerged-weight gradient |

## C. Flow velocity and flow-profile parameters

| Field | Default | Meaning |
|---|---|---|
| `St` | `0.2` | Strouhal number, `f_s = St U / D` |
| `flow_profile` | `'linear_shear'` | `'linear_shear'`, `'uniform'` or `'custom'` |
| `U_top` | `0.5` | current speed at `z = 0` (top end, m/s) |
| `beta` | `0.7` | shear intensity, `U_bottom = (1-beta) U_top` |
| `U_bottom` | `0.15` | current speed at `z = L` (m/s) |
| `flow_profile_z` | – | required for `'custom'`: internal coordinates, `0` at the top end |
| `flow_profile_U` | – | required for `'custom'`: current speed at `flow_profile_z` (linear interpolation, extrapolated outside the given range) |

`flow_profile = 'uniform'` gives `U(z) = U_top`; `beta = 0` in
`'linear_shear'` gives the same result.

## D. Boundary parameters

| Field | Default | Meaning |
|---|---|---|
| `boundary_preset` | `'pinned_pinned'` | see the list of presets in the README |
| `bcPreset.KthetaFactor` | `90.0` | end rotation stiffness in units of `EI/L` |
| `bcPreset.KuFactor` | `1.0` | end translation stiffness in units of `EI/L^3` |
| `bcPreset.Ctheta` | `0.0` | end rotational damping (N m s/rad) |
| `bcPreset.Cu` | `0.0` | end translational damping (N s/m) |
| `bc.left.type`, `bc.right.type` | `'pinned'` | manual types: `pinned`, `clamped`, `free`, `guided`, `semi_rigid`, `elastic` |
| `bc.left.Ku/Cu/Ktheta/Ctheta`, `bc.right.*` | `0.0` | manual stiffness / damping per end |
| `boundary_stiffness_in_time` | `true` | put `Ku`, `Ktheta` into the Newmark operator |
| `boundary_damping_in_time` | `true` | put `Cu`, `Ctheta` into the Newmark operator and right-hand side |
| `boundary_stiffness_in_modal` | `true` | put `Ku`, `Ktheta` into `K phi = omega^2 M phi` |
| `boundary_damping_in_modal` | `false` | keep the eigenvalue problem undamped |

## E. Hydrodynamic and wake-oscillator coefficients

| Field | Default | Meaning |
|---|---|---|
| `CL0` | `0.3` | lift-coefficient amplitude; **`CL0 = 0` switches to modal analysis** |
| `CD0` | `0.2` | fluctuating drag coefficient |
| `C_D` | `1.2` | mean drag coefficient |
| `Ax`, `Ay` | `12` | wake-oscillator excitation coefficients |
| `epsilon_x`, `epsilon_y` | `0.3` | wake-oscillator damping coefficients |

## F. Static and dynamic axial tension

| Field | Default | Meaning |
|---|---|---|
| `N_top` | `245` | static tension at the top end (N) |
| `use_variable_tension` | `true` | include the vibration-induced `DeltaN(t)` |
| `lambda_DeltaN` | `1.0` | feedback strength: `N_eff = N_static + lambda_DeltaN * DeltaN(t)` |
| `include_submerged_weight` | `true` | `false` gives a constant static tension (`w = 0`) |

The static profile is `N_static(z) = N_top - w z` with
`w = g (m_s + m_w - m_f)`; an error is raised if the tension becomes
non-positive somewhere along the span.

## G. Numerical parameters

| Field | Default | Meaning |
|---|---|---|
| `Nz_total` | `1001` | number of spanwise nodes (paper case: `4001`) |
| `T_total` | `30.0` | simulated record length (s) |
| `dt` | `0.01` | time step (s) |
| `nt` | `ceil(T_total/dt)` | number of time steps |
| `betaN`, `gammaN` | `1/4`, `1/2` | Newmark-beta parameters (average acceleration) |
| `kmax_couple` | `8` | maximum strong-coupling iterations per step |
| `couple_tol` | `1e-7` | coupling convergence tolerance |
| `eps_norm` | `1e-14` | residual normalisation floor |
| `relax_wake` | `0.8` | relaxation factor of the wake update |
| `rms_tail_fraction` | `0.30` | fraction of the record used for statistics |
| `TailTime` | `min(10, 0.3*T_total)` | length of the retained tail window (s) |
| `tail_time_fraction` | `[]` | optional: derive `TailTime = tail_time_fraction * T_total` |
| `SaveStride` | `10` | store every `SaveStride`-th step of the tail window |
| `plot.spectrum_omega_max` | `100` | upper limit of the spectrum axis (rad/s) |
| `use_fixed_chaplin_axes` | `false` | fixed axis limits for cross-case comparison |

Runtime scales approximately with `nt * Nz_total`, with an additional factor
from the strong-coupling iterations.  Use a coarse grid and a short record while
exploring a case, then refine.

The statistics (`mean`, `RMS`, `STD`, envelopes) use the last
`rms_tail_fraction` of the record, while the space-time maps and the fatigue
screening use the retained tail window (`TailTime`, sampled every `SaveStride`
steps).  Both windows are user-selectable; the solver prints them at start-up
and keeps `nt` consistent with `T_total/dt`.

## H. Output control

| Field | Default | Meaning |
|---|---|---|
| `case_id` | `''` | empty = automatically generated case identifier |
| `output.enable_export` | `true` | write Excel / MAT files from the solver |
| `output.out_dir` | `''` | empty = `CTXSF_outputs_<timestamp>` in the current folder |
| `output.figure_dir` | `''` | empty = `<out_dir>/figures` |
| `output.save_fig` | `true` | save the solver's built-in report figures |
| `output.make_plots` | `true` | `false` keeps the figures off-screen (batch / cluster) |
| `output.tau_shear_factor` | `4/3` | `tau_max ~ factor * Q_res / A` |
| `output.figures` | `{'all'}` | figure groups drawn by `CTXSFREPORT` |

`output.figures` accepts any subset of
`'displacement'`, `'time_space'`, `'internal_force'`, `'fatigue'`, `'wake'`,
`'tension'`, `'modal'` and `'all'`.

## I. Optional reference-data comparison

| Field | Default | Meaning |
|---|---|---|
| `dns.enable` | `false` | read an external RMS profile and compare it |
| `dns.file` | `'red_and_purple.xlsx'` | spreadsheet with the reference data |
| `dns.sheet` | `1` | sheet index or name |
| `dns.cols` | `[4, 5]` | columns holding `[Y_rms/D, raw z]` |
| `dns.col_order` | `'rms_z'` | `'rms_z'` or `'z_rms'` |
| `dns.header_lines` | `2` | header rows to skip |
| `dns.z_mode` | `'gao_reverse'` | `'gao_reverse'`, `'auto'`, `'physical'`, `'dimensionless'` |
| `dns.flip_rms` | `true` | flip the reference RMS sequence if the direction is reversed |
| `dns.error_grid_N` | `1601` | number of points of the comparison grid |

The solver raises an error if the file is missing, so keep
`dns.enable = false` unless the file is available.  See `data/README.md`.

## J. Modal analysis

| Field | Default | Meaning |
|---|---|---|
| `modal_n_modes` | `10` | number of natural frequencies reported and returned |
| `modal_environment` | `'water'` | `'water'` (with added mass) or `'air'` (dry) |
| `modal_recompute_weight` | `false` | recompute the tension gradient for the modal environment |

## K. Fatigue post-processing

Used by the `'fatigue'` figure group of `ctXsfReport` and by the standalone
`ctXsfFatigueRainflow`.

| Field | Default | Meaning |
|---|---|---|
| `fatigue.enable` | `true` | run the rainflow screening inside the fatigue report |
| `fatigue.make_figures` | `true` | draw the fatigue figures |
| `fatigue.m_values` | `[3 5]` | S-N slopes of the relative demand index (several allowed) |
| `fatigue.n_phi` | `36` | circumferential angles searched per section (accuracy vs runtime) |
| `fatigue.regions_z_over_D_paper` | `[]` | spanwise regions in paper coordinates (bottom = 0); empty = `[0 100; 100 L/D-100; L/D-100 L/D]` |
| `fatigue.region_names` | `{}` | names of those regions; empty = automatic names |
| `fatigue.min_samples_per_period` | `20` | samples per shortest period required for adequate rainflow counting |
| `fatigue.warning_samples_per_period` | `10` | warning threshold below `min_samples_per_period` |
| `fatigue.psd_power_threshold` | `0.05` | spectral power fraction that defines the highest significant frequency |

The retained tail window must resolve the shortest significant period; the
module reports `dt_save`, the required frequency and the resulting sampling
status, and prints the `dt_save` needed to satisfy the 20-sample rule.  Reduce
`dt` or `SaveStride` if the status is not `ADEQUATE_20_SAMPLE_RULE`.

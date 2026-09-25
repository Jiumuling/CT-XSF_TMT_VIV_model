# Reproducing the study figures

Every figure of the associated paper is produced by the same solver, with the
parameter set of the corresponding case.  The table below maps the paper
results to the parameters that control them and to the report group that draws
them.

| Study / figure content | Parameters that define the case | Report group |
|---|---|---|
| Mesh convergence of displacement RMS and of bending / shear fluctuations | `Nz_total` (`401 / 1001 / 2001 / 4001`), `dt`, `T_total` | `displacement`, `internal_force` |
| Natural frequencies (dry and still water) | `CL0 = 0`, `modal_environment = 'air' / 'water'`, `modal_n_modes` | `modal` |
| In-line and cross-flow RMS envelopes, trajectory, spectra | `flow_profile`, `U_top`, `beta`, `Nz_total`, `T_total` | `displacement` |
| Dynamic additional axial tension and effective end tensions | `N_top`, `use_variable_tension`, `lambda_DeltaN`, `include_submerged_weight` | `tension` |
| Bending-moment and shear-force statistics along the span | `boundary_preset`, `bcPreset.*` | `internal_force` |
| True (mixed Timoshenko) versus displacement-based internal forces | any VIV case | `internal_force` |
| Internal-force and stress space-time maps | `TailTime`, `SaveStride` | `time_space`, `fatigue` |
| Bending / shear stress demand and end-region hotspots | `boundary_preset`, `bcPreset.KthetaFactor`, `tau_shear_factor` | `fatigue` |
| Wake-oscillator intensity distribution | `Ax`, `Ay`, `epsilon_x`, `epsilon_y`, `CL0`, `CD0` | `wake` |
| Semi-rigid versus pinned and clamped supports | `boundary_preset`, `bcPreset.KthetaFactor` | `displacement`, `internal_force` |
| Sensitivity to the axial-tension feedback strength | `lambda_DeltaN` | `tension` |
| Rainflow-based relative cyclic stress-demand profiles (bending, equivalent) | `rms_tail_fraction`, `tail_time_fraction`, `SaveStride`, `fatigue.m_values`, `fatigue.n_phi` | `fatigue` |
| Displacement versus stress-indicator comparison and fatigue hotspot regions | `fatigue.regions_z_over_D_paper`, `fatigue.m_values` | `fatigue` |

## Case templates

The examples in `examples/` are the templates for the corresponding studies:

| Study | Template | Case definition |
|---|---|---|
| Mesh convergence | `example_02_viv_shear_flow.m` | loop over `params.Nz_total` |
| Boundary comparison | `example_03_boundary_comparison.m` | `pinned_pinned`, `semi_rigid_both`, `clamped_clamped` |
| Tension feedback | `example_04_dynamic_tension_sweep.m` | `lambda_DeltaN = 0 ... 1` |
| Natural frequencies | `example_01_modal_analysis.m` | `CL0 = 0`, air / water |
| Arbitrary structure / current | `example_05_custom_parameters.m` | user-defined pipe, fluid and profile |

## Paper settings

The reference case of the paper uses

```matlab
params.D        = 0.02;        % m
params.L        = 40.0;        % m,  L/D = 2000
params.Nz_total = 4001;        % dz/D = 1
params.dt       = 5e-4;        % s
params.T_total  = 300;         % s
params.U_top    = 0.5;         % m/s
params.beta     = 0.7;
params.N_top    = 245;         % N
params.CL0      = 0.3;
params.rms_tail_fraction = 0.30;
```

Runtime grows roughly as `nt * Nz`: the reduced grids used in the examples
(`Nz_total = 401`, `T_total = 10 s`) complete in about half a minute, whereas
the paper mesh and record length take hours.  Reduce `Nz_total`, `T_total` or
`dt` first when exploring a new case, and refine afterwards.

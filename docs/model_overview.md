# Model overview

## Structural formulation

The cylinder or riser is described by a **mixed Timoshenko beam** model in two
transverse directions.  Displacement and sectional rotation are independent
unknowns, which is what makes a direct internal-force recovery possible.

For each direction (`u = x` in-line, `u = y` cross-flow):

```text
m u_tt + C u_t - (N_eff u_z)_z - kGA u_zz + kGA theta_z = F
J theta_tt - EI theta_zz - kGA u_z + kGA theta = 0
```

with the internal forces

```text
M = -EI theta_z              bending moment
Q = kGA (u_z - theta)        shear force
R = N_eff u_z + Q            resultant transverse force
```

The corresponding beam-based stress indicators are

```text
sigma_b = M_res * (D/2) / I            bending stress
tau_Q   = tau_factor * Q_res / A       shear stress
```

where `tau_factor` (`params.output.tau_shear_factor`, default `4/3`) converts
the resultant shear force into the maximum shear stress of the cross-section.
These indicators are used for **relative** cyclic stress-demand screening; they
are not a substitute for a full fatigue assessment of the welded connection.

## Boundary conditions

End conditions are imposed with **ghost points** combined with central
differences, so all support types share one implementation:

* essential conditions replace the corresponding matrix rows
  (`u = 0` for pinned, `u = 0, theta = 0` for clamped, `theta = 0` for guided);
* natural conditions are written into the ghost-point relations
  (`M = 0` gives `theta_ghost = theta_neighbor`, `R = 0` gives the force-free
  relation);
* semi-rigid and elastic supports add the stiffness and damping terms to the
  ghost relation,

```text
M + Ktheta * theta + Ctheta * theta_t = 0     semi-rigid / elastic
R + Ku * u + Cu * u_t = 0                     elastic
```

Available presets: `pinned_pinned`, `clamped_clamped`, `free_free`,
`guided_guided`, `semi_rigid_both`, `elastic_both`,
`cantilever_left_clamped_right_free`, `left_pinned_right_free`,
`left_clamped_right_pinned`, `manual`.

Whether `Ku`, `Ktheta`, `Cu`, `Ctheta` enter the time-domain operator and the
eigenvalue problem is controlled by

```text
params.boundary_stiffness_in_time
params.boundary_damping_in_time
params.boundary_stiffness_in_modal
params.boundary_damping_in_modal
```

## Wake oscillators and fluid forces

Acceleration-coupled Van der Pol wake oscillators describe the fluctuating
drag (in-line, variable `p`) and lift (cross-flow, variable `q`):

```text
p_dot       = Omega * ( ... )        in-line wake oscillator
q_dot       = Omega * ( ... )        cross-flow wake oscillator
Omega(z)    = 2*pi*St*U(z)/D         local shedding frequency
```

with the empirical coefficients `Ax`, `Ay`, `epsilon_x`, `epsilon_y` and the
fluid damping `gamma = C_D/(4*pi*St)`.  The fluid forces are projected as

```text
F_D,mean = 0.5  rho D U^2 C_D
F_D,osc  = 0.25 rho D U^2 C_D0 p
F_L      = 0.25 rho D U^2 C_L0 q
F_x      = F_D,mean + F_D,osc - F_L/U * y_t
F_y      = F_L + F_D,osc/U * x_t
```

## Dynamic axial tension

Vibration-induced centreline stretching produces an additional axial tension

```text
DeltaN(t)   = E * Ap / (2L) * integral_0^L ( X_z^2 + Y_z^2 ) dz
N_eff(z,t)  = N_static(z) + lambda_DeltaN * DeltaN(t)
N_static(z) = N_top - w z,   w = g (m_s + m_w - m_f)
```

`params.use_variable_tension` switches the physical effect on or off, and
`params.lambda_DeltaN` scales the feedback fed into the structural matrix
(`0` = constant-tension reference solution, `1` = full feedback).
`params.include_submerged_weight = false` gives a constant static tension along
the span.

## Time integration

The scheme is staggered and strongly coupled inside every time step:

1. Newmark-beta prediction of the structural displacement and velocity;
2. coupling iteration `k = 1 ... kmax_couple`:
   * update `DeltaN(t)` from the current displacement field and the effective tension,
   * evaluate the hydrodynamic forces from the wake variables and the structural velocity,
   * solve the structure with the average-acceleration Newmark-beta method,
   * advance the wake oscillators with classical RK4,
   * check the structural, wake and tension residuals (`couple_tol`, `eps_norm`, `relax_wake`);
3. store the statistics and the tail-window fields used by the report layer.

Average-acceleration Newmark-beta (`betaN = 1/4`, `gammaN = 1/2`) is
unconditionally stable for linear systems; the structural matrix is reassembled
whenever the effective axial tension changes.

## Statistics and outputs

All statistics are accumulated over the last `params.rms_tail_fraction` of the
record (30 % by default), which excludes the transient.  The retained tail
window (`params.TailTime`, `params.SaveStride`) is used for the space-time maps
and for the true-versus-displacement-based comparison.

The `result` structure returned by `ctXsfSolveVIV` contains

| Field group | Content |
|---|---|
| `z`, `z_over_D`, `z_paper` | spanwise coordinates (internal, z/D and paper style) |
| `mean_*`, `rms_*_total`, `rms_*_dyn`, `*_min/mean/max_nd` | displacement statistics and envelopes |
| `*_Moment*`, `*_Shear*`, `std_Mres`, `std_Qres`, `max_Mres`, `max_Qres` | recovered internal forces |
| `max_sigma_b`, `max_tau_Q`, `sigma_b_tail`, `tau_Q_tail` | stress indicators and their space-time fields |
| `DeltaN*`, `Ntop_eff*`, `Nbot_eff*` | dynamic axial tension and effective end tensions |
| `*_tail`, `p_tail`, `q_tail`, `t_tail` | retained space-time data |
| `maxMuResultant`, `maxQuResultant`, `Mdiff_abs_std_tail`, `Qdiff_abs_std_tail` | displacement-based indicators and their differences |
| `trueAssumedHotspotTable` | regional true-vs-assumed internal-force hotspot table |
| `dns`, `dns_error_summary` | optional reference-data comparison |

## Relative fatigue-demand screening (post-processing)

The public post-processing layer (`ctXsfFatigueRainflow`) converts the recovered
internal forces of the retained tail window into a relative cyclic stress-demand
index:

```text
sigma_b(phi) = (D/2)/I * ( Mx cos(phi) + My sin(phi) )     critical fibre
sigma_eq     = sqrt( sigma_b,res^2 + 3 tau_Q^2 )           equivalent stress
D_b(m)       = sum over rainflow cycles of  count * range^m
D_eq(m)      = sum over rainflow cycles of  count * range^m
D_rel        = D / max_z D                                 relative index
```

The critical circumferential angle is obtained by searching
`params.fatigue.n_phi` angles per section.  A sampling-adequacy check compares
the stored tail sampling rate with the shortest significant period
(vortex shedding and spectral content) and reports the required `dt_save`.
`D_rel` ranks spanwise hotspots only; it is not an absolute fatigue life.

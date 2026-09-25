# Protected core and release requirements

## What is protected

The numerical core of the framework is distributed as **MATLAB P-code** in the
`lib/` folder (`.p` files).  It contains

* the assembly of the mixed Timoshenko system for the two transverse directions,
* the ghost-point implementation of the endpoint boundary conditions,
* the Newmark-beta structure solver and the RK4 wake-oscillator integrator,
  including the strong coupling iteration inside each time step,
* the hydrodynamic force projection and the dynamic axial-tension feedback,
* the recovery of bending moment, shear force and stress indicators, and
* the internal figure / Excel / MAT report used in the original study.

Everything a user needs in order to **define a problem and obtain results** is
open source:

| File | Role |
|---|---|
| `src/ctXsfDefaultParams.m` | complete, documented parameter interface |
| `src/ctXsfReport*.m` | selectable post-processing, figures and exports |
| `src/ctXsfFatigueRainflow.m`, `src/ctXsfRainflowRanges.m` | rainflow-based relative cyclic stress-demand screening |
| `examples/*.m` | runnable examples for every input group |
| `ctXsfSetup.m` | path setup |

P-code protects the implementation of the algorithms while keeping the package
runnable: `.p` files behave exactly like the `.m` files from which they were
generated, but their contents cannot be read or modified.

## MATLAB release requirement

The `.p` files were generated with **MATLAB R2023a (9.14)**.

P-code is release-locked:

| MATLAB that runs the `.p` file | Supported |
|---|---|
| R2023a or any **newer** release | yes |
| Any release **older** than R2023a | no |

If you need support for an older release, or you need the original MATLAB
sources under a research collaboration agreement, please contact the authors
(see the contact table in `README.md`).

The protected code runs in MATLAB; it is not compatible with GNU Octave.

## Running the package

```matlab
ctXsfSetup;                       % adds lib/, src/ and examples/ to the path
params = ctXsfDefaultParams();    % open parameter interface
params.Nz_total = 401;            % user-defined numerical settings
params.rho      = 1025;           % user-defined fluid
params.U_top    = 1.0;            % user-defined current
params.boundary_preset = 'semi_rigid_both';
result = ctXsfSolveVIV(params);   % protected core
ctXsfReport(result, params.output);
```

The solver prints a full progress log, writes its outputs into
`params.output.out_dir` (a timestamped folder by default) and returns the
`result` structure.  The report layer is independent of the protected code and
may be edited freely — for example to change the figure style or to add new
quantities computed from `result`.

## Licensing note

The MIT licence of this repository covers the open-source interface, examples
and documentation, and the use of the protected P-code as a library.  The core
numerical sources themselves are not distributed.  If your use case requires
the sources (teaching, code inspection, derivative development), please contact
the corresponding author.

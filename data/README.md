# Reference data (optional)

The comparison against external reference data is **optional** and switched off
by default:

```matlab
params.dns.enable = false;      % default
```

When `params.dns.enable = true`, the solver reads a spreadsheet that contains
the reference (e.g. DNS or experimental) cross-flow RMS profile and compares it
with the model result.  Place your own file in the working directory (or set
`params.dns.file` to its full path) and describe its layout with

```matlab
params.dns.file         = 'my_reference_data.xlsx';
params.dns.sheet        = 1;
params.dns.cols         = [4, 5];      % [Y_rms/D, raw z coordinate]
params.dns.col_order    = 'rms_z';     % or 'z_rms'
params.dns.header_lines = 2;           % header rows to skip
params.dns.z_mode       = 'gao_reverse'; % 'gao_reverse' | 'auto' | 'physical' | 'dimensionless'
params.dns.flip_rms     = true;        % flip the reference RMS sequence if needed
```

`params.dns.z_mode = 'gao_reverse'` maps a raw `0...L/D` coordinate to the
physical span with `z_m = (1 - z_raw/max(z_raw))*L`, i.e. it reverses the
vertical axis so that the top end is at the bottom of the profile array.

The reference data used in the original study is not redistributed here; use
your own dataset or contact the authors.

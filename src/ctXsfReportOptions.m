function o = ctXsfReportOptions(result, opts)
%CTXSFREPORTOPTIONS  Normalise the options of CTXSFREPORT.
%
%   O = CTXSFREPORTOPTIONS(RESULT, OPTS) accepts OPTS either as a dedicated
%   option struct or as the params.output struct produced by
%   CTXSFDEFAULTPARAMS, and returns the complete option set used by the
%   public report layer:
%
%     O.figures            cell array of figure groups to draw, or {'all'}
%     O.out_dir            folder for exported tables / MAT files
%     O.figure_dir         folder for PNG / FIG files
%     O.save_fig           save every generated figure (true / false)
%     O.export             write Excel / MAT summary tables (true / false)
%     O.close_after        close the generated figures when finished
%     O.tau_shear_factor   tau_max ~ factor * Q / A (4/3 for a solid circle)
%     O.prefix             file-name prefix (case_id by default)
%     O.dpi                PNG resolution

if nargin < 2 || isempty(opts)
    opts = struct();
end
if iscell(opts) || isstring(opts) || ischar(opts)
    opts = struct('figures', {cellstr(opts)});
end

o = struct();
o.figures          = {'all'};
o.out_dir          = ctXsfGetField(result, 'output_dir', pwd);
o.figure_dir       = fullfile(o.out_dir, 'figures');
o.save_fig         = true;
o.export           = true;
o.close_after      = false;
o.tau_shear_factor = 4/3;
o.prefix           = ctXsfGetField(result, 'case_id', 'case');
o.dpi              = 300;

% ---- user overrides -------------------------------------------------
if isfield(opts, 'figures') && ~isempty(opts.figures)
    o.figures = cellstr(opts.figures);
end
if isfield(opts, 'out_dir') && ~isempty(opts.out_dir)
    o.out_dir = opts.out_dir;
end
if isfield(opts, 'figure_dir') && ~isempty(opts.figure_dir)
    o.figure_dir = opts.figure_dir;
end
if isfield(opts, 'save_fig')
    o.save_fig = logical(opts.save_fig);
end
if isfield(opts, 'enable_export')          % params.output compatibility
    o.export = logical(opts.enable_export);
end
if isfield(opts, 'export')                 % explicit user override wins
    o.export = logical(opts.export);
end
if isfield(opts, 'close_after')
    o.close_after = logical(opts.close_after);
end
if isfield(opts, 'tau_shear_factor') && ~isempty(opts.tau_shear_factor)
    o.tau_shear_factor = opts.tau_shear_factor;
end
if isfield(opts, 'prefix') && ~isempty(opts.prefix)
    o.prefix = opts.prefix;
end
if isfield(opts, 'case_id') && ~isempty(opts.case_id)
    o.prefix = opts.case_id;
end
if isfield(opts, 'dpi') && ~isempty(opts.dpi)
    o.dpi = opts.dpi;
end

% ---- requested figure groups ----------------------------------------
if isempty(o.figures)
    o.figures = {'all'};
end

% ---- folders ---------------------------------------------------------
if ~exist(o.out_dir, 'dir')
    mkdir(o.out_dir);
end
if o.save_fig && ~exist(o.figure_dir, 'dir')
    mkdir(o.figure_dir);
end
end

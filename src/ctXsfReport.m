function out = ctXsfReport(result, opts)
%CTXSFREPORT  Public, selectable post-processing layer of the CT-XSF model.
%
%   OUT = CTXSFREPORT(RESULT) draws the default figure set from the RESULT
%   structure returned by CTXSFSOLVEVIV and exports a small summary.
%
%   OUT = CTXSFREPORT(RESULT, OPTS) selects what is produced.  OPTS may be
%   the params.output struct returned by CTXSFDEFAULTPARAMS, a cell array of
%   group names, or a struct with the fields
%
%       figures     figure groups to draw:
%                     'displacement'    displacement envelopes, RMS, time
%                                       history, trajectory, spectrum
%                     'time_space'      displacement space-time maps
%                     'internal_force'  bending moment / shear force
%                                       statistics, envelopes, true vs
%                                       displacement-based comparison
%                     'fatigue'         bending and shear stress indicators,
%                                       stress space-time maps, stress
%                                       hotspots
%                     'wake'            wake-oscillator RMS distributions
%                     'tension'         dynamic axial-tension histories
%                     'modal'           natural-frequency chart
%                     'all'             every group (default)
%       out_dir     folder for exported tables / MAT files
%       figure_dir  folder for the PNG / FIG files
%       save_fig    save each figure (default true)
%       export      write Excel / MAT summaries (default true)
%       close_after close the figures when finished (default false)
%       tau_shear_factor   tau_max ~ factor * Q / A (default 4/3)
%       prefix      file-name prefix (case_id by default)
%
%   Example
%       params = ctXsfDefaultParams();
%       result = ctXsfSolveVIV(params);
%       ctXsfReport(result, struct('figures', {{'displacement','fatigue'}}));
%
%   See also CTXSFSOLVEVIV, CTXSFDEFAULTPARAMS.

if nargin < 1 || ~isstruct(result)
    error('ctXsfReport:invalidInput', ...
          'RESULT must be the structure returned by ctXsfSolveVIV.');
end
if nargin < 2
    opts = struct();
end

o = ctXsfReportOptions(result, opts);

out = struct();
out.out_dir    = o.out_dir;
out.figure_dir = o.figure_dir;
out.groups     = {};
out.files      = {};

if strcmpi(ctXsfGetField(result, 'mode', 'viv'), 'modal')

    if ctXsfWantsGroup(o, 'modal')
        ctXsfReportModal(result, o);
        out.groups{end+1} = 'modal';
    end

else

    if ctXsfWantsGroup(o, 'displacement')
        ctXsfReportDisplacement(result, o);
        out.groups{end+1} = 'displacement';
    end
    if ctXsfWantsGroup(o, 'time_space')
        ctXsfReportTimeSpace(result, o);
        out.groups{end+1} = 'time_space';
    end
    if ctXsfWantsGroup(o, 'internal_force')
        ctXsfReportInternalForce(result, o);
        out.groups{end+1} = 'internal_force';
    end
    if ctXsfWantsGroup(o, 'fatigue')
        ctXsfReportFatigue(result, o);
        out.groups{end+1} = 'fatigue';
    end
    if ctXsfWantsGroup(o, 'wake')
        ctXsfReportWake(result, o);
        out.groups{end+1} = 'wake';
    end
    if ctXsfWantsGroup(o, 'tension')
        ctXsfReportTension(result, o);
        out.groups{end+1} = 'tension';
    end

end

if o.export
    out.files = ctXsfReportExport(result, o);
end

if o.close_after
    close('all');
end
end

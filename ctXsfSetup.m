function rootDir = ctXsfSetup()
%CTXSFSETUP  Add the CT-XSF model folders to the MATLAB path.
%
%   ROOTDIR = CTXSFSETUP() must be called once per MATLAB session before the
%   solver and the report layer are used:
%
%       ctXsfSetup;
%       params = ctXsfDefaultParams();
%       result = ctXsfSolveVIV(params);
%       ctXsfReport(result, params.output);
%
%   Added folders
%       lib/   protected core solver and kernels (MATLAB P-code)
%       src/   public parameter interface, report layer, export helpers
%       examples/
%
%   See also CTXSFDEFAULTPARAMS, CTXSFSOLVEVIV, CTXSFREPORT.

rootDir = fileparts(mfilename('fullpath'));

folders = {'lib', 'src', 'examples'};
for k = 1:numel(folders)
    f = fullfile(rootDir, folders{k});
    if exist(f, 'dir')
        addpath(f);
    end
end

if nargout == 0
    fprintf('CT-XSF 2-DOF mixed Timoshenko VIV model added to the path from:\n  %s\n', rootDir);
end
end

function tf = ctXsfWantsGroup(o, name)
%CTXSFWANTSGROUP  True when a figure group has been requested.
%
%   TF = CTXSFWANTSGROUP(O, NAME) tests the option set returned by
%   CTXSFREPORTOPTIONS.  The group is drawn when it is listed explicitly, or
%   when the catch-all entry 'all' is present.

tf = any(strcmpi(o.figures, name)) || any(strcmpi(o.figures, 'all'));
end

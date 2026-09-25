function v = ctXsfGetField(s, name, defaultValue)
%CTXSFGETFIELD  Safe field access with a default value.
%
%   V = CTXSFGETFIELD(S, NAME, DEFAULT) returns S.NAME when the field exists
%   and is not empty, and DEFAULT otherwise.  Used by the public report layer
%   so that optional result fields can be omitted safely.

if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
    v = s.(name);
else
    v = defaultValue;
end
end

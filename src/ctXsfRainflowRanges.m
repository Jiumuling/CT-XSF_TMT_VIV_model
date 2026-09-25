function [ranges, counts] = ctXsfRainflowRanges(x)
%CTXSFRAINFLOWRANGES  Rainflow cycle counting of a scalar time series.
%
%   [RANGES, COUNTS] = CTXSFRAINFLOWRANGES(X) extracts the rainflow stress
%   ranges of the signal X together with their cycle counts (0.5 for half
%   cycles and 1.0 for full cycles).  The turning points of X are found
%   first, then the standard three-point rainflow stack rule is applied.
%
%   The ranges are used to form the relative fatigue-demand index
%
%       D(m) = sum over cycles of  count * range^m
%
%   which is proportional to the damage of a Palmgren-Miner summation with an
%   S-N curve of slope m when the number of cycles and the material constant
%   are the same for all the cases being compared.

x = x(:);
x = x(isfinite(x));
ranges = zeros(0, 1);
counts = zeros(0, 1);

if numel(x) < 3
    return
end

% remove repeated samples, which carry no range information
x = x([true; diff(x) ~= 0]);
if numel(x) < 3
    return
end

% turning points of the signal
dx  = diff(x);
s   = sign(dx);
rev = [1; find(s(1:end-1) .* s(2:end) < 0) + 1; numel(x)];
tp  = x(rev);

if numel(tp) < 2
    return
end

% three-point rainflow stack
stack = zeros(0, 1);
for i = 1:numel(tp)
    stack(end+1, 1) = tp(i); %#ok<AGROW>

    while numel(stack) >= 3
        X = abs(stack(end-1) - stack(end-2));
        Y = abs(stack(end)   - stack(end-1));

        if Y < X
            break
        end

        if numel(stack) == 3
            ranges(end+1, 1) = X;    %#ok<AGROW>
            counts(end+1, 1) = 0.5;  %#ok<AGROW>
            stack(1) = [];
        else
            ranges(end+1, 1) = X;    %#ok<AGROW>
            counts(end+1, 1) = 1.0;  %#ok<AGROW>
            lastPoint = stack(end);
            stack(end-2:end) = [];
            stack(end+1, 1) = lastPoint; %#ok<AGROW>
        end
    end
end

% residual half cycles
for i = 1:(numel(stack)-1)
    ranges(end+1, 1) = abs(stack(i+1) - stack(i)); %#ok<AGROW>
    counts(end+1, 1) = 0.5;                        %#ok<AGROW>
end

valid  = ranges > 0 & isfinite(ranges) & isfinite(counts);
ranges = ranges(valid);
counts = counts(valid);
end

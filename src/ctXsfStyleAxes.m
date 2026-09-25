function ax = ctXsfStyleAxes(ax)
%CTXSFSTYLEAXES  Apply the paper-style axis formatting used by CTXSFREPORT.

if nargin < 1 || isempty(ax)
    ax = gca;
end
grid(ax, 'on');
set(ax, 'YDir', 'normal', 'FontName', 'Times New Roman', 'FontSize', 11);
if strcmpi(get(ax, 'Type'), 'axes')
    set(ax, 'TickLabelInterpreter', 'latex');
end
end

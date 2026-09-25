function ctXsfSaveFig(fig, name, o)
%CTXSFSAVEFIG  Save one figure as PNG and FIG when o.save_fig is true.

if ~ishandle(fig) || ~o.save_fig
    return
end

base  = fullfile(o.figure_dir, sprintf('%s_%s', o.prefix, name));
png   = [base, '.png'];
figf  = [base, '.fig'];

try
    exportgraphics(fig, png, 'Resolution', o.dpi);
catch
    try
        saveas(fig, png);
    catch ME
        warning('ctXsfSaveFig:png', 'Could not save %s: %s', png, ME.message);
    end
end

try
    savefig(fig, figf);
catch ME
    warning('ctXsfSaveFig:fig', 'Could not save %s: %s', figf, ME.message);
end
end

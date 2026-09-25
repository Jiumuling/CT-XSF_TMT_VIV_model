function ctXsfReportModal(result, o)
%CTXSFREPORTMODAL  Natural-frequency chart and table for modal runs.

if ~isfield(result, 'freq_Hz') || isempty(result.freq_Hz)
    return
end

f = result.freq_Hz(:);

fig = figure('Name', 'Natural frequencies of the mixed Timoshenko system', ...
             'Color', 'w', 'Position', [160 150 760 460]);
bar(1:numel(f), f, 0.5, 'FaceColor', [0.25 0.25 0.25]);
xlabel('Mode number', 'Interpreter', 'none');
ylabel('$f$ (Hz)', 'Interpreter', 'latex');
title(sprintf('Natural frequencies (%s)', result.environment), ...
      'Interpreter', 'none');
grid on;
set(gca, 'FontName', 'Times New Roman', 'FontSize', 11);
xticks(1:numel(f));
ctXsfSaveFig(fig, 'modal_frequencies', o);

T = table((1:numel(f)).', f, 2*pi*f, ...
    'VariableNames', {'Mode', 'Frequency_Hz', 'Omega_rad_s'});

if o.export
    xls = fullfile(o.out_dir, sprintf('%s_modal_frequencies.xlsx', o.prefix));
    writetable(T, xls);
    fprintf('Modal frequency table saved: %s\n', xls);
end
end

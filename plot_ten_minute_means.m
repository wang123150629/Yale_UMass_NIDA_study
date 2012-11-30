function[min_val, max_val, title_str] = plot_ten_minute_means(target_subject, dosage, varargin)

number_of_subjects = 2;
[subject_ids, subject_sessions] = get_subject_ids(number_of_subjects);
subj_idx = find(strcmp(target_subject, subject_ids));
load(fullfile(get_project_settings('data'), subject_ids{subj_idx}, subject_sessions{subj_idx}, sprintf('ten_minute_means.mat')));

if any(dosage > 4)
	dosage = str2num(strrep(num2str(dosage), num2str(5), '2 3 4'));
end
assert(isnumeric(dosage));

if length(varargin) > 0
	visible_flag = varargin{1};
else
	visible_flag = false;
end

if visible_flag
	figure();
else
	figure('visible', 'off');
end
set(gcf, 'Position', [10, 10, 1200, 800]);
colors = jet(size(ten_minute_means, 1));
legend_str = {};
legend_cntr = 1;
for s = 1:size(ten_minute_means, 1)
	if any(ten_minute_means(s, end) == dosage)
		plot(ten_minute_means(s, 1:end-6), 'color', colors(s, :));
		legend_str{legend_cntr} = sprintf('%d:%d-%d:%d,%d samples',...
				ten_minute_means(s, end-5), ten_minute_means(s, end-4),...
				ten_minute_means(s, end-3), ten_minute_means(s, end-2),...
				ten_minute_means(s, end-1));
		if legend_cntr == 1
			xlim([0, 210]); hold on;
			ylabel('std. millivolts'); xlabel('mean(Interpolated ECG)');
			% set(gca, 'YTickLabel', ''); 
			grid on; 
		end
		pause(1);
		legend_cntr = legend_cntr + 1;
	end
end
title_str = sprintf('Subject %s, Mean ECG in ten minute intervals', strrep(target_subject, '_', '-'));
title(title_str);
legend(legend_str);

target_idx = find(sum(repmat(ten_minute_means(:, end), 1, size(dosage, 2)) == repmat(dosage, size(ten_minute_means, 1), 1), 2));

min_val = min(min(ten_minute_means(target_idx, 1:end-6)));
max_val = max(max(ten_minute_means(target_idx, 1:end-6)));

%{
file_name = sprintf('%s/subj_%s_ten_minute', get_project_settings('plots'), subject_id);
savesamesize(gcf, 'file', file_name, 'format', image_format);

text(151, mean(ten_minute_means(s, 1:end-6)), sprintf('%d:%d-%d:%d,%d samples',...
		ten_minute_means(s, end-5), ten_minute_means(s, end-4),...
		ten_minute_means(s, end-3), ten_minute_means(s, end-2),...
		ten_minute_means(s, end-1)));

%}


function[] = box_plot_hr(subject_id)

result_dir = get_project_settings('results');
plot_dir = get_project_settings('plots');

switch subject_id
case 'P20_060', classes_to_classify = [1, 9, 11];
case 'P20_061', classes_to_classify = [1, 12, 10];
case 'P20_079', classes_to_classify = [1, 13, 14, 10];
end

mean_hr = [];
groupings = [];
std_hr = [];
g_cntr = 1;
for c = classes_to_classify
	class_information = classifier_profile(c);
	event = class_information{1, 1}.event;
	load(fullfile(result_dir, subject_id, sprintf('%s_preprocessed_data.mat', event)));
	nEvents = length(preprocessed_data);
	for e = 1:nEvents
		mean_hr = [mean_hr; (1000 ./ (preprocessed_data{e}.valid_rr_intervals .* 4)) .* 60];
		% std_hr = [std_hr, (1000 ./ (preprocessed_data{e}.valid_rr_intervals .* 4)) .* 60];
		groupings = [groupings; repmat(g_cntr, length(preprocessed_data{e}.valid_rr_intervals), 1)];
		g_cntr = g_cntr + 1;
	end
	if c == 1
		event_lbl = {'Base', 'fix 8mg', 'fix 16mg', 'fix 32mg', 'Dosage'};
	else
		event_lbl{end+1} = class_information{1, 1}.label;
		g_cntr = g_cntr + 1;
	end
end

figure('visible', 'on');
set(gcf, 'Position', get_project_settings('figure_size'));
boxplot(mean_hr, groupings, 'labels', event_lbl);
ylabel('Heart rate');
title(sprintf('Subject: %s', get_project_settings('strrep_subj_id', subject_id)));
image_format = get_project_settings('image_format');
file_name = sprintf('%s/%s/bx_plot_hr', plot_dir, subject_id);
savesamesize(gcf, 'file', file_name, 'format', image_format);


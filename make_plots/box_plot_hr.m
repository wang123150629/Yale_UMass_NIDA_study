function[] = box_plot_hr(subject_id)

result_dir = get_project_settings('results');
plot_dir = get_project_settings('plots');

classes_to_classify = [1, 2; 1, 3; 1, 4; 1, 5];
switch subject_id
case 'P20_061', classes_to_classify = [1, 12];
case 'P20_060', classes_to_classify = [1, 9, 11];
case 'P20_079', classes_to_classify = [1, 13, 10];
case 'P20_053', classes_to_classify = [1, 8, 10];
end

mean_hr = [];
groupings = [];
event_lbl = {};
std_hr = [];
g_cntr = 1;
for c = classes_to_classify
	class_information = classifier_profile(c);
	event = class_information{1, 1}.event;
	load(fullfile(result_dir, subject_id, sprintf('%s_preprocessed_data.mat', event)));
	nEvents = length(preprocessed_data);
	for e = 1:nEvents
		if ~isempty(preprocessed_data{e}.valid_rr_intervals)
			mean_hr = [mean_hr; (1000 ./ (preprocessed_data{e}.valid_rr_intervals .* 4)) .* 60];
			% std_hr = [std_hr, (1000 ./ (preprocessed_data{e}.valid_rr_intervals .* 4)) .* 60];
			groupings = [groupings; repmat(g_cntr, length(preprocessed_data{e}.valid_rr_intervals), 1)];
			if c == 1
				switch length(unique(preprocessed_data{e}.dosage_labels))
				case 1,
					if unique(preprocessed_data{e}.dosage_labels) < 0
						event_lbl{end+1} = 'Base';
					else
						tttdd = unique(preprocessed_data{e}.dosage_labels);
						event_lbl{end+1} = sprintf('Blind:%d', tttdd(tttdd > 0));
					end
				case 2,
					tttdd = unique(preprocessed_data{e}.dosage_labels);
					event_lbl{end+1} = sprintf('Blind:%d', tttdd(tttdd > 0));
				case 4
					event_lbl{end+1} = 'fixed sess.';
				otherwise, error('Invalid number of dosages!');
				end
			else
				event_lbl{end+1} = class_information{1, 1}.label;
			end
			g_cntr = g_cntr + 1;
		end
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


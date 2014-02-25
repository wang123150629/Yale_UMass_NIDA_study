function[] = box_plot_hr(subject_id, plot_style, varargin)

% box_plot_hr('P20_060', 'box');
% box_plot_hr('P20_060', 'hist');

paper_quality = true;
if paper_quality
	font_size = get_project_settings('font_size');
	le_fs = font_size(1); xl_fs = font_size(2); yl_fs = font_size(3);
	xt_fs = font_size(4); yt_fs = font_size(5); tl_fs = font_size(6);
end

close all;
result_dir = get_project_settings('results');
plot_dir = get_project_settings('plots');
image_format = get_project_settings('image_format');

switch subject_id
case 'P20_060', classes_to_classify = [1, 9, 11];
case 'P20_079', classes_to_classify = [1, 13, 10];
case 'P20_094', classes_to_classify = [1, 9, 10];
case 'P20_098', classes_to_classify = [1, 9, 10];
case 'P20_101', classes_to_classify = [1, 9, 10];
case 'P20_103', classes_to_classify = [1, 9, 10];
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

figure('visible', 'off');
set(gcf, 'PaperPosition', [0 0 10 6]);
set(gcf, 'PaperSize', [10 6]);
interested_groupings = [0, 1, 5, 6, 7];

for i = 1:length(interested_groupings) - 1
	switch interested_groupings(i+1)
	case 1, title_str = 'Baseline';
	case 5, title_str = 'All';
	case 6, title_str = 'Exercise';
	case 7, title_str = 'MPH';
	otherwise, error('Invalid grouping!');
	end

	target_idx = groupings > interested_groupings(i) & groupings <= interested_groupings(i+1);
	if sum(target_idx) > 0
		subplot(2, 2, i); hist(mean_hr(target_idx), 20); hold on; grid on;
		plot(mean(mean_hr(target_idx)), 100, 'ro', 'MarkerFaceColor', 'r');
		title(sprintf('%s, count=%d\nMean HR=%0.2f', title_str, sum(target_idx), mean(mean_hr(target_idx))),...
				'FontSize', 15, 'FontWeight', 'b', 'FontName', 'Times');
		xlabel('Heart rate', 'FontSize', xl_fs, 'FontWeight', 'b', 'FontName', 'Times');
		ylabel('count', 'FontSize', yl_fs, 'FontWeight', 'b', 'FontName', 'Times');
		xlim([50, 150]);
	end
end
file_name = sprintf('%s/%s/%s_hist_plot_hr', plot_dir, subject_id, subject_id);
saveas(gcf, file_name, 'pdf');

% old code where I was plotting HR in sessions
%{
figure('visible', 'off');
set(gcf, 'PaperPosition', [0 0 10 6]);
set(gcf, 'PaperSize', [10 6]);
% set(gcf, 'Position', get_project_settings('figure_size'));

if strcmp(plot_style, 'box')
	boxplot(mean_hr, groupings, 'labels', event_lbl);
	ylabel('Heart rate');
	title(sprintf('Subject: %s', get_project_settings('strrep_subj_id', subject_id)));
	file_name = sprintf('%s/%s/bx_plot_hr', plot_dir, subject_id);
else
	for i = 1:8
		if sum(groupings == i) > 0
			subplot(2, 4, i); hist(mean_hr(groupings == i), 20); hold on; grid on;
			plot(mean(mean_hr(groupings == i)), 100, 'ro', 'MarkerFaceColor', 'r');
			title(sprintf('%s, count=%d', event_lbl{i}, sum(groupings == i)));
			xlabel('Heart rate'); ylabel('count'); xlim([50, 150]);
		end
	end
	file_name = sprintf('%s/%s/%s_hist_plot_hr', plot_dir, subject_id, subject_id);
end
% savesamesize(gcf, 'file', file_name, 'format', image_format);
saveas(gcf, file_name, 'pdf');
%}


function[slack_results] = make_another_slack_plot(varargin)

plot_dir = get_project_settings('plots');
image_format = get_project_settings('image_format');

labels_A = varargin{1};
labels_B = varargin{2};
matching_pm = varargin{3};
disp_flag = varargin{4};
legend_str = varargin{5};
xlabel_str = varargin{6};
record_no = varargin{7};
analysis_id = varargin{8};

nLabels = length(unique(labels_B(find(labels_B))));
assert(matching_pm > 0);
switch xlabel_str
case 'Predictions', tit_str = 'Precision';
case 'Ground-truth', tit_str = 'Recall';
otherwise, error('Invalid X label string!');
end
slack_range = 0:matching_pm;
slack_results = NaN(length(slack_range), nLabels);
dimm = 2;

for w = 1:length(slack_range)
	for l = 1:nLabels
		idx_label_A = find(labels_A == l);
		idx_label_B = find(labels_B == l);
		divide_by = length(idx_label_B);
		% Logic: We would like to give slack to the predicted labels NOT ground truth. Hence for case 'predictions'
		% the predicted labels are sitting in the rows of _low and _high matrix. We are checking if each window (row)
		% is holding atleast one ground truth i.e. by summing along dim = 2. For case 'ground truth' the predictions
		% are sitting along the columns, we would like to see if each predicted label falls within atleast one ground
		% truth window hence summing along dim = 2. Also, note the division for precision we divide by tp / (tp + fp)
		% this translates to 137 P's could be predicted but only 132 are within ground truth proximity hence
		% precision = 132 / 137. For recall we divide tp / (tp + tn) this translates to there are 139 ground truth P's
		% but only 132 are predicted by our CRF model, our model calls the other 7 P peaks as not P's hence 132 / 139.

		label_A_mat = repmat(idx_label_A, length(idx_label_B), 1);
		label_B_low = repmat(idx_label_B'- slack_range(w), 1, length(idx_label_A));
		label_B_high = repmat(idx_label_B'+ slack_range(w), 1, length(idx_label_A));
		assert(isequal(size(label_A_mat), size(label_B_low)));
		assert(isequal(size(label_A_mat), size(label_B_high)));
		result = label_A_mat >= label_B_low & label_A_mat <= label_B_high;
		slack_results(w, l) = sum(sum(result, dimm) >= 1) / divide_by;
		assert(slack_results(w, l) <= 1);
	end
end
assert(all(~isnan(slack_results(:))));

figure('visible', 'off'); set(gcf, 'Position', get_project_settings('figure_size'));
plot(slack_results, 'o-', 'LineWidth', 2);
grid on;
xlabel(sprintf('%s window', xlabel_str));
ylabel('Accuracy'); ylim([min(slack_results(:)) - 0.01, max(slack_results(:)) + 0.01]);
title(sprintf('%s, Record %s', tit_str, get_project_settings('strrep_subj_id', record_no)));
set(gca, 'XTick', 1:length(slack_range));
temp = strcat(setstr(177), strread(num2str(slack_range),'%s'));
set(gca, 'XTickLabel', temp);
legend(legend_str, 'Location', 'SouthEast', 'Orientation', 'Horizontal');
xlim([1, length(slack_range)]);

file_name = sprintf('%s/sparse_coding/%s/%s_%s_peaks', plot_dir, analysis_id, record_no,...
						get_project_settings('strrep_subj_id', xlabel_str));
savesamesize(gcf, 'file', file_name, 'format', image_format);


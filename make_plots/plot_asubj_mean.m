function[] = plot_asubj_mean(which_plot)

% plot_asubj_mean(60, 1)

close all;

result_dir = get_project_settings('results');
plot_dir = get_project_settings('plots');
image_format = get_project_settings('image_format');
feature_ordering = [3, 2, 1];

paper_quality = true;
if paper_quality
	font_size = get_project_settings('font_size');
	le_fs = font_size(1); xl_fs = font_size(2); yl_fs = font_size(3);
	xt_fs = font_size(4); yt_fs = font_size(5); tl_fs = font_size(6);
end

nSubjects = 13;
subject_ids = get_subject_ids(nSubjects);
switch which_plot
case 1
	subject_ids = subject_ids(1, [1:6, 8, 10:end]);
	nAnalysis = 4;
	legend_str = {'Bv8', 'Bv16', 'Bv32', 'BvA'};
	sess_str = 'self_admin';
case 2
	keyboard
	subject_ids = subject_ids(1, [6, 8, 10:end]);
	nAnalysis = 3;
	legend_str = {'BvEX', 'AvEX', 'AvMP'};
	sess_str = 'other_sess';
otherwise
	error('Invalid pipeline!');
end
nSubjects = length(subject_ids);

for s = 1:nSubjects
	classifier_results = load(fullfile(result_dir, subject_ids{s}, sprintf('%s_cross_val_results.mat', subject_ids{s})));
	nFeatures = length(classifier_results.mean_over_runs{1});
	feature_str = classifier_results.feature_str{1, 1};
	if s == 1
		mean_within_subj = zeros(nSubjects, nFeatures, nAnalysis);
	end

	temp = [classifier_results.auc_over_runs{:}];
	switch which_plot
	case 1
		mean_within_subj(s, :, :) = temp;
	case 2
		switch subject_ids{s}
		case 'P20_060', mean_within_subj(s, :, :) = temp(:, [5, 6, 7]);
		case 'P20_079', mean_within_subj(s, :, :) = temp(:, [5, 6, 7]);
		case 'P20_094', mean_within_subj(s, :, :) = temp(:, [5, 7, 9]);
		case 'P20_098', mean_within_subj(s, :, :) = temp(:, [5, 7, 9]);
		case 'P20_101', mean_within_subj(s, :, :) = temp(:, [5, 6, 7]);
		case 'P20_103', mean_within_subj(s, :, :) = temp(:, [5, 6, 7]);
		otherwise, error('Invalid subject Id!');
		end
	otherwise, error('Invalid pipeline!');
	end
end

figure('visible', 'off');
set(gcf, 'PaperPosition', [0 0 10 6]);
set(gcf, 'PaperSize', [10 6]);

model_series = reshape(mean(mean_within_subj, 1), nFeatures, nAnalysis);
model_series = model_series(feature_ordering, :);
model_error = reshape(std(mean_within_subj, [], 1), nFeatures, nAnalysis) ./ nSubjects;
model_error = model_error(feature_ordering, :);
h = bar(model_series); hold on; grid on;
set(h, 'BarWidth', 1); % The bars will now touch each other
numgroups = size(model_series, 1); 
numbars = size(model_series, 2); 
groupwidth = min(0.8, numbars/(numbars+1.5));
for i = 1:numbars
	% Based on barweb.m by Bolu Ajiboye from MATLAB File Exchange
	x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars); % Aligning error bar with individual bar
	errorbar(x, model_series(:,i), model_error(:,i), 'k', 'linestyle', 'none', 'LineWidth', 1.1);
end
legend(legend_str, 'Location', 'South', 'Orientation', 'Horizontal');
xlabel('Features', 'FontSize', xl_fs, 'FontWeight', 'b', 'FontName', 'Times');
ylabel('AUROC', 'FontSize', yl_fs, 'FontWeight', 'b', 'FontName', 'Times');
set(gca, 'XTick', 1:nFeatures);
set(gca, 'XTickLabel', feature_str(1, feature_ordering), 'FontSize', xt_fs, 'FontWeight', 'b', 'FontName', 'Times');
xlim([0.5, nFeatures+0.5]); ylim([0.5, 1.01]);
title(sprintf('Mean across subject (%d subjects), Logistic reg, Area under ROC', nSubjects),...
		'FontSize', tl_fs, 'FontWeight', 'b', 'FontName', 'Times');

file_name = sprintf('%s/mean_%dasubj_%s_auc', plot_dir, nSubjects, sess_str);
saveas(gcf, file_name, 'pdf');


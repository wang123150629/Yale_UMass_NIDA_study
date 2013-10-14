function[] = plot_class_results(tr_percent, varargin)

close all;

if length(varargin) > 0
	paper_quality = varargin{1};
else
	paper_quality = false;
end

nSubjects = 8;
subject_ids = get_subject_ids(nSubjects);
result_dir = get_project_settings('results');
plot_dir = get_project_settings('plots');
image_format = get_project_settings('image_format');
target_feat_rows = 1:9;
target_ana_cols = 1:4;
auroc_over_subjects = NaN(length(target_feat_rows), length(target_ana_cols), nSubjects);

for s = 8:nSubjects
	classifier_results = load(fullfile(result_dir, subject_ids{s}, sprintf('%s_classifier_results_tr%d.mat', subject_ids{s},...
										tr_percent)));
	nAnalysis = length(classifier_results.mean_over_runs);
	legend_str = {};
	for a = 1:nAnalysis
		mean_over_runs = classifier_results.mean_over_runs{1, a};
		nFeatures = length(mean_over_runs);
		errorbars_over_runs = classifier_results.errorbars_over_runs{1, a};
		feature_str = classifier_results.feature_str{1, a};
		class_label = classifier_results.class_label{1, a};
		legend_str{a} = sprintf('%s vs %s', class_label{1}, class_label{2});
	end

	figure('visible', 'off'); set(gcf, 'Position', get_project_settings('figure_size'));
	bar([classifier_results.auc_over_runs{:}]);
	legend(legend_str, 'Location', 'South', 'Orientation', 'Horizontal');
	xlabel('Features'); ylabel('AUROC');
	set(gca, 'XTick', 1:nFeatures);
	set(gca, 'XTickLabel', feature_str);
	xlim([0.5, nFeatures+0.5]); grid on;
	% title(sprintf('%s, within subject, Logistic reg, Area under ROC', get_project_settings('strrep_subj_id', subject_ids{s})));
	file_name = sprintf('%s/%s/class_subj%d_tr%d_auroc', plot_dir, subject_ids{s}, s, tr_percent);
	savesamesize(gcf, 'file', file_name, 'format', image_format);

	%{
	font_size = get_project_settings('font_size');
	le_fs = font_size(1); xl_fs = font_size(2); yl_fs = font_size(3);
	xt_fs = font_size(4); yt_fs = font_size(5); tl_fs = font_size(6);
	figure('visible', 'off');
	set(gcf, 'PaperPosition', [0 0 6 4]);
	set(gcf, 'PaperSize', [6 4]);
	bar([classifier_results.auc_over_runs{:}]);
	xlabel('Features', 'FontSize', xl_fs, 'FontWeight', 'b', 'FontName', 'Times');
	ylabel('AUROC', 'FontSize', yl_fs, 'FontWeight', 'b', 'FontName', 'Times');
	set(gca, 'XTick', 1:nFeatures);
	set(gca, 'XTickLabel', feature_str, 'FontSize', xt_fs, 'FontWeight', 'b', 'FontName', 'Times');
	title('Baseline vs. Physical Exercise');
	xlim([0.5, nFeatures+0.5]); grid on;
	file_name = sprintf('/home/anataraj/Presentations/Images/p20_079_base_exer_class');
	saveas(gcf, file_name, 'pdf') % Save figure
	%}
end

%{
figure('visible', 'off'); set(gcf, 'Position', get_project_settings('figure_size'));
errorbar(1:nFeatures, mean_over_runs, errorbars_over_runs, 'b', 'LineWidth', 2);
hold on; grid on; xlim([0.90, nFeatures+0.10]); ylim([50, 102]);
plot(1:nFeatures, mean(classifier_results.chance_baseline{1, a}, 2), 'r--');
title(sprintf('%s, within subject, Logistic reg, %s vs. %s', get_project_settings('strrep_subj_id', subject_ids{s}),...
						class_label{1}, class_label{2}));
xlabel('Features'); ylabel('Accuracy');
set(gca, 'XTick', 1:nFeatures);
set(gca, 'XTickLabel', feature_str);
file_name = sprintf('%s/%s/class_ana%d_tr%d_perf', plot_dir, subject_ids{s}, a, tr_percent);
savesamesize(gcf, 'file', file_name, 'format', image_format);
%}
% tmp = [classifier_results.auc_over_runs{:}];
% auroc_over_subjects(:, :, s) = tmp(target_feat_rows, target_ana_cols);

%{
if paper_quality
	figure('visible', 'off'); 
	set(gcf, 'PaperPosition', [0 0 6 4]);
	set(gcf, 'PaperSize', [6 4]);
	font_size = get_project_settings('font_size');
	le_fs = font_size(1); xl_fs = font_size(2); yl_fs = font_size(3);
	xt_fs = font_size(4); yt_fs = font_size(5); tl_fs = font_size(6);
else
	figure();
	set(gcf, 'Position', get_project_settings('figure_size'));
end

hold on; grid on;
model_series = mean(auroc_over_subjects, 3);
model_error = (std(auroc_over_subjects, [], 3) ./ nSubjects);

h = bar(model_series);
set(h, 'BarWidth', 1); % The bars will now touch each other

numgroups = size(model_series, 1); 
numbars = size(model_series, 2); 
groupwidth = min(0.8, numbars/(numbars+1.5));
for i = 1:numbars
	% Based on barweb.m by Bolu Ajiboye from MATLAB File Exchange
	x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars); % Aligning error bar with individual bar
	errorbar(x, model_series(:,i), model_error(:,i), 'k', 'linestyle', 'none', 'LineWidth', 1);
end
h_legend = legend(legend_str{1, target_ana_cols}, 'Location', 'South', 'Orientation', 'Horizontal');

set(gca, 'XTick', 1:nFeatures);
xlim([0.5, nFeatures+0.5]); ylim([0, 1]);
if paper_quality
	set(h_legend, 'FontSize', le_fs, 'FontWeight', 'b', 'FontName', 'Times');
	xlabel('Features', 'FontSize', xl_fs, 'FontWeight', 'b', 'FontName', 'Times');
	ylabel('AUROC', 'FontSize', yl_fs, 'FontWeight', 'b', 'FontName', 'Times');
	set(gca, 'XTickLabel', feature_str(1, target_feat_rows), 'FontSize', xt_fs, 'FontWeight', 'b', 'FontName', 'Times');
	title(sprintf('Mean within subject classification, Logistic reg, Area under ROC'),...
						'FontSize', tl_fs, 'FontWeight', 'b', 'FontName', 'Times');
	plot_dir = get_project_settings('pdf_result_location');
	file_name = sprintf('%s/mean_within_subject_feat%d', plot_dir, nFeatures);
	saveas(gcf, file_name, 'pdf') % Save figure
else
	xlabel('Features');
	ylabel('AUROC');
	set(gca, 'XTickLabel', feature_str(1, target_feat_rows));
	title(sprintf('Mean within subject classification, Logistic reg, Area under ROC'));
	file_name = sprintf('%s/mean_within_subject_feat%d', plot_dir, nFeatures);
	savesamesize(gcf, 'file', file_name, 'format', image_format);
end
%}


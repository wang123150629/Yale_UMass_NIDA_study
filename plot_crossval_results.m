function[] = plot_crossval_results()

close all;

number_of_subjects = 6;
subject_ids = get_subject_ids(number_of_subjects);
result_dir = get_project_settings('results');
plot_dir = get_project_settings('plots');
image_format = get_project_settings('image_format');

for s = 1:number_of_subjects
	classifier_results = load(fullfile(result_dir, subject_ids{s}, sprintf('cross_val_results.mat')));
	nAnalysis = length(classifier_results.mean_over_runs);
	legend_str = {};
	for a = 1:nAnalysis
		nFeatures = length(classifier_results.mean_over_runs{1, a});
		feature_str = classifier_results.feature_str{1, a};
		class_label = classifier_results.class_label{1, a};
		legend_str{a} = sprintf('%s vs %s', class_label{1}, class_label{2});
	end

	% figure('visible', 'off'); set(gcf, 'Position', get_project_settings('figure_size'));
	figure(); set(gcf, 'Position', get_project_settings('figure_size'));
	bar([classifier_results.auc_over_runs{:}]);
	legend(legend_str, 'Location', 'South', 'Orientation', 'Horizontal');
	xlabel('Features'); ylabel('AUROC');
	set(gca, 'XTick', 1:nFeatures);
	set(gca, 'XTickLabel', feature_str);
	xlim([0.5, nFeatures+0.5]); grid on; ylim([0, 1]);
	title(sprintf('%s, cross validation, Logistic reg, Area under ROC', get_project_settings('strrep_subj_id', subject_ids{s})));
	file_name = sprintf('%s/%s/crossval_subj%d_auroc', plot_dir, subject_ids{s}, s);
	savesamesize(gcf, 'file', file_name, 'format', image_format);
end


function[] = plot_classification_results(tr_percent)

close all;

number_of_subjects = 7;
subject_ids = get_subject_ids(number_of_subjects);
result_dir = get_project_settings('results');
plot_dir = get_project_settings('plots');
image_format = get_project_settings('image_format');

for s = 7:number_of_subjects
	classifier_results = load(fullfile(result_dir, subject_ids{s}, sprintf('classifier_results_tr%d.mat', tr_percent)));
	nAnalysis = length(classifier_results.mean_over_runs);
	legend_str = {};
	for a = 1:nAnalysis
		mean_over_runs = classifier_results.mean_over_runs{1, a};
		nFeatures = length(mean_over_runs);
		errorbars_over_runs = classifier_results.errorbars_over_runs{1, a};
		feature_str = classifier_results.feature_str{1, a};
		class_label = classifier_results.class_label{1, a};
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
		legend_str{a} = sprintf('%s vs %s', class_label{1}, class_label{2});
	end

	figure('visible', 'off'); set(gcf, 'Position', get_project_settings('figure_size'));
	bar([classifier_results.auc_over_runs{:}]);
	legend(legend_str, 'Location', 'South', 'Orientation', 'Horizontal');
	xlabel('Features'); ylabel('AUROC');
	set(gca, 'XTick', 1:nFeatures);
	set(gca, 'XTickLabel', feature_str);
	xlim([0.5, nFeatures+0.5]); grid on;
	title(sprintf('%s, within subject, Logistic reg, Area under ROC', get_project_settings('strrep_subj_id', subject_ids{s})));
	file_name = sprintf('%s/%s/class_subj%d_tr%d_auroc', plot_dir, subject_ids{s}, s, tr_percent);
	savesamesize(gcf, 'file', file_name, 'format', image_format);
end


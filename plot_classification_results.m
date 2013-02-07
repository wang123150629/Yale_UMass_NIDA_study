function[] = plot_classification_results()

close all;

number_of_subjects = 4;
subject_ids = get_subject_ids(number_of_subjects);
result_dir = get_project_settings('results');
plot_dir = get_project_settings('plots');
image_format = get_project_settings('image_format');

for s = 1:number_of_subjects
	classifier_results = load(fullfile(result_dir, subject_ids{s}, sprintf('classifier_results.mat')));
	nAnalysis = length(classifier_results.mean_over_runs);
	for a = 1:nAnalysis
		mean_over_runs = classifier_results.mean_over_runs{1, a};
		nFeatures = length(mean_over_runs);
		errorbars_over_runs = classifier_results.errorbars_over_runs{1, a};
		feature_str = classifier_results.feature_str{1, a};
		class_label = classifier_results.class_label{1, a};
		figure('visible', 'off'); set(gcf, 'Position', get_project_settings('figure_size'));
		errorbar(1:nFeatures, mean_over_runs, errorbars_over_runs, 'b', 'LineWidth', 2);
		hold on; grid on; xlim([1, nFeatures]); ylim([50, 102]);
		plot(1:nFeatures, mean(classifier_results.chance_baseline{1, a}, 2), 'r--');
		title(sprintf('%s, Logistic reg, %s vs. %s', get_project_settings('strrep_subj_id', subject_ids{s}),...
								class_label{1}, class_label{2}));
		xlabel('Analysis'); ylabel('Accuracy');
		set(gca, 'XTickLabel', feature_str);
		file_name = sprintf('%s/%s/%s_%d_classification_results', plot_dir, subject_ids{s}, subject_ids{s}, a);
		savesamesize(gcf, 'file', file_name, 'format', image_format);
	end
end


function[] = plot_wsubj_hrbased_results(tr_percent, varargin)

close all;

if length(varargin) > 0
	paper_quality = varargin{1};
else
	paper_quality = false;
end

nSubjects = 10;
subject_ids = get_subject_ids(nSubjects);
result_dir = get_project_settings('results');
plot_dir = get_project_settings('plots');
image_format = get_project_settings('image_format');

for s = 6:nSubjects
	classifier_results = load(fullfile(result_dir, subject_ids{s}, sprintf('%s_classifier_hrbased_results_tr%d.mat',...
				subject_ids{s}, tr_percent)));
	nAnalysis = length(classifier_results.mean_over_runs);
	legend_str = {};
	for a = 1:nAnalysis
		mean_over_runs = classifier_results.mean_over_runs{1, a};
		nFeatures = size(mean_over_runs, 1);
		feature_str = classifier_results.feature_str{1, a};
		class_label = classifier_results.class_label{1, a};
		legend_str = classifier_results.bin_str{1, a};
		nBins = length(legend_str);
		legend_str = legend_str(1, [find(sum(classifier_results.auc_over_runs{1, a}))]);

		figure('visible', 'off'); set(gcf, 'Position', get_project_settings('figure_size'));
		h1 = bar([classifier_results.auc_over_runs{1, a}]);
		title(sprintf('%s, within subject, Logistic reg, Area under ROC\n%s vs %s',...
				get_project_settings('strrep_subj_id', subject_ids{s}), class_label{1}, class_label{2}));
		legend([h1([find(sum(classifier_results.auc_over_runs{1, a}))])], legend_str,...
						'Location', 'South', 'Orientation', 'Horizontal');
		xlabel('Features'); ylabel('AUROC');
		set(gca, 'XTick', 1:nFeatures);
		set(gca, 'XTickLabel', feature_str);
		xlim([0.5, nFeatures+0.5]); grid on;
		file_name = sprintf('%s/%s/%s_hrbased_%dbins_tr%d_%s_vs_%s', plot_dir, subject_ids{s}, subject_ids{s},...
				nBins, tr_percent, class_label{1}, class_label{2});
		savesamesize(gcf, 'file', file_name, 'format', image_format);
	end
end


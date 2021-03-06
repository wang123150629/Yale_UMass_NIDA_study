function[] = pairwise_driver()

nSubjects = 6;
set_of_features_to_try = [7, 8, 9];
nRuns = 1;
classifierList = {@two_class_l2_logreg};
classes_to_classify = [1, 2; 1, 3; 1, 4; 1, 5];

nAnalysis = size(classes_to_classify, 1);
subject_ids = get_subject_ids(nSubjects);
result_dir = get_project_settings('results');

for s = 1:nSubjects
	train_subject = [s];
	other_subjects = setdiff(1:nSubjects, s);
	for o = 1:length(other_subjects)
		test_subject = [other_subjects(o)];
		fprintf('pair=%d vs %d\n', train_subject, test_subject);
		mean_over_runs = cell(1, nAnalysis);
		errorbars_over_runs = cell(1, nAnalysis);
		tpr_over_runs = cell(1, nAnalysis);
		fpr_over_runs = cell(1, nAnalysis);
		auc_over_runs = cell(1, nAnalysis);
		chance_baseline = cell(1, nAnalysis);
		feature_str = cell(1, nAnalysis);
		class_label = cell(1, nAnalysis);
		for c = 1:nAnalysis
			[mean_over_runs{1, c}, errorbars_over_runs{1, c}, tpr_over_runs{1, c}, fpr_over_runs{1, c},...
			 auc_over_runs{1, c}, feature_str{1, c}, class_label{1, c}, chance_baseline{1, c}] =...
			pairwise_cross_val({subject_ids{1, train_subject}}, {subject_ids{1, test_subject}},...
				classes_to_classify(c, :), set_of_features_to_try, nRuns, classifierList);
		end
		classifier_results = struct();
		classifier_results.mean_over_runs = mean_over_runs;
		classifier_results.errorbars_over_runs = errorbars_over_runs;
		classifier_results.tpr_over_runs = tpr_over_runs;
		classifier_results.fpr_over_runs = fpr_over_runs;
		classifier_results.auc_over_runs = auc_over_runs;
		classifier_results.feature_str = feature_str;
		classifier_results.class_label = class_label;
		classifier_results.chance_baseline = chance_baseline;
		save(fullfile(result_dir, subject_ids{s}, sprintf('%s_pairwise_%d_vs_%d_results', subject_ids{s},...
				train_subject, test_subject)), '-struct', 'classifier_results');
	end
end


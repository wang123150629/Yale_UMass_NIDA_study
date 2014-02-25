function[] = cross_val_driver()

nSubjects = 13;
set_of_features_to_try = [8, 9];
nRuns = 1;
classifierList = {@two_class_l2_logreg};
classes_to_classify = [1, 2; 1, 3; 1, 4; 1, 5];

nAnalysis = size(classes_to_classify, 1);
subject_ids = get_subject_ids(nSubjects);
% Leaving out subjects P20_053 and P20_061 since they only have blinded session data (no baseline, no fixed sessions)
subject_ids = subject_ids(1, [1:6, 8, 10:end]);
nSubjects = length(subject_ids);
result_dir = get_project_settings('results');

for s = 1:nSubjects
	train_subjects = setdiff(1:nSubjects, s);
	test_subjects = [s];
	fprintf('fold=%d\n', s);
	fprintf('train subjects=[%s]\n', strtrim(sprintf('%d ', train_subjects)));
	fprintf('test subjects=[%s]\n', strtrim(sprintf('%d ', test_subjects)));
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
		cross_validation_over_subjects({subject_ids{1, train_subjects}}, {subject_ids{1, test_subjects}},...
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
	save(fullfile(result_dir, subject_ids{s}, sprintf('%s_cross_val_results', subject_ids{s})), '-struct', 'classifier_results');
end


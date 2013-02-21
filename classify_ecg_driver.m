function[] = classify_ecg_driver(tr_percent)

number_of_subjects = 6;
set_of_features_to_try = [1:13];
nRuns = 1;
% classifierList = {@two_class_linear_kernel_logreg, @two_class_logreg, @two_class_svm_linear};
classifierList = {@two_class_logreg};

subject_ids = get_subject_ids(number_of_subjects);
result_dir = get_project_settings('results');

for s = 1:number_of_subjects
	switch subject_ids{s}
	case 'P20_036', classes_to_classify = [1, 2; 1, 3; 1, 4; 1, 5];
	case 'P20_039', classes_to_classify = [1, 2; 1, 3; 1, 4; 1, 5];
	case 'P20_040', classes_to_classify = [1, 2; 1, 3; 1, 4; 1, 5];
	case 'P20_048', classes_to_classify = [1, 2; 1, 3; 1, 4; 1, 5];
	case 'P20_058', classes_to_classify = [1, 2; 1, 3; 1, 4; 1, 5];
	case 'P20_060', classes_to_classify = [1, 2; 1, 3; 1, 4; 1, 5; 5, 9; 5, 10; 9, 10];
	end
	nAnalysis = size(classes_to_classify, 1);
	mean_over_runs = cell(1, nAnalysis);
	errorbars_over_runs = cell(1, nAnalysis);
	tpr_over_runs = cell(1, nAnalysis);
	fpr_over_runs = cell(1, nAnalysis);
	auc_over_runs = cell(1, nAnalysis);
	chance_baseline = cell(1, nAnalysis);
	feature_str = cell(1, nAnalysis);
	class_label = cell(1, nAnalysis);
	for c = 1:nAnalysis
		[mean_over_runs{1, c}, errorbars_over_runs{1, c}, feature_str{1, c}, class_label{1, c},...
		chance_baseline{1, c}, tpr_over_runs{1, c}, fpr_over_runs{1, c}, auc_over_runs{1, c}] =...
				classify_ecg_data(subject_ids{s}, classes_to_classify(c, :),...
				set_of_features_to_try, nRuns, tr_percent, classifierList);
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
	save(fullfile(result_dir, subject_ids{s}, sprintf('classifier_results_tr%d', tr_percent)), '-struct', 'classifier_results');
end


function[] = classify_ecg_driver()

classes_to_classify = [1, 2; 1, 3; 1, 4; 5, 6];
nAnalysis = size(classes_to_classify, 1);
set_of_features_to_try = [1:8];
nRuns = 5;
tr_percent = 80;
% vclassifierList = {@two_class_logreg, @two_class_svm};
classifierList = {@two_class_logreg};

number_of_subjects = 4;
subject_ids = get_subject_ids(number_of_subjects);

result_dir = get_project_settings('results');

for s = 1:number_of_subjects
	mean_over_runs = cell(1, nAnalysis);
	errorbars_over_runs = cell(1, nAnalysis);
	chance_baseline = cell(1, nAnalysis);
	feature_str = cell(1, nAnalysis);
	class_label = cell(1, nAnalysis);
	for c = 1:size(classes_to_classify, 1)
		[mean_over_runs{1, c}, errorbars_over_runs{1, c}, feature_str{1, c}, class_label{1, c}, chance_baseline{1, c}] =...
				classify_ecg_data(subject_ids{s}, classes_to_classify(c, :),...
				set_of_features_to_try, nRuns, tr_percent, classifierList);
	end
	classifier_results = struct();
	classifier_results.mean_over_runs = mean_over_runs;
	classifier_results.errorbars_over_runs = errorbars_over_runs;
	classifier_results.feature_str = feature_str;
	classifier_results.class_label = class_label;
	classifier_results.chance_baseline = chance_baseline;
	save(fullfile(result_dir, subject_ids{s}, sprintf('classifier_results')), '-struct', 'classifier_results');
end


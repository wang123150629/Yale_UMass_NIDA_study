function[mean_over_runs, errorbars_over_runs,...
	 tpr_over_runs, fpr_over_runs,...
	 auc_over_runs, feature_str,...
	 class_label, chance_baseline] = cross_validation_over_subjects(train_subject_ids, test_subject_ids,...
					 classes_to_classify, set_of_features_to_try, nRuns, classifierList, varargin)

nFeatures = length(set_of_features_to_try);
nClassifiers = numel(classifierList);
nClasses = length(classes_to_classify);
if nargin < 6, error('Missing input arguments!'); end
assert(nClasses == 2);

feature_str = cell(1, nFeatures);
mean_over_runs = NaN(nFeatures, nClassifiers);
errorbars_over_runs = NaN(nFeatures, nClassifiers);
tpr_over_runs = NaN(nFeatures, nClassifiers);
fpr_over_runs = NaN(nFeatures, nClassifiers);
auc_over_runs = NaN(nFeatures, nClassifiers);

[complete_train_set, complete_test_set, class_label, chance_baseline] = gather_train_test_data_relabel(train_subject_ids,...
									test_subject_ids, classes_to_classify);

% Loop over all features to try while trimming off irrelevant columns
for f = 1:length(set_of_features_to_try)
	accuracies = NaN(nRuns, nClassifiers);
	true_pos_rate = NaN(nRuns, nClassifiers);
	false_pos_rate = NaN(nRuns, nClassifiers);
	auc = NaN(nRuns, nClassifiers);
	
	[train_set, test_set, feature_str{1, f}] = trim_features(complete_train_set, complete_test_set, set_of_features_to_try(f));

	for r = 1:nRuns
		for k = 1:nClassifiers
			if isempty(varargin)
				lambda = estimate_lambda(train_subject_ids, test_subject_ids, classes_to_classify,...
					       [set_of_features_to_try(f)], nRuns, {classifierList{k}});
				save_betas = sprintf('crossval_%s_feat%d_%d_vs_%d', test_subject_ids{1},...
					set_of_features_to_try(f), classes_to_classify(1), classes_to_classify(2));
			else
				lambda = varargin{1};
				save_betas = '';
			end
			fprintf('\tf=%d, k=%d, lambda=%0.6f\n', set_of_features_to_try(f), k, lambda);
			[accuracies(r, k), true_pos_rate(r, k), false_pos_rate(r, k), auc(r, k)] =...
							classifierList{k}(train_set, test_set, lambda, save_betas);
		end
	end
	mean_over_runs(f, :) = mean(accuracies, 1);
	errorbars_over_runs(f, :) = std(accuracies, [], 1) ./ nRuns;
	tpr_over_runs(f, :) = mean(true_pos_rate, 1);
	fpr_over_runs(f, :) = mean(false_pos_rate, 1);
	auc_over_runs(f, :) = mean(auc, 1);
end


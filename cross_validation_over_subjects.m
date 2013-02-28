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
			else
				lambda = varargin{1};
			end
			fprintf('\tf=%d, k=%d, lambda=%0.6f\n', set_of_features_to_try(f), k, lambda);
			[accuracies(r, k), true_pos_rate(r, k), false_pos_rate(r, k), auc(r, k)] =...
							classifierList{k}(train_set, test_set, lambda);
		end
	end
	mean_over_runs(f, :) = mean(accuracies, 1);
	errorbars_over_runs(f, :) = std(accuracies, [], 1) ./ nRuns;
	tpr_over_runs(f, :) = mean(true_pos_rate, 1);
	fpr_over_runs(f, :) = mean(false_pos_rate, 1);
	auc_over_runs(f, :) = mean(auc, 1);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[complete_train_set, complete_test_set, class_label, chance_baseline] = gather_train_test_data_relabel(train_subject_ids,...
										test_subject_ids, classes_to_classify)

nClasses = length(classes_to_classify);
class_label = cell(1, nClasses);
complete_train_set = [];
complete_test_set = [];
chance_baseline = [];

% Prop up train dataset for all cross val train subjects
for s = 1:numel(train_subject_ids)
	for c = 1:nClasses
		complete_train_set = [complete_train_set; massage_data(train_subject_ids{s}, classes_to_classify(c))];
		if s == 1
			class_information = classifier_profile(classes_to_classify(c));
			class_label{1, c} = class_information{1, 1}.label;
		end
	end
end

% Prop up test dataset for all cross val test subjects
for s = 1:numel(test_subject_ids)
	for c = 1:nClasses
		test_set = massage_data(test_subject_ids{s}, classes_to_classify(c));
		complete_test_set = [complete_test_set; test_set];
		chance_baseline = [chance_baseline, size(test_set, 1)];
	end
end

% change labels for train and test set
unique_labels = unique(complete_train_set(:, end));
% Reassigning the labels to -1 and 1 for two-class classification
if length(unique_labels) == 2
	complete_train_set(find(unique_labels(1) == complete_train_set(:, end)), end) = -1;
	complete_train_set(find(unique_labels(2) == complete_train_set(:, end)), end) = 1;
	complete_test_set(find(unique_labels(1) == complete_test_set(:, end)), end) = -1;
	complete_test_set(find(unique_labels(2) == complete_test_set(:, end)), end) = 1;
elseif length(unique_labels) == 4
	complete_train_set(find(complete_train_set(:, end) < 0), end) = -1;
	complete_train_set(find(complete_train_set(:, end) > 0), end) = 1;
	complete_test_set(find(complete_test_set(:, end) < 0), end) = -1;
	complete_test_set(find(complete_test_set(:, end) > 0), end) = 1;
else
	error('Invalid classes to compare!');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[train_set, test_set, feature_str] = trim_features(complete_train_set, complete_test_set, feature)

% for train set
[train_set, feature_str] = setup_features(complete_train_set, feature);
% for test set
test_set = setup_features(complete_test_set, feature);
assert(size(train_set, 2) >= 4);

label_col = size(train_set, 2);
expsess_col = size(train_set, 2)-1;
dosage_col = size(train_set, 2)-2;
feature_cols = 1:size(train_set, 2)-3;
train_set = train_set(:, [feature_cols, label_col]);
test_set = test_set(:, [feature_cols, label_col]);


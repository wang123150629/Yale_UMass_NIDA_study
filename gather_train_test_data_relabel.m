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


function[complete_train_set, complete_test_set, chance_baseline] = partition_and_relabel(data, tr_percent)

partitioning_style = 2;

labels = unique(data(:, end));

complete_train_set = [];
complete_test_set = [];
chance_baseline = [];
for c = 1:length(labels)
	[train_set, test_set] = fetch_training_instances(labels(c), data, tr_percent, partitioning_style);
	complete_train_set = [complete_train_set; train_set];
	complete_test_set = [complete_test_set; test_set];
	chance_baseline = [chance_baseline, size(test_set, 1)];
end
chance_baseline = max(chance_baseline) / sum(chance_baseline) * 100;

% change labels
unique_labels = unique(complete_train_set(:, end));
% Reassigning the labels to 0 and 1 for two-class classification
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


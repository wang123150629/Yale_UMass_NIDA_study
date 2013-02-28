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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[train_set, test_set] = fetch_training_instances(target_class, data, tr_percent, partitioning_style)

assert(size(data, 2) >= 4);

label_col = size(data, 2);
expsess_col = size(data, 2)-1;
dosage_col = size(data, 2)-2;
feature_cols = 1:size(data, 2)-3;

switch partitioning_style
case 1
	target_idx = find(data(:, label_col) == target_class);
	all_samples = target_idx(randperm(length(target_idx)));
	temp_tr = round_to(tr_percent * length(all_samples) / 100, 0);
	train_samples = all_samples(1:temp_tr);
case 2
	train_samples = [];
	all_samples = data(:, label_col) == target_class;
	expsess = unique(data(:, expsess_col));
	for e = 1:length(expsess)
		temp_expsess = data(:, expsess_col) == expsess(e);
		dosage = unique(data(:, dosage_col));
		for d = 1:length(dosage)
			temp_dosage = data(:, dosage_col) == dosage(d);
			samples_match = find(temp_expsess & temp_dosage & all_samples);
			temp_tr = round_to(tr_percent * length(samples_match) / 100, 0);
			train_samples = [train_samples; samples_match(1:temp_tr)];
		end
	end
	all_samples = find(all_samples);
end

test_samples = setdiff(all_samples, train_samples);
assert(isempty(intersect(train_samples, test_samples)));
train_set = data(train_samples, [feature_cols, label_col]);
test_set = data(test_samples, [feature_cols, label_col]);


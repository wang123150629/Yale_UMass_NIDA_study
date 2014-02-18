function[partitioned_data, title_str] = load_partition_data(analysis_id, subject_id, first_baseline_subtract,...
					partition_train_set, use_multiple_u_labels)

results_dir = get_project_settings('results');
plot_dir = get_project_settings('plots');

% dimm = 1 is within peaks and dimm = 2 is across peaks i.e. over points
dimm = 1;
window_size = 25;
% Checking if window size is odd
assert(mod(window_size, 2) > 0);
clusters_apart = get_project_settings('clusters_apart');
filter_size = get_project_settings('filter_size');
cluster_partition = 3;
h = fspecial('gaussian', [1, filter_size], 150);
h = h / sum(h);

if use_multiple_u_labels
	load(fullfile(results_dir, 'labeled_peaks', sprintf('%s_relabel_u_grnd_trth.mat', subject_id)));
	assert(size(labeled_peaks, 1) == 4);
else
	load(fullfile(results_dir, 'labeled_peaks', sprintf('%s_grnd_trth.mat', subject_id)));
end
clear time_matrix;
% The last entry is a pair of empty ""
% time_matrix = time_matrix(1, 1:end-1);
% time_matrix = time_matrix(1, filter_size/2:end-filter_size/2);

switch subject_id
case 'P20_040'
	magic_idx = get_project_settings('magic_idx', subject_id);
	labeled_peaks = labeled_peaks(:, magic_idx);
end

% Reading off data from the interface file
ecg_raw = labeled_peaks(1, :);
if first_baseline_subtract
	% Performing baseline correction
	ecg_data = ecg_raw - conv(ecg_raw, h, 'same');
else
	ecg_data = ecg_raw;
end
ecg_data = ecg_data(filter_size/2:end-filter_size/2);

peak_idx = labeled_peaks(3, :) > 0;
peak_idx = peak_idx(filter_size/2:end-filter_size/2);
peak_idx(1, [1:window_size, end-window_size:end]) = 0;

labeled_idx = labeled_peaks(3, :) > 0 & labeled_peaks(3, :) < 100;
labeled_idx = labeled_idx(filter_size/2:end-filter_size/2);
labeled_idx(1, [1:window_size, end-window_size:end]) = 0;

if use_multiple_u_labels
	peak_labels = labeled_peaks(4, :);
else
	peak_labels = labeled_peaks(3, :);
end
peak_labels = peak_labels(filter_size/2:end-filter_size/2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Identifying the labelled, unlabelled peaks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
unlabeled_idx = find(peak_idx - labeled_idx);
assert(~isempty(unlabeled_idx));
ln_idx = unlabeled_idx;

% Finding which of those peaks are in fact hand labelled
labeled_peaks_idx = peak_idx & labeled_idx;
valid_peak_idx = find(labeled_peaks_idx);
valid_clusters = [0, find(diff(valid_peak_idx) > clusters_apart)];
cluster_partition = floor([1:length(valid_clusters)/cluster_partition:length(valid_clusters), length(valid_clusters)]);
assert(length(cluster_partition) == 4);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Clustering the data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch partition_train_set
case 1
	ordered_valid_clusters = 1:length(valid_clusters);
	train_clusters = ordered_valid_clusters(cluster_partition(1):cluster_partition(2));
	validate_clusters = ordered_valid_clusters(cluster_partition(2)+1:cluster_partition(3));
	test_clusters = ordered_valid_clusters(cluster_partition(3)+1:cluster_partition(4));
case 2
	ordered_valid_clusters = randperm(length(valid_clusters));
	train_clusters = ordered_valid_clusters(cluster_partition(1):cluster_partition(2));
	validate_clusters = ordered_valid_clusters(cluster_partition(2)+1:cluster_partition(3));
	test_clusters = ordered_valid_clusters(cluster_partition(3)+1:cluster_partition(4));
case 3
	cross_validation = load(sprintf('%s/sparse_coding/%s/%s_cross_validation.mat', plot_dir, analysis_id, analysis_id));
	train_clusters = [cross_validation.clusters_within_bins{1, cross_validation.train_set{1, cross_validation.which_fold}}];
	validate_clusters = [cross_validation.clusters_within_bins{1, cross_validation.validate_set{1, cross_validation.which_fold}}];
	test_clusters = [cross_validation.clusters_within_bins{1, cross_validation.test_set{1, cross_validation.which_fold}}];
	cross_validation.which_fold = cross_validation.which_fold + 1;
	save(sprintf('%s/sparse_coding/%s/%s_cross_validation.mat', plot_dir, analysis_id, analysis_id), '-struct', 'cross_validation');
otherwise
	error('Invalid partition flag!');
end
assert(length(train_clusters)+length(validate_clusters)+length(test_clusters) == length(valid_clusters));

% Note this line of code will need to be down here since I using the length of this variable above - DO NOT MOVE
valid_clusters = [valid_clusters, length(valid_peak_idx)];

tr_temp_idx = [];
for tr = 1:length(train_clusters)
	% By indexing into train_cluster(tr) I get a number between 1 and 93 say 5. At position 5 in the valid_cluster
	% there is an index 49 sitting. This 49 is where a cluster actually ends hence valid_clusters(49)+1 will give us
	% the first peak in the next cluster. For the end of the cluster we use valid_clusters(49+1) = valid_clusters(50)
	% summary: valid_clusters(49)+1:valid_clusters(50) i.e. 1162+1:1184 == 1163:1184. Recall valid_peak_idx is just
	% the location of all labelled peaks
	tr_temp_idx = [tr_temp_idx, valid_peak_idx(valid_clusters(train_clusters(tr))+1:valid_clusters(train_clusters(tr)+1))];
end
tr_idx = sort(tr_temp_idx);
assert(isequal(sum(diff(tr_idx) > clusters_apart)+1, length(train_clusters)));

vl_temp_idx = [];
for vl = 1:length(validate_clusters)
	vl_temp_idx = [vl_temp_idx, valid_peak_idx(valid_clusters(validate_clusters(vl))+1:valid_clusters(validate_clusters(vl)+1))];
end
vl_idx = sort(vl_temp_idx);
assert(isequal(sum(diff(vl_idx) > clusters_apart)+1, length(validate_clusters)));

ts_temp_idx = [];
for ts = 1:length(test_clusters)
	ts_temp_idx = [ts_temp_idx, valid_peak_idx(valid_clusters(test_clusters(ts))+1:valid_clusters(test_clusters(ts)+1))];
end
ts_idx = sort(ts_temp_idx);
assert(isequal(sum(diff(ts_idx) > clusters_apart)+1, length(test_clusters)));

assert(isequal(length(tr_idx) + length(vl_idx) + length(ts_idx), length(valid_peak_idx)));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Grabbing a window of data around each peak
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
unlabeled_idx = [unlabeled_idx - window_size; unlabeled_idx + window_size];
unlabeled_idx = floor(linspaceNDim(unlabeled_idx(1, :), unlabeled_idx(2, :), window_size*2+1));
ecg_learn = ecg_data(unlabeled_idx)';

train_win_idx = [tr_idx - window_size; tr_idx + window_size];
train_win_idx = floor(linspaceNDim(train_win_idx(1, :), train_win_idx(2, :), window_size*2+1));
ecg_train = ecg_data(train_win_idx)';

validate_win_idx = [vl_idx - window_size; vl_idx + window_size];
validate_win_idx = floor(linspaceNDim(validate_win_idx(1, :), validate_win_idx(2, :), window_size*2+1));
ecg_validate = ecg_data(validate_win_idx)';

test_win_idx = [ts_idx - window_size; ts_idx + window_size];
test_win_idx = floor(linspaceNDim(test_win_idx(1, :), test_win_idx(2, :), window_size*2+1));
ecg_test = ecg_data(test_win_idx)';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Grabbing the height of peaks before normalizing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
learn_peak_heights = ecg_learn(window_size+1, :);
train_peak_heights = ecg_train(window_size+1, :);
validate_peak_heights = ecg_validate(window_size+1, :);
test_peak_heights = ecg_test(window_size+1, :);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Performing subtractive normalization only
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ecg_learn = bsxfun(@minus, ecg_learn, mean(ecg_learn, dimm));
ecg_train = bsxfun(@minus, ecg_train, mean(ecg_train, dimm));
ecg_validate = bsxfun(@minus, ecg_validate, mean(ecg_validate, dimm));
ecg_test = bsxfun(@minus, ecg_test, mean(ecg_test, dimm));

assert(isequal(size(ecg_learn, 1), size(ecg_train, 1)));
assert(isequal(size(ecg_learn, 1), size(ecg_validate, 1)));
assert(isequal(size(ecg_learn, 1), size(ecg_test, 1)));

pooled_std = std([reshape(ecg_learn, 1, size(ecg_learn, 1) * size(ecg_learn, 2)),...
	     reshape(ecg_train, 1, size(ecg_train, 1) * size(ecg_train, 2)),...
	     reshape(ecg_validate, 1, size(ecg_validate, 1) * size(ecg_validate, 2)),...
	     reshape(ecg_test, 1, size(ecg_test, 1) * size(ecg_test, 2))]);

partitioned_data = struct();
partitioned_data.learn_snormed = ecg_learn;
partitioned_data.train_snormed = ecg_train;
partitioned_data.validate_snormed = ecg_validate;
partitioned_data.test_snormed = ecg_test;
partitioned_data.train_idx = tr_idx;
partitioned_data.validate_idx = vl_idx;
partitioned_data.test_idx = ts_idx;
partitioned_data.learn_std = std(ecg_learn, [], dimm);
partitioned_data.train_std = std(ecg_train, [], dimm);
partitioned_data.validate_std = std(ecg_validate, [], dimm);
partitioned_data.test_std = std(ecg_test, [], dimm);
partitioned_data.pooled_std = pooled_std;
partitioned_data.learn_heights = learn_peak_heights;
partitioned_data.train_heights = train_peak_heights;
partitioned_data.validate_heights = validate_peak_heights;
partitioned_data.test_heights = test_peak_heights;
partitioned_data.train_Y = peak_labels(tr_idx)';
partitioned_data.validate_Y = peak_labels(vl_idx)';
partitioned_data.test_Y = peak_labels(ts_idx)';
partitioned_data.raw_ecg_data_length = length(ecg_data);
partitioned_data.nLabels = length(unique(partitioned_data.train_Y));

assert(length(unique(partitioned_data.train_Y)) == length(unique(partitioned_data.validate_Y)));
assert(length(unique(partitioned_data.train_Y)) == length(unique(partitioned_data.test_Y)));

title_str = '';
if first_baseline_subtract, title_str = strcat(title_str, 'bl+'); end
% if sparse_code_peaks, title_str = strcat(title_str, sprintf('sc(%0.4f)+', lambda)); end
switch partition_train_set
case 1, title_str = strcat(title_str, 'T+');
case 2, title_str = strcat(title_str, 'R+');
case 3, title_str = strcat(title_str, 'C+');
otherwise, error('Invalid train/test partition!');
end


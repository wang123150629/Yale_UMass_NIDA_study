function[mul_accuracy, crf_accuracy, mean_dict_elements] = sparse_coding_old(sparse_coding, variable_window, normalize, add_height, add_diff, first_baseline_subtract, initial_lambda)

% sparse_coding(true, true, false, false, true, true, 0.015)

close all;

data_dir = get_project_settings('data');
results_dir = get_project_settings('results');

global label_str
global D
window_size = 25;
tr_partition = 50;
uniform_split = true;
nDictionayElements = 100;
nIterations = 1000;
lambda = initial_lambda;

filter_size = 10000;
h = fspecial('gaussian', [1, filter_size], 150);
h = h / sum(h);

subject_id = 'P20_040';
event = 1;
subject_profile = subject_profiles(subject_id);
subject_sensor = subject_profile.events{event}.sensor;
subject_timestamp = subject_profile.events{event}.timestamp;

% old file : Only five peaks lebelled, unknown peaks assigned previous valid peaks' labels
% load(fullfile(results_dir, 'labeled_peaks', sprintf('%s_temp3_labels.mat', subject_id)));

% New file : Six labels P, Q, R, S, T, U - Unknown
load(fullfile(results_dir, 'labeled_peaks', sprintf('%s_new_labels.mat', subject_id)));

% Reading off data from the interface file
ecg_raw = labeled_peaks(1, :);

if first_baseline_subtract
	% Performing baseline correction
	ecg_data = ecg_raw - conv(ecg_raw, h, 'same');
else
	ecg_data = ecg_raw;
end

ecg_data = ecg_data(filter_size/2:end-filter_size/2);

peak_idx = labeled_peaks(2, :) > 0;
peak_idx = peak_idx(filter_size/2:end-filter_size/2);
peak_idx(1:window_size) = 0;
peak_idx(end-window_size:end) = 0;

labeled_idx = labeled_peaks(3, :) > 0 & labeled_peaks(3, :) < 100;
labeled_idx = labeled_idx(filter_size/2:end-filter_size/2);
labeled_idx(1:window_size) = 0;
labeled_idx(end-window_size:end) = 0;

peak_labels = labeled_peaks(3, :);
peak_labels = peak_labels(filter_size/2:end-filter_size/2);

% Finding which of those peaks are in fact hand labelled
labeled_peaks_idx = peak_idx & labeled_idx;

estimated_hr = ones(size(ecg_data)) * -1;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Computing the HR for each of the peaks (NOTE: Now all peaks are associated with a HR; NOT just labelled peaks)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This mat holds the new range 70 to 140
load('/home/anataraj/NIH-craving/results/labeled_peaks/assigned_hr_bl_subtract_sgram_071313.mat');
% This mat holds the old range 50 to 200
% load('/home/anataraj/NIH-craving/results/labeled_peaks/assigned_hr_bl_subtract_sgram_062113.mat');

% estimated_hr(peak_idx) = compute_hr('rr', ecg_data, peak_idx, subject_profile.events{event}.rr_thresholds);
% estimated_hr(peak_idx) = compute_hr('fft', ecg_data, peak_idx);
% load('/home/anataraj/NIH-craving/results/labeled_peaks/assigned_hr_fft_053013.mat');
% estimated_hr(peak_idx) = assigned_hr;
% load('/home/anataraj/NIH-craving/results/labeled_peaks/assigned_hr_sgram_061013.mat');
% estimated_hr = compute_hr('sgram', ecg_data, peak_idx);
% estimated_hr = compute_hr('wavelet', ecg_data);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
estimated_hr(peak_idx) = assigned_hr;

if uniform_split
	nBins = 3;
	tmp_valid_hr = estimated_hr(estimated_hr > 0);
	binned_hr = ntile_split(tmp_valid_hr, nBins);
	for b = 1:nBins
		hr_bins(b, :) = [min(tmp_valid_hr(binned_hr{b})), max(tmp_valid_hr(binned_hr{b}))];
		new_hr_str{b} = sprintf('%d--%d', floor(min(tmp_valid_hr(binned_hr{b}))), floor(max(tmp_valid_hr(binned_hr{b}))));
	end
else
	hr_bins = [50, 99; 100, 119; 120, 1000];
	new_hr_str = {'80--100', '100--120', '>120'};
end

param = struct();
if sparse_coding
	unlabeled_idx = find(peak_idx - labeled_idx);
	assert(~isempty(unlabeled_idx));
	unlabeled_idx = [unlabeled_idx - window_size; unlabeled_idx + window_size];
	unlabeled_idx = floor(linspaceNDim(unlabeled_idx(1, :), unlabeled_idx(2, :), window_size*2+1));
	ecg_learn = ecg_data(unlabeled_idx)';
	if variable_window
		ecg_learn = window_and_interpolate(ecg_learn, floor(estimated_hr(find(peak_idx - labeled_idx))), window_size);
	end
	peak_heights = ecg_learn(window_size+1, :);
	if normalize
		ecg_learn = bsxfun(@minus, ecg_learn, mean(ecg_learn, 2));
	end
	if add_height
		keyboard % incorrect approach will need to add height only before the actual classification
		ecg_learn = [bsxfun(@minus, ecg_learn, mean(ecg_learn, 2)); peak_heights];
	end
	param.K = nDictionayElements;  % learns a dictionary with 100 elements
	param.iter = nIterations;  % let us see what happens after 1000 iterations
	param.lambda = lambda;
	param.numThreads = 4; % number of threads
	param.batchsize = 400;
	param.approx = 0;
	param.verbose = false;

	D = mexTrainDL(ecg_learn, param);
end

mul_accuracy = NaN(size(hr_bins, 1), size(hr_bins, 1));
crf_accuracy = NaN(size(hr_bins, 1), size(hr_bins, 1));
avg_crf_log_likelihood = NaN(size(hr_bins, 1), size(hr_bins, 1));
mean_dict_elements = NaN(size(hr_bins, 1), size(hr_bins, 1));
incorrect_indices = {};
for hr1 = 1:size(hr_bins, 1)
	% Training instances. Finding which of the hand labelled peaks fall within the valid HR range
	valid_tr_idx = estimated_hr >= hr_bins(hr1, 1) & estimated_hr <= hr_bins(hr1, 2);
	valid_tr_idx = find(valid_tr_idx & labeled_peaks_idx);
	% No permutation
	tr_idx = valid_tr_idx(1:floor(length(valid_tr_idx) * tr_partition / 100));
	for hr2 = 1:size(hr_bins, 1)
		init_option = str2num(sprintf('%d%d', hr1, hr2));

		% Testing instances. Finding which of the hand labelled peaks fall within the valid HR range
		valid_ts_idx = estimated_hr >= hr_bins(hr2, 1) & estimated_hr <= hr_bins(hr2, 2);
		valid_ts_idx = find(valid_ts_idx & labeled_peaks_idx);
		% No permutation
		ts_idx = valid_ts_idx(floor(length(valid_ts_idx) * tr_partition / 100)+1:end);

		assert(isempty(intersect(tr_idx, ts_idx)));

		fprintf('tr=%d, ts=%d, tr length=%d, actual=%d, ts length=%d, actual=%d\n', hr1, hr2, length(valid_tr_idx),...
			length(tr_idx), length(valid_ts_idx), length(ts_idx));

		[mul_accuracy(hr1, hr2), crf_accuracy(hr1, hr2), avg_crf_log_likelihood(hr1, hr2),...
		 mean_dict_elements(hr1, hr2), incorrect_indices{hr1, hr2}] =...
					analyze_based_on_HR(tr_idx, ts_idx, peak_idx, labeled_idx, window_size,...
					peak_labels, ecg_data, init_option, estimated_hr, param,...
					variable_window, sparse_coding, first_baseline_subtract, normalize,...
					add_height, add_diff);
	end
end

label_str = new_hr_str;
sparse_coding_plots(9, mul_accuracy, crf_accuracy, avg_crf_log_likelihood, 0, label_str, variable_window, sparse_coding);
sparse_coding_plots(13, incorrect_indices, ecg_data, labeled_peaks_idx, estimated_hr, hr_bins);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[mul_accuracy, crf_accuracy, avg_crf_log_likelihood, mean_dict_elements, incorrect_indices] =...
								analyze_based_on_HR(tr_idx, ts_idx, peak_idx,...
								labeled_idx, window_size, peak_labels, ecg_data, init_option,...
								estimated_hr, param, variable_window,...
								sparse_coding, first_baseline_subtract, normalize,...
								add_height, add_diff)

assert(all(estimated_hr(peak_idx) > 50));
assert(~isempty(tr_idx));
assert(~isempty(ts_idx));

global D;
global label_str
label_str = {'P', 'Q', 'R', 'S', 'T', 'U'};
mean_dict_elements = [];

train_win_idx = [tr_idx - window_size; tr_idx + window_size];
train_win_idx = floor(linspaceNDim(train_win_idx(1, :), train_win_idx(2, :), window_size*2+1));
ecg_train = ecg_data(train_win_idx)';
ecg_train_Y = peak_labels(tr_idx);
assert(~any(ecg_train_Y <= 0 | ecg_train_Y >= 100));
if variable_window
	ecg_train = window_and_interpolate(ecg_train, floor(estimated_hr(tr_idx)), window_size);
end
peak_heights = ecg_train(window_size+1, :);
if normalize
	ecg_train = bsxfun(@minus, ecg_train, mean(ecg_train, 2));
end
if add_height
	ecg_train = [bsxfun(@minus, ecg_train, mean(ecg_train, 2)); peak_heights];
end

test_win_idx = [ts_idx - window_size; ts_idx + window_size];
test_win_idx = floor(linspaceNDim(test_win_idx(1, :), test_win_idx(2, :), window_size*2+1));
ecg_test = ecg_data(test_win_idx)';
ecg_test_Y = peak_labels(ts_idx);
assert(~any(ecg_test_Y <= 0 | ecg_test_Y >= 100));
if variable_window
	ecg_test = window_and_interpolate(ecg_test, floor(estimated_hr(ts_idx)), window_size);
end
peak_heights = ecg_test(window_size+1, :);
if normalize
	ecg_test = bsxfun(@minus, ecg_test, mean(ecg_test, 2));
	keyboard % you will need to divide by std dev
end
if add_height
	ecg_test = [bsxfun(@minus, ecg_test, mean(ecg_test, 2)); peak_heights];
end

if sparse_coding
	param.mode = 2;
	train_alpha = mexLasso(ecg_train, D, param);
	test_alpha = mexLasso(ecg_test, D, param);
	on_dict_elements = [train_alpha, test_alpha] > 0;
	mean_dict_elements = mean(sum(on_dict_elements));
	if add_diff
		train_alpha = [train_alpha; sum(ecg_train - D * train_alpha)];
		test_alpha = [test_alpha; sum(ecg_test - D * test_alpha)];
	end
else
	train_alpha = ecg_train;
	test_alpha = ecg_test;
end

sparse_coding_plots(2, param, D);
% sparse_coding_plots(3, 1:10, ecg_train, peak_labels, train_alpha, D, tr_idx, 'tr');
% sparse_coding_plots(3, 1:10, ecg_test, peak_labels, test_alpha, D, ts_idx, 'ts');

% perform six class classification using multinomial logistic regression
[mul_confusion_mat, mul_predicted_label] = multinomial_log_reg(train_alpha', ecg_train_Y', test_alpha', ecg_test_Y');
% mul_confusion_mat = bsxfun(@rdivide, mul_confusion_mat, sum(mul_confusion_mat, 2));
% mul_accuracy = sum(diag(mul_confusion_mat)) / sum(mul_confusion_mat(:));
mul_accuracy = sum(mul_confusion_mat(:)) - sum(diag(mul_confusion_mat));

% perform classification using basic CRF's
[crf_confusion_mat, avg_crf_log_likelihood, crf_predicted_label] = basic_crf_classification(tr_idx, ts_idx, train_alpha',...
							ecg_train_Y', test_alpha', ecg_test_Y', init_option);
% crf_confusion_mat = bsxfun(@rdivide, crf_confusion_mat, sum(crf_confusion_mat, 2));
% crf_accuracy = sum(diag(crf_confusion_mat)) / sum(crf_confusion_mat(:));
crf_accuracy = sum(crf_confusion_mat(:)) - sum(diag(crf_confusion_mat));

incorrect_indices = ts_idx(find(crf_predicted_label ~= ecg_test_Y'));

sparse_coding_plots(4, mul_confusion_mat, crf_confusion_mat, init_option, label_str, variable_window, sparse_coding);
sparse_coding_plots(10, ecg_train, ecg_train_Y, ecg_test, ecg_test_Y, crf_predicted_label', mul_predicted_label',...
			init_option, variable_window, sparse_coding, first_baseline_subtract);
sparse_coding_plots(3, find(crf_predicted_label ~= ecg_test_Y'), ecg_test, peak_labels, test_alpha(1:100, :), D,...
						ts_idx, sprintf('ts%d', init_option), crf_predicted_label);

sparse_coding_plots(14, ecg_test, D, test_alpha(1:100, :), crf_predicted_label, ecg_test_Y', init_option);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[confusion_mat, avg_crf_log_likelihood, predicted_label] = basic_crf_classification(tr_idx, ts_idx, ecg_train_X,...
									ecg_train_Y, ecg_test_X, ecg_test_Y, init_option)

% The next two lines converts [1, 24, 31 ...] into [1, 25, 32, ... ; 24, 31, 45,...]
train_clusters = find(diff(tr_idx) > 100);
train_clusters = [1, train_clusters+1; train_clusters, length(tr_idx)];
% I am only choosing a cluster only if it has atleast 2 peaks
valid_tr_cluster_idx = diff(train_clusters) > 1;
train_clusters = train_clusters(:, valid_tr_cluster_idx);

labels = unique(ecg_train_Y);
% optimize featue and transition parameters

keyboard

[feature_params, trans_params] = optimize_feat_trans_params(train_clusters, ecg_train_X, ecg_train_Y, labels);

% sparse_coding_plots(5, exp(feature_params), exp(trans_params), init_option, D, label_str);

% These tell you where a cluster ends
test_clusters = find(diff(ts_idx) > 100);
% These give you the start and end points of a cluster
test_clusters = [1, test_clusters+1; test_clusters, length(ts_idx)];
% I am only choosing a cluster only if it has atleast 2 peaks
valid_ts_cluster_idx = diff(test_clusters) > 1;
test_clusters = test_clusters(:, valid_ts_cluster_idx);
nLabels = length(labels);

fprintf('nTrain=%d, nTest=%d\n', size(train_clusters, 2), size(test_clusters, 2)); 

[log_likelihood, all_unary_marginals, all_pairwise_marginals] =...
				sum_prdt_msg_passing(feature_params, trans_params, test_clusters, ecg_test_X, ecg_test_Y, nLabels);

nTestSamples = length(all_unary_marginals);
predicted_label = NaN(size(ecg_test_Y)); 
for t = 1:nTestSamples
	unary_marginals = all_unary_marginals{t};
	[junk, predicted_label(test_clusters(1, t):test_clusters(2, t), 1)] = max([unary_marginals{:}], [], 1);
end

confusion_mat = confusionmat(ecg_test_Y, predicted_label);
avg_crf_log_likelihood = mean(log_likelihood);

sparse_coding_plots(12, ecg_train_X, ecg_test_X, ecg_train_Y, ecg_test_Y, predicted_label, init_option);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[confusion_mat, yhatt] = multinomial_log_reg(ecg_train_X, ecg_train_Y, ecg_test_X, ecg_test_Y)

labels = unique(ecg_train_Y);
nClasses = length(labels);
nVars = size(ecg_train_X, 2);
options.Display = 0;

% Adding bias
ecg_train_X = [ones(size(ecg_train_X, 1), 1), ecg_train_X];
ecg_test_X = [ones(size(ecg_test_X, 1), 1), ecg_test_X];

funObj = @(W)SoftmaxLoss2(W, ecg_train_X, ecg_train_Y, nClasses);
lambda = 1e-4 * ones(nVars+1, nClasses-1);
lambda(1, :) = 0; % Don't penalize biases
wSoftmax = minFunc(@penalizedL2, zeros((nVars+1) * (nClasses-1), 1), options, funObj, lambda(:));
wSoftmax = reshape(wSoftmax, [nVars+1, nClasses-1]);
wSoftmax = [wSoftmax, zeros(nVars+1, 1)];

[junk, yhatt] = max(ecg_test_X * wSoftmax, [], 2);

confusion_mat = confusionmat(ecg_test_Y, yhatt);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[ecg_samples] = window_and_interpolate(ecg_samples, hr_to_resize, window_size)

global label_str;
results_dir = get_project_settings('results');
plot_dir = get_project_settings('plots');
image_format = get_project_settings('image_format');

% The lower bound 30.3237 comes from taking the slope of the within RT distance
varying_windows = floor(linspace(50, 30.3237, 151));
hr_range = floor(linspace(70, 140, 151));
mid_point = floor(window_size+1);
assert(isequal(size(ecg_samples, 2), size(hr_to_resize, 2)));

for i = 1:size(hr_to_resize, 2)
	varying_window_entry = varying_windows(find(hr_range == hr_to_resize(i)));
	assert(~isempty(varying_window_entry));
	one_half = floor(varying_window_entry/2);
	new_window = mid_point-one_half:mid_point+one_half;
	new_wini = linspace(1, length(new_window), window_size*2+1);
	ecg_samples(:, i) = interp1(1:length(new_window), ecg_samples(new_window, i), new_wini, 'pchip');
end



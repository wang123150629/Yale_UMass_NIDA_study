function[] = sparse_coding(first_baseline_subtract, sparse_code_peaks, variable_window, normalize, add_height,...
				add_summ_diff, add_all_diff, lambda, analysis_id, subject_id, title_str, data_split,...
				partition_train_set)

data_dir = get_project_settings('data');
results_dir = get_project_settings('results');

% dimm = 1 is within peaks and dimm = 2 is across peaks i.e. over points
dimm = 1;
filter_size = 10000;
matching_pm = 4;

[train_alpha, ecg_train_Y, tr_idx, test_alpha, ecg_test_Y, ts_idx, learn_alpha, ln_idx, ecg_data, hr_bins] =...
					load_hr_ecg(first_baseline_subtract, sparse_code_peaks, variable_window,...
					normalize, add_height, add_summ_diff, add_all_diff, subject_id, lambda,...
					data_split, dimm, analysis_id, filter_size, partition_train_set);

crf_summary_mat = NaN(size(hr_bins, 1));
mul_summary_mat = NaN(size(hr_bins, 1));
crf_total_errors = 0;
mul_total_errors = 0;
for hr1 = 1:size(hr_bins, 1)
	hold_crf_predicted_label = {};
	hold_test_clusters = {};
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Learn CRF model paramters
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	[feature_params, trans_params] = build_feature_trans_parms(train_alpha{hr1}', ecg_train_Y{hr1}', tr_idx{hr1});

	for hr2 = 1:size(hr_bins, 1)
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		% Multinomial Logistic regression
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		[mul_confusion_mat, mul_predicted_label] =...
				multinomial_log_reg(train_alpha{hr1}', ecg_train_Y{hr1}', test_alpha{hr2}', ecg_test_Y{hr2}');

		mul_summary_mat(hr1, hr2) = sum(diag(mul_confusion_mat)) / sum(mul_confusion_mat(:));
		assert(isequal(sum(mul_confusion_mat(:)) - sum(diag(mul_confusion_mat)),...
			sum(mul_predicted_label ~= ecg_test_Y{hr2}')));
		mul_total_errors = mul_total_errors + (sum(mul_confusion_mat(:)) - sum(diag(mul_confusion_mat)));

		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		% CRF test set predictions
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		[crf_confusion_mat, crf_predicted_label, test_clusters] =...
				basic_crf_classification(test_alpha{hr2}', ecg_test_Y{hr2}', ts_idx{hr2}, feature_params, trans_params);

		crf_summary_mat(hr1, hr2) = sum(diag(crf_confusion_mat)) / sum(crf_confusion_mat(:));
		assert(isequal(sum(crf_confusion_mat(:)) - sum(diag(crf_confusion_mat)),...
			sum(crf_predicted_label ~= ecg_test_Y{hr2}')));
		crf_total_errors = crf_total_errors + (sum(crf_confusion_mat(:)) - sum(diag(crf_confusion_mat)));

		% I gather this data to make some fancy plots later
		hold_crf_predicted_label{hr2} = crf_predicted_label';
		hold_test_clusters{hr2} = test_clusters;

		fprintf('tr=%d, ts=%d, tr length=%d, ts length=%d\n', hr1, hr2, length(tr_idx{hr1}), length(ts_idx{hr2}));
		%--------------------------------------------------------------------------------------------------------------------
		% sparse_coding_plots(4, mul_confusion_mat, crf_confusion_mat, title_str, analysis_id, sprintf('%d%d', hr1, hr2));
		% ecg_test_reconstructions and ecg_test_originals will need to come from load_hr_ecg
		% sparse_coding_plots(14, ecg_test_originals{hr2}, ecg_test_reconstructions{hr2}, ecg_test_Y{hr2}',...
		%			crf_predicted_label, analysis_id);
	end
	% time_matrix will ned to come from load_hr_ecg
	% sparse_coding_plots(16, ecg_data, time_matrix, hold_crf_predicted_label, hold_test_clusters, ts_idx,...
	%			sprintf('%s%d', analysis_id, hr1));
end
% sparse_coding_plots(9, mul_summary_mat, crf_summary_mat, mul_total_errors, crf_total_errors, hr_bins, title_str, analysis_id);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CRF learn set predictions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

crf_learn_predlbl{1} = zeros(1, length(ln_idx{1}));
% [crf_learn_predlbl{1}, learn_clusters{1}] = label_learn_samples(learn_alpha{1}', ln_idx{1},...
%						length(unique(ecg_train_Y{1})), feature_params, trans_params);
% time_matrix will need to come from load_hr_ecg
% sparse_coding_plots(16, ecg_data, time_matrix, crf_learn_predlbl, learn_clusters, ln_idx, analysis_id);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ECGPUWave predictions on test set
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
filter_size = filter_size/2 - 1;
% purely for sanity check
shifted_ecg_data = [zeros(1, filter_size), ecg_data, zeros(1, filter_size+1)];
nEntries = length(shifted_ecg_data);
magic_idx = [1.29e+5:7.138e+5, 7.806e+5:3.4e+6, 3.515e+6:nEntries];

peak_labels_crf = zeros(1, nEntries);
peak_labels_crf(1, filter_size+tr_idx{1}) = ecg_train_Y{1}';
peak_labels_crf(1, filter_size+ts_idx{1}) = crf_predicted_label';
peak_labels_crf(1, filter_size+ln_idx{1}) = crf_learn_predlbl{1}';
assert(sum(peak_labels_crf(1:filter_size)) == 0);
assert(sum(peak_labels_crf(end-filter_size:end)) == 0);
assert(sum(isnan(peak_labels_crf)) == 0);
peak_labels_crf = peak_labels_crf(1, magic_idx);

load(fullfile(pwd, 'ecgpuwave', 'annotations', sprintf('%s_wqrs.mat', subject_id)));
peak_labels_puwave = ones(1, length(magic_idx)) .* 6;
peak_labels_puwave(1, annt.P(~isnan(annt.P))) = 1;
peak_labels_puwave(1, annt.Q(~isnan(annt.Q))) = 2;
peak_labels_puwave(1, annt.R(~isnan(annt.R))) = 3;
% nine labels 7 - Q's and 2 - P's
peak_labels_puwave(1, annt.S(~isnan(annt.S))) = 4;
peak_labels_puwave(1, annt.T(~isnan(annt.T))) = 5;
assert(sum(isnan(peak_labels_puwave)) == 0);
assert(length(unique(peak_labels_puwave)) == 6);

shifted_ecg_test_Y = zeros(1, nEntries);
shifted_ecg_test_Y(filter_size+ts_idx{1}) = ecg_test_Y{1};
shifted_ecg_test_Y = shifted_ecg_test_Y(1, magic_idx);
target_idx = find(shifted_ecg_test_Y);

matching_confusion_mat = matching_driver(target_idx, shifted_ecg_test_Y, annt, matching_pm, peak_labels_crf);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generating plots and book keeping
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mul_confusion_mat = bsxfun(@rdivide, mul_confusion_mat, sum(mul_confusion_mat, 2));
matching_confusion_mat = bsxfun(@rdivide, matching_confusion_mat, sum(matching_confusion_mat, 2));
crf_confusion_mat = bsxfun(@rdivide, crf_confusion_mat, sum(crf_confusion_mat, 2));
sparse_coding_plots(17, {sprintf('Mul Log. Reg.'), sprintf('Matching, %s%d', setstr(177), matching_pm),...
			sprintf('Basic CRF\n%s', title_str)}, analysis_id,...
			mul_confusion_mat, matching_confusion_mat, crf_confusion_mat);

keyboard

write_to_html(analysis_id, subject_id, lambda, 100, first_baseline_subtract, sparse_code_peaks, variable_window, normalize,...
		add_height, add_summ_diff, add_all_diff, mul_summary_mat, crf_summary_mat, mul_total_errors, crf_total_errors,...
		data_split, dimm, partition_train_set);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[confusion_mat, predicted_label, test_clusters] =...
					basic_crf_classification(test_alpha, ecg_test_Y, ts_idx, feature_params, trans_params)

labels = unique(ecg_test_Y);
nLabels = length(labels);

% The next two lines converts [1, 24, 31 ...] into [1, 25, 32, ... ; 24, 31, 45,...]
test_clusters = find(diff(ts_idx) > 100);
test_clusters = [1, test_clusters+1; test_clusters, length(ts_idx)];
% I am only choosing a cluster only if it has atleast 2 peaks
valid_ts_cluster_idx = diff(test_clusters) > 1;
test_clusters = test_clusters(:, valid_ts_cluster_idx);

fprintf('nTest=%d\n', size(test_clusters, 2)); 

[all_unary_marginals, all_pairwise_marginals] = sum_prdt_msg_passing(feature_params, trans_params, test_clusters, test_alpha, [], nLabels);

nTestSamples = length(all_unary_marginals);
predicted_label = NaN(size(test_alpha, 1), 1);
for t = 1:nTestSamples
	unary_marginals = all_unary_marginals{t};
	[junk, predicted_label(test_clusters(1, t):test_clusters(2, t), 1)] = max([unary_marginals{:}], [], 1);
end
assert(~any(isnan(predicted_label)));
confusion_mat = confusionmat(ecg_test_Y, predicted_label);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[predicted_label, learn_clusters] = label_learn_samples(learn_alpha, ln_idx, nLabels, feature_params, trans_params)

% The next two lines converts [1, 24, 31 ...] into [1, 25, 32, ... ; 24, 31, 45,...]
learn_clusters = find(diff(ln_idx) > 100);
learn_clusters = [1, learn_clusters+1; learn_clusters, length(ln_idx)];
% I am only choosing a cluster only if it has atleast 2 peaks
valid_ln_cluster_idx = diff(learn_clusters) > 1;
learn_clusters = learn_clusters(:, valid_ln_cluster_idx);

fprintf('nLearn=%d\n', size(learn_clusters, 2));

[all_unary_marginals, all_pairwise_marginals] =...
				sum_prdt_msg_passing(feature_params, trans_params, learn_clusters, learn_alpha, [], nLabels);

nLearnSamples = length(all_unary_marginals);
predicted_label = NaN(size(learn_alpha, 1), 1); 
for t = 1:nLearnSamples
	unary_marginals = all_unary_marginals{t};
	[junk, predicted_label(learn_clusters(1, t):learn_clusters(2, t), 1)] = max([unary_marginals{:}], [], 1);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[feature_params, trans_params] = build_feature_trans_parms(train_alpha, ecg_train_Y, tr_idx)

labels = unique(ecg_train_Y);
nLabels = length(labels);

% The next two lines converts [1, 24, 31 ...] into [1, 25, 32, ... ; 24, 31, 45,...]
train_clusters = find(diff(tr_idx) > 100);
train_clusters = [1, train_clusters+1; train_clusters, length(tr_idx)];
% I am only choosing a cluster only if it has atleast 2 peaks
valid_tr_cluster_idx = diff(train_clusters) > 1;
train_clusters = train_clusters(:, valid_tr_cluster_idx);

fprintf('nTrain=%d ', size(train_clusters, 2));

% optimize feature and transition parameters
[feature_params, trans_params] = optimize_feat_trans_params(train_clusters, train_alpha, ecg_train_Y, labels);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[confusion_mat, yhatt] = multinomial_log_reg(train_alpha, ecg_train_Y, test_alpha, ecg_test_Y)

labels = unique(ecg_train_Y);
nClasses = length(labels);
nVars = size(train_alpha, 2);
options.Display = 0;

% Adding bias
train_alpha = [ones(size(train_alpha, 1), 1), train_alpha];
test_alpha = [ones(size(test_alpha, 1), 1), test_alpha];

funObj = @(W)SoftmaxLoss2(W, train_alpha, ecg_train_Y, nClasses);
lambda = 1e-4 * ones(nVars+1, nClasses-1);
lambda(1, :) = 0; % Don't penalize biases
wSoftmax = minFunc(@penalizedL2, zeros((nVars+1) * (nClasses-1), 1), options, funObj, lambda(:));
wSoftmax = reshape(wSoftmax, [nVars+1, nClasses-1]);
wSoftmax = [wSoftmax, zeros(nVars+1, 1)];

[junk, yhatt] = max(test_alpha * wSoftmax, [], 2);

confusion_mat = confusionmat(ecg_test_Y, yhatt);

%{
% I use this code to write out mats which I use in ECGPUWave toolbox comparisons
misc_mat = struct();
nEntries = 5945750;
filter_size = 10000;
filter_size = filter_size/2 - 1;

% Initializing both train, predicted test and learn predicted learn set peak labels
misc_mat.peak_labels = zeros(1, nEntries);
misc_mat.peak_labels(1, filter_size+tr_idx{1}) = ecg_train_Y{1}';
misc_mat.peak_labels(1, filter_size+ts_idx{1}) = crf_predicted_label';
misc_mat.peak_labels(1, filter_size+ln_idx{1}) = crf_learn_predlbl{1}';
% Making sure nothing is written before and after filter size / 2
assert(sum(misc_mat.peak_labels(1:filter_size)) == 0);
assert(sum(misc_mat.peak_labels(end-filter_size:end)) == 0);
% Initializing groud truth test set peak labels
misc_mat.ts_grnd_lbl = zeros(1, nEntries);
misc_mat.ts_grnd_lbl(filter_size+ts_idx{1}) = ecg_test_Y{1};
misc_mat.title_str = title_str;
misc_mat.mul_confusion_mat = mul_confusion_mat;
save(sprintf('misc_mats/%s_info.mat', analysis_id), '-struct', 'misc_mat');
%}


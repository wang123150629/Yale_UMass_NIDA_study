function[] = sparse_coding(first_baseline_subtract, sparse_code_peaks, variable_window, normalize, add_height, add_summ_diff,...
 					add_all_diff, lambda, analysis_id, subject_id, title_str, data_split)

data_dir = get_project_settings('data');
results_dir = get_project_settings('results');

window_size = 19;
tr_partition = 50;
uniform_split = true;
nDictionayElements = 100;
nIterations = 1000;
filter_size = 10000;

assert(mod(window_size, 2) > 0);

[train_alpha, ecg_train_Y, tr_idx, test_alpha, ecg_test_Y, ts_idx, learn_alpha, ln_idx, ecg_data, hr_bins] =...
				load_hr_ecg(first_baseline_subtract, sparse_code_peaks, variable_window,...
				normalize, add_height, add_summ_diff, add_all_diff, subject_id, lambda, data_split);

[crf_learn_predlbl, learn_clusters] = label_learn_samples(train_alpha, ecg_train_Y, tr_idx, learn_alpha{1}', ln_idx{1});
sparse_coding_plots(16, ecg_data, crf_learn_predlbl, learn_clusters, ln_idx{1}, analysis_id);

keyboard

crf_summary_mat = NaN(size(hr_bins, 1));
mul_summary_mat = NaN(size(hr_bins, 1));
crf_total_errors = 0;
mul_total_errors = 0;
for hr1 = 1:size(hr_bins, 1)
	[feature_params, trans_params] = build_feature_trans_parms(train_alpha{hr1}', ecg_train_Y{hr1}', tr_idx{hr1});
	for hr2 = 1:size(hr_bins, 1)
		%--------------------------------------------------------------------------------------------------------------------
		[mul_confusion_mat, mul_predicted_label] =...
				multinomial_log_reg(train_alpha{hr1}', ecg_train_Y{hr1}', test_alpha{hr2}', ecg_test_Y{hr2}');

		mul_summary_mat(hr1, hr2) = sum(diag(mul_confusion_mat)) / sum(mul_confusion_mat(:));
		assert(isequal(sum(mul_confusion_mat(:)) - sum(diag(mul_confusion_mat)),...
			sum(mul_predicted_label ~= ecg_test_Y{hr2}')));
		mul_total_errors = mul_total_errors + (sum(mul_confusion_mat(:)) - sum(diag(mul_confusion_mat)));

		%--------------------------------------------------------------------------------------------------------------------
		[crf_confusion_mat, crf_predicted_label] =...
				basic_crf_classification(test_alpha{hr2}', ecg_test_Y{hr2}', ts_idx{hr2}, feature_params, trans_params);

		crf_summary_mat(hr1, hr2) = sum(diag(crf_confusion_mat)) / sum(crf_confusion_mat(:));
		assert(isequal(sum(crf_confusion_mat(:)) - sum(diag(crf_confusion_mat)),...
			sum(crf_predicted_label ~= ecg_test_Y{hr2}')));
		crf_total_errors = crf_total_errors + (sum(crf_confusion_mat(:)) - sum(diag(crf_confusion_mat)));

		fprintf('tr=%d, ts=%d, tr length=%d, ts length=%d\n', hr1, hr2, length(tr_idx{hr1}), length(ts_idx{hr2}));
		%--------------------------------------------------------------------------------------------------------------------
		sparse_coding_plots(4, mul_confusion_mat, crf_confusion_mat, title_str, analysis_id, sprintf('%d%d', hr1, hr2));
	end
end
sparse_coding_plots(9, mul_summary_mat, crf_summary_mat, mul_total_errors, crf_total_errors, hr_bins, title_str, analysis_id);

write_to_html(analysis_id, subject_id, lambda, 100, first_baseline_subtract, sparse_code_peaks, variable_window, normalize,...
	add_height, add_summ_diff, add_all_diff, mul_summary_mat, crf_summary_mat, mul_total_errors, crf_total_errors, data_split);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[confusion_mat, predicted_label] = basic_crf_classification(test_alpha, ecg_test_Y, ts_idx, feature_params, trans_params)

labels = unique(ecg_test_Y);
nLabels = length(labels);

% The next two lines converts [1, 24, 31 ...] into [1, 25, 32, ... ; 24, 31, 45,...]
test_clusters = find(diff(ts_idx) > 100);
test_clusters = [1, test_clusters+1; test_clusters, length(ts_idx)];
% I am only choosing a cluster only if it has atleast 2 peaks
valid_ts_cluster_idx = diff(test_clusters) > 1;
test_clusters = test_clusters(:, valid_ts_cluster_idx);

fprintf('nTest=%d\n', size(test_clusters, 2)); 

[all_unary_marginals, all_pairwise_marginals] =...
				sum_prdt_msg_passing(feature_params, trans_params, test_clusters, test_alpha, [], nLabels);

nTestSamples = length(all_unary_marginals);
predicted_label = NaN(size(test_alpha, 1), 1); 
for t = 1:nTestSamples
	unary_marginals = all_unary_marginals{t};
	[junk, predicted_label(test_clusters(1, t):test_clusters(2, t), 1)] = max([unary_marginals{:}], [], 1);
end
confusion_mat = confusionmat(ecg_test_Y, predicted_label);

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
function[predicted_label, learn_clusters] = label_learn_samples(tr_alpha, ecg_tr_Y, tr_idx, learn_alpha, ln_idx)

train_alpha = [];
ecg_train_Y = [];
train_idx = [];
for tr = 1:length(tr_alpha)
	train_alpha = [train_alpha; tr_alpha{tr}'];
	ecg_train_Y = [ecg_train_Y; ecg_tr_Y{tr}'];
	train_idx = [train_idx, tr_idx{tr}];
end

[feature_params, trans_params] = build_feature_trans_parms(train_alpha, ecg_train_Y, train_idx);

labels = unique(ecg_train_Y);
nLabels = length(labels);

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


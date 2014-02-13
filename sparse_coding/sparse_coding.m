function[mul_confusion_mat, matching_confusion_mat, crf_confusion_mat] = sparse_coding(first_baseline_subtract,...
				sparse_code_peaks, variable_window, normalize, add_height,...
				add_summ_diff, add_all_diff, lambda, analysis_id, grnd_trth_subject_id, title_str, data_split,...
				partition_train_set, puwave_subject_id, matching_pm, from_wrapper, give_it_some_slack)

data_dir = get_project_settings('data');
results_dir = get_project_settings('results');
plot_dir = get_project_settings('plots');

% dimm = 1 is within peaks and dimm = 2 is across peaks i.e. over points
dimm = 1;
filter_size = 10000;
clusters_apart = get_project_settings('clusters_apart');

[train_alpha, ecg_train_Y, tr_idx, test_alpha, ecg_test_Y, ts_idx, learn_alpha, ln_idx, ecg_data, hr_bins] =...
					load_hr_ecg(first_baseline_subtract, sparse_code_peaks, variable_window,...
					normalize, add_height, add_summ_diff, add_all_diff, grnd_trth_subject_id, lambda,...
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
	[feature_params, trans_params] = build_feature_trans_parms(train_alpha{hr1}', ecg_train_Y{hr1}', tr_idx{hr1}, clusters_apart);

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
		[crf_confusion_mat, crf_predicted_label, test_clusters] = basic_crf_classification(...
							 test_alpha{hr2}', ecg_test_Y{hr2}', ts_idx{hr2},...
							 feature_params, trans_params,...
							 length(unique(ecg_train_Y{hr1})), clusters_apart);

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

% If any of these asserts crashes you will need to scan through and fix all places that use a {1} to index into these cells
assert(length(ln_idx) == 1);
assert(length(ts_idx) == 1);
assert(length(ecg_test_Y) == 1);
assert(length(ecg_train_Y) == 1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CRF learn set predictions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

crf_learn_predlbl{1} = zeros(1, length(ln_idx{1}));
% [junk, crf_learn_predlbl{1}, learn_clusters{1}] = basic_crf_classification(learn_alpha{1}', [], ln_idx{1},...
%						feature_params, trans_params, length(unique(ecg_train_Y{1})), clusters_apart);
% time_matrix will need to come from load_hr_ecg
% sparse_coding_plots(16, ecg_data, time_matrix, crf_learn_predlbl, learn_clusters, ln_idx, analysis_id);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ECGPUWave predictions on test set
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
filter_size = filter_size / 2 - 1;
ground_truth_test_labels = zeros(1, (length(ecg_data)+2*filter_size+1));
ground_truth_test_labels(filter_size+ts_idx{1}) = ecg_test_Y{1};
nLabels = length(unique(ecg_test_Y{1}));

ecg_labels = {'P', 'Q', 'R', 'S', 'T'};
load(fullfile(pwd, 'ecgpuwave', 'annotations', sprintf('%s.mat', puwave_subject_id)));
temp_indices = [annt.P, annt.Q, annt.R, annt.S, annt.T];
puwave_pred_labels = zeros(1, max(temp_indices));
for e = 1:numel(ecg_labels)
	temp_indices = getfield(annt, ecg_labels{e});
	temp_indices = temp_indices(~isnan(temp_indices));
	puwave_pred_labels(temp_indices) = repmat(e, 1, length(temp_indices));
	clear temp_indices;
end

matching_confusion_mat = matching_driver(ground_truth_test_labels, puwave_pred_labels, matching_pm, nLabels, false);
matching_total_errors = sum(matching_confusion_mat(:)) - sum(diag(matching_confusion_mat));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CRF predictions are matched Matching style
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pred_crf_test_labels = zeros(1, (length(ecg_data)+2*filter_size+1));
pred_crf_test_labels(filter_size+ts_idx{1}) = crf_predicted_label;
if give_it_some_slack
	%{
	sparse_coding_plots(18, ground_truth_test_labels, pred_crf_test_labels, matching_pm,...
		false, {'P', 'Q', 'R', 'S', 'T', 'U'}, 'Predictions', grnd_trth_subject_id, analysis_id);
	sparse_coding_plots(18, pred_crf_test_labels, ground_truth_test_labels, matching_pm,...
		false, {'P', 'Q', 'R', 'S', 'T', 'U'}, 'Ground-truth', grnd_trth_subject_id, analysis_id);
	%}
	sparse_coding_plots(19, ground_truth_test_labels, pred_crf_test_labels, 50,...
		false, {'P', 'Q', 'R', 'S', 'T', 'U'}, 'Predictions', grnd_trth_subject_id, analysis_id);
	sparse_coding_plots(19, pred_crf_test_labels, ground_truth_test_labels, 50,...
		false, {'P', 'Q', 'R', 'S', 'T', 'U'}, 'Ground-truth', grnd_trth_subject_id, analysis_id);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generating plots and book keeping
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~from_wrapper
	sparse_coding_plots(17, {sprintf('Mul Log. Reg.'), sprintf('Matching, %s%d', setstr(177), matching_pm),...
				sprintf('Basic CRF\n%s', title_str)}, analysis_id,...
				bsxfun(@rdivide, mul_confusion_mat, sum(mul_confusion_mat, 2)),...
				bsxfun(@rdivide, matching_confusion_mat, sum(matching_confusion_mat, 2)),...
				bsxfun(@rdivide, crf_confusion_mat, sum(crf_confusion_mat, 2)));

	sum(mul_confusion_mat, 2)'
	sum(matching_confusion_mat, 2)'
	sum(crf_confusion_mat, 2)'
	dispf('Mul err=%d, Puwave=%d, crf err=%d', mul_total_errors, matching_total_errors, crf_total_errors);

	crf_model = struct();
	crf_model.feature_params = feature_params;
	crf_model.trans_params = trans_params;
	crf_model.ground_truth = ground_truth_test_labels;
	crf_model.mul_nom = zeros(1, (length(ecg_data)+2*filter_size+1));
	crf_model.mul_nom(filter_size+ts_idx{1}) = mul_predicted_label;
	crf_model.puwave = puwave_pred_labels;
	crf_model.crf = pred_crf_test_labels;
	save(sprintf('%s/sparse_coding/%s/%s_results.mat', plot_dir, analysis_id, analysis_id), '-struct', 'crf_model');

	keyboard

	write_to_html(analysis_id, grnd_trth_subject_id, lambda, 100, first_baseline_subtract, sparse_code_peaks,...
			variable_window, normalize,...
			add_height, add_summ_diff, add_all_diff, mul_summary_mat, crf_summary_mat, mul_total_errors, crf_total_errors,...
			data_split, dimm, partition_train_set);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[confusion_mat, predicted_label, used_clusters] = basic_crf_classification(vector_alpha, vector_Y, vector_idx,...
								feature_params, trans_params, nLabels, clusters_apart)

confusion_mat = [];
predicted_label = NaN(size(vector_alpha, 1), 1);
used_clusters = [];

% The next two lines converts [1, 24, 31 ...] into [1, 25, 32, ... ; 24, 31, 45,...]
used_clusters = find(diff(vector_idx) > clusters_apart);
used_clusters = [1, used_clusters+1; used_clusters, length(vector_idx)];
% I am only choosing a cluster only if it has atleast 2 peaks
valid_cluster_idx = diff(used_clusters) > 1;
used_clusters = used_clusters(:, valid_cluster_idx);

if isempty(vector_Y)
	fprintf('nLearn=%d\n', size(used_clusters, 2));
else
	fprintf('nTest=%d\n', size(used_clusters, 2));
end

[all_unary_marginals, all_pairwise_marginals] = sum_prdt_msg_passing(feature_params, trans_params, used_clusters,...
						vector_alpha, [], nLabels);

nSamples = length(all_unary_marginals);
for t = 1:nSamples
	unary_marginals = all_unary_marginals{t};
	[junk, predicted_label(used_clusters(1, t):used_clusters(2, t), 1)] = max([unary_marginals{:}], [], 1);
end
assert(~any(isnan(predicted_label)));
confusion_mat = confusionmat(vector_Y, predicted_label);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[feature_params, trans_params] = build_feature_trans_parms(train_alpha, ecg_train_Y, tr_idx, clusters_apart)

labels = unique(ecg_train_Y);
nLabels = length(labels);

% The next two lines converts [1, 24, 31 ...] into [1, 25, 32, ... ; 24, 31, 45,...]
train_clusters = find(diff(tr_idx) > clusters_apart);
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ECGPUWave predictions on test set
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
filter_size = filter_size/2 - 1;
% purely for sanity check
shifted_ecg_data = [zeros(1, filter_size), ecg_data, zeros(1, filter_size+1)];
nEntries = length(shifted_ecg_data);

peak_labels_crf = zeros(1, nEntries);

load(fullfile(pwd, 'ecgpuwave', 'annotations', sprintf('%s.mat', puwave_subject_id)));

shifted_ecg_test_Y = zeros(1, nEntries);
shifted_ecg_test_Y(filter_size+ts_idx{1}) = ecg_test_Y{1};
target_idx = find(shifted_ecg_test_Y);

matching_confusion_mat2 = matching_driver2(target_idx, shifted_ecg_test_Y, annt, matching_pm, peak_labels_crf);
%}

%{
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[predicted_label, learn_clusters] = label_learn_samples(learn_alpha, ln_idx, nLabels, feature_params,...
						trans_params, clusters_apart)

% The next two lines converts [1, 24, 31 ...] into [1, 25, 32, ... ; 24, 31, 45,...]
learn_clusters = find(diff(ln_idx) > clusters_apart);
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
%}

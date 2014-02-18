function[mul_confusion_mat, matching_confusion_mat, crf_confusion_mat] = sparse_coding(first_baseline_subtract,...
				sparse_code_peaks, variable_window, normalize, add_height,...
				add_summ_diff, add_all_diff, lambda, analysis_id, grnd_trth_subject_id, title_str,...
				partition_train_set, puwave_subject_id, matching_pm, from_wrapper, give_it_some_slack)

data_dir = get_project_settings('data');
results_dir = get_project_settings('results');
plot_dir = get_project_settings('plots');

filter_size = 10000;
clusters_apart = get_project_settings('clusters_apart');

[train_alpha, ecg_train_Y, tr_idx, test_alpha, ecg_test_Y, ts_idx, learn_alpha, ln_idx, ecg_data, D] =...
					load_hr_ecg(first_baseline_subtract, sparse_code_peaks, variable_window,...
					normalize, add_height, add_summ_diff, add_all_diff, grnd_trth_subject_id, lambda,...
					analysis_id, filter_size, partition_train_set);
fprintf('nTrain=%d, nTest=%d\n', length(tr_idx{1}), length(ts_idx{1}));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Learn CRF model parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[feature_params, trans_params] = build_feature_trans_parms(train_alpha{1}', ecg_train_Y{1}', tr_idx{1}, clusters_apart);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Multinomial Logistic regression
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[mul_confusion_mat, mul_predicted_label] = multinomial_log_reg(train_alpha{1}', ecg_train_Y{1}', test_alpha{1}', ecg_test_Y{1}');
assert(isequal(sum(mul_confusion_mat(:)) - sum(diag(mul_confusion_mat)), sum(mul_predicted_label ~= ecg_test_Y{1}')));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CRF test set predictions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[crf_confusion_mat, crf_predicted_label] = basic_crf_classification(test_alpha{1}', ecg_test_Y{1}', ts_idx{1},...
							feature_params, trans_params, length(unique(ecg_train_Y{1})),...
							clusters_apart);
assert(isequal(sum(crf_confusion_mat(:)) - sum(diag(crf_confusion_mat)), sum(crf_predicted_label ~= ecg_test_Y{1}')));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CRF learn set predictions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% [junk, crf_learn_predlbl{1}] = basic_crf_classification(learn_alpha{1}', [], ln_idx{1},...
%							feature_params, trans_params, length(unique(ecg_train_Y{1})), clusters_apart);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ECGPUWave test set predictions
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CRF predictions are matched Matching style
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pred_crf_test_labels = zeros(1, (length(ecg_data)+2*filter_size+1));
pred_crf_test_labels(filter_size+ts_idx{1}) = crf_predicted_label;
if give_it_some_slack
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
	dispf('Mul err=%d, Puwave=%d, crf err=%d', sum(mul_confusion_mat(:)) - sum(diag(mul_confusion_mat)),...
						   sum(matching_confusion_mat(:)) - sum(diag(matching_confusion_mat)),...
						   sum(crf_confusion_mat(:)) - sum(diag(crf_confusion_mat)));

	crf_model = struct();
	crf_model.feature_params = feature_params;
	crf_model.trans_params = trans_params;
	crf_model.ground_truth = ground_truth_test_labels;
	crf_model.mul_nom = zeros(1, (length(ecg_data)+2*filter_size+1));
	crf_model.mul_nom(filter_size+ts_idx{1}) = mul_predicted_label;
	crf_model.puwave = puwave_pred_labels;
	crf_model.crf = pred_crf_test_labels;
	crf_model.D = D;
	save(sprintf('%s/sparse_coding/%s/%s_results.mat', plot_dir, analysis_id, analysis_id), '-struct', 'crf_model');

	keyboard

	write_to_html(analysis_id, grnd_trth_subject_id, title_str, mul_confusion_mat, matching_confusion_mat, crf_confusion_mat);
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


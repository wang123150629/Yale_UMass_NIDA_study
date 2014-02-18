function[mul_confusion_mat, matching_confusion_mat, crf_confusion_mat,...
			crf_validate_errors, mul_validate_errors] = label_ecg_peaks(analysis_id, subject_id,...
									first_baseline_subtract, partition_train_set,...
									give_it_some_slack, matching_pm, from_wrapper,...
									use_multiple_u_labels)

plot_dir = get_project_settings('plots');
nPipelines = 9;
if nPipelines == 1, dispf('WARNING! number of pipelines is 1'); end

[partitioned_data, title_str] = load_partition_data(analysis_id, subject_id, first_baseline_subtract,...
								partition_train_set, use_multiple_u_labels);

crf_validate_errors = NaN(1, nPipelines);
mul_validate_errors = NaN(1, nPipelines);
for p = 1:nPipelines
	fprintf('Pipeline=%d ', p);
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% CRF learn feature and transition params
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	[train_alpha, validate_alpha] = setup_feature(p, partitioned_data, 'train', 'validate');

	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% CRF validate set predictions
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	[feature_params, trans_params] = build_feature_trans_parms(train_alpha, partitioned_data.train_Y, partitioned_data.train_idx);

	[crf_confusion_mat, crf_predicted_label] = basic_crf_classification(validate_alpha, partitioned_data.validate_Y,...
							partitioned_data.validate_idx,...
							feature_params, trans_params, partitioned_data.nLabels);
	assert(isequal(sum(crf_confusion_mat(:)) - sum(diag(crf_confusion_mat)), sum(crf_predicted_label ~= partitioned_data.validate_Y)));
	crf_validate_errors(1, p) = sum(partitioned_data.validate_Y ~= crf_predicted_label);

	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% MUL. Log. Reg. validate set predictions
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	[mul_confusion_mat, mul_predicted_label] = multinomial_log_reg(train_alpha, partitioned_data.train_Y,...
								validate_alpha, partitioned_data.validate_Y);
	assert(isequal(sum(mul_confusion_mat(:)) - sum(diag(mul_confusion_mat)), sum(mul_predicted_label ~= partitioned_data.validate_Y)));
	mul_validate_errors(1, p) = sum(partitioned_data.validate_Y ~= mul_predicted_label);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CRF test set predictions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[junk, best_crf_pipeline] = min(crf_validate_errors);
fprintf('Best Pipeline=%d ', best_crf_pipeline);
[train_alpha, test_alpha, crf_title_str, D] = setup_feature(best_crf_pipeline, partitioned_data, 'train', 'test', title_str);
[feature_params, trans_params] = build_feature_trans_parms(train_alpha, partitioned_data.train_Y, partitioned_data.train_idx);
[crf_confusion_mat, crf_predicted_label] = basic_crf_classification(test_alpha, partitioned_data.test_Y,...
						partitioned_data.test_idx,...
						feature_params, trans_params, partitioned_data.nLabels);
assert(isequal(sum(crf_confusion_mat(:)) - sum(diag(crf_confusion_mat)), sum(crf_predicted_label ~= partitioned_data.test_Y)));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MUl. Log. Reg. test set predictions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[junk, best_mul_pipeline] = min(mul_validate_errors);
[train_alpha, test_alpha, mul_title_str] = setup_feature(best_mul_pipeline, partitioned_data, 'train', 'test', title_str);
[mul_confusion_mat, mul_predicted_label] = multinomial_log_reg(train_alpha, partitioned_data.train_Y,...
							test_alpha, partitioned_data.test_Y);
assert(isequal(sum(mul_confusion_mat(:)) - sum(diag(mul_confusion_mat)), sum(mul_predicted_label ~= partitioned_data.test_Y)));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ECGPUWave test set predictions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
filter_size = get_project_settings('filter_size');
filter_size = filter_size / 2 - 1;
ground_truth_test_labels = zeros(1, (partitioned_data.raw_ecg_data_length+2*filter_size+1));
ground_truth_test_labels(filter_size+partitioned_data.test_idx) = partitioned_data.test_Y;
if use_multiple_u_labels
	ground_truth_test_labels(ground_truth_test_labels > 6) = 6;
end
nLabels = sum(unique(ground_truth_test_labels) > 0);

puwave_labels = {'P', 'Q', 'R', 'S', 'T'};
load(fullfile(pwd, 'ecgpuwave', 'annotations', sprintf('%s_wqrs.mat', subject_id)));
temp_indices = [annt.P, annt.Q, annt.R, annt.S, annt.T];
puwave_pred_labels = zeros(1, max(temp_indices));
for e = 1:numel(puwave_labels)
	temp_indices = getfield(annt, puwave_labels{e});
	temp_indices = temp_indices(~isnan(temp_indices));
	puwave_pred_labels(temp_indices) = repmat(e, 1, length(temp_indices));
	clear temp_indices;
end
matching_confusion_mat = matching_driver(ground_truth_test_labels, puwave_pred_labels, matching_pm, nLabels, false);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CRF predictions are matched Matching style
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pred_crf_test_labels = zeros(1, (partitioned_data.raw_ecg_data_length+2*filter_size+1));
pred_crf_test_labels(filter_size+partitioned_data.test_idx) = crf_predicted_label;
if use_multiple_u_labels
	pred_crf_test_labels(pred_crf_test_labels > 6) = 6;
end
if give_it_some_slack
	ecg_label_misc_plots(19, ground_truth_test_labels, pred_crf_test_labels, 50,...
		false, {'P', 'Q', 'R', 'S', 'T', 'U'}, 'Predictions', subject_id, analysis_id);
	ecg_label_misc_plots(19, pred_crf_test_labels, ground_truth_test_labels, 50,...
		false, {'P', 'Q', 'R', 'S', 'T', 'U'}, 'Ground-truth', subject_id, analysis_id);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generating plots and book keeping
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~from_wrapper
	ecg_label_misc_plots(17, {sprintf('Mul Log. Reg.'), sprintf('Matching, %s%d', setstr(177), matching_pm),...
				sprintf('Basic CRF\n%s', crf_title_str)}, analysis_id,...
				bsxfun(@rdivide, mul_confusion_mat, sum(mul_confusion_mat, 2)),...
				bsxfun(@rdivide, matching_confusion_mat, sum(matching_confusion_mat, 2)),...
				bsxfun(@rdivide, crf_confusion_mat, sum(crf_confusion_mat, 2)));

	% Note: When you sum the columns (2nd dimension) of the confusion matrix the U entries in the matching matrix will be
	% slightly more than the ground truth U entries. This is because
	% Grnd: p q   r s t
	% pred: p q r r s t. In the grnd truth predictions there is a label missing hence matching algorithm will introduce a U
	% to fill the gap, this leads to Grnd: p q u r s t and pred: p q r r s t. Hence when matching thee is going to be an
	% extra entry in the U row but r column. Hence summing over columns we see a couple of extra U's
	sum(mul_confusion_mat, 2)'
	sum(matching_confusion_mat, 2)'
	sum(crf_confusion_mat, 2)'
	dispf('Mul err=%d, Puwave=%d, crf err=%d', sum(mul_confusion_mat(:)) - sum(diag(mul_confusion_mat)),...
						   sum(matching_confusion_mat(:)) - sum(diag(matching_confusion_mat)),...
						   sum(crf_confusion_mat(:)) - sum(diag(crf_confusion_mat)));

	crf_model = struct();
	crf_model.feature_params = feature_params;
	crf_model.trans_params = trans_params;
	crf_model.D = D;
	crf_model.ground_truth = ground_truth_test_labels;
	crf_model.mul_nom = zeros(1, (partitioned_data.raw_ecg_data_length+2*filter_size+1));
	crf_model.mul_nom(filter_size+partitioned_data.test_idx) = mul_predicted_label;
	crf_model.puwave = puwave_pred_labels;
	crf_model.matching_confusion_mat = matching_confusion_mat;
	crf_model.crf = pred_crf_test_labels;
	crf_model.crf_validate_errors = crf_validate_errors;
	crf_model.mul_validate_errors = mul_validate_errors;
	save(sprintf('%s/sparse_coding/%s/%s_results.mat', plot_dir, analysis_id, analysis_id), '-struct', 'crf_model');

	write_to_html(analysis_id, subject_id, mul_title_str, crf_title_str, mul_confusion_mat, matching_confusion_mat, crf_confusion_mat);
end


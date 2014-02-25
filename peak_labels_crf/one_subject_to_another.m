function[] = one_subject_to_another()

plot_dir = get_project_settings('plots');

analysis_id = '1402163a';
subj2 = '16773_atr';

subj1 = 'P20_040';
subj1_analysis_id = '1402161a';
subj1_params = load(sprintf('%s/sparse_coding/%s/%s_results.mat', plot_dir, subj1_analysis_id, subj1_analysis_id));

[partitioned_data, title_str] = load_partition_data(analysis_id, subj2, true, 1, false);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CRF test set predictions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[junk, best_crf_pipeline] = min(subj1_params.crf_validate_errors);
fprintf('Best Pipeline=%d ', best_crf_pipeline);
[train_alpha, test_alpha, crf_title_str] = setup_crf_feature(best_crf_pipeline, partitioned_data, 'train', 'test',...
						title_str, subj1_params.D);
[feature_params, trans_params] = build_feature_trans_parms(train_alpha, partitioned_data.train_Y, partitioned_data.train_idx);
[crf_confusion_mat, crf_predicted_label] = basic_crf_classification(test_alpha, partitioned_data.test_Y,...
						partitioned_data.test_idx,...
						feature_params, trans_params, partitioned_data.nLabels);
assert(isequal(sum(crf_confusion_mat(:)) - sum(diag(crf_confusion_mat)), sum(crf_predicted_label ~= partitioned_data.test_Y)));

keyboard


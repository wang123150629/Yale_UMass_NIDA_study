function[confusion_mat, predicted_label, predicted_lbl_prob] = basic_crf_classification(vector_alpha, vector_Y, vector_idx,...
										feature_params, trans_params, nLabels)

confusion_mat = [];
predicted_label = NaN(size(vector_alpha, 1), 1);
predicted_lbl_prob = NaN(size(vector_alpha, 1), 1);
used_clusters = [];
clusters_apart = get_project_settings('clusters_apart');

% The next two lines converts [1, 24, 31 ...] into [1, 25, 32, ... ; 24, 31, 45,...]
used_clusters = find(diff(vector_idx) > clusters_apart);
used_clusters = [1, used_clusters+1; used_clusters, length(vector_idx)];
% I am only choosing a cluster only if it has atleast 2 peaks
valid_cluster_idx = diff(used_clusters) > 0;
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
	[predicted_lbl_prob(used_clusters(1, t):used_clusters(2, t), 1), predicted_label(used_clusters(1, t):used_clusters(2, t), 1)] =...
								max([unary_marginals{:}], [], 1);
end
assert(~any(isnan(predicted_label)));
confusion_mat = confusionmat(vector_Y, predicted_label);


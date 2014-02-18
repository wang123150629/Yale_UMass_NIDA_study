function[feature_params, trans_params] = build_feature_trans_parms(train_alpha, ecg_train_Y, tr_idx)

labels = unique(ecg_train_Y);
nLabels = length(labels);
clusters_apart = get_project_settings('clusters_apart');

% The next two lines converts [1, 24, 31 ...] into [1, 25, 32, ... ; 24, 31, 45,...]
train_clusters = find(diff(tr_idx) > clusters_apart);
train_clusters = [1, train_clusters+1; train_clusters, length(tr_idx)];
% I am only choosing a cluster only if it has atleast 2 peaks
valid_tr_cluster_idx = diff(train_clusters) > 1;
train_clusters = train_clusters(:, valid_tr_cluster_idx);

fprintf('nTrain=%d ', size(train_clusters, 2));

% optimize feature and transition parameters
[feature_params, trans_params] = optimize_feat_trans_params(train_clusters, train_alpha, ecg_train_Y, labels);


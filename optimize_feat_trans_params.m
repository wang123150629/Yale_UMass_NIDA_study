function[learned_feature_params, learned_trans_params] = optimize_feat_trans_params(train_chunks, ecg_train_X, ecg_train_Y, labels)

global l2_penalty
l2_penalty  = 0.01;
global nLabels
nLabels = length(labels);
global nFeatures
nFeatures = size(ecg_train_X, 2);

% Seed features and transition matrices appropriately. They are in log space
feature_params = normrnd(0, 0.01, nLabels, nFeatures);
trans_params = normrnd(0, 0.01, nLabels, nLabels);

% Convert the 6 x 100 matrix and 6 x 6 matrix into 1 x 636 vector (Matlab convention)
params = [reshape(feature_params, 1, size(feature_params, 1)*size(feature_params, 2)),...
	  reshape(trans_params, 1, size(trans_params, 1)*size(trans_params, 2))];

func = @(x)gradient_function(x, train_chunks, ecg_train_X, ecg_train_Y);
% options.Derivativecheck = 'on';
options.Method = 'lbfgs';
options.TolFun = 1e-10;
options.Display = 0;
params = minFunc(func, params', options);

% [fval, params] = gradient_function(params, train_chunks, ecg_train_X, ecg_train_Y);

% Convert the 1 x 636 vector into 6 x 100 matrix and 6 x 6 matrix
learned_feature_params = reshape(params(1:nLabels*nFeatures), nLabels, nFeatures);
learned_trans_params = reshape(params(((nLabels*nFeatures)+1):end), nLabels, nLabels);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[f, g] = gradient_function(params, train_chunks, ecg_train_X, ecg_train_Y)

global nLabels; global nFeatures; global l2_penalty;
nTrainsamples = size(train_chunks, 2);

% Convert the 1 x 636 vector into 6 x 100 matrix and 6 x 6 matrix
feature_params = reshape(params(1:nLabels*nFeatures), nLabels, nFeatures);
trans_params = reshape(params(((nLabels*nFeatures)+1):end), nLabels, nLabels);

% Use sum product message passing algorithm from part A to compute log likelihood and marginals
[log_likelihood, all_unary_marginals, all_pairwise_marginals] =...
				sum_prdt_msg_passing(feature_params, trans_params, train_chunks, ecg_train_X, ecg_train_Y, nLabels);

% Compute the objective function. Since we minimize we take a -ve
f = -mean(log_likelihood + (0.5 .* l2_penalty .* trans_params(:)' * trans_params(:)), 2);

% Compute the gradient of the feature and transition matrix
w_F = compute_gradient_w_f(nTrainsamples, all_unary_marginals, train_chunks, ecg_train_X, ecg_train_Y) ./ nTrainsamples;
w_T = compute_gradient_w_t(nTrainsamples, all_pairwise_marginals, train_chunks, ecg_train_X, ecg_train_Y) ./ nTrainsamples;
w_T = w_T - (trans_params .* l2_penalty);

% Convert the 6 x 100 matrix and 6 x 6 matrix into 1 x 636 vector (Matlab convention)
g = -[reshape(w_F, 1, size(w_F, 1)*size(w_F, 2)), reshape(w_T, 1, size(w_T, 1)*size(w_T, 2))]';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[w_F] = compute_gradient_w_f(nTrainsamples, all_unary_marginals, train_chunks, ecg_train_X, ecg_train_Y)

global nLabels; global nFeatures;

w_F = zeros(nLabels, nFeatures);
% For each sample in the training set
for sample = 1:nTrainsamples
	% fetch image sequence
	train_sample = ecg_train_X(train_chunks(1, sample):train_chunks(2, sample), :);
	% fetch ground truth indices for PQRR this will be [1 2 3 3]
	grnd_truth_indices = ecg_train_Y(train_chunks(1, sample):train_chunks(2, sample), :)';
	% get sample length
	sample_length = length(grnd_truth_indices);
	% The next three lines will pick out the matrix entries in the respective rows from the 6 x 100 matrix.
	% This will fetch a cell array. For instance 1 x 24. Each entry is a 6 x 1 matrix.
	unary_marginals = all_unary_marginals{sample};
	% This will reshape the cell array from 1 x 24 (6 x 1 matrix) into 24 x 6 matrix
	unary_marginals = reshape([unary_marginals{1:sample_length}], nLabels, sample_length)';
	assert(size(unary_marginals, 1) == length(grnd_truth_indices));
	assert(size(unary_marginals, 1) == size(train_sample, 1));
	% This line fetches the associated ecg values from each row. For instance if the first sample corresponds to peak T
	% i.e. 5th label, then it retains the fifth entry in the first row, etc
	target_marginals = unary_marginals(sub2ind(size(unary_marginals), [1:sample_length], [grnd_truth_indices]))';

	% Update the w_F matrix target rows only (but for all columns)
	for f = 1:length(target_marginals)
		w_F(grnd_truth_indices(f), :) = w_F(grnd_truth_indices(f), :) + train_sample(f, :);
		w_F = w_F - unary_marginals(f, :)' * train_sample(f, :);
	end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[w_T] = compute_gradient_w_t(nTrainsamples, all_pairwise_marginals, train_chunks, ecg_train_X, ecg_train_Y)

global nLabels; global nFeatures;

w_T = zeros(nLabels, nLabels);
% For each sample in the training set
for sample = 1:nTrainsamples
	% fetch image sequence
	train_sample = ecg_train_X(train_chunks(1, sample):train_chunks(2, sample), :);
	% fetch ground truth indices for PQRR this will be [1 2 3 3]
	grnd_truth_indices = ecg_train_Y(train_chunks(1, sample):train_chunks(2, sample), :)';
	% get sample length
	sample_length = length(grnd_truth_indices);
	% This converts [3, 6, 7] to [3, 6; 6, 7]
	trans_comb_indicator = make_lbl_transitions(grnd_truth_indices);
	% For each transition flip the zero to one in the dummay mat and then update the w_T matrix
	for l = 1:size(trans_comb_indicator, 1)
		dummy_mat = zeros(nLabels, nLabels);
		dummy_mat(trans_comb_indicator(l, 1), trans_comb_indicator(l, 2)) = 1;
		w_T = w_T + (dummy_mat - all_pairwise_marginals{sample}{l});
	end
end


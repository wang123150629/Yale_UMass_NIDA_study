function[feature_params_new, trans_params_new] = optimize_feat_trans_params(train_chunks, ecg_train_X, ecg_train_Y)

labels = 1:6;
global nLabels
nLabels = length(labels);
global nFeatures
nFeatures = 100;

% Seed features and transition matrices appropriately. They are in normal space
feature_params = log(rand(6, 100));
trans_params = log(rand(6, 6));

% Convert the 6 x 100 matrix and 6 x 6 matrix into 1 x 636 vector (Matlab convention)
params = [reshape(feature_params, 1, size(feature_params, 1)*size(feature_params, 2)),...
	  reshape(trans_params, 1, size(trans_params, 1)*size(trans_params, 2))];

func = @(x)gradient_function(x, train_chunks, ecg_train_X, ecg_train_Y);
options.Method = 'lbfgs';
params = minFunc(func, params', options);

% [fval, params] = gradient_function(params, train_chunks, ecg_train_X, ecg_train_Y);

% Convert the 1 x 3310 vector into 10 x 321 matrix and 10 x 10 matrix
feature_params_new = reshape(params(1:600), nLabels, nFeatures);
trans_params_new = reshape(params(601:end), nLabels, nLabels);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[f, g] = gradient_function(params, train_chunks, ecg_train_X, ecg_train_Y)

global nLabels; global nFeatures;
nTrainsamples = size(train_chunks, 2);

% Convert the 1 x 3310 vector into 10 x 321 matrix and 10 x 10 matrix.
feature_params = reshape(params(1:600), nLabels, nFeatures);
trans_params = reshape(params(601:end), nLabels, nLabels);

% Use sum product message passing algorithm from part A to compute log likelihood and marginals
[log_likelihood, all_unary_marginals, all_pairwise_marginals] =...
	msg_passing_in_axn_up(feature_params, trans_params, train_chunks, ecg_train_X, ecg_train_Y);

% Compute the objective function. Since we minimize we take a -ve
f = -sum(log_likelihood, 2) ./ nTrainsamples;
% Compute the gradient of the feature and transition matrix
if nargout > 1
	w_F = compute_gradient_w_f(nTrainsamples, all_unary_marginals, train_chunks, ecg_train_X, ecg_train_Y) ./ nTrainsamples;
	w_T = compute_gradient_w_t(nTrainsamples, all_pairwise_marginals, train_chunks, ecg_train_X, ecg_train_Y) ./ nTrainsamples;
end
% Convert the 10 x 321 matrix and 10 x 10 matrix into 1 x 3310 vector (Matlab convention)
g = -[reshape(log(w_F), 1, size(w_F, 1)*size(w_F, 2)), reshape(log(w_T), 1, size(w_T, 1)*size(w_T, 2))]';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[w_F] = compute_gradient_w_f(nTrainsamples, all_unary_marginals, train_chunks, ecg_train_X, ecg_train_Y)

global nLabels; global nFeatures;

w_F = zeros(nLabels, 100);
% For each sample in the training set
for sample = 1:nTrainsamples
	% fetch image sequence
	train_sample = ecg_train_X(train_chunks(1, sample):train_chunks(2, sample), :);
	% fetch ground truth indices for TREE this will be [2 9 1 1]
	grnd_truth_indices = ecg_train_Y(train_chunks(1, sample):train_chunks(2, sample), :)';
	% get sample length
	sample_length = length(grnd_truth_indices);
	% The next three lines will pick out the matrix entries in the respective rows from the 10 x 321 matrix.
	% For the sample OHS this will be just three values
	unary_marginals = all_unary_marginals{sample};
	unary_marginals = reshape([unary_marginals{1:sample_length}], nLabels, sample_length)';
	assert(size(unary_marginals, 1) == length(grnd_truth_indices));
	assert(size(unary_marginals, 1) == size(train_sample, 1));
	target_marginals = unary_marginals(sub2ind(size(unary_marginals), [1:sample_length], [grnd_truth_indices]))';

	% Updates the w_F matrix by component multiplying the three entries with the respective rows only (but for all columns)
	for f = 1:length(target_marginals)
		w_F(grnd_truth_indices(f), :) = w_F(grnd_truth_indices(f), :) +...
						train_sample(f, :) - (train_sample(f, :) .* target_marginals(f));
	end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[w_T] = compute_gradient_w_t(nTrainsamples, all_pairwise_marginals, train_chunks, ecg_train_X, ecg_train_Y)

global nLabels; global nFeatures;

% Reading in ground truth train labels
dummy_mat = ones(nLabels, nLabels);

w_T = zeros(nLabels, nLabels);
% For each sample in the training set
for sample = 1:nTrainsamples
	% fetch image sequence
	train_sample = ecg_train_X(train_chunks(1, sample):train_chunks(2, sample), :);
	% fetch ground truth indices for TREE this will be [2 9 1 1]
	grnd_truth_indices = ecg_train_Y(train_chunks(1, sample):train_chunks(2, sample), :);
	% get sample length
	sample_length = length(grnd_truth_indices);
	% This converts [3, 6, 7] to [3, 6; 6, 7]
	trans_comb_indicator = make_transitions(grnd_truth_indices);

	% For each transition flip the zero to one in the dummay mat and then update the w_T matrix
	for l = 1:size(trans_comb_indicator, 1)
		w_T = w_T + dummy_mat - all_pairwise_marginals{sample}{l};
	end
end


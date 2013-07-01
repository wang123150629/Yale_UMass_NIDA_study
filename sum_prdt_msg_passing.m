function[log_likelihood, all_unary_marginals, all_pairwise_marginals] =...
				sum_prdt_msg_passing(feature_params, trans_params, sample_chunks, ecg_X, ecg_Y, nLabels)

nSamples = size(sample_chunks, 2);
log_likelihood = NaN(1, nSamples);
all_unary_marginals = {};
all_pairwise_marginals = {};
for s = 1:nSamples
	[log_likelihood(1, s), all_unary_marginals{s}, all_pairwise_marginals{s}] =...
					single_pairwise_marginals(...
					ecg_X(sample_chunks(1, s):sample_chunks(2, s), :),...
					ecg_Y(sample_chunks(1, s):sample_chunks(2, s), :),...
					feature_params, trans_params, nLabels);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[log_likelihood, unary_marginal, pairwise_marginal] = single_pairwise_marginals(data_X, data_Y,...
										feature_params, trans_params, nLabels)

sample_length = size(data_X, 1);
nCliques = sample_length-1;

% Factor reduction
% Compute the clique potentials for the P cliques. Note the last clique has two feature potentials hence the special case
clique_information = {};
for p = 1:nCliques
	clique_information{p} = struct();
	if p == nCliques
		clique_information{p}.potential = bsxfun(@plus, bsxfun(@plus, trans_params,...
				       sum(bsxfun(@times, feature_params, data_X(p, :)), 2)),...
				       sum(bsxfun(@times, feature_params, data_X(p+1, :)), 2)');
	else
		clique_information{p}.potential = bsxfun(@plus, trans_params, sum(bsxfun(@times, feature_params, data_X(p, :)), 2));
	end
end

% Compute the messages from left to right (rep by 1) and then right to left (rep by 2)
% 1 2 3 2
% 1 1 2 2
msg_dir = [1:nCliques-1, nCliques:-1:2; repmat(1, 1, nCliques-1), repmat(2, 1, nCliques-1)];
for m = 1:size(msg_dir, 2)
	total_msg = clique_information{msg_dir(1, m)}.potential;
	switch msg_dir(2, m)
	case 1
		% Only from the second clique we receive messages from previous cliques. >>>>> direction
		if msg_dir(1, m)-1 >= 1
			total_msg = bsxfun(@plus, total_msg, clique_information{msg_dir(1, m)-1}.right_sigma);
		end
		clique_information{msg_dir(1, m)}.right_sigma = logsumexp(total_msg, msg_dir(2, m))';
	case 2
		% Only from the last but one clique we receive messages from previous cliques. <<<< direction
	 	if msg_dir(1, m)+1 <= nCliques
			total_msg = bsxfun(@plus, total_msg, clique_information{msg_dir(1, m)+1}.left_sigma);
		end
		clique_information{msg_dir(1, m)}.left_sigma = logsumexp(total_msg, msg_dir(2, m))';
	end
end

% compute the log beliefs for each clique
for p = 1:nCliques
	clique_information{p}.log_beliefs = clique_information{p}.potential;
	if p-1 >= 1 & isfield(clique_information{p-1}, 'right_sigma')
		clique_information{p}.log_beliefs = bsxfun(@plus, clique_information{p}.log_beliefs, clique_information{p-1}.right_sigma);
	end
	if p+1 <= nCliques & isfield(clique_information{p+1}, 'left_sigma')
		clique_information{p}.log_beliefs = bsxfun(@plus, clique_information{p}.log_beliefs, clique_information{p+1}.left_sigma);
	end
	z = logsumexp(logsumexp(clique_information{p}.log_beliefs, 1), 2);
	pairwise_marginal{p} = exp(clique_information{p}.log_beliefs - repmat(z, nLabels, nLabels));
	unary_marginal{p} = sum(pairwise_marginal{p}, 2); % y1 survives
end
% For the last feature use the last clique's information along the second dimension 
clique_information{p+1}.log_beliefs = clique_information{p}.log_beliefs;
z = logsumexp(logsumexp(clique_information{p+1}.log_beliefs, 1), 2);
pairwise_marginal{p+1} = exp(clique_information{p+1}.log_beliefs - repmat(z, nLabels, nLabels));
unary_marginal{p+1} = sum(pairwise_marginal{p+1}, 1)'; % y2 survives

log_likelihood = compute_negative_energy(data_X, data_Y, feature_params, trans_params) - z;
log_likelihood = log_likelihood / length(data_Y);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[neg_energy] = compute_negative_energy(data_X, data_Y, feature_params, trans_params)

% Computing node potential per position
node_potential = compute_potential_per_pos(data_X, data_Y, feature_params);
% Computing transition potential per transition
trans_potential = compute_potential_per_trans(data_Y, trans_params);
% Summing over all positions to get total potential
neg_energy = sum([sum(node_potential, 2), sum(trans_potential, 2)], 2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[node_potential] = compute_potential_per_pos(data_X, data_Y, feature_params)

node_potential = NaN(1, size(data_X, 1));

% Computes potential per position i.e. returns [200, 100, 300, 100] for a four letter word
for t = 1:length(data_Y)
	node_potential(1, t) = sum([feature_params(data_Y(t), :) .* data_X(t, :)], 2);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[trans_potential] = compute_potential_per_trans(data_Y, trans_params)

% make transitions from labels
trans_label_indicator = make_lbl_transitions(data_Y');

trans_potential = NaN(1, size(trans_label_indicator, 1));
% compute transition potential for this word
for t = 1:size(trans_label_indicator, 1)
	trans_potential(1, t) = trans_params(trans_label_indicator(t, 1), trans_label_indicator(t, 2));
end


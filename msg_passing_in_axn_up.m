function[log_likelihood, all_unary_marginals, all_pairwise_marginals] =...
				msg_passing_in_axn_up(feature_params, trans_params, train_chunks, ecg_train_X, ecg_train_Y)

nSamples = size(train_chunks, 2);
log_likelihood = NaN(1, nSamples);
all_unary_marginals = {};
all_pairwise_marginals = {};

for sample = 1:nSamples
	[log_likelihood(1, sample), all_unary_marginals{sample}, all_pairwise_marginals{sample}] =...
		single_pairwise_marginals(ecg_train_X(train_chunks(1, sample):train_chunks(2, sample), :),...
		feature_params, trans_params, ecg_train_Y(train_chunks(1, sample):train_chunks(2, sample), :));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[log_likelihood, unary_marginal, pairwise_marginal] = single_pairwise_marginals(train_sample,...
						feature_params, trans_params, train_sample_indicator)

labels = 1:6;
nLabels = length(labels);
sample_length = size(train_sample, 1);
nCliques = sample_length-1;

clique_information = {};
for p = 1:nCliques
	clique_information{p} = struct();
	if p == nCliques
		clique_information{p}.potential = bsxfun(@plus, bsxfun(@plus, trans_params,...
				       sum(bsxfun(@times, feature_params, train_sample(p, :)), 2)),...
				       sum(bsxfun(@times, feature_params, train_sample(p+1, :)), 2)');
	else
		clique_information{p}.potential = bsxfun(@plus, trans_params, sum(bsxfun(@times, feature_params, train_sample(p, :)), 2));
	end
end

msg_dir = [1:nCliques-1, nCliques:-1:2; repmat(1, 1, nCliques-1), repmat(2, 1, nCliques-1)];
for m = 1:size(msg_dir, 2)
	total_msg = clique_information{msg_dir(1, m)}.potential;
	switch msg_dir(2, m)
	case 1
		if msg_dir(1, m)-1 >= 1
			total_msg = bsxfun(@plus, total_msg, clique_information{msg_dir(1, m)-1}.right_sigma);
		end
		clique_information{msg_dir(1, m)}.right_sigma = logsumexp(total_msg, msg_dir(2, m))';
	case 2
	 	if msg_dir(1, m)+1 <= nCliques
			total_msg = bsxfun(@plus, total_msg, clique_information{msg_dir(1, m)+1}.left_sigma);
		end
		clique_information{msg_dir(1, m)}.left_sigma = logsumexp(total_msg, msg_dir(2, m))';
	end
end

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
clique_information{p+1}.log_beliefs = clique_information{p}.log_beliefs;
z = logsumexp(logsumexp(clique_information{p+1}.log_beliefs, 1), 2);
pairwise_marginal{p+1} = exp(clique_information{p+1}.log_beliefs - repmat(z, nLabels, nLabels));
unary_marginal{p+1} = sum(pairwise_marginal{p+1}, 1)'; % y2 survives

log_likelihood = compute_negative_energy(train_sample_indicator, feature_params, trans_params, train_sample) - z;


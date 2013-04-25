function[neg_energy] = compute_negative_energy(test_word_indicator, feature_params, trans_params, test_word)

% Computing node potential per position
node_potential = compute_potential_per_pos(test_word_indicator, feature_params, test_word);
% Computing transition potential per transition
trans_potential = compute_potential_per_trans(test_word_indicator, trans_params);
% Summing over all positions to get total potential
neg_energy = sum([sum(node_potential, 2), sum(trans_potential, 2)], 2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[node_potential] = compute_potential_per_pos(test_word_indicator, feature_params, test_word)

node_potential = NaN(1, size(test_word, 1));

% Computes potential per position i.e. returns [200, 100, 300, 100] for a four letter word
for t = 1:length(test_word_indicator)
	node_potential(1, t) = sum([feature_params(test_word_indicator(t), :) .* test_word(t, :)], 2);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[trans_potential] = compute_potential_per_trans(test_word_indicator, trans_params)

% make transitions from labels
trans_label_indicator = make_transitions(test_word_indicator);

trans_potential = NaN(1, size(trans_label_indicator, 1));
% compute transition potential for this word
for t = 1:size(trans_label_indicator, 1)
	trans_potential(1, t) = trans_params(trans_label_indicator(t, 1), trans_label_indicator(t, 2));
end


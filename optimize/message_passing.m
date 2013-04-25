function[accuracy] = message_passing(nWords, varargin)

if length(varargin) == 2
	feature_params = varargin{1};
	trans_params = varargin{2};
else
	feature_params = textread('/home/anataraj/CSClasses/cs691/assignments/assign2/Assignment2A/model/feature-params.txt');
	trans_params = textread('/home/anataraj/CSClasses/cs691/assignments/assign2/Assignment2A/model/transition-params.txt');
end

% Reading in ground truth test labels
ground_truth_test_labels = textread('/home/anataraj/CSClasses/cs691/assignments/assign2/Assignment2A/data/test_words.txt', '%s');

% Reading in the test image
accuracy = NaN(nWords, 2);
for word = 1:nWords
	test_word = textread(sprintf('/home/anataraj/CSClasses/cs691/assignments/assign2/Assignment2A/data/test_img%d.txt', word));
	accuracy(word, :) = predict_label(word, test_word, feature_params, trans_params, ground_truth_test_labels);
end
accuracy = sum(accuracy, 1);
accuracy = 100 * accuracy(1) / accuracy(2);
fprintf('Prediction accuracy = %0.4f\n', accuracy);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[hit_or_miss] = predict_label(word, test_word, feature_params, trans_params, ground_truth_test_labels)

latex_flag = false;
display_flag = false;

labels = 1:10;
nLabels = length(labels);
word_length = size(test_word, 1);
nCliques = word_length-1;

clique_info = struct();
switch nCliques
case 2
	clique_info.clique_potentials = {[1], [2, 3]}; % Like which rows to pick from the test word for TREE it is 1, 2, 3, 4
	clique_info.clique_strech_dim = {[2], [2, 1]};
	clique_info.messages = [1, 2];
	clique_info.message_dim = [1, 2];
	clique_info.extra_msg = [0, 0];
	clique_info.extra_msg_dim = [0, 0];
	clique_info.ass_messages = {[2], [1]};
	clique_info.ass_message_dim = {[1], [2]};
case 3
	clique_info.clique_potentials = {[1], [2], [3, 4]}; % Like which rows to pick from the test word for TREE it is 1, 2, 3, 4
	clique_info.clique_strech_dim = {[2], [2], [2, 1]};
	clique_info.messages = [1, 2, 3, 2];
	clique_info.message_dim = [1, 1, 2, 2];
	clique_info.extra_msg = [0, 1, 0, 3];
	clique_info.extra_msg_dim = [0, 2, 0, 1];
	clique_info.ass_messages = {[4], [1, 3], [2]};
	clique_info.ass_message_dim = {[1], [2, 1], [2]};
case 4
	clique_info.clique_potentials = {[1], [2], [3], [4, 5]}; % Like which rows to pick from the test word for TREE it is 1, 2, 3, 4
	clique_info.clique_strech_dim = {[2], [2], [2], [2, 1]};
	clique_info.messages = [1, 2, 3, 4, 3, 2];
	clique_info.message_dim = [1, 1, 1, 2, 2, 2];
	clique_info.extra_msg = [0, 1, 2, 0, 4, 3];
	clique_info.extra_msg_dim = [0, 2, 2, 0, 1, 1];
	clique_info.ass_messages = {[6], [1, 5], [2, 4], [3]};
	clique_info.ass_message_dim = {[1], [2, 1], [2, 1], [2]};
otherwise, error('Invalid number of cliques!');
end

if display_flag, fprintf('===========================================\n'); end
% Computing 2.1
clique_potential = {};
for p = 1:nCliques
	phi_clique = trans_params;
	phi_positions = clique_info.clique_potentials{p};
	phi_strech_dim = clique_info.clique_strech_dim{p};
	nPhis = length(phi_positions);
	for phis = 1:nPhis
		phi_feature = NaN(1, length(labels));
		for l = labels
			phi_feature(1, l) = sum([feature_params(l, :) .* test_word(phi_positions(phis), :)], 2);
		end
		phi_streched = strech_matrix(phi_feature, phi_strech_dim(phis), nLabels);
		phi_clique = phi_clique + phi_streched;
	end
	clique_potential{p} = phi_clique;
	if display_flag
		fprintf('Clique potential: %d\n', p);
		write_mat_out(phi_clique(1:2, 1:2), latex_flag);
	end
end

if display_flag, fprintf('===========================================\n'); end
% Computing 2.2
sigma = {};
for m = 1:length(clique_info.messages)
	clique_phi = clique_potential{clique_info.messages(m)};
	if clique_info.extra_msg(m) > 0
		prev_msg = strech_matrix(sigma{clique_info.extra_msg(m)}, clique_info.extra_msg_dim(m), nLabels);
		clique_phi = clique_phi + prev_msg;
	end
	sigma{m} = logsumexp(clique_phi, clique_info.message_dim(m));
	if display_flag
		fprintf('Message: %d\n', m);
		write_mat_out(sigma{m}, latex_flag);
	end
end

if display_flag, fprintf('===========================================\n'); end
% Computing 2.3
log_beliefs = {};
for p = 1:nCliques
	clique_chi = clique_potential{p};
	for m = 1:length(clique_info.ass_messages{p})
		clique_chi = clique_chi +...
			strech_matrix(sigma{clique_info.ass_messages{p}(m)}, clique_info.ass_message_dim{p}(m), nLabels);
	end
	log_beliefs{p} = clique_chi;
	if display_flag
		fprintf('Log beliefs: %d\n', p);
		write_mat_out(log_beliefs{p}(1:2, 1:2), latex_flag);
	end
end
log_beliefs{p+1} = log_beliefs{p};

if display_flag, fprintf('===========================================\n'); end
% Computing 2.4
predicted_label = NaN(1, word_length);
for l = 1:word_length
	z = logsumexp(logsumexp(log_beliefs{l}, 1), 2);
	pairwise_marginal = exp(log_beliefs{l} - repmat(z, nLabels, nLabels));
	unary_marginal_1 = sum(pairwise_marginal, 2); % y1 survives
	unary_marginal_2 = sum(pairwise_marginal, 1); % y2 survives
	[max_val, predicted_label(l)] = max(unary_marginal_1);
	if l == word_length
		[max_val, predicted_label(l)] = max(unary_marginal_2);
		if display_flag
			fprintf('Marginal prob: %d\n', l);
			write_mat_out(unary_marginal_2, latex_flag, 8);
		end
	else
		if display_flag
			fprintf('Marginal prob: %d\n', l);
			write_mat_out(unary_marginal_1, latex_flag, 8);
		end
	end
	if display_flag
		fprintf('Pairwise marginal prob: %d\n', l);
		write_mat_out(pairwise_marginal(1:2, 1:2), latex_flag, 8);
	end
end
if display_flag, fprintf('===========================================\n'); end
fprintf('guessed=%s, ground=%s\n', convert_to_label(predicted_label), ground_truth_test_labels{word});
hit_or_miss(1) = sum(predicted_label == convert_to_indices(ground_truth_test_labels{word}));
hit_or_miss(2) = length(predicted_label);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[streched_matrix] = strech_matrix(A, dimension, how_long)

if size(A, 1) == 1
	switch dimension
	case 1, streched_matrix = repmat(A, how_long, 1);
	case 2, streched_matrix = repmat(A', 1, how_long);
	end
elseif size(A, 2) == 1
	switch dimension
	case 1, streched_matrix = repmat(A', how_long, 1);
	case 2, streched_matrix = repmat(A, 1, how_long);
	end
else
	error('Invalid matrix to strech!');
end


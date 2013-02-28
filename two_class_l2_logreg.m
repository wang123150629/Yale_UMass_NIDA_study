function[accuracy, tpr, fpr, AUC] = two_class_l2_logreg(train_set, test_set, lambda)

interested_class = 1;

options.Display = 0;
X = [ones(size(train_set, 1), 1), train_set(:, 1:end-1)];
y = train_set(:, end);
nVars = size(X, 2);

funObj = @(w)LogisticLoss(w, X, y);
lambda = lambda .* ones(nVars, 1);
lambda(1) = 0; % Don't penalize bias
betas = minFunc(@penalizedL2, zeros(nVars, 1), options, funObj, lambda)';

% Adding ones to the test set since there is an intercept term
intercept_added_test_set = test_set(:, 1:end-1)';
intercept_added_test_set = [ones(1, size(intercept_added_test_set, 2)); intercept_added_test_set];

z = betas * intercept_added_test_set;
pos_class_prob = 1 ./ (1 + exp(-z));
neg_class_prob = 1 - pos_class_prob;
likelihood_ratio = neg_class_prob ./ pos_class_prob;
class_guessed = ones(size(intercept_added_test_set, 2), 1);
class_guessed(find(likelihood_ratio > 1)) = -1;

accuracy = sum(class_guessed == test_set(:, end)) * 100 / size(test_set, 1);

class_1_idx = find(test_set(:, end) == 1);
class_m1_idx = find(test_set(:, end) == -1);
assert(isempty(intersect(class_1_idx, class_m1_idx)));
tpr = length(find(class_guessed(class_1_idx) == interested_class)) / length(class_1_idx);
fpr = length(find(class_guessed(class_m1_idx) == interested_class)) / length(class_m1_idx);
[x_val, y_val, T, AUC] = perfcurve(test_set(:, end), class_guessed, interested_class);


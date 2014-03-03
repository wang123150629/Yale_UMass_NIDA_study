function[confusion_mat, yhatt, AUC] = multinomial_log_reg(train_alpha, ecg_train_Y, test_alpha, ecg_test_Y)

labels = unique(ecg_train_Y);
nClasses = length(labels);
nVars = size(train_alpha, 2);
options.Display = 0;

% Adding bias
train_alpha = [ones(size(train_alpha, 1), 1), train_alpha];
test_alpha = [ones(size(test_alpha, 1), 1), test_alpha];

funObj = @(W)SoftmaxLoss2(W, train_alpha, ecg_train_Y, nClasses);
lambda = 1e-4 * ones(nVars+1, nClasses-1);
lambda(1, :) = 0; % Don't penalize biases
wSoftmax = minFunc(@penalizedL2, zeros((nVars+1) * (nClasses-1), 1), options, funObj, lambda(:));
wSoftmax = reshape(wSoftmax, [nVars+1, nClasses-1]);
wSoftmax = [wSoftmax, zeros(nVars+1, 1)];

[junk, yhatt] = max(test_alpha * wSoftmax, [], 2);

confusion_mat = confusionmat(ecg_test_Y, yhatt);

AUC = one_vs_all_auc(nClasses, ecg_test_Y, test_alpha * wSoftmax);


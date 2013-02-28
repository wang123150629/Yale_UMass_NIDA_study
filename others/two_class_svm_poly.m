function [accuracy, tpr, fpr] = two_class_svm_poly(complete_train_set, complete_test_set)

options.Method = 'lbfgs';
lambda = 1e-2;

nVars = size(complete_train_set, 2) - 1;
complete_train_set(:, end) = complete_train_set(:, end) + 1;
nClasses = length(unique(complete_train_set(:, end)));
complete_test_set(:, end) = complete_test_set(:, end) + 1;
nInstances = size(complete_train_set, 1);
% Kpoly = kernelPoly(complete_test_set(:, 1:end-1), complete_test_set(:, 1:end-1), polyOrder);

% Polynomial
polyOrder = 2;
Kpoly = kernelPoly(complete_train_set(:, 1:end-1), complete_train_set(:, 1:end-1), polyOrder);
funObj = @(u)SSVMMultiLoss(u, Kpoly, complete_train_set(:, end), nClasses);
fprintf('Training kernel(poly) multi-class SVM...\n');
uPoly = minFunc(@penalizedKernelL2_matrix, randn(nInstances * nClasses, 1), options, Kpoly, nClasses, funObj, lambda);
uPoly = reshape(uPoly, [nInstances nClasses]);

[junk yhat] = max(Kpoly * uPoly, [], 2);
%{
accuracy = sum(complete_test_set(:, end) == yhat) * 100 / size(complete_test_set, 1);

class_1_idx = find(complete_test_set(:, end) == 1);
class_2_idx = find(complete_test_set(:, end) == 2);
assert(isempty(intersect(class_1_idx, class_2_idx)));
tpr = length(find(yhat(class_1_idx) == 1)) / length(class_1_idx);
fpr = length(find(yhat(class_2_idx) == 1)) / length(class_2_idx);
%}

keyboard


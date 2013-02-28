function [accuracy, tpr, fpr] = two_class_linear_kernel_logreg(complete_train_set, complete_test_set)

options.Display = 1;
lambda = 1e-2;
X = complete_train_set(:, 1:end-1);
y = 2.*complete_train_set(:, end)-1;
nVars = size(X, 2);
nInstances = size(X, 1);

% First fit a regular linear model
funObj = @(w)LogisticLoss(w,X,y);
fprintf('Training linear logistic regression model...\n');
wLinear = minFunc(@penalizedL2, zeros(nVars,1), options, funObj, lambda);

% Now fit the same model with the kernel representation
K = kernelLinear(X, X);
funObj = @(u)LogisticLoss(u, K, y);
fprintf('Training kernel(linear) logistic regression model...\n');
uLinear = minFunc(@penalizedKernelL2, zeros(nInstances,1), options, K, funObj, lambda);

% Check that wLinear and uLinear represent the same model:
fprintf('Parameters estimated from linear and kernel(linear) model:\n');
[wLinear X'*uLinear]

trainErr_linear = sum(y ~= sign(X*wLinear))/length(y);

keyboard

%{
% Now try a degree-2 polynomial kernel expansion
polyOrder = 2;
Kpoly = kernelPoly(X,X,polyOrder);
funObj = @(u)LogisticLoss(u,Kpoly,y);
fprintf('Training kernel(poly) logistic regression model...\n');
uPoly = minFunc(@penalizedKernelL2,zeros(nInstances,1),options,Kpoly,funObj,lambda);

% Squared exponential radial basis function kernel expansion
rbfScale = 1;
Krbf = kernelRBF(X,X,rbfScale);
funObj = @(u)LogisticLoss(u,Krbf,y);
fprintf('Training kernel(rbf) logistic regression model...\n');
uRBF = minFunc(@penalizedKernelL2,zeros(nInstances,1),options,Krbf,funObj,lambda);

trainErr_poly = sum(y ~= sign(Kpoly*uPoly))/length(y)
trainErr_rbf = sum(y ~= sign(Krbf*uRBF))/length(y)
%}


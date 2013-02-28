function [] = two_class_svm_play()

options.Display = 1;
nInstances = 400;
nVars = 2;
[X,y] = makeData('classificationNonlinear',nInstances,nVars);

lambda = 1e-2;

% First fit a regular linear model
funObj = @(w)LogisticLoss(w,X,y);
fprintf('Training linear logistic regression model...\n');
wLinear = minFunc(@penalizedL2,zeros(nVars,1),options,funObj,lambda);

% Now fit the same model with the kernel representation
K = kernelLinear(X,X);
funObj = @(u)LogisticLoss(u,K,y);
fprintf('Training kernel(linear) logistic regression model...\n');
uLinear = minFunc(@penalizedKernelL2,zeros(nInstances,1),options,K,funObj,lambda);

% Check that wLinear and uLinear represent the same model:
fprintf('Parameters estimated from linear and kernel(linear) model:\n');
[wLinear X'*uLinear]

trainErr_linear = sum(y ~= sign(X*wLinear))/length(y)

fprintf('Making plots...\n');
figure;
subplot(2,2,1);
plotClassifier(X,y,wLinear,'Linear Logistic Regression');
subplot(2,2,2);
plotClassifier(X,y,uLinear,'Kernel-Linear Logistic Regression',@kernelLinear,[]);

keyboard

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

fprintf('Making plots...\n');
figure;
subplot(2,2,1);
plotClassifier(X,y,wLinear,'Linear Logistic Regression');
subplot(2,2,2);
plotClassifier(X,y,uLinear,'Kernel-Linear Logistic Regression',@kernelLinear,[]);
subplot(2,2,3);
plotClassifier(X,y,uPoly,'Kernel-Poly Logistic Regression',@kernelPoly,polyOrder);
subplot(2,2,4);
plotClassifier(X,y,uRBF,'Kernel-RBF Logistic Regression',@kernelRBF,rbfScale);
pause;



options.Method = 'lbfgs';
nVars = 2;
nClasses = 2;
nInstances = 1000;
[X,y] = makeData('multinomialNonlinear',nInstances,nVars,nClasses);

lambda = 1e-2;

% Linear
funObj = @(w)SSVMMultiLoss(w,X,y,nClasses);
fprintf('Training linear multi-class SVM...\n');
wLinear = minFunc(@penalizedL2,zeros(nVars*nClasses,1),options,funObj,lambda);
wLinear = reshape(wLinear,[nVars nClasses]);

% Polynomial
polyOrder = 2;
Kpoly = kernelPoly(X,X,polyOrder);
funObj = @(u)SSVMMultiLoss(u,Kpoly,y,nClasses);
fprintf('Training kernel(poly) multi-class SVM...\n');
uPoly = minFunc(@penalizedKernelL2_matrix,randn(nInstances*nClasses,1),options,Kpoly,nClasses,funObj,lambda);
uPoly = reshape(uPoly,[nInstances nClasses]);

% RBF
rbfScale = 1;
Krbf = kernelRBF(X,X,rbfScale);
funObj = @(u)SSVMMultiLoss(u,Krbf,y,nClasses);
fprintf('Training kernel(rbf) multi-class SVM...\n');
uRBF = minFunc(@penalizedKernelL2_matrix,randn(nInstances*nClasses,1),options,Krbf,nClasses,funObj,lambda);
uRBF = reshape(uRBF,[nInstances nClasses]);

% Compute training errors
[junk yhat] = max(X*wLinear,[],2);
trainErr_linear = sum(y~=yhat)/length(y)
[junk yhat] = max(Kpoly*uPoly,[],2);
trainErr_poly = sum(y~=yhat)/length(y)
[junk yhat] = max(Krbf*uRBF,[],2);
trainErr_rbf = sum(y~=yhat)/length(y)

fprintf('Making plots...\n');
figure;
subplot(2,2,1);
plotClassifier(X,y,wLinear,'Linear Multi-Class Smooth SVM');
subplot(2,2,2);
plotClassifier(X,y,uPoly,'Kernel-Poly Multi-Class Smooth SVM',@kernelPoly,polyOrder);
subplot(2,2,3);
plotClassifier(X,y,uRBF,'Kernel-RBF Multi-Class Smooth SVM',@kernelRBF,rbfScale);
pause;

svmStruct = svmtrain(complete_train_set(:, 1:end-1), complete_train_set(:, end), 'kernel_function',...
						'quadratic', 'method', 'LS', 'autoscale', false);
class_guessed = svmclassify(svmStruct, complete_test_set(:, 1:end-1));
accuracy = sum(class_guessed == complete_test_set(:, end)) * 100 / size(complete_test_set, 1);


function play_with_multinomial()

options = struct();
nInstances = 10000;
nVars = 2;
nClasses = 3;
[X,y] = makeData('multinomial',nInstances,nVars,nClasses);

% Add bias
X = [ones(nInstances,1) X];

funObj = @(W)SoftmaxLoss2(W,X,y,nClasses);
lambda = 1e-4*ones(nVars+1,nClasses-1);
lambda(1,:) = 0; % Don't penalize biases
fprintf('Training multinomial logistic regression model...\n');
wSoftmax = minFunc(@penalizedL2,zeros((nVars+1)*(nClasses-1),1),options,funObj,lambda(:));
wSoftmax = reshape(wSoftmax,[nVars+1 nClasses-1]);
wSoftmax = [wSoftmax zeros(nVars+1,1)];

[junk yhat] = max(X*wSoftmax,[],2);
trainErr = sum(yhat~=y)/length(y)

% Plot the result
figure;
plotClassifier(X,y,wSoftmax,'Multinomial Logistic Regression');
pause;

keyboard

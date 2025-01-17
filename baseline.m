close all;
clear;

load('Train.mat');
load('Test.mat');

Xtrain = normr(Xtrain);
%% trainning phase XTrain YTrain => models
models = cell(3,1);
kernelScale = 140;
boxconstraint = 54;
% 0 1
models{1} = fitcsvm([Xtrain(Ytrain==0,:);Xtrain(Ytrain==1,:)],...
                    [Ytrain(Ytrain==0);Ytrain(Ytrain==1)],'KernelFunction','rbf',...
                    'KernelScale',kernelScale,'BoxConstraint',boxconstraint);
% 0 3
models{2} = fitcsvm([Xtrain(Ytrain==0,:);Xtrain(Ytrain==3,:)],...
                    [Ytrain(Ytrain==0);Ytrain(Ytrain==3)],'KernelFunction','rbf',...
                    'KernelScale',kernelScale,'BoxConstraint',boxconstraint);
% 1 3
models{3} = fitcsvm([Xtrain(Ytrain==1,:);Xtrain(Ytrain==3,:)],...
                    [Ytrain(Ytrain==1);Ytrain(Ytrain==3)],'KernelFunction','rbf',...
                    'KernelScale',kernelScale,'BoxConstraint',boxconstraint);

%% predicting phase XTest models => YPredict
[label1,score1] = predict(models{1},Xtest);
[label2,score2] = predict(models{2},Xtest);
[label3,score3] = predict(models{3},Xtest);

scoreSum0 = score1(:,1) + score2(:,1);
scoreSum1 = score1(:,2) + score3(:,1);
scoreSum3 = score2(:,2) + score3(:,2);

allScore = [scoreSum0, scoreSum1, scoreSum3];
% normalize y predict
%minall = min(min(allScore));
%allScore = allScore - minall;
%allScore = bsxfun(@rdivide, allScore, sum(allScore,2));
%round(allScore,4);
%allScore(:,3) = 1 - sum(allScore(:,1:2),2);
[~,YPredict] = max(allScore,[],2);
%YPredict(YPredict==1) = 0;
%YPredict(YPredict==2) = 1;
%YPredict(YPredict==3) = 3;

writeScore = zeros(size(allScore));
for i=1:size(YPredict,1)
    writeScore(i,YPredict(i)) = 1;
end

%% Cross Validation
%class1_loss = kfoldLoss(crossval(models{1}))
%class2_loss = kfoldLoss(crossval(models{2}))
%class3_loss = kfoldLoss(crossval(models{3}))

% write to prediction.csv for turnin
csvwrite('prediction.csv', writeScore);
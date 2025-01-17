clear;
close all;

load Train.mat;
load Test.mat;

addpath(genpath('DeepLearnToolbox'));

%% preprocess the data
Xall = [Xtrain;Xtest];
Xbias = min(Xall);
Xall = bsxfun(@minus,Xall,Xbias);
Xscale = max(Xall)-min(Xall);
Xall = bsxfun(@rdivide,Xall,Xscale);

%%  Dimensin reduction using autoencoder
rand('state',0);
aesize = [5903 3000 1000];
sae = saesetup(aesize);
% layers
for i=1:numel(aesize)-1
    sae.ae{i}.activation_function       = 'sigm';
    sae.ae{i}.learningRate              = 0.005;
    sae.ae{i}.inputZeroMaskedFraction   = 0;
end
% optimize
opts.numepochs =  20;
opts.batchsize = 100;
sae = saetrain(sae, Xall(1:1500,:), opts);
save('sae.mat','sae');
%load sae.mat;

% global optimize
nng = nnsetup([aesize(1:end-1), fliplr(aesize)]);
for i=1:numel(aesize)-1
    nng.W{i} = sae.ae{i}.W{1};
    nng.W{numel(aesize)+2-i} = sae.ae{i}.W{2};
end
nng.activation_function = 'sigm';
%load nng.mat;
nng.learningRate = 0.005;
opts.numepochs =  200;
nng = nntrain(nng, Xall(1:1500,:), Xall(1:1500,:), opts);
save('nng.mat','nng','Xscale','Xbias');

% Use the SDAE to initialize a FFNN
nn = nnsetup(aesize);
nn.activation_function              = 'sigm';
% layers
for i=1:numel(aesize)-1
    nn.W{i} = nng.W{i};
end

%% compute reduced Xtrain
nn = nnff(nn, Xtrain, zeros(size(Xtrain,1), nn.size(end)));
XtrainR = nn.a{end};
nn = nnff(nn, Xtest, zeros(size(Xtest,1), nn.size(end)));
XtestR = nn.a{end};
save('TrainR.mat','XtrainR','XtestR');
%load TrainR.mat;

%% train and cross validate on svm
outlier_frac = 0.05;
kernel_scale = 15;
box_constraint = 30;
shrinkage = 3000;
err_rate = cross_validate_baseline_all( kernel_scale, box_constraint, ...
    XtrainR, Ytrain, outlier_frac, shrinkage)

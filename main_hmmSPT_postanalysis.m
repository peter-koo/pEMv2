%--------------------------------------------------------------------------
% This script runs perturbation expectation-maximization version 2 (pEMv2) 
% on a set of simulated particle tracks. The tracks have to be stored in a 
% mat file under the variable X, which is a cell that contains each
% trajectory X{1} = [x_1 y_1], X{2} = [x_2, y_2]... where x_i and y_i are
% vectors of the positions of the trajectories.  The output of pEMv2 is
% saved in a mat file in the results folder.
% 
% Code written by: 
%       Peter Koo
%       Yale University, Department of Physis, New Haven, CT, 06511  
%--------------------------------------------------------------------------

clear all;
clc;
close all;
addpath('pEMv2');
addpath('HMM');
addpath('visualization')

%%  load file

[filename,dirpath] = uigetfile('*.mat','Select protein track positions mat file');
data = load(fullfile(dirpath,filename));
Xraw = data.X;

%% user set parameters

% movie parameters
dt = .032;              % time between steps
dE = .032;              % exposure time

% pEM parameters
minStates = 1;          % minimum number of states to explore
maxStates = 5;          % maximum number of states to explore
numReinitialize = 3;    % number of reinitialization trials
numPerturb = 20;        % number of perturbation trials
maxiter = 10000;        % maximum number of iterations within EM trial
convergence = 1e-5;     % convergence criteria for change in log-likelihood 
lambda = 0.0001;        % shrinkage factor (useful when numerical issues calculating
                        % inverse of covariance matrix, labmda = 0.0 for no correction 
                        % lambda = 0.001 for correction)

numFeatures = 5;        % number of covariance features to include (min=2 for
                        % normal diffusion, 3-5 for non-normal diffusion)
splitLength = 15;       % length of steps to split each track

%% run pEM version 2

% split tracks into equal bin sizes
[X,splitIndex] = SplitTracks(Xraw,splitLength);

% structure for track info
trackInfo.numberOfTracks = length(X);   % number of tracks
trackInfo.dimensions = size(X{1},2);    % particle track dimensions
trackInfo.numFeatures = numFeatures;    % number of features to retain in covariance matrix
trackInfo.splitLength = splitLength;    % length of each bin
trackInfo.splitIndex = splitIndex;      % index of each track
trackInfo.dt = dt;                      % frame duration
trackInfo.R = 1/6*dE/dt;                % motion blur coefficient
trackInfo.lambda = lambda;              % shrinkage factor

% load pEMv2 results
[tmp, name] = fileparts(filename);
saveFolder = fullfile('results',name);
disp(['loading results: ' fullfile(saveFolder,['results.mat'])]); 
results = load(fullfile(saveFolder,['results.mat']),'results');

optimalSize = results.optimalSize;
optimalVacf = results.optimalVacf;
optimalP = results.optimalP;
disp('-------------------------------------------------------');
disp(['OptimalSize: ' num2str(optimalSize) ' states']);
for i = 1:numFeatures
    disp(['Sigma_k(i,i+' num2str(i-1) '): ' num2str(optimalVacf(:,i)') ' um^2']);
end
disp(['pi_k: ' num2str(optimalP)]);
disp('-------------------------------------------------------');

% initialize HMM
transProb = .99;  % diagional transition probabilities
hmmmodel = InitializeHMM(X, optimalP, optimalVacf, transProb);

% train HMM
hmmparams.maxiter = 100;
hmmparams.tolerance = 1e-4;
hmmparams.verbose = 1;
hmmmodel = HMMGMM(X, hmmmodel, trackInfo, hmmparams);

% store HMM results
results.hmm.p = hmmmodel.p;
results.hmm.a = hmmmodel.a;
results.hmm.b = hmmmodel.b;
results.hmm.sigma = hmmmodel.sigma;
results.hmm.gammank = hmmmodel.gammank;
results.hmm.logL = hmmmodel.logL;

disp(['Saving results: ' fullfile(saveFolder,'results.mat')]); 
save(fullfile(saveFolder,'results.mat'),'results');






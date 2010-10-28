classdef prtClassRvmSequential < prtClassRvm
    % prtClassRvmSequential  Relevance vector machin classifier using
    % sequential training
    %
    % prtClassRvmSequential is most useful for datasets with a large number
    % of observations for which the gram matrix can not be held in memory.
    % The sequential RVM training algorithm is capable of operating by
    % generating necessary portions of the gram matrix when needed.
    % The size of the generated portion of the gram matrix is determined by
    % the property, largestNumberOfGramColumns
    % Sequential RVM training will attempt to generate portions of the gram
    % matrix that are TraingData.nObservations x largesNumberofGramColums
    % in size. If the entire gram matrix is this size or smaller it need
    % only be generated once. Therefore if the entire gram matrix can be
    % stored in memory, training is much faster. For quickest operation, 
    % largestNumberOfGramColumns should be set as large as possible.
    %
    %
    %       Tipping, M. E. and A. C. Faul (2003). Fast marginal likelihood
    %   maximisation for sparse Bayesian models. In C. M. Bishop and 
    %   B. J. Frey (Eds.), Proceedings of the Ninth International Workshop
    %   on Artificial Intelligence and Statistics, Key West, FL, Jan 3-6.
    %
    %
    %    A prtClassRvm object inherits the TRAIN, RUN, CROSSVALIDATE and
    %    KFOLDS methods from prtAction. It also inherits the PLOT and
    %    PLOTDECISION classes from prtClass.
    %
    %    Example:
    %{
        TrainingDataSet = prtDataGenUnimodal;  % training data
        classifier = prtClassRvmSequential;    % Create a classifier
        classifier = classifier.train(TrainingDataSet);    % Train
        classifier.plot;
    %}
    
    
    properties
        learningPoorlyScaledLikelihoodThreshold = 1e4;
        learningLikelihoodIncreaseThreshold = 1e-6;
        largestNumberOfGramColumns = 1000;
        learningCorrelationRemovalThreshold = 0.99;
        learningFactorRemove = true;
        learningResults
    end
    
    methods
        function Obj = prtClassRvmSequential(varargin)
            Obj = prtUtilAssignStringValuePairs(Obj,varargin{:});
            
            %Obj.name = 'Relevance Vector Machine - Sequential';
        end
    end
    
    methods (Access=protected, Hidden = true)
        function Obj = trainAction(Obj,DataSet)
            %Rvm = trainAction(Rvm,DataSet) (Private; see prtClass\train)
                        
            warningState = warning;
            %warning off MATLAB:nearlySingularMatrix
            
            y = Obj.getMinusOneOneTargets(DataSet);
            
            nBasisVec = prtKernel.nDimsMultiKernel(Obj.kernels,DataSet);
            nBasis = sum(nBasisVec);
            if false && nBasis <= Obj.largestNumberOfGramColumns
                Obj = trainActionSequentialInMemory(Obj, DataSet, y);
                return
            end
            
            if Obj.learningVerbose
                fprintf('Sequential RVM training with %d possible vectors.\n', nBasis);
            end
            
            % The sometimes we want y [-1 1] but mostly not
            ym11 = y;
            y(y ==-1) = 0;
            
            Obj.beta = zeros(nBasis,1);
            
            relevantIndices = false(nBasis,1); % Nobody!
            alpha = inf(nBasis,1); % Nobody!
            forbidden = zeros(nBasis,1); % Will hold who is forbidding you from joining
            
            % Find first kernel
            kernelCorrs = zeros(nBasis,1);
            nBlocks = ceil(nBasis./ Obj.largestNumberOfGramColumns);
            for iBlock = 1:nBlocks
                cInds = ((iBlock-1)*Obj.largestNumberOfGramColumns+1):min([iBlock*Obj.largestNumberOfGramColumns nBasis]);
                
                trainedKernelCell = prtKernel.sparseKernelFactory(Obj.kernels,DataSet,cInds);
                blockPhi = prtKernel.runMultiKernel(trainedKernelCell,DataSet);
                blockPhiNormalized = bsxfun(@rdivide,blockPhi,sqrt(sum(blockPhi.*blockPhi))); % We have to normalize here
                
                kernelCorrs(cInds) = abs(blockPhiNormalized'*ym11);
            end
            [maxVal, maxInd] = max(kernelCorrs);
            
            
            % Make this ind relevant
            relevantIndices(maxInd) = true;
            selectedInds = maxInd;
            
            % Add things to forbidden list
            initLogical = false(nBasis,1);
            initLogical(maxInd) = true;
            firstKernel = prtKernel.sparseKernelFactory(Obj.kernels,DataSet, initLogical);
            firstPhiNormalized = prtKernel.runMultiKernel(firstKernel, DataSet);
            firstPhiNormalized = firstPhiNormalized - mean(firstPhiNormalized);
            firstPhiNormalized = firstPhiNormalized./sqrt(sum(firstPhiNormalized.^2));
            phiCorrs = zeros(nBasis,1);
            for iBlock = 1:nBlocks
                cInds = ((iBlock-1)*Obj.largestNumberOfGramColumns+1):min([iBlock*Obj.largestNumberOfGramColumns nBasis]);
                
                trainedKernelCell = prtKernel.sparseKernelFactory(Obj.kernels,DataSet,cInds);
                
                if nBlocks > 1 % If there is only one block we can keep the on from before
                    blockPhi = prtKernel.runMultiKernel(trainedKernelCell,DataSet);
                end
                blockPhiDemeanedNormalized = bsxfun(@minus,blockPhi,mean(blockPhi));
                blockPhiDemeanedNormalized = bsxfun(@rdivide,blockPhiDemeanedNormalized,sqrt(sum(blockPhiDemeanedNormalized.*blockPhiDemeanedNormalized))); % We have to normalize here
                
                phiCorrs(cInds) = blockPhiDemeanedNormalized'*firstPhiNormalized;
            end
            forbidden(phiCorrs > Obj.learningCorrelationRemovalThreshold) = maxInd;
            
            % Start the actual Process
            if Obj.learningVerbose
                %fprintf('Sequential RVM training with %d possible vectors.\n', length(trainedKernels));
                fprintf('\t Iteration 0: Intialized with vector %d.\n', maxInd);
                
                nVectorsStringLength = ceil(log10(length(nBasis)))+1;
            end
            
            if nBlocks == 1
                % If we have only 1 block we only need to do this once.
                trainedKernelCell = prtKernel.sparseKernelFactory(Obj.kernels,DataSet,true(nBasis,1));
                PhiM = prtKernel.runMultiKernel(trainedKernelCell,DataSet);
            end
            
            % Get the first relevant kernel matrix
            trainedKernelCell = prtKernel.sparseKernelFactory(Obj.kernels,DataSet,relevantIndices);
            cPhi = prtKernel.runMultiKernel(trainedKernelCell,DataSet);
            
            for iteration = 1:Obj.learningMaxIterations
                
                % Store old log Alpha
                logAlphaOld = log(alpha);
                
                if iteration == 1
                    % Initial estimates
                    % Estimate Sigma, mu etc.
                    
                    logOut = (ym11*0.9+1)/2;
                    mu = cPhi \ log(logOut./(1-logOut));
                    
                    alpha(relevantIndices) = 1./mu.^2;
                    
                    % Laplacian approx. IRLS
                    A = diag(alpha(relevantIndices));
                    
                    [mu, SigmaInvChol, obsNoiseVar] = prtUtilPenalizedIrls(y,cPhi,mu,A);
                    
                    SigmaChol = inv(SigmaInvChol);
                    Obj.Sigma = SigmaChol*SigmaChol';
                    
                    yHat = 1 ./ (1+exp(-cPhi*mu));
                end
                
                % Eval additions and subtractions
                Sm = zeros(nBasis,1);
                Qm = zeros(nBasis,1);
                cError = y-yHat;
                
                cPhiProduct = bsxfun(@times,cPhi,obsNoiseVar);
                for iBlock = 1:nBlocks
                    cInds = ((iBlock-1)*Obj.largestNumberOfGramColumns+1):min([iBlock*Obj.largestNumberOfGramColumns nBasis]);
                    

                    if nBlocks > 1 % If there is only one block we can keep the on from before
                        trainedKernelCell = prtKernel.sparseKernelFactory(Obj.kernels,DataSet,cInds);
                        PhiM = prtKernel.runMultiKernel(trainedKernelCell,DataSet);
                    end
                    
                    Sm(cInds) = (obsNoiseVar'*(PhiM.^2)).' - sum((PhiM.'*cPhiProduct*SigmaChol).^2,2);
                    Qm(cInds) = PhiM.'*cError;
                end
                
                % Find little sm and qm (these are different for relevant vectors)
                sm = Sm;
                qm = Qm;
                
                cDenom = (alpha(relevantIndices)-Sm(relevantIndices));
                sm(relevantIndices) = alpha(relevantIndices) .* Sm(relevantIndices) ./ cDenom;
                qm(relevantIndices) = alpha(relevantIndices) .* Qm(relevantIndices) ./ cDenom;
                
                theta = qm.^2 - sm;
                cantBeRelevent = theta < 0;
                
                % Addition
                addLogLikelihoodChanges = 0.5*( theta./Sm + log(Sm ./ Qm.^2) ); % Eq (27)
                addLogLikelihoodChanges(cantBeRelevent) = 0; % Can't add things that are disallowed by theta
                addLogLikelihoodChanges(relevantIndices) = 0; % Can't add things already in
                addLogLikelihoodChanges(forbidden > 0) = 0; % Can't add things that are forbidden
                
                % Removal
                removeLogLikelihoodChanges = -0.5*( qm.^2./(sm + alpha) - log(1 + sm./alpha) ); % Eq (37) (I think this is wrong in the paper. The one in the paper uses Si and Qi, I got this based on si and qi (or S and Q in their code), from corrected from analyzing code from http://www.vectoranomaly.com/downloads/downloads.htm)
                removeLogLikelihoodChanges(~relevantIndices) = 0; % Can't remove things not in
                removeLogLikelihoodChanges(imag(removeLogLikelihoodChanges) > 0) = inf;
                
                % Modify
                updatedAlpha = sm.^2 ./ theta;
                updatedAlphaDiff = 1./updatedAlpha - 1./alpha;
                modifyLogLikelihoodChanges = 0.5*( updatedAlphaDiff.*(Qm.^2) ./ (updatedAlphaDiff.*Sm + 1) - log(1 + Sm.*updatedAlphaDiff) );
                
                modifyLogLikelihoodChanges(~relevantIndices) = 0; % Can't modify things not in
                modifyLogLikelihoodChanges(cantBeRelevent) = 0; % Can't modify things that technically shouldn't be in (they would get dropped)
                
                [addChange, bestAddInd] = max(addLogLikelihoodChanges);
                [remChange, bestRemInd] = max(removeLogLikelihoodChanges);
                [modChange, bestModInd] = max(modifyLogLikelihoodChanges);
                
                if iteration == 1
                    % On the first iteration we don't allow removal
                    [maxChangeVal, actionInd] = max([addChange, nan, modChange]);
                else
                    if remChange > 0 && Obj.learningFactorRemove
                        % Removing is top priority.
                        % If removing increases the likelihood, we have two
                        % options, actually remove that sample or modify that
                        % sample if that is better
                        [maxChangeVal, actionInd] = max([nan remChange, modifyLogLikelihoodChanges(bestRemInd)]);
                    else
                        % Not going to remove, so we would be allowed to modify
                        [maxChangeVal, actionInd] = max([addChange, remChange, modChange]);
                    end
                end
                
                if maxChangeVal > Obj.learningPoorlyScaledLikelihoodThreshold
                    warning('prtClassRvm:BadKernelMatrix','Kernel matrix is poorly conditioned. Consider modifying your kernels. Optimization Exiting...' );
                    break
                end
                
                if maxChangeVal < Obj.learningLikelihoodIncreaseThreshold
                    % There are no good options right now. Therefore we
                    % should exit with the previous iteration stats.
                    Obj.learningConverged = true;
                    Obj.learningResults.exitReason = 'No Good Actions';
                    Obj.learningResults.exitValue = maxChangeVal;
                    if Obj.learningVerbose
                        fprintf('Convergence criterion met, no necessary actions remaining, maximal change in log-likelihood %g\n\n',maxChangeVal);
                    end
                    
                    break;
                end
                
                if Obj.learningVerbose
                    actionStrings = {sprintf('Addition: Vector %s has been added.  ', sprintf(sprintf('%%%dd',nVectorsStringLength),bestAddInd));
                        sprintf('Removal:  Vector %s has been removed.', sprintf(sprintf('%%%dd',nVectorsStringLength), bestRemInd));
                        sprintf('Update:   Vector %s has been updated.', sprintf(sprintf('%%%dd',nVectorsStringLength), bestModInd));};
                    fprintf('\t Iteration %d: %s Change in log-likelihood %g.\n',iteration, actionStrings{actionInd}, maxChangeVal);
                end
                
                switch actionInd
                    case 1 % Add
                        
                        relevantIndices(bestAddInd) = true;
                        selectedInds = cat(1,selectedInds,bestAddInd);
                        
                        alpha(bestAddInd) = updatedAlpha(bestAddInd);
                        % Modify Mu
                        % (Penalized IRLS will fix it soon but we need good initialization)
                        
                        trainedKernelCell = prtKernel.sparseKernelFactory(Obj.kernels,DataSet,bestAddInd);
                        newPhi = prtKernel.runMultiKernel(trainedKernelCell,DataSet);
                        
                        cFactor = (Obj.Sigma*(cPhi)'*(newPhi.*obsNoiseVar));
                        Sigmaii = 1./(updatedAlpha(bestAddInd) + Sm(bestAddInd));
                        newMu = Sigmaii*Qm(bestAddInd);
                        
                        updatedOldMu = mu - newMu*cFactor;
                        sortedSelected = sort(selectedInds);
                        newMuLocation = find(sortedSelected==bestAddInd);
                        
                        mu = zeros(length(mu)+1,1);
                        mu(setdiff(1:length(mu),newMuLocation)) = updatedOldMu;
                        mu(newMuLocation) = newMu;
                        
                        
                        % Add things to forbidden list
                        % **Why are we re-calculating newPhi here?
                        newPhiDemeanedNormalized = newPhi - mean(newPhi);
                        newPhiDemeanedNormalized = newPhiDemeanedNormalized./sqrt(sum(newPhiDemeanedNormalized.^2));
                        phiCorrs = zeros(nBasis,1);
                        for iBlock = 1:nBlocks
                            cInds = ((iBlock-1)*Obj.largestNumberOfGramColumns+1):min([iBlock*Obj.largestNumberOfGramColumns nBasis]);
                            
                            if nBlocks > 1
                                trainedKernelCell = prtKernel.sparseKernelFactory(Obj.kernels,DataSet,cInds);
                                blockPhiDemeanedNormalized = prtKernel.runMultiKernel(trainedKernelCell,DataSet);
                                
                                blockPhiDemeanedNormalized = bsxfun(@minus,blockPhiDemeanedNormalized,mean(blockPhiDemeanedNormalized));
                                blockPhiDemeanedNormalized = bsxfun(@rdivide,blockPhiDemeanedNormalized,sqrt(sum(blockPhiDemeanedNormalized.*blockPhiDemeanedNormalized))); % We have to normalize here
                                
                                %else we have this from before
                                
                            end
                            
                            phiCorrs(cInds) = blockPhiDemeanedNormalized'*newPhiDemeanedNormalized;
                        end
                        forbidden(phiCorrs > Obj.learningCorrelationRemovalThreshold) = bestAddInd;
                        
                        
                    case 2 % Remove
                        
                        removingInd = sort(selectedInds)==bestRemInd;
                        
                        mu = mu + mu(removingInd) .* Obj.Sigma(:,removingInd) ./ Obj.Sigma(removingInd,removingInd);
                        mu(removingInd) = [];
                        
                        relevantIndices(bestRemInd) = false;
                        selectedInds(selectedInds==bestRemInd) = [];
                        alpha(bestRemInd) = inf;
                        
                        % Anything this guy said is forbidden is now
                        % allowed.
                        forbidden(forbidden == bestRemInd) = 0;
                        
                    case 3 % Modify
                        modifyInd = sort(selectedInds)==bestModInd;
                        
                        alphaChangeInv = 1/(updatedAlpha(bestModInd) - alpha(bestModInd));
                        kappa = 1/(Obj.Sigma(modifyInd,modifyInd) + alphaChangeInv);
                        mu = mu - mu(modifyInd)*kappa*Obj.Sigma(:,modifyInd);
                        
                        alpha(bestModInd) = updatedAlpha(bestModInd);
                end
                
                % At this point relevantIndices and alpha have changes.
                % Now we re-estimate Sigma, mu, and sigma2
                if nBlocks > 1
                    trainedKernelCell = prtKernel.sparseKernelFactory(Obj.kernels,DataSet,relevantIndices);
                    cPhi = prtKernel.runMultiKernel(trainedKernelCell,DataSet);
                else
                    cPhi = PhiM(:,relevantIndices);
                end
                
                % Laplacian approx. IRLS
                A = diag(alpha(relevantIndices));
                
                if isempty(cPhi)
                    yHat = 0.5*ones(size(y));
                else
                    [mu, SigmaInvChol, obsNoiseVar] = prtUtilPenalizedIrls(y,cPhi,mu,A);
                    
                    SigmaChol = inv(SigmaInvChol);
                    Obj.Sigma = SigmaChol*SigmaChol';
                    
                    yHat = 1 ./ (1+exp(-cPhi*mu)); % We use a logistic here. 
                end
                
                % Store beta
                Obj.beta = zeros(nBasis,1);
                Obj.beta(relevantIndices) = mu;
                
                if ~mod(iteration,Obj.learningPlot)
                    if DataSet.nFeatures == 2
                        Obj.verboseIterationPlot(DataSet,relevantIndices);
                    elseif iteration == 1
                        warning('prt:prtClassRvmSequential','Learning iteration plot can only be produced for training Datasets with 2 features');
                    end
                end
                
                % Check tolerance
                changeVal = abs(log(alpha)-logAlphaOld);
                changeVal(isnan(changeVal)) = 0; % inf-inf = nan
                if all(changeVal < Obj.learningConvergedTolerance) && iteration > 1
                    Obj.learningConverged = true;
                    Obj.learningResults.exitReason = 'Alpha Not Changing';
                    Obj.learningResults.exitValue = TOL;
                    if Obj.learningVerbose
                        fprintf('Exiting...Precisions no longer changing appreciably.\n\n');
                    end
                    break;
                end
            end
            
            if Obj.learningVerbose && iteration == Obj.learningMaxIterations
                fprintf('Exiting...Convergence not reached before the maximum allowed iterations was reached.\n\n');
            end
            
            % Make sparse represenation
            Obj.sparseBeta = Obj.beta(relevantIndices,1);
            Obj.sparseKernels = prtKernel.sparseKernelFactory(Obj.kernels,DataSet,relevantIndices);
            
            
            % Very bad training
            if isempty(Obj.sparseBeta)
                warning('prt:prtClassRvm:NoRelevantFeatures','No relevant features were found during training.');
            end
            
            % Reset warning
            warning(warningState);
            
        end
    end
end
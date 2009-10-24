classdef prtDataSetLabeledInMemory < prtDataSetInMemory & prtDataSetBaseInMemoryLabeled
    
    properties (Dependent)
        nTargetDimensions   % size(targets,2)
    end
    
    % inherits: data, targets from prtDataSetInMemoryTemp
    
    methods
        
        function nTargetDimensions = get.nTargetDimensions(obj)
            nTargetDimensions = size(obj.targets,2);
        end
        
        % PLOT has to go in class or regress, but should use
        % prtDataSetBase.plotPoints...
        %
        
        %         function varargout = plot(obj, featureIndices)
%             if nargin < 2 || isempty(featureIndices)
%                 featureIndices = 1:obj.nFeatures;
%             end
%             if islogical(featureIndices)
%                 featureIndices = find(featureIndices);
%             end
%             
%             nPlotDimensions = length(featureIndices);
%             if nPlotDimensions < 1
%                 warning('prt:plot:NoPlotDimensionality','No plot dimensions requested.');
%                 return
%             end
%             if nPlotDimensions > 3
%                 error('prt:plot:plotDimensionality','The number of requested plot dimensions (%d) is greater than 3. You may want to use explore() to selet and visualize a subset of the features.',nPlotDimensions);
%             end
%             if max(featureIndices) > obj.nFeatures
%                 error('prt:plot:plotDimensionality','A requested plot dimensions (%d) exceeds the dimensionality of the data set (%d).',max(featureIndices),obj.nFeatures);
%             end
%             
%             % Preserve the hold state of the figure
%             holdState = ishold;
%             
%             % This is a little weird. But it prevents us from duplicating
%             % this code so ...
%             % Get colors and symbols from the colors and symbols functions
%             isLabeled = ismethod(obj,'getTargets');
%             if isLabeled
%                 nClasses = obj.nUniqueTargets;
%                 classColors = obj.plottingColors;
%                 classSymbols = obj.plottingSymbols;
%             else
%                 nClasses = 1;
%                 classColors = prtPlotUtilClassColors(1);
%                 classSymbols = prtPlotUtilClassSymbols(1);
%             end
%             
%             
%             handleArray = zeros(nClasses,1);
%             % Loop through classes and plot
%             for i = 1:nClasses
%                 if isLabeled
%                     cX = obj.getObservationsByUniqueTargetInd(i, featureIndices);
%                 else
%                     cX = obj.getObservations([], featureIndices);
%                 end
%                 
%                 
%                 cEdgeColor = min(classColors(i,:) + 0.2,[0.8 0.8 0.8]);
%                 
%                 switch nPlotDimensions
%                     case 1
%                         handleArray(i) = plot(cX,ones(size(cX)),classSymbols(i),'MarkerFaceColor',classColors(i,:),'MarkerEdgeColor',cEdgeColor,'linewidth',0.1);
%                         xlabel(getFeatureNames(obj,featureIndices(1)));
%                         grid on
%                     case 2
%                         handleArray(i) = plot(cX(:,1),cX(:,2),classSymbols(i),'MarkerFaceColor',classColors(i,:),'MarkerEdgeColor',cEdgeColor,'linewidth',0.1);
%                         xlabel(getFeatureNames(obj,featureIndices(1)));
%                         ylabel(getFeatureNames(obj,featureIndices(2)));
%                         grid on
%                     case 3
%                         handleArray(i) = plot3(cX(:,1),cX(:,2),cX(:,3),classSymbols(i),'MarkerFaceColor',classColors(i,:),'MarkerEdgeColor',cEdgeColor,'linewidth',0.1);
%                         xlabel(getFeatureNames(obj,featureIndices(1)));
%                         ylabel(getFeatureNames(obj,featureIndices(2)));
%                         zlabel(getFeatureNames(obj,featureIndices(3)));
%                         grid on;
%                 end
%                 if i == 1
%                     hold on;
%                 end
%             end
%             
%             % Set title
%             title(obj.name);
%             
%             % Set hold state back to the way it was
%             if holdState
%                 hold on;
%             else
%                 hold off;
%             end
%             
%             % Create legend
%             if isLabeled
%                 legendStrings = getUniqueTargetNames(obj);
%                 legend(handleArray,legendStrings,'Location','SouthEast');
%             end
%             
%             % Handle Outputs
%             varargout = {};
%             if nargout > 0
%                 varargout = {handleArray,legendStrings};
%             end
%         end
               
    end
        
end
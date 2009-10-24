classdef prtDataSetUnLabeled < prtDataSetInMemory
    
    properties (Dependent, Hidden)
        % Additional properties for plotting
        plottingColors
        plottingSymbols
    end
    
    methods
        %% Constructor %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function prtDataSet = prtDataSetUnsupervised(varargin)
            % prtDataSet = prtDataSetClass
            % prtDataSet = prtDataSetClass(prtDataSetClassIn, {paramName1, paramVal2, ...})
            % prtDataSet = prtDataSetClass(data, {paramName1, paramVal2, ...})
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Empty Constructor %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % prtDataSet = prtDataSetClass %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if nargin == 0
                % Empty constructor
                % Nothing to do
                return
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % All Other Constructors %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % prtDataSet = prtDataSetClass(prtDataSetIn, {paramName1, paramVal2, ...})
            % prtDataSet = prtDataSetClass(data, targets, {paramName1, paramVal2, ...})
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if isa(varargin{1}, 'prtDataSetUnsupervised')
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % Copy Constructor %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % prtDataSet = prtDataSetClass(prtDataSetClassIn, {paramName1, paramVal2, ...})
                % Will be the same as other constructors after this..
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                prtDataSet = varargin{1};
                varargin = varargin(2:end);
                
            else
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % Regular Constructor %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % prtDataSet = prtDataSetUnsupervised(data, {paramName1, paramVal2, ...})
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                prtDataSet.data = varargin{1};
                varargin = varargin(2:end);
            end
            
            % At this point we have varargin as string value pairs and
            % prtDataSet with data and targets set
            
            % Quick exit if no more inputs.
            if isempty(varargin)
                return
            end
            
            % Check Parameter string, value pairs
            inputError = false;
            if mod(length(varargin),2)
                inputError = true;
            end
            paramNames = varargin(1:2:(end-1));
            if ~iscellstr(paramNames)
                inputError = true;
            end
            
            paramValues = varargin(2:2:end);
            if inputError
                error('prt:prtDataSetUnsupervised:invalidInputs','Additional input arguments must be specified as parameter string, value pairs.')
            end
            
            % Now we loop through and apply the properties
            for iPair = 1:length(paramNames)
                prtDataSet.(paramNames{iPair}) = paramValues{iPair};
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        end
    end
    
    methods
       
        function colors = get.plottingColors(obj)
            colors = prtPlotUtilClassColors(obj.nUniqueTargets);
        end
        function symbols = get.plottingSymbols(obj)
            symbols = prtPlotUtilClassSymbols(obj.nUniqueTargets);
        end
        
        %PLOT:
        function varargout = plot(obj, featureIndices)
            
             if nargin < 2 || isempty(featureIndices)
                 featureIndices = 1:obj.nFeatures;
             end
             if islogical(featureIndices)
                 featureIndices = find(featureIndices);
             end
            
            nPlotDimensions = length(featureIndices);
            if nPlotDimensions < 1
                warning('prt:plot:NoPlotDimensionality','No plot dimensions requested.');
                return
            end
            
            nClasses = 1;
            classColors = prtPlotUtilClassColors(nClasses);
            classSymbols = prtPlotUtilClassSymbols(nClasses);
            handleArray = zeros(nClasses,1);
            
            cX = obj.getObservations;
            classEdgeColor = min(classColors + 0.2,[0.8 0.8 0.8]);
            linewidth = .1;
            handleArray = prtDataSetBase.plotPoints(cX,obj.getFeatureNames(featureIndices),classSymbols,classColors,classEdgeColor,linewidth);
            
            % Set title
            title(obj.name);
                        
            % Handle Outputs
            varargout = {};
            if nargout > 0
                varargout = {handleArray};
            end
        end
    end
end

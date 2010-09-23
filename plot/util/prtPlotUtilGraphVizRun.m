function FileInfo = prtPlotUtilGraphVizRun(connectivity)
% FileInfo = prtPlotUtilGraphVizRun(connectivity)
%   Calls the GraphViz binary neato on the graph specified by 
%   connectivity matrix.
% 
%   This requires that GraphViz is installed or more specifically that
%   neato is available from the command prompt.

% Write file for graphviz
tempDotFileName = fullfile(tempdir,'_tempPrtGraphVizGraph.dot');
tempLayoutFileName = fullfile(tempdir,'_tempPrtGraphVizLayout.dot');
prtPlotUtilGraphVizWriteDot(connectivity, tempDotFileName);

% Create graphviz command 
% -Gsplines=true -Gsep=0.1
% -Glevelsgap=100
% -Gratio="expand" 
% -Goverlap=true
% -Gminlen=5 
% -Gdiredgeconstraints= 
% -Gnojustify=true
% -Gpack=true
% -Gratio="expand"
%commandStr = 'neato -Tdot -Gminlen=2 -Gnormalize=true  -Gmaxiter=25000 -Gmode=hier -Glevelsgap=10 -Grankdir="LR" -y';
%commandStr = 'sfdp -Tdot -Gnormalize=true -Gratio="expand" -Gmaxiter=25000 -Gquadtree=true -Glevels=6 -y';

commandStr = 'dot -Tdot -Grankdir="LR" -Gmaxiter=2500 -Gpack=true';

commandStr = cat(2,commandStr,' -o "',tempLayoutFileName,'" "',tempDotFileName,'"');

% Call graphviz
[systemStatus, systemResult] = system(commandStr); %#ok<NASGU>

if systemStatus
    error('prtPlotUtilGraphVizRun:graphvizIssue','Problem running Graphviz. Do you have it installed and on the system path? Try >>system(''dot -V'') to see.')
end

% Read file from graphviz
FileInfo = prtPlotUtilGraphVizReadDot(tempLayoutFileName);

% Clean up temporary files 
delete(tempDotFileName);
delete(tempLayoutFileName);
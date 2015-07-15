% std_lm_getvars() - Retrieve categorical and continuous variables from a
%                    design in the STUDY structure to build the regressors
%
% Usage:
%   >>  [catvar,varnames,StartEndIndx] =
%       std_lm_getvars(STUDY,ALLEEG,'S01','design_indx',1);
%   >>  [catvar,varnames,StartEndIndx] =
%       std_lm_getvars(STUDY,ALLEEG,'S01','design_indx',1,'vartype','cat');
%
% Inputs:
%      STUDY       - studyset structure containing some or all files in ALLEEG
%      ALLEEG      - vector of loaded EEG datasets
%      subject     - String with the subject identifier
%
% Optional inputs:
%      vartype      - Categoricals ('cat') or continuous ('cont')
%      design_indx  - Index of the design in he STUDY structure
%      factors      - Name of the variables(factors) to pull out. If not
%                     provided, will use all the factors availables in the design.
%
% Outputs:
% var_matrix   - Variables retrieved from the design specified in the STUDY.
%                Each column represent a factor a nd each row the index of
%                the variables in STUDY.design.variable.value
%                By default NaNs values will be inserted if no info from
%                that variable is not found in the original ALLEEG index,
%                This is to keep the original number of trials from ALLEEG
% See also:
%
% Author: Ramon Martinez-Cancino, SCCN, 2015
%
% Copyright (C) 2015  Ramon Martinez-Cancino,INC, SCCN
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

function [var_matrix,catvar_info] = std_lm_getvars(STUDY,subject,varargin)

% Prevent empty output
var_matrix  = [];
catvar_info = [];

%% Varargin stuff
%  --------------
try
    options = varargin;
    if ~isempty( varargin ),
        for i = 1:2:numel(options)
            g.(options{i}) = options{i+1};
        end
    else g= []; end;
catch
    error('std_lm_getcatvars() error: calling convention {''key'', value, ... } error'); return;
end;

try, g.design;         catch, g.design      = 1 ;       end; % By default will be use the fisrt design if not especified
try, g.factors;        catch, g.factors     = '';       end; % If not provided it will use all the factors
try, g.setindx;        catch, g.setindx     = '';       end; % if not provided it will look for all the Sets that belong to this Subject
try, g.vartype;        catch, g.vartype     = 'cat';    end; % 'cat' or 'cont'

%% cat/cont defs
%  -------------
if strcmp(g.vartype,'cat')
    vartype = 'categorical';
elseif strcmp(g.vartype,'cont')
    vartype = 'continuous';
end
%% Checking if design
%  ------------------
if g.design > size(STUDY.design,2)
    error('std_lm_getvars() error: Invalid design index');
end

%% Checking setindex and valid subject
%  -----------------------------------
CurrentSubIndxDataset   = find(strcmp({STUDY.datasetinfo.subject},subject));
if isempty(subject)
    error('std_lm_getcatvars() error: A valid subject must be provided');
end

if ~isempty(g.setindx)
    if sum(ismember(CurrentSubIndxDataset, g.setindx)) == 0
        error('std_lm_getcatvars() error: Indices of sets does not match the subject provided ');
    end
else
    g.setindx = CurrentSubIndxDataset;
end

%% Getting factors
%  ---------------
if isempty(g.factors)
    varindx   = find(strcmp({STUDY.design(g.design).variable.vartype},vartype));
    for i = 1:length(varindx)
        if strcmp(g.vartype,'cat')
            g.factors{i} = STUDY.design(g.design).variable(varindx(i)).value;
        else
            g.factors{i} = STUDY.design(g.design).variable(varindx(i)).label;
        end
    end
    % Cleaning  'g.factors' from empty cells
    for i = 1 : length(g.factors)
        if isempty(g.factors{i}) | strcmp(g.factors{i},''), g.factors(i) = []; end;
    end
else
    % Place to check consistency of factors input
end

%% Number of trials and index
%  --------------------------
NbTrials   = 0;
dsetvect = [];
indstrialscont = [];
for i = 1 : length(g.setindx)
    nbtrials_tpm = length(STUDY.datasetinfo(g.setindx(i)).trialinfo);
    NbTrials = NbTrials + nbtrials_tpm;
    % ---
    if i == 1,
        StartEndIndx{i} = 1: nbtrials_tpm;
    else
        StartEndIndx{i} = StartEndIndx{i-1}(end) + 1 : StartEndIndx{i-1}(end) + nbtrials_tpm;
    end
    dsetvect       = [dsetvect g.setindx(i)*ones(1,length(StartEndIndx{i}))];
    indstrialscont = [indstrialscont 1: nbtrials_tpm];
end

%% Getting categorical/continuous variables from STUDY design
%  ----------------------------------------------------------
var_matrix = nan(NbTrials,length(g.factors));                   % Initializing Categorical Variables

%  Retreiving all trials and values for this subject
trialinfo  = std_combtrialinfo(STUDY.datasetinfo, g.setindx);   % Combining trialinfo
ntrials = 0;
for i = 1 : length(g.setindx)
    startendindx(i,1) = ntrials + 1;
    ntrials = ntrials + length(STUDY.datasetinfo(g.setindx(i)).trialinfo);
    startendindx(i,2) = ntrials;
end

%  Loop per variable
for i = 1 : length(varindx)
    
    % case for continous variables
    if strcmp(g.vartype, 'cont')
        varlength = 1;
        catflag = 0;
    else
        varlength = length(STUDY.design(g.design).variable(varindx(i)).value);
        catflag = 1;
    end
    
    % Loop per Variable values
    for j = 1 : varlength
        if catflag
            facval = cell2mat(STUDY.design(g.design).variable(varindx(i)).value(j));
            if isnumeric(facval)
                facval_indx = find(facval == cell2mat(STUDY.design(g.design).variable(varindx(i)).value));
            else
                facval_indx = find(strcmp(facval,STUDY.design(g.design).variable(varindx(i)).value));
            end
        end
        
        % No loop per dataset since we merged datasetinfo
        if catflag
            if isnumeric( cell2mat(STUDY.design(g.design).variable(varindx(i)).value(j)))
                varval = cell2mat(STUDY.design(g.design).variable(varindx(i)).value(j));
            else
                varval = STUDY.design(g.design).variable(varindx(i)).value(j);
            end
        else
            varval = '';
        end
        [trialindsx, eventvals] = std_gettrialsind(trialinfo,STUDY.design(g.design).variable(varindx(i)).label, varval);
        if ~isempty(trialindsx)
            % case for continous variables
            if ~catflag
                facval_indx = eventvals;
            end
            var_matrix(trialindsx,i) = facval_indx;
        end
    end
end

%% Getting trialindex  and names for overlapped conditions
%  -------------------------------------------------------
tmpmat = var_matrix;
tmpindx = find(isnan(tmpmat));
[I,tmp] = ind2sub(size(tmpmat),tmpindx); clear tmp; %#ok<ASGLU>
tmpmat(I,:) = [];
if strcmp(g.vartype,'cat')
    ind = 1;
    comb = unique(tmpmat,'rows');
    for i = 1: size(comb,1)
        TrialIndx_tmp{i} = find(sum(repmat(comb(i,:),[size(var_matrix,1),1]) == var_matrix,2) == size(var_matrix,2));
        tmpsets = dsetvect(TrialIndx_tmp{i});
        uniqtmpset = unique(tmpsets);
        if length(uniqtmpset) ~= 1
            tmpvect = dsetvect;
            tmpvect(setdiff(1:length(dsetvect),TrialIndx_tmp{i})) = 0;
            
            for k = 1: length(uniqtmpset)
                TrialIndx_datasetinfo{ind} = find(uniqtmpset(k) == tmpvect);
                datasets{ind} = uniqtmpset(k);
                ind = ind + 1;
            end
        else
            TrialIndx_datasetinfo{ind} = TrialIndx_tmp{i};
            datasets{ind}              = uniqtmpset;
        end
        ind = ind + 1;
    end
else
    datasets = g.setindx;
    TrialIndx_datasetinfo = StartEndIndx;
    if ~isempty(tmpindx)
        for i = 1:length(TrialIndx_datasetinfo)
            for j = 1:length(I)
                if ismember(I(j),TrialIndx_datasetinfo{i}), TrialIndx_datasetinfo{i}(I(j)) = []; end
            end
        end
    end
end

for i = 1:length(TrialIndx_datasetinfo)
    TrialIndx_sets{i} =  indstrialscont(TrialIndx_datasetinfo{i});
end

%% Outputs
%  -------
catvar_info.datasetinfo_trialindx   = TrialIndx_sets;  % Indices at datasetinfo.trialinfo {1:Ntrials1} {1:Ntrials2}
catvar_info.concat_trialindx        = StartEndIndx;    % Indices at [ 1 : Ntrials1 , Ntrials1+1 : Ntrials2]
catvar_info.datasetinfo_concatindx  = g.setindx;
catvar_info.dataset                 = datasets;
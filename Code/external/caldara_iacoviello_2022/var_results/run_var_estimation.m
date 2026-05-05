% tic
% 
% %----------------------
% % Housekeeping    
% %----------------------
% 
% clc; 
% clear all;  
% close all;
% 
% addpath('auxfiles')
% 
% %----------------------
% % Specify Settings
% %----------------------
% 
% % Specify models to estimate (see model_spec.m)
% model_vec = {'GPRBASELINE'}; %,'GPRSPIKES','GPREPU','GPRALTCHOL',...
%              %'GPRSMALL_INV','GPRSMALL_HOURS','GPRLAGS','GPRGDP'}; 
% 
% mode = 'quarterly';  % or 'quarterly', 'annual', 'monthly'
% variable = 'Political Violence'; % 'Mass Civil Protest', 'Instability within Regime"', 'Instability of Regime'
% 
% if strcmp(mode,'annual')
%     country_vec = {'Benin','Burkina_Faso','Cameroon','Central_African_Republic','Chad','Cote_d_Ivoire', 'Democratic_Republic_of_the_Congo', ...
%     'Equatorial_Guinea','Gabon','Ghana', 'Guinea_Bissau', 'Mali', ... %'Mauritania', 
%     'Niger','Nigeria','Senegal','Togo'};
% 
%     varnames = {variable,'Exchange Rate', 'CPI','Interest Rate','GDP growth'};
%     varlabels = {strrep(variable, '_', '\_'),'Exchange Rate', 'CPI','Interest Rate','GDP growth'};
% 
% elseif strcmp(mode, 'quarterly')
%     country_vec = {'Benin','Burkina_Faso','Cote_d_Ivoire', 'Ghana', 'Guinea_Bissau', 'Mali', 'Niger', 'Nigeria', 'Senegal','Togo'};
% 
%     varnames = {variable,'Exchange Rate', 'CPI','Interest Rate','GDP growth'};
%     varlabels = {strrep(variable, '_', '\_'),'Exchange Rate', 'CPI','Interest Rate','GDP growth'};
% 
% elseif strcmp(mode, 'monthly')
%     country_vec = {'Benin','Burkina_Faso','Cameroon','Central_African_Republic','Chad','Cote_d_Ivoire', 'Democratic_Republic_of_the_Congo', ...
%     'Equatorial_Guinea','Gabon','Ghana', 'Guinea_Bissau', 'Mali', 'Mauritania', ...
%     'Niger','Nigeria','Senegal','Togo'};
% 
%     varnames = {variable,'Exchange Rate', 'CPI','Interest Rate','Nighttime Light'};
%     varlabels = {strrep(variable, '_', '\_'),'Exchange Rate', 'CPI','Interest Rate','Nighttime Light'};
% end
% 
% 
% 
% % Create output folder if it doesn't exist
% outputFolder = ['./estimate_' mode '/'];
% if ~exist(outputFolder, 'dir')
%     mkdir(outputFolder);
% end
% 
% % Number of lags & pre-sample for Minnesota Prior set on line 53
% minn_prior =0;    % Minnesota Prior
% T_hist = 0;       % Quarter to start extraction of structural shocks (0: full sample)
% nd    = 20000;    % Number of draws in MC chain
% bburn = 0.2*nd;   % Burn-in 
% 
% Horizon = 12;     % Horizon for impulse responses
% 
% ptileVEC  = [5 16 50 84 95]; % Percentiles of posterior distributions to store
% 
% randn('state',294015341); % Seed for random number generator
% 
% %----------
% % Load data
% %----------
% 
% % clear data
% % newData = importdata(['Burkina_Faso.csv']);
% % vars = fieldnames(newData);    
% % for i = 1:length(vars)
% %     assignin('base', vars{i}, newData.(vars{i}));
% % end
% % YYdata = data;
% % clear data
% % rawDates = textdata(2:end,1);
% % dt = datetime(rawDates,'InputFormat','yyyy.MM.dd');  % case-sensitive!
% % nDate = datenum(dt);
% 
% %------------------------------------------------------------
% % Original model_vec loop (commented out)
% %------------------------------------------------------------
% 
% % for iii = 1:size(model_vec,2)
% %     mmodel = model_vec{iii}; 
% %     
% %     disp(' ')
% %     disp(mmodel)
% %     
% %     if strcmp(mmodel,'GPRLAGS')
% %         p   = 4;          % Number of lags
% %         T0  = 4;          % Pre-sample for Minnesota Prior
% %         minn_prior =1;    % Minnesota Prior
% %     else 
% %         p   = 2;          % Number of lags
% %         T0  = 2;          % Pre-sample for Minnesota Prior
% %         minn_prior =0;    % Minnesota Prior
% %     end
% %     
% %     model_spec
% %     n = size(i_var_str,2);  % Number of Endogenous variables
% %     ...
% %     save(strcat('./Result_',char(mmodel),'.mat'),'VAR')
% % end
% 
% %------------------------------------------------------------
% % New country_vec loop to process one model across countries
% %------------------------------------------------------------
% 
% for c = 1:length(country_vec)
%     country = country_vec{c};
%     mmodel = 'GPRBASELINE';  % fixed model
% 
%     disp(['Processing country: ', country])
% 
%     %---------- Load data for the specific country ----------    
%     clear data
%     %filename = [country, '.csv'];
% 
%     dataPath = 'C:\Users\kphilipp\GitHub\newspaper_sentiment\Data\VAR\';
%     filename = fullfile([dataPath mode '\'], [country, '.csv']);
%     newData = importdata(filename);
% 
%     vars = fieldnames(newData);    
%     for i = 1:length(vars)
%         assignin('base', vars{i}, newData.(vars{i}));
%     end
%     YYdata = data;
%     clear data
% 
%     rawDates = textdata(2:end,1);
%     dt = datetime(rawDates,'InputFormat','yyyy.MM.dd');
%     nDate = datenum(dt);
% 
% 
%     %----------------------------
%     % Model setup
%     %----------------------------
% 
%     if strcmp(mmodel,'GPRLAGS')
%         p   = 4;          % Number of lags
%         T0  = 4;          % Pre-sample for Minnesota Prior
%         minn_prior =1;    % Minnesota Prior
%     else 
%         p   = 2;          % Number of lags
%         T0  = 2;          % Pre-sample for Minnesota Prior
%         minn_prior =0;    % Minnesota Prior
%     end
% 
%     model_spec
%     n = size(i_var_str,2);  % Number of Endogenous variables
% 
%     %----------------------------------------------------------------------    
%     %     DEFINITION OF PRIOR, DATA, LAG STRUCTURE AND POSTERIOR SIMULATION
%     %----------------------------------------------------------------------
% 
%     vm_dummy
% 
%     if minn_prior ==0
%         X          = XXact;
%         Y          = YYact;
%         T          = nobs;
%     elseif minn_prior ==1
%         X          = [XXact; XXdum];
%         Y          = [YYact; YYdum];
%         T          = nobs+Tdummy;
%     end



%==============================
% Bayesian VARX Estimation
%==============================

tic
clc; clear all; close all;
scriptDir = fileparts(mfilename('fullpath'));
auxDir = fullfile(scriptDir, 'auxfiles');
addpath(scriptDir)
addpath(auxDir)
packageRoot = fullfile(scriptDir, '..', '..', '..', '..');

model_vec = {'GPRBASELINE'};
mode = 'monthly';  % 'monthly' or 'annual' or 'quarterly'
variables = {'Political Violence', 'Mass Civil Protest', 'Instability within Regime', 'Instability of Regime'};  % 

%----------------------------------------
% Define countries and variables by mode
%----------------------------------------
if strcmp(mode,'annual')
    country_vec = {'Benin','Burkina_Faso','Cameroon','Central_African_Republic','Chad','Cote_d_Ivoire', ...
                   'Democratic_Republic_of_the_Congo','Equatorial_Guinea','Gabon','Ghana','Guinea_Bissau', ...
                   'Mali','Niger','Nigeria','Senegal','Togo'};
elseif strcmp(mode, 'quarterly')
    country_vec = {'Benin','Burkina_Faso','Cote_d_Ivoire', 'Ghana', 'Guinea_Bissau', 'Mali', 'Niger', 'Senegal','Togo' 'Nigeria'};
elseif strcmp(mode, 'monthly')
    country_vec = {'Democratic_Republic_of_the_Congo'};
end


minn_prior = 0;
T_hist = 0;
nd = 20000;
bburn = 0.2 * nd;
Horizon = 12;
ptileVEC = [5 16 50 84 95];

randn('state',294015341);

for vv = 1:length(variables)
    variable = variables{vv};

    outputFolder = fullfile(scriptDir, ['estimate_' mode], variable);
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

for c = 1:length(country_vec)
    country = country_vec{c};
    mmodel = 'GPRBASELINE';
    disp(['Processing country: ', country])

    %--------- Load Data ----------
    dataPath = fullfile(packageRoot, 'Data', 'Raw', 'public', 'VAR');
    filename = fullfile(dataPath, mode, [country, '.csv']);
    newData = importdata(filename);

fields = fieldnames(newData);
for i = 1:length(fields)
    assignin('base', fields{i}, newData.(fields{i}));
end
    YYdata = data;
    rawDates = textdata(2:end,1);
    dt = datetime(rawDates,'InputFormat','yyyy.MM.dd');
    nDate = datenum(dt);

    %--------- Model Setup ---------
    if strcmp(mmodel,'GPRLAGS')
        p = 4; T0 = 4; minn_prior = 1;
    else
        p = 3; T0 = 3; minn_prior = 0;
    end

    model_spec
    n = length(endo_vars);

    %--------- Prior & Regressors ---------
    vm_loaddata
    vm_dummy

    if minn_prior == 0
        X = XXact;
        Y = YYact;
        T = nobs;
    else
        X = [XXact; XXdum];
        Y = [YYact; YYdum];
        T = nobs + Tdummy;
    end


    J = [eye(n);repmat(zeros(n),p-1,1)];
    F = zeros(n*p,n*p);    % Matrix for Companion Form
    I  = eye(n);
    for i=1:p-1
        F(i*n+1:(i+1)*n,(i-1)*n+1:i*n) = I;
    end

    B = (X'*X)\(X'*Y); % Point estimates
    U = Y-X*B;      % Residuals
    Sigmau = U'*U/(T-p*n-1);   % Covariance matrix of residuals

    LC = chol(Sigmau)';
    Omega1 = [LC;zeros((p-1)*n,size(LC,2))];
    A0 = (LC')\eye(size(LC,1));
    F(1:n,1:n*p)    = B(1:n*p,:)';

    Ltilde      = zeros(nd-bburn,Horizon+1,n,nshocks);
    epsHistilde = zeros(nd-bburn,T,n);
    
    m = size(B,1);  % number of coefficients per equation

    if minn_prior ==0
        %N0=zeros(size(X',1),size(X,2));
        N0 = zeros(m,m);
        nnu0=0;
        nnuT = T +nnu0;
        NT = N0 + X'*X;    
        Bbar0=B;
        S0=Sigmau;
        BbarT = NT\(N0*Bbar0 + (X'*X)*B);
        %ST = (nnu0/nnuT)*S0 + (T/nnuT)*Sigmau + (1/nnuT)*((B-Bbar0)')*N0*(NT\eye(n*p+nex))*(X'*X)*(B-Bbar0);
        ST = (nnu0/nnuT)*S0 + (T/nnuT)*Sigmau + (1/nnuT)*(B-Bbar0)' * N0 * (NT\(X'*X)) * (B-Bbar0);
        STinv = ST\eye(n);
        m=size(B,1);
        R=zeros(n,nnuT);
    end

    %--------------------------
    % Bayesian Estimation
    %--------------------------
    
    record=0;     
    counter = 0;

    while record<nd

        if minn_prior == 1
            Sigmadraw   = iwishrnd(Sigmau*(T-n*p-1),T-n*p-1);  
            B_new = mvnrnd(reshape(B,n*(n*p+1),1),kron(Sigmadraw,inv(X'*X))); 
            %Bdraw     = reshape(B_new,n*p+nex,n);
            Bdraw = reshape(B_new,m,n);  % use m not hardcoded

        elseif minn_prior == 0
            R=mvnrnd(zeros(n,1),STinv/nnuT,nnuT)';
            Sigmadraw=(R*R')\eye(n);
            bbeta = B(:);
            %SigmaB = kron(Sigmadraw,NT\eye(n*p+nex));
            SigmaB = kron(Sigmadraw,NT\eye(m));  % use m
            SigmaB = (SigmaB+SigmaB')/2;
            Bdraw = mvnrnd(bbeta,SigmaB);
            %Bdraw     = reshape(Bdraw,n*p+nex,n);
            Bdraw = reshape(Bdraw,m,n);  % use m
        end

        %Bdraw= reshape(Bdraw,n*p+nex,n);
        LC =chol(Sigmadraw,'lower');
        F(1:n,1:n*p)    = Bdraw(1:n*p,:)';    

        record=record+1;
        counter = counter +1;
        if counter==0.2*nd
            disp(['         DRAW NUMBER:   ', num2str(record)]);
            counter = 0;
        end

        if record > bburn

            Utildedraw = YYact-XXact*Bdraw;
            epsHisdraw = LC\Utildedraw';
            epsHisdraw = epsHisdraw(:,T_hist+1:end);

            if strcmp(mmodel,'GPRBASELINE')
                epsHistilde(record-bburn,:,:) = epsHisdraw';
            end
            
            IRF_T = vm_irf(F,J,LC,Horizon+1,n,Omega1);

            if strcmp(mmodel,'GPRALTCHOL')
               IRF_T(:,:,1) = IRF_T(:,:,5);
            end
            
            IRF_T = IRF_T(:,:,1:nshocks);
            
            Ltilde(record-bburn,:,:,:) = IRF_T;

        end

    end 

    LtildeFull = prctile(Ltilde,ptileVEC);
    VAR.LtildeFull = permute(LtildeFull,[3,2,1,4]);

    if strcmp(mmodel,'GPRBASELINE')
        VAR.epsHistildeFull = prctile(epsHistilde,ptileVEC);
    end
    
    VAR.i_var_str_names = i_var_str_names;

    % Save with country name in filename
    %save(strcat('./Result_',country,'_',char(mmodel),'.mat'),'VAR')

    save(fullfile(outputFolder, ['Result_' country '_' char(mmodel) '.mat']), 'VAR')
end
end

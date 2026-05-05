% % PURPOSE: Generates dummy observations for a Minnesota Prior
% % -----------------------------------------------------
% % USAGE: vm_dummy
% % -----------------------------------------------------
% % NOTE: requires to run vm_spec.m
% % -----------------------------------------------------
% 
% % tau    : Overall tightness
% % d      : Scaling down the variance for the coefficients of a distant lag
% % w      : Number of observations used for obtaining the prior for the 
% %          covariance matrix of error terms (usually fixed to 1). 
% % lambda : Tuning parameter for coefficients for constant.
% % mu     : Tuning parameter for the covariance between coefficients*/
% 
% tau    = 0.5;
% d      = 3;
% w      = 1;
% lambda = 0.1;
% mu     = 0.1;
% 
% nv      = n;     %* number of variables */
% nobs    = size(YY,1)-T0;  %* number of observations */
% nlags_  = p;
% nex_    = nex;
% %******************************************************** 
% % Dummy Observations                                    *
% %*******************************************************/
% 
% %** Obtain mean and standard deviation from expandend pre-sample data
% if minn_prior==1
%    YY0     =   YY(1:T0,:);  
%     ybar    =   mean(YY0)';      
%     sbar    =   std(YY0)'; 
%     premom  =   [ybar sbar];
%     % Generate matrices with dummy observations
%     hyp = [tau; d; w; lambda; mu];
%     [YYdum, XXdum, breakss] = varprior_h(nv,nlags_,nex_,hyp,premom);
%     Tdummy = size(YYdum,1);
% end
% 
% % Actual observations
% 
% YYact = YY(T0+1:T0+nobs,:);
% XXact = zeros(nobs,nv*nlags_);
% 
% i = 1;
% 
% while (i <= nlags_)
%     XXact(:,(i-1)*nv+1:i*nv) = YY(T0-(i-1):T0+nobs-i,:);
%     i = i+1;
% end
% 
% XXact = [XXact ones(nobs,1)];
% 
% if nex ==2
%     XXact = [XXact dummybreak2001(nlags_+1:end,:)];
% end






%==============================
% Dummy Observations (VARX)
%==============================

tau = 0.5; d = 3; w = 1;
lambda = 0.1; mu = 0.1;

nv = length(endo_vars);
nobs = size(YY_endo,1)-T0;
nlags_ = p;
nex_ = size(YY_exog,2) + 1;

if minn_prior == 1
    YY0 = YY_endo(1:T0,:);
    ybar = mean(YY0)';      
    sbar = std(YY0)'; 
    premom = [ybar sbar];
    hyp = [tau; d; w; lambda; mu];
    [YYdum, XXdum, breakss] = varprior_h(nv, nlags_, nex_, hyp, premom);
    Tdummy = size(YYdum,1);
end

YYact = YY_endo(T0+1:T0+nobs,:);
XXact = zeros(nobs, nv*nlags_);

for i = 1:nlags_
    XXact(:,(i-1)*nv+1:i*nv) = YY_endo(T0-(i-1):T0+nobs-i,:);
end

% Add constant
XXact = [XXact, ones(nobs,1)];

% Add exogenous variables
if ~isempty(YY_exog)
    XXact = [XXact, YY_exog(T0+1:T0+nobs,:)];
end

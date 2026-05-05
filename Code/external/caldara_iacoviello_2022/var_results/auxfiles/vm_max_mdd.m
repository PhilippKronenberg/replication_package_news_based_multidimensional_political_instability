% PURPOSE: Compute Marginal Data Density for optimization
% 	   of hyper parameters
% -----------------------------------------------------
% USAGE: @vm_max_mdd in non-linear solver
% -----------------------------------------------------
% RETURNS: lnpYY = - (log marginal data density)
% -----------------------------------------------------
% NOTE: Requires to load
%	.mat file with data and VAR settings.
% -----------------------------------------------------


function lnpYY = vm_max_mdd(PE)

% tau     =   PE(1); 
% d       =   PE(2);
tau     =   1; 
d       =   3;
w       =   1;
% lambda  =   PE(3);
% mu      =   PE(4);
lambda  =   PE(1);
mu      =   PE(2);

%******************************************************** 
% Import data and VAR settings                          *
%*******************************************************/
load('results/data_max_mdd.mat','YY','T0','nlags_','nex_');


nv      = size(YY,2);     %* number of variables */
nobs    = size(YY,1)-T0;  %* number of observations */

%******************************************************** 
% Dummy Observations                                    *
%*******************************************************/

%** Obtain mean and standard deviation from expandend pre-sample data
 
YY0     =   YY(1:T0,:);  
ybar    =   mean(YY0)';      
sbar    =   std(YY0)'; 
premom  =   [ybar sbar];

% Generate matrices with dummy observations
hyp = [tau; d; w; lambda; mu];
% disp(hyp)
[YYdum, XXdum, breakss] = varprior_h(nv,nlags_,nex_,hyp,premom);

% Actual observations

YYact = YY(T0+1:T0+nobs,:);
XXact = zeros(nobs,nv*nlags_);

i = 1;

while (i <= nlags_)
    XXact(:,(i-1)*nv+1:i*nv) = YY(T0-(i-1):T0+nobs-i,:);
    i = i+1;
end

XXact = [XXact ones(nobs,1)];

%******************************************************** 
%* Compute the log marginal data density for the VAR model 
%*******************************************************/

YY=[YYdum' YYact']';
XX=[XXdum' XXact']';

n_total = size(YY,1);
n_dummy = n_total-nobs;
k      = size(XX,2);

S0     = (YYdum'*YYdum)-YYdum'*XXdum/(XXdum'*XXdum)*(XXdum'*YYdum); 

S1     = (YY'*YY)-YY'*XX/(XX'*XX)*XX'*YY;

%* compute constants for integrals

i=1;  
gam0=0; 
gam1=0; 

while i <= nv; 
   gam0=gam0+lngam(0.5*(n_dummy-k+1-i)); 
   gam1=gam1+lngam(0.5*(n_total-k+1-i)); 
   i=i+1; 
end; 

%** dummy observation

lnpY0 = -nv*(n_dummy-k)*0.5*log(pi)-(nv/2)*log(abs(det(XXdum'*XXdum)))-(n_dummy-k)*0.5*log(abs(det(S0)))+nv*(nv-1)*0.25*log(pi)+gam0;

%** dummy and actual observations
   
lnpY1 = -nv*(n_total-k)*0.5*log(pi)-(nv/2)*log(abs(det(XX'*XX)))-(n_total-k)*0.5*log(abs(det(S1)))+nv*(nv-1)*0.25*log(pi)+gam1;  

lnpYY = -(lnpY1-lnpY0); % the 'minus is because we minimize the function

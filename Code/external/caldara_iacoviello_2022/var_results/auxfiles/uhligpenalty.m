function [mufactor fflag] = uhligpenalty(P,B,s,R,nper,nshock)

% Christophe Kamps, September 2011.
% Edited by Dario Caldara February 2013
% This function solves for the factor matrix for the penalty function
% approach introduced by H. Uhlig (JME 2005) and extended to a multi-shock
% setting by A. Mountford and H. Uhlig (JAE 2009).
%
% Inputs:   P:      Cholesky decomposition of VCV matrix of reduced-form 
%                   residuals.
%           B:      VAR(1) representation (see Hamilton (1994), p. 259). 
%                   The first 'nvar' rows hold the matrices of autoregressive
%                   coefficients [B1, B2, ..., Bp], where p is the lag order 
%                   of the VAR.
%           s:      Vector holding the standard deviations of reduced-form
%                   residuals.
%           R:      matrix holding the sign restrictions (columns = shocks; 
%                   rows = IRFs restricted). 
%                    0  IRF is not restricted.
%                    1  IRF is restricted to be positive.
%                   -1  IRF is restricted to be negative.
%           nper:   Number of periods for which sign restrictions hold.
%           nshock: Number of shocks to be computed.
%
% Output:   mufactor:   Factor matrix for the penalty function approach to
%                       sign restrictions

nvar = size(P,1);

% Computing VMA representation for number of restricted periods
VMA = cat(nper);
VMA(:,:,1) = eye(nvar);
if nper > 1
   for i = 2:nper
       temp = B^(i-1);
       VMA(:,:,i) = temp(1:nvar,1:nvar);
   end
end

% Computing the sign-restriction factor matrix

theta = diag(linspace(pi/2,pi/2,nvar));
mufactor = P;
IRFsr = cat(nper);
IRFtemp = cat(nper);
f = zeros(nvar,nshock);
fflag = 0; % Modified by Dario Caldara 09.12.2012. Flag whether SR are satisfied
           % instead of blocking the code with error message.

for k = 1:nshock
    sbar = R(:,k)./s; % scaling the IRFs to be restricted
    for i = 1:nper
        IRFsr(:,:,i) = VMA(:,:,i)*mufactor;
        f(:,k) = f(:,k) + IRFsr(:,:,i)'*sbar;
    end

    for i = k+1:nvar
        if f(i-1,k)==0
            theta(k,i)=0;
        else
            theta(k,i)=atan(sin(theta(k,i-1))*f(i,k)/f(i-1,k));
        end
        for j = 1:nvar
            tau1 = mufactor(j,k);
            tau2 = mufactor(j,i);
            mufactor(j,k) = tau1*cos(theta(k,i))+tau2*sin(theta(k,i));
            mufactor(j,i) = -tau1*sin(theta(k,i))+tau2*cos(theta(k,i));
        end
    end
    
    for i = 1:nper % Added by Dario Caldara 09.12.2012 to recompute the IRFS with new mufactor
        IRFtemp(:,:,i) = VMA(:,:,i)*mufactor;
    end
    
%         if sign(R(:,k))==sign(abs(sign(R(:,k))).*mufactor(:,k))
%         Modified by Dario Caldara 09.12.2012, check SR at horizons 1:nper
    if sign(repmat(R(:,k),1,nper))==sign(abs(sign(repmat(R(:,k),1,nper))).*squeeze(IRFtemp(:,k,:)))
%         fprintf('Shock %1.0f: All sign restrictions are satisfied.\n', k);
        fflag = 1;
%         elseif sign(R(:,k))==sign(abs(sign(R(:,k))).*-mufactor(:,k))
%         Modified by Dario Caldara 09.12.2012, check SR at horizons 1:nper
    elseif sign(repmat(R(:,k),1,nper))==sign(abs(sign(repmat(R(:,k),1,nper))).*squeeze(-IRFtemp(:,k,:)))
        mufactor(:,k) = -mufactor(:,k);
%         fprintf('Shock %1.0f: All sign restrictions are satisfied, sign was flipped.\n', k);
        fflag = 1;
    else
%       disp(mufactor);
        fflag = 0;
        break
%         error('The sign restrictions are not satisfied.')
    end
end
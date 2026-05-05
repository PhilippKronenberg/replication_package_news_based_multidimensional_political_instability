function lng = lngam(x)

% PURPOSE: compute the log-gamma function
% -----------------------------------------------------
% USAGE: lng = lngam(x)
% where  x = input scalar
% -----------------------------------------------------
% RETURNS: lng = log-gamma function of x
% -----------------------------------------------------
% NOTE: a Gauss compatability function
%       This function is called by vm_mdd
% -----------------------------------------------------
             
if x <= 3
   lng= log(gamma(x));
else
   k = floor(x-2);
   lng= sumc(log(seqa(x-1,-1,k))) + log(gamma(x-k));
end

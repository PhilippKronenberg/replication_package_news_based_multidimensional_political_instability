%Decomp routine for use with smooth history simple
%	REMEMBER THAT WE ARE USING THAT DAMN KOOPMANS TIMING CONVENTION

function results = decomp_smooth_dario(s_var,model)

G = model.G;
impact = model.struct_eps.shockmat;
nshock = size(impact,2);
% a_smooth = s_var.a_tT;
% n_var0 = size(a_smooth,1);
smooth_err = s_var.eps_tT;
n_var0 = size(s_var.a0,1);
% nobs0 = size(a_smooth,2);
nobs0 = size(s_var.eps_tT,2);


smooth_decomp = zeros(n_var0,nobs0,nshock);
smooth_init = s_var.a0;

for k = 2:nobs0+1;
    smooth_init(:,k) = G*smooth_init(:,k-1);
end;

eps_decomp = zeros(n_var0,nshock,nobs0);
decomp_t = zeros(n_var0,nshock);
for t = 1:nobs0
    decomp_t = G*decomp_t + impact*diag(smooth_err(:,t));
    eps_decomp(:,:,t) = decomp_t;
end

% results.smooth_decomp =
% permute(cat(3,zeros(n_var0,nshock,1),eps_decomp(:,:,1:(end-1))), [1,3,2]);
results.smooth_decomp = permute(eps_decomp, [1,3,2]);
results.smooth_init = smooth_init;



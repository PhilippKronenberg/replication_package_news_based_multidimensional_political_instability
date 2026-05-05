%=========================================================================
%               HISTORICAL DECOMPOSITION
%=========================================================================
model.G = Fols;
model.struct_eps.shockmat = [mufactorOLS;zeros((nlags_-1)*nv,size(mufactorOLS,2))];
s_var.eps_tT = epsHis;
s_var.a0 = s0;
results = decomp_smooth(s_var,model);
smooth_decomp = results.smooth_decomp;
smooth_init = results.smooth_init;

%=========================================================================
%               PLOT RESULTS
%=========================================================================

i_var_str_names_hist =  {'UNC','EBP','TREAS02Y','TREAS10Y','IPM','EMPL','PCE','PPCE','LMRET','GSCI'};
                    
x = permute(smooth_decomp,[2 3 1]);
xlevel = zeros(size(x));

for j = 5:10
    for i = 1:10
        xlevel(:,i,j) = cumsum(squeeze(x(:,i,j)));
    end
end

x_change12 = zeros(size(x));
x_change12(13:end,:,:) = xlevel(13:end,:,:) - xlevel(1:end-12,:,:);

xplot = x(:,1:2,:);
xplot(:,:,5:10) = x_change12(:,1:2,5:10);
xplot_annual = xplot(24:12:end,:,:);

hist_decomp = xplot(:,:,1:10);
hist_decomp_annual = xplot_annual(:,:,1:10);

actual_series = zeros(size(YYact));
actual_serieslevel = zeros(size(YYact));
for j = 5:10
    actual_serieslevel(:,j) = cumsum(YYact(:,j));
end

actual_series12 = zeros(size(YYact));
actual_series12(13:end,:) = actual_serieslevel(13:end,:) - actual_serieslevel(1:end-12,:);

actual_series(:,1:4) = YYact(:,1:4) - repmat(mean(YYact(:,1:4)),size(YYact,1),1);
actual_series(:,5:10) = actual_series12(:,5:10);

actual_series_annual = actual_series(24:12:end,:);

save(strcat('./results/Hist_',char(mmodel),'_iden_',num2str(identification),'.mat'),...
        'hist_decomp','hist_decomp_annual','actual_series','actual_series_annual');    

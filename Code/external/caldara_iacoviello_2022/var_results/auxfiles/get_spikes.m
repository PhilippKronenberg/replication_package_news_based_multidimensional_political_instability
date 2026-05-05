% input : year,  variable, news

% output: year_spike, news_spike, variable_spike, 

function [spikes_GPR, DGPR_just_spikes, iS, nS, nT ] = get_spikes(GPR,cut_off,iplus)


d_GPR_plus=max(diff1(GPR),0);

if iplus==1
XX1 = [ GPR.^0 lag(GPR,1) lag(d_GPR_plus,1)  ];
else
XX1 = [ GPR.^0 lag(GPR,1) ];
end

[B1,BINT1,GPR_resid,RINT1,STATS1] = regress(GPR,XX1);

se = nanstd(GPR_resid);

z1 = diff1(GPR);
z1(GPR_resid<cut_off*se)=0;
z1(z1<0)=0;
z1(isnan(GPR_resid))=0;
for t=7:numel(z1)
    if z1(t)<max(z1(t-6:t-1))
        z1(t)=0;
    end
end
[iS,~]=find(z1>0);
nS = numel(iS);
nT = numel(GPR);

spikes_GPR = GPR(iS);
% episodes_GPR = episodes(iS);
% year_GPR = year(iS);
DGPR_just_spikes = z1;

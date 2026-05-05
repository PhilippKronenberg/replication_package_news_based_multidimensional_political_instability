% 
% 
% %*************************
% % Model-specific settings/
% %*************************
% 
% nshocks=2;       % Number of shocks to identify
% nex = 1;          % Deterministic terms (1: constant)
% 
% %str_sample_init = '1986-03-01';
% %str_sample_end  = '2019-12-01';
% 
% %str_sample_init = '2012-04-01';
% %str_sample_end  = '2024-04-01';
% 
% %str_sample_init = '1994-01-01';
% %str_sample_end  = '2024-01-01';
% 
%     % Flexible sample start from first available date
%     str_sample_init = datestr(dt(1), 'yyyy-mm-dd');
% 
%     % Optional: Set end date as last date in data
%     str_sample_end = datestr(dt(end), 'yyyy-mm-dd');
% 
% if strcmp(mmodel,'GPRBASELINE') || strcmp(mmodel,'GPRLAGS')
%     %i_var_str = {'NBS Indicator','Exchange Rate', 'CPI','Interest Rate','Nighttime Light'}; %  
% 
%     if strcmp(mode,'annual')
%         i_var_str = {'Political Violence','Exchange Rate', 'CPI','Interest Rate','GDP'};  
%     elseif strcmp(mode, 'quarterly')
%         i_var_str = {'Political Violence','Exchange Rate', 'CPI','Interest Rate','GDP'};  
%     elseif strcmp(mode, 'monthly')
%         i_var_str = {'Political Violence','Exchange Rate', 'CPI','Interest Rate','Nighttime Light'}; 
% 
%     end
% 
% 
% 
% %if strcmp(mmodel,'GPRBASELINE') || strcmp(mmodel,'GPRLAGS')
% %    i_var_str = {'LGPR','SPVXO','LUS_INV_PC','LUS_HOURS_PC'...
% %        ,'LUS_SP500','LUS_OIL_WTI','FCM2','NFCI'}; %  
% % elseif strcmp(mmodel,'GPREPU')
% %     i_var_str = {'LGPR','LEPU','LUS_INV_PC','LUS_HOURS_PC'...
% %         ,'LUS_SP500','FCM2','LUS_OIL_WTI','NFCI'};
% % elseif strcmp(mmodel,'GPRSPIKES')
% %     i_var_str = {'GPR_SPIKES','SPVXO','LUS_INV_PC','LUS_HOURS_PC'...
% %             ,'LUS_SP500','FCM2','LUS_OIL_WTI','NFCI'};
% % elseif strcmp(mmodel,'GPRSMALL_INV')
% %     i_var_str = {'LGPR','LUS_INV_PC','FCM2','NFCI'};
% % elseif strcmp(mmodel,'GPRSMALL_HOURS')
% %     i_var_str = {'LGPR','LUS_HOURS_PC','FCM2','NFCI'};
% % elseif strcmp(mmodel,'GPRALTCHOL')
% %     i_var_str = {'SPVXO','LUS_SP500','FCM2','LUS_OIL_WTI','LGPR','NFCI'...
% %             ,'LUS_INV_PC','LUS_HOURS_PC'};
% % elseif strcmp(mmodel,'GPRALTCHOL2')
% %     i_var_str = {'SPVXO','LUS_SP500','FCM2','LUS_OIL_WTI','NFCI'...
% %         ,'LUS_INV_PC','LUS_HOURS_PC','LGPR'};
% % elseif strcmp(mmodel,'GPRGDP')
% %     i_var_str = {'LGPR','SPVXO','LUS_INV_PC','LUS_HOURS_PC'...
% %             ,'LUS_SP500','LUS_GDP_PC','FCM2','LUS_OIL_WTI','NFCI'};
% end
% 
% i_var_str_names = i_var_str;
% 
% vm_loaddata




%==============================
% Model Specification (VARX)
%==============================

nshocks = 2;
nex = 1;  % constant
str_sample_init = datestr(dt(1), 'yyyy-mm-dd');
str_sample_end  = datestr(dt(end), 'yyyy-mm-dd');

% % Define endogenous and exogenous variables
% if strcmp(mmodel,'GPRBASELINE') || strcmp(mmodel,'GPRLAGS')
%     if strcmp(mode,'annual') || strcmp(mode,'quarterly')
%         endo_vars = [variable,{'CPI','GDP'}];
%         exog_vars = {'Exchange Rate','Interest Rate'};
%     elseif strcmp(mode,'monthly')
%         endo_vars = [variable,{'CPI','Nighttime Light'}];
%         exog_vars = {'Exchange Rate','Interest Rate'};
%     end
% end


non_independent_monetary_countries = {
    'Benin','Burkina_Faso','Cote_d_Ivoire','Guinea_Bissau','Mali','Niger','Senegal','Togo', ...
    'Cameroon','Central_African_Republic','Chad','Equatorial_Guinea','Gabon'
};
cnt_GDP = {'Benin','Burkina_Faso','Cote_d_Ivoire','Ghana','Guinea_Bissau','Mali','Niger','Nigeria','Senegal','Togo','Ghana', 'Nigeria','Senegal'};
cnt_NL = {'Cameroon','Central_African_Republic','Chad', 'Democratic_Republic_of_the_Congo','Equatorial_Guinea','Gabon', 'Mauritania'};

%cnt_NAC = {'Ghana', 'Nigeria','Senegal'};

% Check if current country is in the monetary union
is_in_monetary_union = any(strcmp(country, non_independent_monetary_countries));

% Set endogenous and exogenous variables based on mode and country
if strcmp(mode,'annual')
    full_var_order = [variable, {'Exchange Rate', 'CPI', 'Interest Rate', 'GDP'}];

elseif strcmp(mode, 'quarterly')
    if ismember(country, cnt_NL)
        full_var_order = [variable, {'CPI', 'Interest Rate', 'Nighttime Light'}];
        %full_var_order = [variable, {'Exchange Rate', 'CPI', 'Interest Rate', 'Nighttime Light'}];
    elseif ismember(country, cnt_GDP)
        full_var_order = [variable, {'CPI', 'Interest Rate', 'GDP'}];
        %full_var_order = [variable, {'Exchange Rate', 'CPI', 'Interest Rate', 'GDP'}];
    end

    % if ismember(country, cnt_NAC)
    %     %full_var_order = [full_var_order(1:end-1), {'Exports'}, full_var_order(end)];
    %         %,-`Final consumption expenditure, General government`, -`Final consumption expenditure, Private sector`, -`Gross fixed capital formation`, -`Imports of goods and services`
    % end

elseif strcmp(mode,'monthly')
    full_var_order = [variable, {'Exchange Rate', 'Commodity Price Index', 'CPI', 'Interest Rate', 'Nighttime Light'}];
end

if strcmp(country, 'Equatorial_Guinea')
   full_var_order = setdiff(full_var_order, 'Commodity Price Index', 'stable');
end

% Assign endogenous and exogenous variables based on monetary policy
if ismember(country, non_independent_monetary_countries)
    % Country has no independent monetary policy
    exog_vars = {'Exchange Rate', 'Commodity Price Index', 'Interest Rate'};
    %exog_vars = {'Exchange Rate', 'Interest Rate'};
    if strcmp(country, 'Equatorial_Guinea')
    exog_vars = {'Exchange Rate', 'Interest Rate'};
    end
    endo_vars = setdiff(full_var_order, exog_vars, 'stable');

else
    % Country has independent monetary policy
    %exog_vars = {};
    exog_vars = {'Commodity Price Index'};
    endo_vars = setdiff(full_var_order, exog_vars, 'stable');

end

i_var_str = [endo_vars, exog_vars];
i_var_str_names = i_var_str;

vm_loaddata
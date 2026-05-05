% text = textdata;
% %***********************************************/
% % RETRIEVE POSITIONS OF VARIABLES IN THE DATASET/
% %***********************************************/
% 
% %[~,i_var]    = ismember(i_var_str,text(1,2:end));
% headers = strrep(text(1,2:end),'"','');   % remove " from each string
% [~, i_var] = ismember(i_var_str, headers);
% 
% 
% %************************************************/
% % RETRIEVE POSITION OF FIRST AND LAST OBSERVATION/
% %************************************************/
% 
% sample_init = datenum(str_sample_init, 'yyyy-mm-dd');
% sample_end = datenum(str_sample_end, 'yyyy-mm-dd');
% 
% [~, sample_init_row] = ismember(sample_init,nDate,'rows');
% [~, sample_end_row] = ismember(sample_end,nDate);
% 
% %****************************************************/
% % SELECT APPROPRIATE ROWS AND COLUMNS OF DATA MATRIX /
% %****************************************************/
% YY = YYdata(sample_init_row:sample_end_row,i_var);
% 
% if strcmp(mmodel,'GPRSPIKES')
%    YY(YY(:,1)~=0,1) = log(YY(YY(:,1)~=0,1));
% end







%==============================
% Load Data for VARX
%==============================

text = textdata;
headers = strrep(textdata(1,2:end),'"','');

used_vars = [endo_vars, exog_vars];
[~, var_indices] = ismember(used_vars, headers);
Y_raw = data(:, var_indices);

sample_init = datenum(str_sample_init, 'yyyy-mm-dd');
sample_end = datenum(str_sample_end, 'yyyy-mm-dd');

[~, sample_init_row] = ismember(sample_init,nDate,'rows');
[~, sample_end_row] = ismember(sample_end,nDate);

YY = Y_raw(sample_init_row:sample_end_row,:);

% Extract endogenous and exogenous separately
n_endo = length(endo_vars);
YY_endo = YY(:,1:n_endo);
YY_exog = YY(:,n_endo+1:end);

if strcmp(mmodel,'GPRSPIKES')
   YY_endo(YY_endo(:,1)~=0,1) = log(YY_endo(YY_endo(:,1)~=0,1));
end
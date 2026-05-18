% MODEL_SPEC
% DRC-only monthly VAR specification used in the package IRF workflow.

nshocks = 2;
str_sample_init = datestr(dt(1), 'yyyy-mm-dd');
str_sample_end = datestr(dt(end), 'yyyy-mm-dd');

if ~strcmp(mode, 'monthly')
    error('This package MATLAB workflow only supports monthly mode.');
end

if ~strcmp(country, 'Democratic_Republic_of_the_Congo')
    error('This package MATLAB workflow only supports Democratic_Republic_of_the_Congo.');
end

full_var_order = { ...
    variable, ...
    'Exchange Rate', ...
    'Commodity Price Index', ...
    'CPI', ...
    'Interest Rate', ...
    'Nighttime Light' ...
};

switch spec_name
    case 'GPRBASELINE'
        exog_vars = {'Commodity Price Index'};
    case 'GPRBASELINE_ENDO_COM'
        exog_vars = {};
    case 'GPRBASELINE_NO_COM'
        full_var_order = setdiff(full_var_order, 'Commodity Price Index', 'stable');
        exog_vars = {};
    otherwise
        error('Unsupported specification: %s', spec_name);
end

endo_vars = setdiff(full_var_order, exog_vars, 'stable');
i_var_str = [endo_vars, exog_vars];
i_var_str_names = i_var_str;

vm_loaddata

% RUN_VAR_ESTIMATION
% Estimates the monthly DRC VAR for the baseline and two robustness
% specifications used in the package IRF figures.

tic;
clearvars -except packageRoot;
close all;
clc;

scriptDir = fileparts(mfilename('fullpath'));
auxDir = fullfile(scriptDir, 'auxfiles');
addpath(scriptDir);
addpath(auxDir);

if ~exist('packageRoot', 'var')
    packageRoot = fullfile(scriptDir, '..', '..', '..', '..');
end

mode = 'monthly';
country_vec = {'Democratic_Republic_of_the_Congo'};
variables = {'Political Violence', 'Mass Civil Protest', 'Instability within Regime', 'Instability of Regime'};

specs = {
    struct('name', 'GPRBASELINE', 'resultTag', 'GPRBASELINE', 'cacheTag', 'base'), ...
    struct('name', 'GPRBASELINE_ENDO_COM', 'resultTag', 'GPRBASELINE_endo_com', 'cacheTag', 'endo'), ...
    struct('name', 'GPRBASELINE_NO_COM', 'resultTag', 'GPRBASELINE_no_com', 'cacheTag', 'nocom')
};

minn_prior = 0;
T_hist = 0;
nd = 20000;
bburn = 0.2 * nd;
Horizon = 12;
ptileVEC = [5 16 50 84 95];

randn('state', 294015341);

for ss = 1:length(specs)
    spec = specs{ss};
    spec_name = spec.name;
    result_tag = spec.resultTag;
    cache_tag = spec.cacheTag;

    for vv = 1:length(variables)
        variable = variables{vv};
        variable_tag = local_variable_tag(variable);
        outputFolder = fullfile(scriptDir, ['estimate_' mode], cache_tag, variable_tag);

        if ~exist(outputFolder, 'dir')
            mkdir(outputFolder);
        end

        for c = 1:length(country_vec)
            country = country_vec{c};
            country_tag = local_country_tag(country);
            mmodel = spec_name;

            disp(['Processing specification: ', result_tag]);
            disp(['Processing country: ', country]);

            dataPath = fullfile(packageRoot, 'Data', 'Raw', 'public', 'VAR');
            filename = fullfile(dataPath, mode, [country, '.csv']);
            newData = importdata(filename);

            fields = fieldnames(newData);
            for i = 1:length(fields)
                assignin('base', fields{i}, newData.(fields{i}));
            end

            YYdata = data;
            rawDates = textdata(2:end, 1);
            dt = datetime(rawDates, 'InputFormat', 'yyyy.MM.dd');
            nDate = datenum(dt);

            p = 2;
            T0 = 2;

            model_spec
            n = length(endo_vars);

            vm_loaddata
            vm_dummy

            if minn_prior == 0
                X = XXact;
                Y = YYact;
                T = nobs;
            else
                X = [XXact; XXdum];
                Y = [YYact; YYdum];
                T = nobs + Tdummy;
            end

            J = [eye(n); repmat(zeros(n), p - 1, 1)];
            F = zeros(n * p, n * p);
            I = eye(n);

            for i = 1:p - 1
                F(i * n + 1:(i + 1) * n, (i - 1) * n + 1:i * n) = I;
            end

            B = (X' * X) \ (X' * Y);
            U = Y - X * B;
            Sigmau = U' * U / (T - p * n - 1);

            LC = chol(Sigmau)';
            Omega1 = [LC; zeros((p - 1) * n, size(LC, 2))];
            F(1:n, 1:n * p) = B(1:n * p, :)';

            Ltilde = zeros(nd - bburn, Horizon + 1, n, nshocks);
            epsHistilde = zeros(nd - bburn, T, n);
            m = size(B, 1);

            if minn_prior == 0
                N0 = zeros(m, m);
                nnu0 = 0;
                nnuT = T + nnu0;
                NT = N0 + X' * X;
                Bbar0 = B;
                S0 = Sigmau;
                BbarT = NT \ (N0 * Bbar0 + (X' * X) * B);
                ST = (nnu0 / nnuT) * S0 ...
                    + (T / nnuT) * Sigmau ...
                    + (1 / nnuT) * (B - Bbar0)' * N0 * (NT \ (X' * X)) * (B - Bbar0);
                STinv = ST \ eye(n);
                R = zeros(n, nnuT);
            end

            record = 0;
            counter = 0;

            while record < nd
                if minn_prior == 1
                    Sigmadraw = iwishrnd(Sigmau * (T - n * p - 1), T - n * p - 1);
                    B_new = mvnrnd(reshape(B, m * n, 1), kron(Sigmadraw, inv(X' * X)));
                    Bdraw = reshape(B_new, m, n);
                else
                    R = mvnrnd(zeros(n, 1), STinv / nnuT, nnuT)';
                    Sigmadraw = (R * R') \ eye(n);
                    bbeta = B(:);
                    SigmaB = kron(Sigmadraw, NT \ eye(m));
                    SigmaB = (SigmaB + SigmaB') / 2;
                    Bdraw = mvnrnd(bbeta, SigmaB);
                    Bdraw = reshape(Bdraw, m, n);
                end

                LC = chol(Sigmadraw, 'lower');
                F(1:n, 1:n * p) = Bdraw(1:n * p, :)';

                record = record + 1;
                counter = counter + 1;

                if counter == 0.2 * nd
                    disp(['         DRAW NUMBER:   ', num2str(record)]);
                    counter = 0;
                end

                if record > bburn
                    Utildedraw = YYact - XXact * Bdraw;
                    epsHisdraw = LC \ Utildedraw';
                    epsHisdraw = epsHisdraw(:, T_hist + 1:end);

                    epsHistilde(record - bburn, :, :) = epsHisdraw';

                    IRF_T = vm_irf(F, J, LC, Horizon + 1, n, Omega1);
                    IRF_T = IRF_T(:, :, 1:nshocks);

                    Ltilde(record - bburn, :, :, :) = IRF_T;
                end
            end

            LtildeFull = prctile(Ltilde, ptileVEC);
            VAR.LtildeFull = permute(LtildeFull, [3, 2, 1, 4]);
            VAR.epsHistildeFull = prctile(epsHistilde, ptileVEC);
            VAR.i_var_str_names = i_var_str_names;
            VAR.spec_name = spec_name;
            VAR.result_tag = result_tag;
            VAR.cache_tag = cache_tag;
            VAR.country_tag = country_tag;
            VAR.variable_tag = variable_tag;

            save(fullfile(outputFolder, ['res_' country_tag '_' cache_tag '.mat']), 'VAR');
        end
    end
end

toc;

function variable_tag = local_variable_tag(variable)
switch variable
    case 'Political Violence'
        variable_tag = 'pv';
    case 'Mass Civil Protest'
        variable_tag = 'mcp';
    case 'Instability within Regime'
        variable_tag = 'iwr';
    case 'Instability of Regime'
        variable_tag = 'ior';
    otherwise
        error('Unsupported variable: %s', variable);
end
end

function country_tag = local_country_tag(country)
switch country
    case 'Democratic_Republic_of_the_Congo'
        country_tag = 'drc';
    otherwise
        error('Unsupported country: %s', country);
end
end

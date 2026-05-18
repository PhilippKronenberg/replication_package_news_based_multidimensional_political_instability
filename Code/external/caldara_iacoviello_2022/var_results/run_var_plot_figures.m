% RUN_VAR_PLOT_FIGURES
% Builds the package IRF figures for the baseline and two robustness
% specifications from the stored monthly VAR estimates, using the
% original rendering path and styling from the archived workflow.

clearvars -except packageRoot;
close all;

scriptDir = fileparts(mfilename('fullpath'));
addpath(scriptDir);
addpath(fullfile(scriptDir, 'auxfiles'));

if ~exist('packageRoot', 'var')
    packageRoot = fullfile(scriptDir, '..', '..', '..', '..');
end

mode = 'monthly';
variables = {'Political Violence', 'Mass Civil Protest', 'Instability within Regime', 'Instability of Regime'};
country_vec = {'Democratic_Republic_of_the_Congo'};

specs = {
    struct('resultTag', 'GPRBASELINE', 'cacheTag', 'base', 'targetDir', fullfile(packageRoot, 'Outputs', 'Main', 'Figures'), 'targetName', 'IRF_%s_GPRBASELINE.png'), ...
    struct('resultTag', 'GPRBASELINE_endo_com', 'cacheTag', 'endo', 'targetDir', fullfile(packageRoot, 'Outputs', 'Annex', 'Figures'), 'targetName', 'IRF_%s_GPRBASELINE_endo_com.png'), ...
    struct('resultTag', 'GPRBASELINE_no_com', 'cacheTag', 'nocom', 'targetDir', fullfile(packageRoot, 'Outputs', 'Annex', 'Figures'), 'targetName', 'IRF_%s_GPRBASELINE_no_com.png')
};

Horizon = 13;
H = Horizon - 1;
linW = 2;
% Use fully opaque, preblended colors so the exported PNG renders
% consistently across local viewers and the in-app preview.
outerBandAlpha = 1.0;
innerBandAlpha = 1.0;
outerBandColor = [0.88 0.90 1.00];
innerBandColor = [0.75 0.79 0.98];

for ss = 1:length(specs)
    spec = specs{ss};

    if ~exist(spec.targetDir, 'dir')
        mkdir(spec.targetDir);
    end

    for c = 1:length(country_vec)
        country = country_vec{c};
        fig = figure( ...
            'Name', ['IRF_' strrep(country, '_', ' ') '_' spec.resultTag], ...
            'NumberTitle', 'off', ...
            'Position', [100, 100, 300 * length(variables), 400 * length(variables)] ...
        );
        set(fig, 'Color', 'w');

        for vv = 1:length(variables)
            variable = variables{vv};
            variable_tag = local_variable_tag(variable);
            country_tag = local_country_tag(country);
            resultFile = fullfile( ...
                scriptDir, ...
                ['estimate_' mode], ...
                spec.cacheTag, ...
                variable_tag, ...
                ['res_' country_tag '_' spec.cacheTag '.mat'] ...
            );

            if ~exist(resultFile, 'file')
                warning('File not found: %s', resultFile);
                continue
            end

            disp(['Loading: ' resultFile]);
            result = load(resultFile);
            varnames = result.VAR.i_var_str_names;
            nvar = size(result.VAR.LtildeFull, 1);

            for ii = 1:nvar
                subidx = (vv - 1) * nvar + ii;
                subplot(length(variables), nvar, subidx);

                bandValues = squeeze(result.VAR.LtildeFull(ii, :, :, 1));
                yMin = min(bandValues(:));
                yMax = max(bandValues(:));
                yPad = max((yMax - yMin) * 0.05, 1e-6);

                hold on

                xVals = 0:1:H;
                draw_band_patch(xVals, squeeze(result.VAR.LtildeFull(ii, :, 1, 1)), squeeze(result.VAR.LtildeFull(ii, :, 2, 1)), outerBandColor, outerBandAlpha);
                draw_band_patch(xVals, squeeze(result.VAR.LtildeFull(ii, :, 2, 1)), squeeze(result.VAR.LtildeFull(ii, :, 3, 1)), innerBandColor, innerBandAlpha);
                draw_band_patch(xVals, squeeze(result.VAR.LtildeFull(ii, :, 3, 1)), squeeze(result.VAR.LtildeFull(ii, :, 4, 1)), innerBandColor, innerBandAlpha);
                draw_band_patch(xVals, squeeze(result.VAR.LtildeFull(ii, :, 4, 1)), squeeze(result.VAR.LtildeFull(ii, :, 5, 1)), outerBandColor, outerBandAlpha);

                plot(0:1:H, 0 * squeeze(result.VAR.LtildeFull(ii, :, 1, 1)), 'k', 'LineWidth', 0.75);
                plot(0:1:H, squeeze(result.VAR.LtildeFull(ii, :, 3, 1)), 'k', 'LineWidth', linW);
                set(gca, 'FontSize', 12);
                title(varnames{ii}, 'FontSize', 14);
                xlabel('Months', 'FontSize', 11);
                set(gca, 'XTick', 0:4:H);
                ylim([yMin - yPad, yMax + yPad]);
            end
        end

        sgtitle(['Impulse Responses to Political Instability Shock: ', strrep(country, '_', ' ')], 'FontSize', 16);

        filenameSafe = strrep(country, ' ', '_');
        outputFile = fullfile(spec.targetDir, sprintf(spec.targetName, filenameSafe));

        figure(fig);
        set(fig, 'Visible', 'on');
        drawnow;
        exportgraphics(fig, outputFile, 'Resolution', 300);

        disp(['Saved figure for: ' country ' (' spec.resultTag ')']);
        close(fig);
    end
end

function draw_band_patch(xVals, lowerBand, upperBand, fillColor, alphaVal)
patch( ...
    [xVals, fliplr(xVals)], ...
    [upperBand(:).', fliplr(lowerBand(:).')], ...
    fillColor, ...
    'EdgeColor', 'none', ...
    'FaceAlpha', alphaVal ...
);
end

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

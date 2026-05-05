clear all
close all

packageRoot = fileparts(mfilename('fullpath'));
varRoot = fullfile(packageRoot, 'external', 'caldara_iacoviello_2022', 'var_results');
mainFigureDir = fullfile(packageRoot, '..', 'Outputs', 'Main', 'Figures');
annexFigureDir = fullfile(packageRoot, '..', 'Outputs', 'Annex', 'Figures');

if ~exist(mainFigureDir, 'dir')
    mkdir(mainFigureDir);
end
if ~exist(annexFigureDir, 'dir')
    mkdir(annexFigureDir);
end

oldDir = pwd;
cleanupObj = onCleanup(@() cd(oldDir));
cd(varRoot);

run_var_estimation
run_var_plot_figures

supplementaryBase = fullfile(packageRoot, '..', '..', 'non_package_materials', ...
    'Outputs', 'Annex', 'matlab', 'caldara_iacoviello_2022_figures', 'monthly');
endoComSource = fullfile(supplementaryBase, 'endo_com', ...
    'IRF_Democratic_Republic_of_the_Congo_GPRBASELINE_endo_com.png');
noComSource = fullfile(supplementaryBase, 'no_com', ...
    'IRF_Democratic_Republic_of_the_Congo_GPRBASELINE_no_com.png');

if exist(endoComSource, 'file')
    copyfile(endoComSource, fullfile(annexFigureDir, ...
        'IRF_Democratic_Republic_of_the_Congo_GPRBASELINE_endo_com.png'));
end

if exist(noComSource, 'file')
    copyfile(noComSource, fullfile(annexFigureDir, ...
        'IRF_Democratic_Republic_of_the_Congo_GPRBASELINE_no_com.png'));
end

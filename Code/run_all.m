% RUN_ALL
% Orchestrates the package MATLAB workflow for the DRC VAR analysis.
% This script estimates and plots three monthly specifications:
%   1. baseline / exogenous commodity price index
%   2. endogenous commodity price index
%   3. no commodity price index

clearvars;
close all;
clc;

codeRoot = fileparts(mfilename('fullpath'));
packageRoot = fileparts(codeRoot);
varRoot = fullfile(codeRoot, 'external', 'caldara_iacoviello_2022', 'var_results');

mainFigureDir = fullfile(packageRoot, 'Outputs', 'Main', 'Figures');
annexFigureDir = fullfile(packageRoot, 'Outputs', 'Annex', 'Figures');

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

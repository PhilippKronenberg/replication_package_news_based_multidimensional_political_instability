clear all
close all

scriptDir = fileparts(mfilename('fullpath'));
packageRoot = fullfile(scriptDir, '..', '..', '..', '..');
addpath(scriptDir)

mode = 'monthly';
variables = {'Political Violence', 'Mass Civil Protest', 'Instability within Regime', 'Instability of Regime'};  % 


% Select variable by model
%MBASEvarselec = 6;
MBASEvarname  = {'Political Instability Shock'};
%MBASEvarname  = {'GPR Shock','GPA Shock','GPT Shock'};
MBASEylab     = {'(%)'};
MBASEylim     = [-5 2];

%varnames = {'political_violence','Exchange Rate', 'CPI','Interest Rate','Nighttime Light'};
%varlabels = {'political_violence','Exchange Rate', 'CPI','Interest Rate','Nighttime Light'};
%varnames = {'GPR','VIX','Private Fixed Investment','Hours','S&P 500','Oil Price','Two-Year Yield','NFCI Index'};
%varlabels = {'Percent','Index','Percent','Percent','Percent','Percent','Percentage Points','Index'};

%varnames = {'Political Violence','Exchange Rate', 'Inflation','Interest Rate','GDP growth'};
%varlabels = {'Political Violence','Exchange Rate', 'Inflation','Interest Rate','GDP growth'};


pprint = 0;
Horizon = 13;
H = Horizon -1;
linW = 2;
transp90 = 0.1;
transp68 = 0.2;

     if strcmp(mode,'annual')
     country_vec = {'Benin','Burkina_Faso','Cameroon','Central_African_Republic','Chad','Cote_d_Ivoire', 'Democratic_Republic_of_the_Congo', ...
     'Equatorial_Guinea','Gabon','Ghana', 'Guinea_Bissau', 'Mali', ... %,'Nigeria', 'Mauritania', % Too short data
     'Niger','Senegal','Togo'};

 elseif strcmp(mode, 'quarterly')
     country_vec = {'Benin','Burkina_Faso','Cote_d_Ivoire', 'Ghana', 'Guinea_Bissau', 'Mali', 'Niger', 'Senegal','Togo', 'Nigeria'}; % 

 elseif strcmp(mode, 'monthly')
     country_vec = {'Democratic_Republic_of_the_Congo'};
     end

nCountries = length(country_vec);
%nVars = length(varnames);


outDir = fullfile(packageRoot, 'Outputs', 'Main', 'Figures');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

% GPR              = load('Result_GPRBASELINE');
% GPRGDP           = load('Result_GPRGDP');
% GPREPU           = load('Result_GPREPU');
% GPRSPIKES        = load('Result_GPRSPIKES');
% GPRLAGS          = load('Result_GPRLAGS');
% GPRSMALL_INV     = load('Result_GPRSMALL_INV');
% GPRSMALL_HOURS   = load('Result_GPRSMALL_HOURS');
% GPRALTCHOL       = load('Result_GPRALTCHOL');
% GPRAT            = load('Result_GPRAT');



for c = 1:length(country_vec)
    country = country_vec{c};

    fig = figure('Name', ['IRF_' strrep(country, '_', ' ')], ...
             'NumberTitle', 'off', 'Position', [100, 100, 300 * length(variables), 400 * length(variables)]);  % Make it wider


for vv = 1:length(variables)
    variable = variables{vv};
%variable = {'Political Violence'}; % 'Mass Civil Protest', 'Instability within Regime"', 'Instability of Regime'

    result_filename = fullfile(scriptDir, ['estimate_' mode], variable, ['Result_' country '_GPRBASELINE.mat']);
    
    if exist(result_filename, 'file')
        disp(['Loading: ' result_filename])
        GPR = load(result_filename);
    else
        warning(['File not found: ' result_filename])
        continue
    end




varnames = GPR.VAR.i_var_str_names;
varlabels = varnames;  % Use same names for labels, or modify if needed
nVars = length(varnames);


nvar = size(GPR.VAR.LtildeFull,1);

GPR.VAR.LtildeFull(:,:,:,1) = GPR.VAR.LtildeFull(:,:,:,1);

% GPRGDP.VAR.LtildeFull(:,:,:,1) = 2*GPRGDP.VAR.LtildeFull(:,:,:,1);
% 
% GPRSPIKES.VAR.LtildeFull(:,:,:,1) = 2*GPRSPIKES.VAR.LtildeFull(:,:,:,1);
% GPRLAGS.VAR.LtildeFull(:,:,:,1) = 2*GPRLAGS.VAR.LtildeFull(:,:,:,1);
% GPREPU.VAR.LtildeFull(:,:,:,1) = 2*GPREPU.VAR.LtildeFull(:,:,:,1);
% 
% GPRSMALL_INV.VAR.LtildeFull(:,:,:,1) = 2*GPRSMALL_INV.VAR.LtildeFull(:,:,:,1);
% GPRSMALL_HOURS.VAR.LtildeFull(:,:,:,1) = 2*GPRSMALL_HOURS.VAR.LtildeFull(:,:,:,1);
% GPRSMALL = GPRSMALL_INV;
% GPRSMALL.VAR.LtildeFull(3,:,:,1) = GPRSMALL_HOURS.VAR.LtildeFull(2,:,:,1);
% 
% GPRALTCHOL.VAR.LtildeFull(:,:,:,1) = 2*GPRALTCHOL.VAR.LtildeFull(:,:,:,1);
% 
% GPRAT.VAR.LtildeFull = 2*GPRAT.VAR.LtildeFull;
% GPRAT.VAR.LtildeFullPE = 2*GPRAT.VAR.LtildeFullPE;

%ylimmatrix = [-5 50; -3 3; -4 3; -1.5 1; ...
%              -10 4; -15 10; -0.5 0.5; -0.2 0.2];
          


          
          
%-----------------------
% FIGURE 9: The Impact of Increased Geopolitical Risk
%-----------------------
          
          
%fig=figure('Name','Figure 9','NumberTitle','off');


for ii = 1:nvar
    subidx = (vv-1)*nvar + ii;
subplot(length(variables),nvar, subidx)

    plot(0:1:H,0*squeeze(GPR.VAR.LtildeFull(ii,:,1,1)),'k','LineWidth',0.5)
    hold on
    a = squeeze(GPR.VAR.LtildeFull(ii,:,1,1));
    b = squeeze(GPR.VAR.LtildeFull(ii,:,2,1));
    [~,~]=jbfill(0:1:H,a,b,'b','none',1,transp90);
    a = squeeze(GPR.VAR.LtildeFull(ii,:,2,1));
    b = squeeze(GPR.VAR.LtildeFull(ii,:,3,1));
    [~,~]=jbfill(0:1:H,a,b,'b','none',1,transp68);
    a = squeeze(GPR.VAR.LtildeFull(ii,:,3,1));
    b = squeeze(GPR.VAR.LtildeFull(ii,:,4,1));
    [~,~]=jbfill(0:1:H,a,b,'b','none',1,transp68);
    a = squeeze(GPR.VAR.LtildeFull(ii,:,4,1));
    b = squeeze(GPR.VAR.LtildeFull(ii,:,5,1));
    [~,~]=jbfill(0:1:H,a,b,'b','none',1,transp90);
    hold on
    plot(0:1:H,squeeze(squeeze(GPR.VAR.LtildeFull(ii,:,3,1))),'k','LineWidth',linW)
    set(gca,'FontSize',12)
    title(varnames{ii},'FontSize',14)
    % if ii == 1
    %     ylabel(varlabels{vv},'FontSize',11)
    % end
    if strcmp(mode,'annual')
        xlabel('Years','FontSize',11)
    elseif strcmp(mode,'quarterly')
        xlabel('Quarters','FontSize',11)
    elseif strcmp(mode,'monthly')
        xlabel('Months','FontSize',11)
    end
    
    set(gca,'XTick',0:4:H)
    %axis([0 12 ylimmatrix(ii,:)]) 
end

%figSize = [14,6];
%graph_extended
end
    % Add a super-title with the country name
    sgtitle(['Impulse Responses to Political Instability Shock: ', strrep(country, '_', ' ')], 'FontSize', 16)

filename_safe = strrep(country,' ','_');
output_file = fullfile(outDir, ['IRF_' filename_safe '_GPRBASELINE.png']);

% Ensure figure is visible and rendered
figure(fig);
set(fig, 'Visible', 'on');
drawnow;

% Save using exportgraphics (better rendering)
exportgraphics(fig, output_file, 'Resolution', 300);

disp(['✅ Displayed and saved figure for: ' country])

end





% 
% 
% %-----------------------
% % FIGURE 10(a): Impulse Responses to a GPA Shock
% %-----------------------
% 
% 
% varnamesAT = {'GPR Acts','GPR Threats','VIX','Private Fixed Investment','Hours','S&P 500','Two-Year Yield','Oil Price','NFCI Index'};
% varlabelsAT = {'Percent','Percent','Index','Percent','Percent','Percent','Percentage Points','Percent','Index'};
% 
% varsel = [1 2 4 5];
% ylimmatrixAT = [-10 70; -10 70; -4 3; -1.5 1];
% font_num = 14;
% 
% fig=figure('Name','Figure 10(a)','NumberTitle','off');
% 
% for ii = 1:4
% subplot(1,4,ii)
%     plot(0:1:H,0*squeeze(GPRAT.VAR.LtildeFull(varsel(ii),:,1,1)),'k','LineWidth',1)
%     hold on
%     a = squeeze(GPRAT.VAR.LtildeFull(varsel(ii),:,1,1));
%     b = squeeze(GPRAT.VAR.LtildeFull(varsel(ii),:,2,1));
%     [~,~]=jbfill(0:1:H,a,b,'b','none',1,transp90);
%     a = squeeze(GPRAT.VAR.LtildeFull(varsel(ii),:,2,1));
%     b = squeeze(GPRAT.VAR.LtildeFull(varsel(ii),:,3,1));
%     [~,~]=jbfill(0:1:H,a,b,'b','none',1,transp68);
%     a = squeeze(GPRAT.VAR.LtildeFull(varsel(ii),:,3,1));
%     b = squeeze(GPRAT.VAR.LtildeFull(varsel(ii),:,4,1));
%     [~,~]=jbfill(0:1:H,a,b,'b','none',1,transp68);
%     a = squeeze(GPRAT.VAR.LtildeFull(varsel(ii),:,4,1));
%     b = squeeze(GPRAT.VAR.LtildeFull(varsel(ii),:,5,1));
%     [~,~]=jbfill(0:1:H,a,b,'b','none',1,transp90);
%     hold on
%     h1 = plot(0:1:H,squeeze(squeeze(GPRAT.VAR.LtildeFull(varsel(ii),:,3,1))),'k','LineWidth',linW);
%     h2 = plot(0:1:H,squeeze(squeeze(GPRAT.VAR.LtildeFullPE(varsel(ii),:,3,1))),'r--','LineWidth',linW);
%     title(varnamesAT(varsel(ii)),'FontSize',15)
%     axis([0 12 ylimmatrixAT(ii,:)]) 
%     set(gca,'XTick',0:4:H)
% 
%     xlabel('Quarters','FontSize',14)
%     ylabel(varlabelsAT(ii),'FontSize',14)
%     set(gca,'FontSize',13)
% 
%     if ii == 1
%     legend([h1 h2],{'Act shock','Act w/ fixed threat'},'Location','NorthEast','box','off',...       
%         'FontSize',font_num-2)
%     end
% 
% end
% 
% figSize = [14,3];
% 
% graph_extended
% 
% 
% 
% 
% 
% %-----------------------
% % FIGURE 10(b): Impulse Responses to a GPT Shock
% %-----------------------
% 
% 
% fig=figure('Name','Figure 10(b)','NumberTitle','off');
% 
% for ii = 1:4
% subplot(1,4,ii)
%     plot(0:1:H,0*squeeze(GPRAT.VAR.LtildeFull(varsel(ii),:,1,2)),'k','LineWidth',1)
%     hold on
%     a = squeeze(GPRAT.VAR.LtildeFull(varsel(ii),:,1,2));
%     b = squeeze(GPRAT.VAR.LtildeFull(varsel(ii),:,2,2));
%     [~,~]=jbfill(0:1:H,a,b,'b','none',1,transp90);
%     a = squeeze(GPRAT.VAR.LtildeFull(varsel(ii),:,2,2));
%     b = squeeze(GPRAT.VAR.LtildeFull(varsel(ii),:,3,2));
%     [~,~]=jbfill(0:1:H,a,b,'b','none',1,transp68);
%     a = squeeze(GPRAT.VAR.LtildeFull(varsel(ii),:,3,2));
%     b = squeeze(GPRAT.VAR.LtildeFull(varsel(ii),:,4,2));
%     [~,~]=jbfill(0:1:H,a,b,'b','none',1,transp68);
%     a = squeeze(GPRAT.VAR.LtildeFull(varsel(ii),:,4,2));
%     b = squeeze(GPRAT.VAR.LtildeFull(varsel(ii),:,5,2));
%     [~,~]=jbfill(0:1:H,a,b,'b','none',1,transp90);
%     hold on
%     h1 = plot(0:1:H,squeeze(squeeze(GPRAT.VAR.LtildeFull(varsel(ii),:,3,2))),'k','LineWidth',linW);
%     h2 = plot(0:1:H,squeeze(squeeze(GPRAT.VAR.LtildeFullPE(varsel(ii),:,3,2))),'r--','LineWidth',linW);
%     title(varnamesAT(varsel(ii)),'FontSize',15)
%     axis([0 12 ylimmatrixAT(ii,:)])
%     set(gca,'XTick',0:4:H)
% 
%     xlabel('Quarters','FontSize',12)
%     ylabel(varlabelsAT(ii),'FontSize',12)
%     set(gca,'FontSize',13)
% 
%     if ii == 1
%     legend([h1 h2],{'Threat shock','Threat w/ fixed acts'},'Location','NorthEast','box','off',...
%         'FontSize',font_num-2)
%     end
% end
% 
% figSize = [14,3];
% graph_extended
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% %-----------------------
% % FIGURE A.5: Impact of Increased Geopolitical Risk : Robustness
% %-----------------------
% 
% 
% varsel = [3 4];
% varselsmall = [2 3];
% varselalt = [7 8];
% varselalt2 = [6 7];
% 
% fig=figure('Name','Figure A.5','NumberTitle','off');
% 
% for ii = 1:2
% subplot(1,2,ii)
%     plot(0:1:H,0*squeeze(GPR.VAR.LtildeFull(varsel(ii),:,1,1)),'k','LineWidth',1)
%     hold on
%     a = squeeze(GPR.VAR.LtildeFull(varsel(ii),:,1,1));
%     b = squeeze(GPR.VAR.LtildeFull(varsel(ii),:,2,1));
%     [~,~]=jbfill(0:1:H,a,b,'b','none',1,transp90);
%     a = squeeze(GPR.VAR.LtildeFull(varsel(ii),:,2,1));
%     b = squeeze(GPR.VAR.LtildeFull(varsel(ii),:,3,1));
%     [~,~]=jbfill(0:1:H,a,b,'b','none',1,transp68);
%     a = squeeze(GPR.VAR.LtildeFull(varsel(ii),:,3,1));
%     b = squeeze(GPR.VAR.LtildeFull(varsel(ii),:,4,1));
%     [~,~]=jbfill(0:1:H,a,b,'b','none',1,transp68);
%     a = squeeze(GPR.VAR.LtildeFull(varsel(ii),:,4,1));
%     b = squeeze(GPR.VAR.LtildeFull(varsel(ii),:,5,1));
%     [~,~]=jbfill(0:1:H,a,b,'b','none',1,transp90);
%     hold on
%     h1 = plot(0:1:H,squeeze(squeeze(GPR.VAR.LtildeFull(varsel(ii),:,3,1))),'k','LineWidth',linW);
%     h2 = plot(0:1:H,squeeze(squeeze(GPRSPIKES.VAR.LtildeFull(varsel(ii),:,3,1))),'r--','LineWidth',linW);
%     h3 = plot(0:1:H,squeeze(squeeze(GPRLAGS.VAR.LtildeFull(varsel(ii),:,3,1))),'b-o','LineWidth',linW);
%     h4 = plot(0:1:H,squeeze(squeeze(GPRSMALL.VAR.LtildeFull(varselsmall(ii),:,3,1))),'g-+','LineWidth',linW);
%     h5 = plot(0:1:H,squeeze(squeeze(GPRALTCHOL.VAR.LtildeFull(varselalt(ii),:,3,1))),'m-.','LineWidth',linW);
%     h6 = plot(0:1:H,squeeze(squeeze(GPREPU.VAR.LtildeFull(varsel(ii),:,3,1))),'c-d','LineWidth',linW);
%     set(gca,'FontSize',13)
%     title(varnames(varsel(ii)),'FontSize',20)
%     if ii == 1
%     legend([h1 h2 h3 h4 h5 h6 ],...
%         {'Baseline','Jumps','4 Lags','Small','GPR after Fin.Var.','VAR w/ EPU'},...
%         'Location','NorthWest','box','off',...
%         'FontSize',13,'NumColumns',2)
%     end    
%     xlabel('Quarters','FontSize',15)
%     ylabel('Percent','FontSize',15)
%     set(gca,'FontSize',13)
%     set(gca,'XTick',0:4:H)
%     axis([0 12 ylimmatrix(varsel(ii),:)]) 
% 
%     if ii==1
%         ylim([-3.5 1.8])
%     end
%     if ii==2
%         ylim([-1.3 0.7])
%     end
% end
% 
% figSize = [14,5];
% graph_extended
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% %-----------------------
% % FIGURE A.6: Time Series of the VAR-identified Geopolitical Shocks
% %-----------------------
% % Note: Some labels have been manually moved for best on-screen placement
% 
% T = size(GPR.VAR.epsHistildeFull,2);
% dates  = 1900+(86+1/2:1/4:120-1/4);
% datesaxis = 1900+(85:1/4:120);
% GPRepisodes = {'US Panama Invasion','Kuwait Invasion','Gulf War','Bosnian War','9/11','Iraq War','Russia-Crimea','Paris Attacks'};
% GPRepisodesdates = [1989+3/4 1990+1/2 1991 1999+1/4 2001+3/4 2003 2014+1/2 2015+3/4];
% [~,i_gprepisodes]    = ismember(GPRepisodesdates,dates);
% 
% fig=figure('Name','Figure A.6','NumberTitle','off');
% 
% subplot(311)
% plot(datesaxis,0*datesaxis,'k','LineWidth',0.5)
% hold on
% plot(datesaxis,0*datesaxis+1,'k--','LineWidth',0.5)    
% plot(datesaxis,0*datesaxis-1,'k--','LineWidth',0.5)  
% hold on
% a = squeeze(GPR.VAR.epsHistildeFull(1,:,1));
% b = squeeze(GPR.VAR.epsHistildeFull(2,:,1));
% [~,~]=jbfill(dates,a,b,'b','none',1,transp90);
% a = squeeze(GPR.VAR.epsHistildeFull(2,:,1));
% b = squeeze(GPR.VAR.epsHistildeFull(3,:,1));
% [~,~]=jbfill(dates,a,b,'b','none',1,transp68);
% a = squeeze(GPR.VAR.epsHistildeFull(3,:,1));
% b = squeeze(GPR.VAR.epsHistildeFull(4,:,1));
% [~,~]=jbfill(dates,a,b,'b','none',1,transp68);
% a = squeeze(GPR.VAR.epsHistildeFull(4,:,1));
% b = squeeze(GPR.VAR.epsHistildeFull(5,:,1));
% [~,~]=jbfill(dates,a,b,'b','none',1,transp90);
% hold on
% l = plot(dates,GPR.VAR.epsHistildeFull(3,:,1),'-bo','MarkerFaceColor','b','LineWidth',1.5);
% l.MarkerSize = 3;
% scatter(GPRepisodesdates, GPR.VAR.epsHistildeFull(3,i_gprepisodes,1),'MarkerFaceColor','r')
% labelpoints(GPRepisodesdates, GPR.VAR.epsHistildeFull(3,i_gprepisodes,1),GPRepisodes,'N',0.7,'FontSize',12)
% axis([datesaxis(1) datesaxis(end) -3 6])
% set(gca,'YTick',-3:1:6)
% set(gca,'FontSize',15)
% ylabel('Standard Deviations','FontSize',15)
% title('GPR Shocks','FontSize',18)
% 
% 
% GPRAepisodes = {'Kuwait Invasion','Gulf War','Bosnian War','9/11','Russia-Crimea','Paris Attacks'};
% GPRAepisodesdates = [1990+1/2 1991 1999+1/4 2001+3/4 2014+1/2 2015+3/4];
% [~,i_gpraepisodes]    = ismember(GPRAepisodesdates,dates);
% 
% subplot(312)
% plot(datesaxis,0*datesaxis,'k','LineWidth',0.5)
% hold on
% plot(datesaxis,0*datesaxis+1,'k--','LineWidth',0.5)    
% plot(datesaxis,0*datesaxis-1,'k--','LineWidth',0.5)  
% hold on
% a = squeeze(GPRAT.VAR.epsHistildeFull(1,:,1));
% b = squeeze(GPRAT.VAR.epsHistildeFull(2,:,1));
% [~,~]=jbfill(dates,a,b,'b','none',1,transp90);
% a = squeeze(GPRAT.VAR.epsHistildeFull(2,:,1));
% b = squeeze(GPRAT.VAR.epsHistildeFull(3,:,1));
% [~,~]=jbfill(dates,a,b,'b','none',1,transp68);
% a = squeeze(GPRAT.VAR.epsHistildeFull(3,:,1));
% b = squeeze(GPRAT.VAR.epsHistildeFull(4,:,1));
% [~,~]=jbfill(dates,a,b,'b','none',1,transp68);
% a = squeeze(GPRAT.VAR.epsHistildeFull(4,:,1));
% b = squeeze(GPRAT.VAR.epsHistildeFull(5,:,1));
% [~,~]=jbfill(dates,a,b,'b','none',1,transp90);
% hold on
% l = plot(dates,GPRAT.VAR.epsHistildeFull(3,:,1),'-bo','MarkerFaceColor','b','LineWidth',1.5);
% l.MarkerSize = 3;
% scatter(GPRAepisodesdates, GPRAT.VAR.epsHistildeFull(3,i_gpraepisodes,1),'MarkerFaceColor','r')
% labelpoints(GPRAepisodesdates, GPRAT.VAR.epsHistildeFull(3,i_gpraepisodes,1),GPRAepisodes,'N',0.7,'FontSize',12)
% axis([datesaxis(1) datesaxis(end) -3 6])
% ylabel('Standard Deviations','FontSize',15)
% set(gca,'FontSize',15)
% set(gca,'YTick',-3:1:6)
% title('GPR Acts Shocks','FontSize',18)
% 
% 
% GPRTepisodes = {'Kuwait Invasion','USSR Coup','Balkan Tensions India Nuclear Test','Iraq War','N.Korea Tensions UK Terror Threats','Russia-Crimea','US - N. Korea','Middle East Tensions'};
% GPRTepisodesdates = [1990+1/2 1991+1/2 1998+1/4 2003 2006+1/2 2014+1/2 2017+1/2 2018 + 1/4];
% [~,i_gprtepisodes]    = ismember(GPRTepisodesdates,dates);
% 
% subplot(313)
% plot(datesaxis,0*datesaxis,'k','LineWidth',0.5)
% hold on
% plot(datesaxis,0*datesaxis+1,'k--','LineWidth',0.5)    
% plot(datesaxis,0*datesaxis-1,'k--','LineWidth',0.5)    
% hold on
% a = squeeze(GPRAT.VAR.epsHistildeFull(1,:,2));
% b = squeeze(GPRAT.VAR.epsHistildeFull(2,:,2));
% [~,~]=jbfill(dates,a,b,'b','none',1,transp90);
% a = squeeze(GPRAT.VAR.epsHistildeFull(2,:,2));
% b = squeeze(GPRAT.VAR.epsHistildeFull(3,:,2));
% [~,~]=jbfill(dates,a,b,'b','none',1,transp68);
% a = squeeze(GPRAT.VAR.epsHistildeFull(3,:,2));
% b = squeeze(GPRAT.VAR.epsHistildeFull(4,:,2));
% [~,~]=jbfill(dates,a,b,'b','none',1,transp68);
% a = squeeze(GPRAT.VAR.epsHistildeFull(4,:,2));
% b = squeeze(GPRAT.VAR.epsHistildeFull(5,:,2));
% [~,~]=jbfill(dates,a,b,'b','none',1,transp90);
% hold on
% l = plot(dates,GPRAT.VAR.epsHistildeFull(3,:,2),'-bo','MarkerFaceColor','b','LineWidth',1.5);
% l.MarkerSize = 3;
% scatter(GPRTepisodesdates, GPRAT.VAR.epsHistildeFull(3,i_gprtepisodes,2),'MarkerFaceColor','r')
% labelpoints(GPRTepisodesdates, GPRAT.VAR.epsHistildeFull(3,i_gprtepisodes,2),GPRTepisodes,'N',0.7,'FontSize',12)
% axis([datesaxis(1) datesaxis(end) -3 6])
% set(gca,'YTick',-3:1:6)
% 
% ylabel('Standard Deviations','FontSize',15)
% set(gca,'FontSize',15)
% 
% title('GPR Threats Shocks','FontSize',18)
% 
% figSize = [15.5,11];
% graph_extended
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% %-----------------------
% % FIGURE A.7: Impact of Increased Geopolitical Risk on GDP
% %-----------------------
% 
% ii = 6;
% 
% fig=figure('Name','Figure A.7','NumberTitle','off');
% 
% plot(0:1:H,0*squeeze(GPRGDP.VAR.LtildeFull(ii,:,1,1)),'k','LineWidth',0.5)
% hold on
% a = squeeze(GPRGDP.VAR.LtildeFull(ii,:,1,1));
% b = squeeze(GPRGDP.VAR.LtildeFull(ii,:,2,1));
% [~,~]=jbfill(0:1:H,a,b,'b','none',1,transp90);
% a = squeeze(GPRGDP.VAR.LtildeFull(ii,:,2,1));
% b = squeeze(GPRGDP.VAR.LtildeFull(ii,:,3,1));
% [~,~]=jbfill(0:1:H,a,b,'b','none',1,transp68);
% a = squeeze(GPRGDP.VAR.LtildeFull(ii,:,3,1));
% b = squeeze(GPRGDP.VAR.LtildeFull(ii,:,4,1));
% [~,~]=jbfill(0:1:H,a,b,'b','none',1,transp68);
% a = squeeze(GPRGDP.VAR.LtildeFull(ii,:,4,1));
% b = squeeze(GPRGDP.VAR.LtildeFull(ii,:,5,1));
% [~,~]=jbfill(0:1:H,a,b,'b','none',1,transp90);
% hold on
% plot(0:1:H,squeeze(squeeze(GPRGDP.VAR.LtildeFull(ii,:,3,1))),'k','LineWidth',linW)
% set(gca,'FontSize',12)
% title('GDP','FontSize',16)
% xlabel('Quarters','FontSize',14)
% ylabel('Percent','FontSize',14)
% set(gca,'XTick',0:4:H)
% pprint = 0;
% figSize = [6,5];
% graph_extended
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 


% if pprint==1
% 
%     fig = figure(1);
%     print(fig,'-dpdf','irf_baseline');
%     fig = figure(2);
%     print(fig,'-dpdf','irf_acts');
%     fig = figure(3);
%     print(fig,'-dpdf','irf_threats');
%     fig = figure(4);
%     print(fig,'-dpdf','irf_robustness');
%     fig = figure(5);
%     print(fig,'-dpdf','gpr_shocks');
%     fig = figure(6);
%     print(fig,'-dpdf','irf_gdp');
% 
% end

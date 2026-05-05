function vm_plot_irf_bvar(mmodel,identification,fflagFEVD,nper)

% Set path to store supplementary review figures outside the formal package
resultsDir = fullfile('..', '..', '..', '..', '..', '..', '..', 'non_package_materials', 'Outputs', 'Annex', 'matlab', 'caldara_iacoviello_2022_figures', 'results');
if ~exist(resultsDir, 'dir')
    mkdir(resultsDir);
end

graph_opt.font_num = 10;
load(strcat('Result_',char(mmodel),'Iden_',num2str(identification),'_PF',num2str(nper)))
nv = size(VAR.LtildeFull,1);
Horizon = size(VAR.LtildeFull,2);
H = Horizon -1;
nshock = 2; 
selMatrix = 1:nv;
nsel = length(selMatrix);
pprint=1;

[nbplt,nr,nc,lr,lc,nstar] = pltorg(nsel);
for jj = 1:nshock % Shock
    % Plot IRFs
    fig = figure(jj);
%     fig = figure;
    for ii = 1:nsel % Variable
        subplot(nr,nc,ii)
        plot(0:1:H,squeeze(VAR.LtildeFull(selMatrix(ii),1:Horizon,3,jj)),'LineWidth',2)
        hold on
        plot(0:1:H,squeeze(VAR.LtildeFull(selMatrix(ii),1:Horizon,2,jj)),'r--', ...
             'LineWidth',2)
        plot(0:1:H,squeeze(VAR.LtildeFull(selMatrix(ii),1:Horizon,4,jj)),'r--', ...
             'LineWidth',2)
        plot(0:1:H,squeeze(VAR.LtildeFull(selMatrix(ii),1:Horizon,1,jj)),'g--', ...
             'LineWidth',2)
        plot(0:1:H,squeeze(VAR.LtildeFull(selMatrix(ii),1:Horizon,5,jj)),'g--', ...
             'LineWidth',2)
        axis([0 H ylim])          
        plot(0:1:H,0*squeeze(VAR.LtildeFull(selMatrix(ii),1:Horizon,3,jj)),'k','LineWidth',1)
        title(VAR.i_var_str_names(:,selMatrix(ii)),'FontSize',graph_opt.font_num,'FontWeight','bold','Interpreter','none','FontSize',14)
        set(gca,'XTick',0:4:Horizon)
        set(gca,'FontSize',12)
        set(gca,'LineWidth',2.0)
        box off
    end
if pprint == 1
    dim = [15,10]*0.8;
    set(gcf,'paperpositionmode','manual','paperunits','inches');
    set(gcf,'papersize',dim,'paperposition',[0,0,dim]);
    print(fig,'-dpdf',fullfile(resultsDir, strcat('IRF_',char(mmodel),'shock_',num2str(jj))));
end

%     Plot FEVD
    if fflagFEVD ==1
%     nvW = size(VAR.WhFull,1);
    [~,nrW,ncW,~,~,~] = pltorg(nsel);
    figure
    for ii = 1:nsel % Variable
        subplot(nrW,ncW,ii)
        plot(0:1:H,squeeze(VAR.WhFull(selMatrix(ii),1:Horizon,3,jj)),'LineWidth',2)
        hold on
        plot(0:1:H,squeeze(VAR.WhFull(selMatrix(ii),1:Horizon,1,jj)),'r--','LineWidth',2)
        plot(0:1:H,squeeze(VAR.WhFull(selMatrix(ii),1:Horizon,5,jj)),'r--','LineWidth',2)
        %{             
        a=(squeeze(Whq_low(1:Horizon,ii,jj)))';
        b=(squeeze(Whq_high(1:Horizon,ii,jj)))';
        x = 0:1:H;
        [ph,msg]=jbfill(x,a,b,[0 0.3 0],[0 0.3 0],0,0.5);
        %}
        title(VAR.i_var_str_names(:,selMatrix(ii)),'FontSize',graph_opt.font_num,'FontWeight','bold')
        set(gca,'XTick',[0;6;12;18;24;30;36])
%         set(gca,'XTickLabel',['0 ';'10';'20';'30';'40'])
        set(gca,'LineWidth',2.0)
grid on
box off
    end
    if pprint==1
        print('-dpdf',fullfile(resultsDir, strcat('FEVD_',char(mmodel),'Ident_',num2str(identification),'_PF',num2str(nper),'shock_',int2str(jj),'.pdf')))
    end
    end
end

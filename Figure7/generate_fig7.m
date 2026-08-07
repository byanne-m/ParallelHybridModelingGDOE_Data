%%plotting the saved data
load('fig7_data.mat')
it=[5,10,15];
purple = [0.4941 0.1843 0.5569];
orange = [0.9294 0.6941 0.1255];
figure; i=0;
for f=[1,3,5]
i=i+1;
a=it(i)/5; b=3*a-2; 

    mu_p=Pdata(:,f);
    sd_p=Pdata(:,f+1); 
    x_param=PdataE(:,f);
    y_param=PdataE(:,f+1);
   % --- Parametric ---
    subplot(3,3,b); hold on; grid on; 
    ylim([-3 3]); yl = ylim;
    fill([15 20 20 15], [yl(1) yl(1) yl(2) yl(2)], ...
     [0.9 0.9 0.9], ...      % light gray (or any RGB color)
     'FaceAlpha', 0.4, ...
     'EdgeColor', 'none');


    fill([x_pred; flipud(x_pred)], ...
         [mu_p-2*sd_p; flipud(mu_p+2*sd_p)], ...
         purple, 'FaceAlpha',0.3, 'EdgeColor','none');
    plot(x_pred, mu_p, 'Color', purple, 'LineWidth',1.5);
    plot(x_pred, ytrue_pred, 'k', 'LineWidth',1);
    scatter(x_param, y_param, 20, 'r', 'filled');
    xline(15,'--k'); 
    title('Parametric'); ylabel('y'); set(gca,'FontSize',11);xlabel('x');

 % --- GP ---
    subplot(3,3,b+1); hold on; grid on;
        ylim([-3 3]); yl = ylim;
    fill([15 20 20 15], [yl(1) yl(1) yl(2) yl(2)], ...
     [0.9 0.9 0.9], ...      % light gray (or any RGB color)
     'FaceAlpha', 0.4, ...
     'EdgeColor', 'none');

    mu_g=GPdata(:,f);
    sd_g=GPdata(:,f+1); 
    x_gp=GPdataE(:,f);
    y_gp=GPdataE(:,f+1);


    fill([x_pred; flipud(x_pred)], ...
         [mu_g-2*sd_g; flipud(mu_g+2*sd_g)], ...
         orange, 'FaceAlpha',0.3, 'EdgeColor','none');
    plot(x_pred, mu_g, 'Color', orange, 'LineWidth',1.5);
    plot(x_pred, ytrue_pred, 'k', 'LineWidth',1);
    scatter(x_gp, y_gp, 20, 'r', 'filled');
    xline(15,'--k');
    title('GP'); ylabel('y'); set(gca,'FontSize',11); xlabel('x');

    % --- Hybrid ---
    mu_h=Hdata(:,f);
    sd_h=Hdata(:,f+1); 
    x_hybrid=HdataE(:,f);
    y_hybrid=HdataE(:,f+1);

    subplot(3,3,b+2); hold on; grid on;
        ylim([-3 3]); yl = ylim;
    fill([15 20 20 15], [yl(1) yl(1) yl(2) yl(2)], ...
     [0.9 0.9 0.9], ...      % light gray (or any RGB color)
     'FaceAlpha', 0.4, ...
     'EdgeColor', 'none');
    fill([x_pred; flipud(x_pred)], ...
         [mu_h-2*sd_h; flipud(mu_h+2*sd_h)], ...
         [0.8 0.8 1], 'FaceAlpha',0.4, 'EdgeColor','none');
    plot(x_pred, ytrue_pred, 'k', 'LineWidth',1.5);
    plot(x_pred, mu_h, 'b', 'LineWidth',1);
    scatter(x_hybrid, y_hybrid, 20, 'r', 'filled');
    xline(15,'--k'); 
    title('Hybrid'); xlabel('x'); ylabel('y'); set(gca,'FontSize',11);

end 
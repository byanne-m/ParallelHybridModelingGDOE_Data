%%plotting parity plots 
%choose between 'Figure10_Data.csv' 'Figure12_Data.csv'
T = readtable('Figure12_Data.csv', 'VariableNamingRule', 'preserve');

colorMap=[0    0.4471    0.7412; 0.8510    0.3255    0.0980;...
    0.4667    0.6745    0.1882;0.5020    0.5020    0.5020;...
    0.4941    0.1843    0.5569];

it=45;
 figure('Color','w');
    t = tiledlayout(2,2,'Padding','compact','TileSpacing','compact');
    title(t, sprintf('Parity plots on unseen pool (it=%d)', it));

    for i=1:4 
    y_true=table2array(T(:,2*i-1));
    y_pred=table2array(T(:,2*i));
    nexttile;
    scatter(y_true, y_pred, 12, 'filled','MarkerFaceColor',colorMap(i,:)); hold on; grid on;
    hold on; 
    plot([0 1.02], [0 1.02], 'k--', 'LineWidth', 1.0);
    axis equal;
    xlim([0 1.02]);
    ylim([0 1.02]);

    xlabel('True (unseen pool)');
    ylabel('Predicted');

    % txt = sprintf('MSE = %.3g\nN = %d', mse, numel(y_true));
    % text(0.05, 0.95, txt, 'Units','normalized', ...
    %     'VerticalAlignment','top', ...
    %     'BackgroundColor','w', 'EdgeColor',[0.8 0.8 0.8]);
    end 
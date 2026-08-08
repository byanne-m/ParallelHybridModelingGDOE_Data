
%plotting the saved data 

nRuns=100; 
nTrain=[16:1:85]'; 

allData = readmatrix('fig11_data.csv'); %'fig11_data.csv' or 'fig9_data.csv'

mse_gp_all    = allData(:, 1:100);
mse_hyb_all   = allData(:, 101:200);
mse_hyb_all3  = allData(:, 201:300);
mse_param_all = allData(:, 301:400);


% Define outlier detection method (using 'quartiles' which is IQR method)
outlier_method = 'grubbs'; % or 'median', 'grubbs', 'gesd', 'mean'

% Remove outliers from each dataset along appropriate dimension
% Assuming data is arranged with runs in columns, nTrain values in rows
mse_param_clean = rmoutliers(mse_param_all, outlier_method, 2);
mse_gp_clean = rmoutliers(mse_gp_all, outlier_method, 2);
mse_hyb_clean = rmoutliers(mse_hyb_all, outlier_method, 2);
mse_hyb_clean3 = rmoutliers(mse_hyb_all3, outlier_method, 2);


% Alternative: If you want to keep the same dimensions but replace outliers with NaN
% mse_param_clean = filloutliers(mse_param_all, NaN, outlier_method, 2);

% Calculate means after outlier removal
m_param = mean(mse_param_clean, 2, 'omitnan');
m_gp = mean(mse_gp_clean, 2, 'omitnan');
m_hyb = mean(mse_hyb_clean, 2, 'omitnan');
m_hyb3 = mean(mse_hyb_clean3, 2, 'omitnan');

% Calculate standard deviations
s_param = std(mse_param_clean, 0, 2, 'omitnan')./2;
s_gp = std(mse_gp_clean, 0, 2, 'omitnan')./2;
s_hyb = std(mse_hyb_clean, 0, 2, 'omitnan')./2;
s_hyb3 = std(mse_hyb_clean3, 0, 2, 'omitnan')./2;

% Create figure with professional styling for black-and-white printing
figure('Color', 'w', 'Position', [100, 100, 800, 500]);
hold on; grid on; box on;

% Customize grid and axes
ax = gca;
ax.GridLineStyle = ':';
ax.GridAlpha = 0.3;
ax.LineWidth = 1;
ax.XMinorGrid=1;
ax.YMinorTick=1;
ax.FontName = 'Arial';
ax.FontSize = 11;
ax.TickDir = 'in';
ax.TickLength = [0.02, 0.02];

% Define black-and-white friendly styles
line_styles = {'-', '--', ':', '-.', '--'};
markers = {'o', 's', 'd', '^', 'v'};
marker_sizes = [5, 5, 5, 5, 5];
line_widths = [1.5, 1.5, 1.5, 1.5, 1.5];
colorMap=[0    0.4471    0.7412; 0.8510    0.3255    0.0980;...
    0.4667    0.6745    0.1882;0.5020    0.5020    0.5020;...
    0.4941    0.1843    0.5569];

% Plot the data
plot(nTrain, m_param, 'color', colorMap(1,:), 'LineStyle', line_styles{1}, ...
    'Marker', markers{1}, 'MarkerSize', marker_sizes(1), ...
    'LineWidth', line_widths(1), 'MarkerFaceColor', 'w');

plot(nTrain, m_gp, 'color', colorMap(2,:), 'LineStyle', line_styles{2}, ...
    'Marker', markers{2}, 'MarkerSize', marker_sizes(2), ...
    'LineWidth', line_widths(2), 'MarkerFaceColor', 'w');

plot(nTrain, m_hyb, 'color', colorMap(3,:), 'LineStyle', line_styles{3}, ...
    'Marker', markers{3}, 'MarkerSize', marker_sizes(3), ...
    'LineWidth', line_widths(3), 'MarkerFaceColor', 'w');

plot(nTrain, m_hyb3, 'color', colorMap(4,:), 'LineStyle', line_styles{5}, ...
    'Marker', markers{5}, 'MarkerSize', marker_sizes(5), ...
    'LineWidth', line_widths(5), 'MarkerFaceColor', 'w');

% Labels and title
xlabel('Number of selected experiments', ...
    'FontName', 'Arial', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('MSE on remaining (unselected) pool', ...
    'FontName', 'Arial', 'FontSize', 12, 'FontWeight', 'bold');
title(sprintf('Pool-based sequential DoE: mean over %d runs', nRuns), ...
    'FontName', 'Arial', 'FontSize', 13, 'FontWeight', 'bold');

% Legend
% In your MATLAB plotting code:
legend('Empirical', 'GP', 'Hybrid-U', 'Hybrid-F', ...
       'Location', 'best', 'FontSize', 10);

% Then in your paper caption write:
% "Fig. X: Mean squared error (MSE) versus number of training points for 
% different modeling approaches: Empirical model (Cioncolini & Thome, 2010), 
% Gaussian Process (GP), and two hybrid models combining both approaches. 
% Hybrid-U estimates empirical model parameters without constraints, while 
% Hybrid-F uses the known parameters provided. Error shading shows 
% ±1σ over 100 independent runs."


% % Optional: Add error bars using shaded regions
% add_error_shading = true;
% if add_error_shading
%     alpha_val = 0.15;
% 
%    % For parametric
    x_fill = [nTrain; flipud(nTrain)];
%     y_fill_param = [m_param + s_param; flipud(m_param - s_param)];
%     fill(x_fill, y_fill_param, 'k', 'FaceAlpha', alpha_val, ...
%         'EdgeColor', 'none');
% 
%     % For GP (different pattern)
%     y_fill_gp = [m_gp + s_gp; flipud(m_gp - s_gp)];
%     fill(x_fill, y_fill_gp, [0.3, 0.3, 0.3], 'FaceAlpha', alpha_val, ...
%         'EdgeColor', 'none', ...
%         'LineStyle', '--', 'FaceColor', [0.5 0.5 0.5]);
% 
%     % Bring lines to front
%     arrayfun(@(h) uistack(h, 'top'), findobj(gca, 'Type', 'line'));
% end


add_error_shading = true;
if add_error_shading
    alpha_val = 0.2; % Transparency for error bars
    
    % For parametric (blue)
    y_fill_param = [m_param + s_param; flipud(m_param - s_param)];
    fill(x_fill, y_fill_param, colorMap(1,:), ...
        'FaceAlpha', alpha_val, 'EdgeColor', 'none');
        %'DisplayName', 'Empirical ±1σ');
    
    % For GP (orange)
    y_fill_gp = [m_gp + s_gp; flipud(m_gp - s_gp)];
    fill(x_fill, y_fill_gp, colorMap(2,:), ...
        'FaceAlpha', alpha_val, 'EdgeColor', 'none');
        %'DisplayName', 'GP ±1σ');
    
    % For hybrid-no param bounds (green)
    y_fill_hyb = [m_hyb + s_hyb; flipud(m_hyb - s_hyb)];
    fill(x_fill, y_fill_hyb, colorMap(3,:), ...
        'FaceAlpha', alpha_val, 'EdgeColor', 'none');
        %'DisplayName', 'Hybrid-U ±1σ');
    
    % For hybrid-known param (purple)
    y_fill_hyb3 = [m_hyb3 + s_hyb3; flipud(m_hyb3 - s_hyb3)];
    fill(x_fill, y_fill_hyb3, colorMap(4,:), ...
        'FaceAlpha', alpha_val, 'EdgeColor', 'none');
       % 'DisplayName', 'Hybrid-F ±1σ');
end


% Adjust axis
ax.XMinorTick = 'on';
ax.YMinorTick = 'on';

% Optional: Set Y to log scale if MSE varies widely
% if max([m_param; m_gp; m_hyb; m_hyb3]) / min([m_param; m_gp; m_hyb; m_hyb3]) > 100
%     set(gca, 'YScale', 'log');
%     ylabel([get(ylabel), ' (log scale)']);
% end

hold off;

% Adjust layout
set(gcf, 'PaperPositionMode', 'auto');
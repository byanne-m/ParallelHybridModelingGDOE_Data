%%generate Fig 6 matlab code
x_plot = (0:0.1:15)';
theta_true = [1.5, 0.9];

k = 0.6;
s = @(x) 1 ./ (1 + exp(-k*(x - 7.5)));
y2 = @(x) 0.4 * (s(x) - s(0)) / (s(12) - s(0));

Ytrue = @(x) theta_true(1)*sin(theta_true(2)*x) + y2(x); %0.002*exp(0.55*x);

ytrue = Ytrue(x_plot);

% Noise settings
varSig = var(ytrue);
SNR    = 20;
sigma  = sqrt(varSig/SNR);

y1data=ytrue;
y2data=y2(x_plot);

figure; plot(x_plot,y1data,'LineWidth',2); hold on
plot(x_plot,y2data,'LineWidth',2); grid on; 
plot(x_plot,ytrue,'k','LineWidth',2);
% plot(x_plot,y3(x_plot),'k','LineWidth',2);

legend('y1','y2','y1+y2')

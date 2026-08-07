%% MC study: Sequential DoE (Parametric vs GP vs Hybrid) — MASKING-ONLY ACQUISITION
% -------------------------------------------------------------------------
% Goal
%   Compare sequential learning of three approaches under identical truth:
%     (1) Parametric (misspecified) MCMC model
%     (2) GP regression model
%     (3) Hybrid = Parametric mean + GP residual correction
%
% Key DoE rules (per model, independently):
%   - Candidate set is DISCRETE grid x_pred = 0:0.1:19 (prediction grid)
%   - We NEVER sample experiments in the extrapolation region (x > 15)
%   - We NEVER resample a previously sampled condition
%   - Acquisition = posterior predictive variance (greedy max-variance)
%
% Implementation detail:
%   - DoE restrictions are enforced ONLY by masking:
%         var(~avail_mask) = -Inf
%     where avail_mask excludes (i) already-sampled points, (ii) x>15 points.
%   - No recomputation on a separate DoE grid is needed because:
%         x_doe ⊂ x_pred and acquisition depends only on variance.

clc; clear; close all;

%% -------------------- User settings --------------------
MC = 100;     % Monte Carlo runs
M  = 15;      % sequential acquisitions per run

% Prediction grid includes extrapolation (we evaluate predictions here)
x_pred = (0:0.1:19)';     % NOTE: includes extrapolated region

% Experimental domain restriction (no sampling beyond this)
x_max_sample = 15;

% Initial design (indices on x_pred, ensure within x<=15)
idx0 = [1, round(numel((0:0.1:x_max_sample)')/2), numel((0:0.1:x_max_sample)')];
% idx0 refers to indices of x_pred for x<=15 because x_pred starts at 0 with step 0.1
% (so the first part of x_pred is exactly the same grid up to 15)
x_init = x_pred(idx0);

% Misspecified parametric model
y_m = @(theta, x) theta(1)*sin(theta(2)*x);

% MCMC init
theta_init = [0.2; 0.2];

%% -------------------- Truth + noise --------------------
theta_true = [1.5, 0.9];

k = 0.6;
s  = @(x) 1 ./ (1 + exp(-k*(x - 7.5)));
y2 = @(x) 0.4 * (s(x) - s(0)) / (s(12) - s(0));
Ytrue = @(x) theta_true(1)*sin(theta_true(2)*x) + y2(x);

ytrue_pred = Ytrue(x_pred);

% Noise chosen from variability on the *training* domain [0,15]
x_train = (0:0.1:x_max_sample)';
ytrue_train = Ytrue(x_train);
SNR = 20;
sigma_true = sqrt(var(ytrue_train)/SNR);

% Extrapolation region mask for reporting
mask_extr = (x_pred >= 15) & (x_pred <= 19);

%% -------------------- Storage --------------------
mse_param_all = nan(MC, M);
mse_gp_all    = nan(MC, M);
mse_hy_all    = nan(MC, M);

mse_extr_param_final = nan(MC,1);
mse_extr_gp_final    = nan(MC,1);
mse_extr_hy_final    = nan(MC,1);

%% ================================
%            MC LOOP
% ================================
for r = 1:MC
    clc; r
    rng(1000 + r); % reproducible Monte Carlo

    % Initial noisy observations
    y_init = Ytrue(x_init) + sigma_true*randn(size(x_init));

    % Three independent datasets (and hence independent DoEs)
    x_param  = x_init;  y_param  = y_init;
    x_gp     = x_init;  y_gp     = y_init;
    x_hybrid = x_init;  y_hybrid = y_init;

    % Availability masks live on x_pred (candidate grid):
    % true  = allowed to sample
    % false = forbidden (already sampled OR in extrapolation region x>15)
    avail_param  = true(size(x_pred));
    avail_gp     = true(size(x_pred));
    avail_hybrid = true(size(x_pred));

    % forbid extrapolation region for sampling
    avail_param(x_pred > x_max_sample)  = false;
    avail_gp(x_pred > x_max_sample)     = false;
    avail_hybrid(x_pred > x_max_sample) = false;

    % forbid re-sampling initial points
    avail_param(idx0)  = false;
    avail_gp(idx0)     = false;
    avail_hybrid(idx0) = false;

    % Track last-iteration predictions for final extrapolation MSE
    mu_p_last = []; mu_g_last = []; mu_h_last = [];

    %% ---------------- Sequential loop ----------------
    for it = 1:M

        % ==========================================================
        % (1) Parametric model: MCMC -> posterior predictive on x_pred
        % ==========================================================
        [mu_p, sd_p, thetas_p] = ...
            fitParametricModel2(x_param, y_param, x_pred, y_m, NaN, theta_init);

        mse_param_all(r,it) = mean((mu_p(:) - ytrue_pred(:)).^2);

        % DoE acquisition: maximize predictive variance with masking
        var_p = sd_p(:).^2;
        var_p(~avail_param) = -Inf;

        idxP = local_pick_index(var_p);
        if ~isnan(idxP)
            avail_param(idxP) = false; % prevent repeats
            x_new = x_pred(idxP);
            y_new = Ytrue(x_new) + sigma_true*randn;
            x_param = [x_param; x_new];
            y_param = [y_param; y_new];
        else
            % no candidates left; freeze remaining trajectory
            mse_param_all(r,it:end) = mse_param_all(r,it);
        end

        % ==========================================================
        % (2) GP model: fitGPModel -> predictive on x_pred
        % ==========================================================
        [mu_g, sd_g, psi_g] = fitGPModel(x_gp, y_gp, x_pred, NaN);

        mse_gp_all(r,it) = mean((mu_g(:) - ytrue_pred(:)).^2);

        var_g = sd_g(:).^2;
        var_g(~avail_gp) = -Inf;

        idxG = local_pick_index(var_g);
        if ~isnan(idxG)
            avail_gp(idxG) = false;
            x_new = x_pred(idxG);
            y_new = Ytrue(x_new) + sigma_true*randn;
            x_gp = [x_gp; x_new];
            y_gp = [y_gp; y_new];
        else
            mse_gp_all(r,it:end) = mse_gp_all(r,it);
        end

        % ==========================================================
        % (3) Hybrid model: parametric MCMC + GP residual correction
        %     Predictions returned on x_pred
        % ==========================================================
        [mu_m, sd_m, mu_corr, sd_corr, thetas_h, psi_h] = ...
            fitHybridOnce2(x_hybrid, y_hybrid, x_pred, y_m, NaN, theta_init);

        mu_h = mu_m(:) + mu_corr(:);
        sd_h = sqrt(sd_m(:).^2 + sd_corr(:).^2); %#ok<NASGU>

        mse_hy_all(r,it) = mean((mu_h(:) - ytrue_pred(:)).^2);

        var_h = sd_m(:).^2 + sd_corr(:).^2;
        var_h(~avail_hybrid) = -Inf;

        idxH = local_pick_index(var_h);
        if ~isnan(idxH)
            avail_hybrid(idxH) = false;
            x_new = x_pred(idxH);
            y_new = Ytrue(x_new) + sigma_true*randn;
            x_hybrid = [x_hybrid; x_new];
            y_hybrid = [y_hybrid; y_new];
        else
            mse_hy_all(r,it:end) = mse_hy_all(r,it);
        end

        % store last predictions (final iteration)
        mu_p_last = mu_p;
        mu_g_last = mu_g;
        mu_h_last = mu_h;

    end % it

    %% ---------------- Final extrapolation-region MSE ----------------
    mse_extr_param_final(r) = mean((mu_p_last(mask_extr) - ytrue_pred(mask_extr)).^2);
    mse_extr_gp_final(r)    = mean((mu_g_last(mask_extr) - ytrue_pred(mask_extr)).^2);
    mse_extr_hy_final(r)    = mean((mu_h_last(mask_extr) - ytrue_pred(mask_extr)).^2);

end % MC

%% ================================
%     Plot average MSE trajectories
% ================================
avg_param = mean(mse_param_all, 1, 'omitnan');
avg_gp    = mean(mse_gp_all,    1, 'omitnan');
avg_hy    = mean(mse_hy_all,    1, 'omitnan');
purple = [0.4941 0.1843 0.5569];
orange = [0.9294 0.6941 0.1255];
figure; hold on; grid on;
plot(1:M, avg_param, '-o', 'color', purple,'LineWidth', 1.8);
plot(1:M, avg_gp,    '-s', 'color',orange, 'LineWidth', 1.8);
plot(1:M, avg_hy,    '-d', 'color','b','LineWidth', 1.8);
xlabel('Iteration'); ylabel('Average MSE on [0,19]');
title(sprintf('Average MSE Trajectories over %d MC runs (DoE masked to x\\leq%.1f)', MC, x_max_sample));
legend('Parametric','GP','Hybrid','Location','best');

%% ================================
%   Table: extrapolation MSE [15,19]
% ================================
T = table( ...
    mean(mse_extr_param_final,'omitnan'), std(mse_extr_param_final,'omitnan'), ...
    mean(mse_extr_gp_final,'omitnan'),    std(mse_extr_gp_final,'omitnan'), ...
    mean(mse_extr_hy_final,'omitnan'),    std(mse_extr_hy_final,'omitnan'), ...
    'VariableNames', {'Param_MSE_mean','Param_MSE_std', ...
                      'GP_MSE_mean','GP_MSE_std', ...
                      'Hybrid_MSE_mean','Hybrid_MSE_std'} );

disp('Final-iteration average MSE over extrapolated region x in [15, 19] (mean ± std across MC):');
disp(T);

%% ================================
% Helper: pick max index, return NaN if none left
% ================================
function idx = local_pick_index(acq)
    [~, idx0] = max(acq);
    if isempty(idx0) || ~isfinite(acq(idx0))
        idx = NaN;
    else
        idx = idx0;
    end
end

%% GP MODEL
function [mean_gp, sd_gp,hyper_param_GP] = fitGPModel(xobs, yobs, x_grid, sigma)

    % gprMdl = fitrgp(xobs, yobs, ...
    %     "KernelFunction","ardsquaredexponential", ...
    %     "Sigma", sigma, "ConstantSigma", true);
    % 
    % [mean_gp, sd_gp] = predict(gprMdl, x_grid);

  [hyperP, mean_gp, sd_gp] = EnhanceGPKernel3(xobs, yobs, x_grid, "ardsquaredexponential", ...
                                      sigma, [], 'option', 1);
  hyper_param_GP=hyperP.values;

end

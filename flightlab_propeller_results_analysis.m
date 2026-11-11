%===== FLIGHT LAB - Experimental Propeller Analysis =====

clear;
clc;
close all;

%% 1. READ EXPERIMENTAL DATA

filename = 'moltas_prop_run1.dat';

M = readmatrix(filename);


%% 2. EXTRACT EXPERIMENTAL RESULTS

rpm = M(:,1);

I_avg = M(:,2);
I_max = M(:,3);
I_min = M(:,4);

V_avg = M(:,5);
V_max = M(:,6);
V_min = M(:,7);

P_avg = M(:,8);
P_max = M(:,9);
P_min = M(:,10);

thrust_g = M(:,11);

%% 3. CONVERT THRUST TO NEWTONS

g = 9.80665;

thrust_N = thrust_g * g / 1000;

%% 4. CHECK EXPERIMENTAL DATA

valid = isfinite(rpm) & ...
        isfinite(I_avg) & isfinite(I_max) & isfinite(I_min) & ...
        isfinite(V_avg) & isfinite(V_max) & isfinite(V_min) & ...
        isfinite(P_avg) & isfinite(P_max) & isfinite(P_min) & ...
        isfinite(thrust_N);

rpm = rpm(valid);

I_avg = I_avg(valid);
I_max = I_max(valid);
I_min = I_min(valid);

V_avg = V_avg(valid);
V_max = V_max(valid);
V_min = V_min(valid);

P_avg = P_avg(valid);
P_max = P_max(valid);
P_min = P_min(valid);

thrust_N = thrust_N(valid);

% Use average electrical power in the analysis
power_W = P_avg;

if numel(unique(rpm)) < 4
    error('Not enough distinct RPM values for regression.');
end

%% 5. DISPLAY BASIC INFORMATION

fprintf('Valid measurements: %d\n', length(rpm));
fprintf('RPM range: %.0f to %.0f\n', min(rpm), max(rpm));
fprintf('Maximum thrust: %.3f N\n', max(thrust_N));
fprintf('Maximum power: %.3f W\n', max(power_W));

%% 6. THRUST VS RPM

figure;

plot(rpm, thrust_N, '.');

xlabel('RPM');
ylabel('Thrust [N]');
title('Experimental Thrust vs RPM');

yline(1, '--', 'Target = 1 N');

grid on;


%% 7. POWER VS RPM

figure;

plot(rpm, power_W, '.');

xlabel('RPM');
ylabel('Electrical Power [W]');
title('Experimental Power vs RPM');

grid on;


%% 8. THRUST VS POWER

figure;

plot(power_W, thrust_N, '.');

xlabel('Electrical Power [W]');
ylabel('Thrust [N]');
title('Experimental Thrust vs Power');

yline(1, '--', 'Target = 1 N');

grid on;


%% 9. THRUST REGRESSION

T_target = 1.0;

% Check whether the measurements cover the target
if min(thrust_N) > T_target || max(thrust_N) < T_target
    error('Measured thrust does not cover 1 N.');
end

% Quadratic thrust regression
p_T = polyfit(rpm, thrust_N, 2);

% Smooth RPM values for plotting
rpm_fit = linspace(min(rpm), max(rpm), 200);

% Predicted thrust
T_fit = polyval(p_T, rpm_fit);


%% 10. PLOT THRUST REGRESSION

figure;

plot(rpm, thrust_N, '.', 'DisplayName', 'Measurements');
hold on;

plot(rpm_fit, T_fit, '-', 'LineWidth', 1.5, ...
    'DisplayName', 'Quadratic regression');

yline(T_target, '--', 'Target = 1 N');

xlabel('RPM');
ylabel('Thrust [N]');
title('Experimental Thrust Regression');

legend('Location', 'best');
grid on;

hold off;

%% 11. FIND RPM AT 1 N

% Solve T(RPM) = 1 N
p_target = p_T;
p_target(end) = p_target(end) - T_target;

rpm_candidates = roots(p_target);

% Keep real roots
rpm_candidates = rpm_candidates( ...
    abs(imag(rpm_candidates)) < 1e-8);

rpm_candidates = real(rpm_candidates);

% Keep roots inside measured RPM range
rpm_candidates = rpm_candidates( ...
    rpm_candidates >= min(rpm) & ...
    rpm_candidates <= max(rpm));

if numel(rpm_candidates) ~= 1
    error('Could not determine one valid RPM at 1 N.');
end

rpm_1N = rpm_candidates;


%% 12. POWER REGRESSION

p_P = polyfit(rpm, power_W, 3);

P_fit = polyval(p_P, rpm_fit);

% Evaluate power at the RPM required for 1 N
P_1N = polyval(p_P, rpm_1N);

if P_1N <= 0 || ~isfinite(P_1N)
    error('Invalid estimated power at 1 N.');
end


%% PLOT POWER REGRESSION

figure;

plot(rpm, power_W, '.', 'DisplayName', 'Measurements');
hold on;

plot(rpm_fit, P_fit, '-', 'LineWidth', 1.5, ...
    'DisplayName', 'Cubic regression');

plot(rpm_1N, P_1N, 'o', 'MarkerSize', 8, ...
    'DisplayName', 'Operating point at 1 N');

xlabel('RPM');
ylabel('Electrical Power [W]');
title('Experimental Power Regression');

legend('Location', 'best');
grid on;

hold off;


%% 13. SCORE CALCULATION

mass_g = 0;    % Replace with actual mass after balancing

T_target_g = T_target * 1000 / g;

score = 6000 * T_target_g / (rpm_1N * P_1N) ...
        - 0.1 * mass_g;

fprintf('\n--- EXPERIMENTAL PERFORMANCE AT 1 N ---\n');

fprintf('RPM:   %.1f rpm\n', rpm_1N);
fprintf('Power: %.3f W\n', P_1N);
fprintf('Mass:  %.2f g\n', mass_g);
fprintf('Score: %.3f\n', score);
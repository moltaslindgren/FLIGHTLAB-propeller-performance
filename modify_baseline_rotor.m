%% =========================================================
% FLIGHT LAB - Propeller Geometry Design
%Read baseline.rotor, modify chord and twist
%estimate solidity, and print XRotor ARBI input
%% =========================================================

clear;
clc;
close all;

filename = 'baseline.rotor';

%% READ FILE
fid = fopen(filename,'r');

if fid == -1
    error('Could not open %s', filename);
end

lines = {};
while ~feof(fid)
    lines{end+1,1} = fgetl(fid);
end

fclose(fid);


%% =========================================================
% FIND NUMBER OF SECTIONS AND NUMBER OF BLADES
%% =========================================================

for i = 1:length(lines)

    if contains(lines{i}, 'II Nblds')

        values = sscanf(lines{i+1}, '%f');

        N_sections = values(1);
        N_blades   = 3;

        break
    end
end

fprintf('Number of radial sections = %d\n', N_sections);
fprintf('Number of blades     = %d\n', N_blades);


%% =========================================================
% FIND GEOMETRY TABLE
%% =========================================================

for i = 1:length(lines)

    if contains(lines{i}, 'r/R') && contains(lines{i}, 'C/R')

        geometryStart = i + 1;

        break
    end
end


%% READ GEOMETRY

geometry = zeros(N_sections,4);

for j = 1:N_sections

    values = sscanf(lines{geometryStart + j - 1}, '%f');

    geometry(j,:) = values(1:4)';

end


%% EXTRACT VARIABLES

r_R   = geometry(:,1);
c_R   = geometry(:,2);
twist = geometry(:,3);
Ubody = geometry(:,4);


%% SHOW TABLE

baselineGeometry = table(r_R, c_R, twist, Ubody);

disp(baselineGeometry);


%% =========================================================
% PLOT BASELINE CHORD
%% =========================================================

figure;

plot(r_R, c_R, 'o-', 'LineWidth',1.5);

xlabel('r/R');
ylabel('c/R');
title('Baseline Chord Distribution');
grid on;


%% =========================================================
% PLOT BASELINE TWIST
%% =========================================================

figure;

plot(r_R, twist, 'o-', 'LineWidth',1.5);

xlabel('r/R');
ylabel('Twist [deg]');
title('Baseline Twist Distribution');
grid on;


%% =========================================================
% SOLIDITY
%% =========================================================

c_R_mean = trapz(r_R, c_R) / ...
           (r_R(end) - r_R(1));

sigma = N_blades * c_R_mean / pi;

fprintf('\n--- Baseline geometry ---\n');
fprintf('Mean c/R = %.4f\n', c_R_mean);
fprintf('Solidity = %.4f\n', sigma);

%% =========================================================
% DESIGN 1
% Smooth chord modification using control points
%% =========================================================

c_R_new = c_R;

%% CONTROL POINTS FOR CHORD SCALING

r_factor = [
    r_R(1)
    0.25
    0.8
    r_R(end)
];

factor_points = [
    0.86
    0.9
    0.9
    0.82
];

%% SMOOTH INTERPOLATION OF FACTOR
% Keeps the same original 30 r/R stations

chord_factor = interp1( ...
    r_factor, ...
    factor_points, ...
    r_R, ...
    'pchip');

%% APPLY CHORD CHANGE

c_R_new = chord_factor .* c_R;

%% =========================================================
% TWIST MODIFICATION
% Same twist changes, but smooth transitions
%% =========================================================

twist_new = twist;

%% ORIGINAL TWIST SETTINGS

start_twist_change  = 10;   % deg
middle_twist_change = 11;   % deg
end_twist_change    = 7;  % deg

%% USE SAME REGION BOUNDARIES AS CHORD

start_end  = 0.25;
middle_end = 0.85;

%% TRANSITION WIDTH

twist_transition = 0.2;


%% =========================================================
% CREATE SMOOTH TWIST CHANGE
%% =========================================================

twist_change = zeros(size(r_R));

for i = 1:length(r_R)

    r = r_R(i);

    % START REGION
    if r <= start_end - twist_transition/2

        twist_change(i) = start_twist_change;


    % SMOOTH TRANSITION: START -> MIDDLE
    elseif r < start_end + twist_transition/2

        x = (r - (start_end - twist_transition/2)) ...
            / twist_transition;

        s = 3*x^2 - 2*x^3;

        twist_change(i) = ...
            start_twist_change + ...
            s*(middle_twist_change-start_twist_change);


    % MIDDLE REGION
    elseif r <= middle_end - twist_transition/2

        twist_change(i) = middle_twist_change;


    % SMOOTH TRANSITION: MIDDLE -> END
    elseif r < middle_end + twist_transition/2

        x = (r - (middle_end - twist_transition/2)) ...
            / twist_transition;

        s = 3*x^2 - 2*x^3;

        twist_change(i) = ...
            middle_twist_change + ...
            s*(end_twist_change-middle_twist_change);


    % END REGION
    else

        twist_change(i) = end_twist_change;

    end

end


%% APPLY TWIST CHANGE

twist_new = twist + twist_change;

%% NEW SOLIDITY

c_R_mean_new = trapz(r_R, c_R_new) / ...
               (r_R(end) - r_R(1));

sigma_new = N_blades * c_R_mean_new / pi;

fprintf('\n--- Design 1 ---\n');
fprintf('Baseline solidity = %.4f\n', sigma);
fprintf('Design 1 solidity = %.4f\n', sigma_new);


%% =========================================================
% COMPARE CHORD DISTRIBUTIONS
%% =========================================================

figure;

plot(r_R, c_R, 'o-', 'LineWidth',1.5);
hold on;

plot(r_R, c_R_new, 'o-', 'LineWidth',1.5);

xlabel('r/R');
ylabel('c/R');

legend('Baseline','Design 1', ...
       'Location','best');

title('Chord Distribution Comparison');

grid on;


%% =========================================================
% COMPARE TWIST DISTRIBUTIONS
%% =========================================================

figure;

plot(r_R, twist, 'o-', 'LineWidth',1.5);
hold on;

plot(r_R, twist_new, 'o-', 'LineWidth',1.5);

xlabel('r/R');
ylabel('Twist [deg]');

legend('Baseline','Modified', ...
       'Location','best');

title('Twist Distribution Comparison');

grid on;
%% =========================================================
% PRINT VALUES FOR XRotor ARBI
%% =========================================================

fprintf('\n');
fprintf('===== DESIGN 1 ARBI INPUT =====\n');
fprintf('      r/R         c/R      twist [deg]\n');

for i = 1:N_sections

    fprintf('%10.5f  %10.5f  %10.4f\n', ...
        r_R(i), ...
        c_R_new(i), ...
        twist_new(i));

end
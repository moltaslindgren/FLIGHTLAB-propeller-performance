%% =========================================================
% FLIGHT LAB - Compare Multiple Propeller Designs
%% =========================================================

clear;
clc;
close all;

%% =========================================================
% FILES TO COMPARE
%% =========================================================

files = {
    'baseline.out'
    'design3_chordchange.out'
    'design6_chordchange_solidity13_3blades.out'
    'design7_chordchange_13solidity_3blades_twistchange.out'
    'design8_thisisdesign6_moretwistchange.out'
    'design9_thisisdesign6_ca10degtwistchange.out'
    'design10_thisisdesign6_20degtwist.out'
    'design11_thisisdesign6_15degtwist.out'
    'design12_thisisdesign6_7degtwist.out'
    'design13_thisisdesign6_12n13degtwist.out'
    'smoothdesign.out'
    'smoothdesign_twisttesting.out'
    'smoothdesign_twistinmiddle.out'
    'smoothdesign_finaltwist.out'
    'finaldesign_xrotorsolidity125.out'
    'FINALASSIGNMENT.out'

};

names = {
    'Baseline'
    'Design 3 big chord change'
    'Design 6 3 blades, 13 solidity (chord change only)'
    'Design 7 (Design 6 but with small twist distribution change, design 6)'
    'Design 8 (Design 7, slightly more twist than D7, design 6)'
    'Design 9 (big twist change, 10-11 deg, design 6)'
    'Design 10 (even bigger twist, 20-21 deg, design 6))'
    'Design 11 (15 deg twist, design 6'
    'Design 12 (7 deg twist, D6)'
    'Design 13 (12n13 degtwist, D6)'
    'Smoothed out Design 9'
    'Twist distribution testing, D9'
    'Twist optimized in middle, D9'
    'Twist optimized final'
    'Final thursday with xrotor solidity 12.5'
    'FINALASSIGNMENT.out'
};

%% MASSES [g]
% Enter actual masses later if known

masses = [
    11
    17
    16.1
    16.1
    16.1
    16.1
    16.1
    16.1
    16.1
    16.1
    16.1
    16.1
    16.1
    16.1
    16.6
    16.6
];

%% TARGET THRUST

Ttarget = 1.0;                         % N
thrust_g = Ttarget / 9.80665 * 1000;  % gram-force

Ndesigns = length(files);


%% =========================================================
% LOAD ALL DESIGNS
%% =========================================================

D = struct();

for k = 1:Ndesigns

    filename = files{k};

    fid = fopen(filename,'r');

    if fid == -1
        error('Could not open %s',filename);
    end

    % Skip first 3 header lines
    for i = 1:3
        fgetl(fid);
    end

    data = textscan(fid,repmat('%f',1,23));

    fclose(fid);

    M = [data{:}];

    %% Store XRotor results

    D(k).name = names{k};

    D(k).rpm = M(:,5);
    D(k).P   = M(:,10);
    D(k).T   = M(:,11);
    D(k).Q   = M(:,12);
    D(k).eff = M(:,13);
    D(k).CT  = M(:,18);
    D(k).CP  = M(:,19);

    D(k).mass = masses(k);


    %% =====================================================
    % INTERPOLATE AT EXACTLY 1 N
    %% =====================================================

    D(k).rpm_1N = interp1( ...
        D(k).T, ...
        D(k).rpm, ...
        Ttarget, ...
        'linear');

    D(k).P_1N = interp1( ...
        D(k).T, ...
        D(k).P, ...
        Ttarget, ...
        'linear');


    %% SCORE DENOMINATOR

    D(k).RPMxPower = ...
        D(k).rpm_1N * D(k).P_1N;


    %% SCORE

    D(k).score = ...
        6000 * thrust_g / D(k).RPMxPower ...
        - 0.1 * D(k).mass;


    %% CT / CP

    D(k).ratio = ...
        D(k).CT ./ D(k).CP;


    %% RPM * POWER CURVE

    D(k).denomCurve = ...
        D(k).rpm .* D(k).P;

end


%% =========================================================
% PERCENT CHANGES RELATIVE TO BASELINE
%% =========================================================

baseline_rpm   = D(1).rpm_1N;
baseline_P     = D(1).P_1N;
baseline_denom = D(1).RPMxPower;
baseline_score = D(1).score;

for k = 1:Ndesigns

    D(k).rpm_change = ...
        100 * (D(k).rpm_1N - baseline_rpm) ...
        / baseline_rpm;

    D(k).power_change = ...
        100 * (D(k).P_1N - baseline_P) ...
        / baseline_P;

    D(k).denom_change = ...
        100 * (D(k).RPMxPower - baseline_denom) ...
        / baseline_denom;

    D(k).score_change = ...
        100 * (D(k).score - baseline_score) ...
        / abs(baseline_score);

end


%% =========================================================
% PRINT RESULTS
%% =========================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('              PROPELLER COMPARISON AT 1 N\n');
fprintf('============================================================\n');

for k = 1:Ndesigns

    fprintf('\n%s\n',upper(D(k).name));

    fprintf('RPM at 1 N      = %.1f rpm\n', ...
        D(k).rpm_1N);

    fprintf('Power at 1 N    = %.4f W\n', ...
        D(k).P_1N);

    fprintf('RPM x Power     = %.1f\n', ...
        D(k).RPMxPower);

    fprintf('Approx. Score   = %.3f\n', ...
        D(k).score);

    if k > 1

        fprintf('RPM change      = %+.2f %%\n', ...
            D(k).rpm_change);

        fprintf('Power change    = %+.2f %%\n', ...
            D(k).power_change);

        fprintf('RPM x P change  = %+.2f %%\n', ...
            D(k).denom_change);

        fprintf('Score change    = %+.2f %%\n', ...
            D(k).score_change);

    end

end


%% =========================================================
% FIND BEST DESIGN
%% =========================================================

scores = [D.score];

[bestScore,bestIndex] = max(scores);

fprintf('\n============================================================\n');
fprintf('BEST DESIGN: %s\n',D(bestIndex).name);
fprintf('Score       : %.3f\n',bestScore);
fprintf('============================================================\n');


%% =========================================================
% COMPARISON TABLE
%% =========================================================

Design = strings(Ndesigns,1);

RPM_at_1N = zeros(Ndesigns,1);
Power_at_1N = zeros(Ndesigns,1);
RPMxPower = zeros(Ndesigns,1);
Mass_g = zeros(Ndesigns,1);
Score = zeros(Ndesigns,1);

RPM_change_pct = zeros(Ndesigns,1);
Power_change_pct = zeros(Ndesigns,1);
RPMxPower_change_pct = zeros(Ndesigns,1);
Score_change_pct = zeros(Ndesigns,1);

for k = 1:Ndesigns

    Design(k) = D(k).name;

    RPM_at_1N(k) = D(k).rpm_1N;
    Power_at_1N(k) = D(k).P_1N;
    RPMxPower(k) = D(k).RPMxPower;

    Mass_g(k) = D(k).mass;
    Score(k) = D(k).score;

    RPM_change_pct(k) = D(k).rpm_change;
    Power_change_pct(k) = D(k).power_change;
    RPMxPower_change_pct(k) = D(k).denom_change;
    Score_change_pct(k) = D(k).score_change;

end


comparisonTable = table( ...
    Design, ...
    RPM_at_1N, ...
    Power_at_1N, ...
    RPMxPower, ...
    Mass_g, ...
    Score, ...
    RPM_change_pct, ...
    Power_change_pct, ...
    RPMxPower_change_pct, ...
    Score_change_pct);

disp(comparisonTable);


%% =========================================================
% OPTIONAL: EXPORT TO EXCEL
%% =========================================================

writetable( ...
    comparisonTable, ...
    'propeller_comparison.xlsx');

fprintf('\nResults saved to propeller_comparison.xlsx\n');


%% =========================================================
% PLOT 1: THRUST vs RPM
%% =========================================================

figure;
hold on;

for k = 1:Ndesigns

    plot( ...
        D(k).rpm, ...
        D(k).T, ...
        'o-', ...
        'LineWidth',1.5);

end

yline(Ttarget,'--','Target = 1 N');

xlabel('RPM');
ylabel('Thrust [N]');

legend(names,'Location','best');

title('Thrust vs RPM');

grid on;


%% =========================================================
% PLOT 2: THRUST vs POWER
%% =========================================================

figure;
hold on;

for k = 1:Ndesigns

    plot( ...
        D(k).P, ...
        D(k).T, ...
        'o-', ...
        'LineWidth',1.5);

end

yline(Ttarget,'--','Target = 1 N');

xlabel('Power [W]');
ylabel('Thrust [N]');

legend(names,'Location','best');

title('Thrust vs Power');

grid on;


%% =========================================================
% PLOT 3: POWER vs RPM
%% =========================================================

figure;
hold on;

for k = 1:Ndesigns

    plot( ...
        D(k).rpm, ...
        D(k).P, ...
        'o-', ...
        'LineWidth',1.5);

end

xlabel('RPM');
ylabel('Power [W]');

legend(names,'Location','best');

title('Power vs RPM');

grid on;


%% =========================================================
% PLOT 4: CT vs RPM
%% =========================================================

figure;
hold on;

for k = 1:Ndesigns

    plot( ...
        D(k).rpm, ...
        D(k).CT, ...
        'o-', ...
        'LineWidth',1.5);

end

xlabel('RPM');
ylabel('C_T');

legend(names,'Location','best');

title('Thrust Coefficient vs RPM');

grid on;


%% =========================================================
% PLOT 5: CP vs RPM
%% =========================================================

figure;
hold on;

for k = 1:Ndesigns

    plot( ...
        D(k).rpm, ...
        D(k).CP, ...
        'o-', ...
        'LineWidth',1.5);

end

xlabel('RPM');
ylabel('C_P');

legend(names,'Location','best');

title('Power Coefficient vs RPM');

grid on;


%% =========================================================
% PLOT 6: CT / CP vs RPM
%% =========================================================

figure;
hold on;

for k = 1:Ndesigns

    plot( ...
        D(k).rpm, ...
        D(k).ratio, ...
        'o-', ...
        'LineWidth',1.5);

end

xlabel('RPM');
ylabel('C_T / C_P');

legend(names,'Location','best');

title('C_T / C_P vs RPM');

grid on;


%% =========================================================
% PLOT 7: RPM x POWER vs THRUST
%% =========================================================

figure;
hold on;

for k = 1:Ndesigns

    plot( ...
        D(k).T, ...
        D(k).denomCurve, ...
        'o-', ...
        'LineWidth',1.5);

end

xline(Ttarget,'--','Target = 1 N');

xlabel('Thrust [N]');
ylabel('RPM \times Power [RPM W]');

legend(names,'Location','best');

title('Score Denominator vs Thrust');

grid on;


%% =========================================================
% PLOT 8: SCORE COMPARISON
%% =========================================================

figure;

bar(categorical(names),scores);

ylabel('Approximate Score');

title('Propeller Score Comparison');

grid on;
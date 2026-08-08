
clc
clear all 

[Full_D, meta] = load_ELFDataBank_2023('Full_ELFDataBank_2023.txt');

% counts = groupcounts(T, "technique_id");
% disp(counts)

%% Extract the data with H2O-air, technique 2, adiabatic flow, circular geometery, mixer ID =6, spacergrid=0

Extracted = Full_D( ...
    Full_D.fluids_id      == 1 & ...   % H2O–air
    Full_D.technique_id   == 2 & ...   % Core sampling
    Full_D.test_id        == 0 & ...   % Adiabatic
    Full_D.geometry_id    == 1 & ...   % Circular tube
    Full_D.mixer_id       == 6 & ...   % Mixer #6
    Full_D.spacergrid_id  == 0 , : );  % No spacer grid

%height(Extracted)

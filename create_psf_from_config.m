function [psf] = create_psf_from_config(config_filename, config_filepath)
%% <placeholder>
%

display_string = strcat('creating new PSF from config file:',{' '},config_filename);
disp(char(display_string));

prev_dir = cd(config_filepath);
psf = PSFGenerator.compute(config_filename);
cd(prev_dir);

%
%%%
%%%%%
%%%
%
%% simulate_psf_image.m
%
%  BEFORE RUNNING: make sure 'PSFGenerator.jar' is on your current MATLAB
%  path by typing the following into the command window:
% 
%  WINDOWS: javaaddpath('C:\Program Files\MATLAB\R2017b\java\PSFGenerator.jar');
% 
%  MAC: javaddpath('/Applications/MATLAB_R2017b.app/java/PSFGenerator.jar');
%  
%  small application to simulate image / set of images w/ same PSFs
%  but varying noise.
%
%  (very) basic process of recording a fluorescence image:
% 
%  (1) fluorophore excitation
%  (2) photon emission
%  (3) photon detection
%  (4) quantification & storage
%
%  2 key sources of imprecision that occur during fluorescence imaging:
% 
%  (1) blurring - light originating from some point cannot be focused back
%                 to a single point
%  (2) noise - random variance throughout captured image, due to randomness
%              of photon emission and imprecise determination of phtons 
%              emitted 
%
%  Blur is mathematically described by a convolution involving the
%  microscope's point spread function (PSF), which essentially acts like a
%  linear filter applied to the data.
% 
%  Points emitting light are replaced by their PSF, scaled according to
%  their individual brightness; where they overlap, detected intensities
%  add together.
%
%  Light originating from some observable point ends up being focused to
%  some larger volume (PSF), which has a minimum size based on light's
%  wavelength and the lens being used.
%  

%% user arguments
%{
% psf_config_filename: filename of <.txt> file compatible with 
%                      PSFGenerator which can be used to generate a
%                      theoretical PSF (default : 'config_NEMO.txt')
%}

psf_config_filename = 'config_NEMO.txt';
psf_config_filepath = cd;

%{
% image_dimesions: 1 x 3 vector containing the dimensions of the simulated
%                  image [x, y, z] in pixels/z-slices 
%                  (default : [512 512 64])
%}

image_dimensions = [512 512 64];

%{
% number of signals: single value indicating number of theoretical PSFs to
%                    insert into the image (default : 1500)
%}

number_of_signals = 1500;

%{
% lower_int_bound: lower bound for intensity manipulation. each PSF is
%                  randomly assigned a scalar value from the distribution
%                  [lower_int_bound, 1] which is applied to the PSF. 
%                  (default : 0.5) (note: arguments <= 0 & > 1 will default
%                  to 0.5)
%}

lower_int_bound = 0.5;

%{
% include_cell: boolean value indicating whether to include a polygon in
%               the image approximating cellular background 
%               (default : True)
%}

include_cell = true;

%{
% signals_in_cell_only: boolean value indicating whether PSFs should only
%                       be placed within the bounds of the polygon 
%                       approximating cellular background (default : True)
%                       (note: set to False if include_cell is False)
%}

signals_in_cell_only = true;

%{
% noise_range: vector of integer values indicating standard deviation of
%              Gaussian noise to add to the image 
%              (default : [50 100 150 200 250 300])
%}

noise_range = [50 100 150 200 250 300];

%{
% output_filename: string indicating what name to save created image / 
%                  set of images under (default : [])
%}

output_filename = [];
output_filepath = cd;

%
%%%
%%%%%%%%%%%%%%%%%%%%%%% DO NOT EDIT PAST THIS POINT %%%%%%%%%%%%%%%%%%%%%%%
%%%
%

%% priming cell, coordinate, intensity info
% 

% breadcrumbs
init_folder = cd;

% create polygon mask if 'include_cell'
if include_cell
    [polygon, simulated_cell_mask] = create_simulated_cell(image_dimensions);
end

% create set of subpixel coordinates. two signals cannot exist in the same
% space within some distance (d). 
if include_cell && signals_in_cell_only
    [subpixel_coordinates] = constrain_randomization(number_of_signals, image_dimensions, polygon);
else
    [subpixel_coordinates] = constrain_randomization(number_of_signals, image_dimensions);
end

% confirm placement of <number_of_signals> given image dimension
% constraints.
if number_of_signals ~= size(subpixel_coordinates, 1)
    disp('unable to insert submitted number of signals given the current constraints.');
    disp(char(strcat('number of signals successfully inserted:',{' '}, num2str(size(subpixel_coordinates, 1)))));
    number_of_signals = size(subpixel_coordinates, 1);
end

% couple subpixel coordinates with values from some intensity distribution
if lower_int_bound <= 0 || lower_int_bound > 1
    lower_int_bound = 0.5;
end
intensity_dist_values = (lower_int_bound).*rand(1, number_of_signals) + lower_int_bound;
psf_coords = [subpixel_coordinates, intensity_dist_values'];

%% inserting PSFs into image at set coordinates/intensities
%

[PSF] = create_psf_from_config(psf_config_filename, psf_config_filepath);

[im32bit, im16bit] = insert_psfs(PSF, image_dimensions, psf_coords, 1000);

% apply cellular mask (additive)
if include_cell
    for i=1:size(im16bit, 3)
        im16bit(:,:,i) = im16bit(:,:,i) + simulated_cell_mask;
    end
end

%% confirming the image looks okay for user
%

figure;
imshow(imadjust(max(im16bit,[],3)));

q1 = {'A maximum intensity projection of the simulated image without',...
    'any Gaussian noise is currently displayed in a separate window.',...
    'Proceed with writing this image to file and any additional images',...
    'which introduce Gaussian noise of [user-defined] standards of deviation?'};
q1 = char(strjoin(q1,' '));
q2 = 'Confirm simulated image.';
q3 = {'Yes','No','Yes'};

answer = questdlg(q1, q2, q3{1}, q3{2}, q3{3});

if strcmp(answer,q3{2})
    tmp_msg = {'Writing simulated image to file terminated. Please',...
        'adjust user arguments as desired and run the process again.'};
    msgbox(char(strjoin(tmp_msg,' ')));
    delete(gcf);
    return;
end

delete(gcf);

%% setting save location
%

if isempty(output_filename)
    [output_filename, output_filepath] = uiputfile('*','Select location to save image(s).');
    if output_filename==0
        % warning dialog
        return;
    end
end

% strip any file extensions off of 'output_filename'
S = strsplit(output_filename, '.');
if length(S) == 1
    root_name = S{1};
else
    root_name = char(strjoin(S(1,1:length(S)-1),'_'));
end

output_filename = char(strcat(root_name,'.tif'));

cd(output_filepath);
if ~exist(root_name, 'dir')
    mkdir(root_name);
    addpath(fullfile(cd, root_name));
else
    addpath(fullfile(cd, root_name));
end
cd(root_name);

%% writing image w/out noise to file
%

tmp_msg = {'writing image to', output_filename};
disp(char(strjoin(tmp_msg,' ')));

for zz=1:size(im16bit, 3)
    imwrite(im16bit(:,:,zz),output_filename,...
        'WriteMode','append');
end

%% writing psf / image information to excel, .mat-file
%

% writing to mat-file
psf_coords(:,1) = psf_coords(:,1) + 0.5;    % true centroid in middle of 4 pix. at center
psf_coords(:,2) = psf_coords(:,2) + 0.5;    % true centroid in middle of 4 pix. at center 
psf_coord_struct = cell2struct(num2cell(psf_coords),...
    {'xCoord','yCoord','zCoord','intFactor'},...
    2);

sim_img_settings = struct;
sim_img_settings.psf_config_filename = psf_config_filename;
sim_img_settings.psf_config_filepath = psf_config_filepath;
sim_img_settings.image_dimensions = image_dimensions;
sim_img_settings.number_of_signals = number_of_signals;
sim_img_settings.lower_int_bound = lower_int_bound;
sim_img_settings.include_cell = include_cell;
sim_img_settings.signals_in_cell_only = signals_in_cell_only;
sim_img_settings.noise_range = noise_range;
if include_cell
    sim_img_settings.cell_polygon_coords = polygon;
else
    sim_img_settings.cell_polygon_coords = [];
end

matfile_out = char(strcat(root_name,'_INFO.mat'));
save(matfile_out, 'psf_coord_struct', 'sim_img_settings','-v7.3');

% writing to excel
psf_info_arr = num2cell(psf_coords);
psf_info_arr = cat(1, fieldnames(psf_coord_struct).', psf_info_arr);
sim_img_info_arr = {};
sim_img_info_fields = fieldnames(sim_img_settings);
for field_idx=1:length(sim_img_info_fields)
    
    next_field = sim_img_settings.(sim_img_info_fields{field_idx});
    if isnumeric(next_field)
        if size(next_field,1) == 1
            next_entry = cat(2,sim_img_info_fields(field_idx),num2cell(next_field));
        else
            next_entry = cat(2, {strcat(sim_img_info_fields{field_idx},'_X');...
                strcat(sim_img_info_fields{field_idx},'_Y')},...
                num2cell(next_field.'));     
        end
    else
        next_entry = cat(2,sim_img_info_fields(field_idx),{next_field});
    end
    
    if isempty(sim_img_info_arr)
        sim_img_info_arr = cat(1, sim_img_info_arr, next_entry);
    else
        if size(next_entry,2) > size(sim_img_info_arr,2)
            padding = size(next_entry,2) - size(sim_img_info_arr,2);
            sim_img_info_arr = cat(2,sim_img_info_arr,cell(size(sim_img_info_arr,1),padding));
            sim_img_info_arr = cat(1,sim_img_info_arr,next_entry);
        elseif size(next_entry, 2) < size(sim_img_info_arr,2)
            padding = size(sim_img_info_arr,2) - size(next_entry,2);
            next_entry = cat(2,next_entry, cell(size(next_entry,1),padding));
            sim_img_info_arr = cat(1,sim_img_info_arr,next_entry);
        else
            sim_img_info_arr = cat(1,sim_img_info_arr, next_entry);
        end
    end
    
end

excel_out = char(strcat(root_name,'_INFO.xlsx'));
xlswrite(excel_out, sim_img_info_arr, 'IMG_SETTINGS');
xlswrite(excel_out, psf_info_arr, 'PSF_COORDS');

%% writing images w/ noise to file
%

if ~isempty(noise_range)
    for nn=1:length(noise_range)

        fprintf('writing image w/ noise taken from dist. w/ %d std (%d/%d)\n',noise_range(nn),nn,length(noise_range));

        % add noise
        std_deviation = noise_range(nn);
        im16bit_with_noise = add_noise(im16bit, std_deviation);

        % save image to file
        tmp_S = {root_name, 'NOISE', 'STD', num2str(std_deviation)};
        output_filename_noisy = char(strcat(strjoin(tmp_S,'_'),'.tif'));
        for zz=1:size(im16bit_with_noise, 3)
            imwrite(im16bit_with_noise(:,:,zz), output_filename_noisy,...
                'WriteMode','append');
        end
        
    end
end

%% wrap-up
%

cd(init_folder);

%
%%%
%%%%%
%%%
%
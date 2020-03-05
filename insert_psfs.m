function [image_32bit,image_16bit] = insert_psfs(psf, image_dims, psf_coords, scalar_val)
%% fxn for inserting theoretical PSFs into some space 
%  
%  Inputs:
%   . image_dimensions -- [x y z]
%   . psf_coords -- [number_of_signals x 3] arr containing [x y z]
%                   coordinates
%   . scalar_val -- value to multiply normalized 32bit image by to get 
%                   16bit image
%  
%  Outputs:
%   . image_32bit -- simulated image w/ [number_of_signals] theoretical
%                    PSFs inserted into it, type 32bit
%   . image_16bit -- simulated image w/ [number_of_signals] theoretical
%                    PSFs inserted into it, type 16bit, normalized from 
%                    original 32 bit image & multiplied by some
%                    [scalar_val]
%

% create theoretical PSF - returned as 32bit object
% disp('creating PSF.');
% psf = PSFGenerator.compute('config_IKK.txt');

% create empty 3D image of given dimensions
simulated_image = int32(zeros(image_dims));

% user update
fprintf('inserting PSFs (%d/%d)\n',0,size(psf_coords,1));

for i=1:size(psf_coords,1)
    
    if mod(i,100) == 0
        fprintf('inserting PSFs (%d/%d)\n',i,size(psf_coords,1));
    end
    
    % get random x,y coordinates, at least 10 pixels in from image border
    x_coord = psf_coords(i,1);
    % x_coord = random_x_values(1,i);
    % x_coord = randi([10 image_dims(1,1)-10],1,1);
    % assignin('base','xx',x_coord);
    y_coord = psf_coords(i,2);
    % y_coord = random_y_values(1,i);
    % y_coord = randi([10 image_dims(1,2)-10],1,1);
    % assignin('base','yy',y_coord);
    % get random z coordinate, at least > 1 and less than (image depth)-1
    z_coord = psf_coords(i,3);
    % z_coord = random_z_values(1,i);
    % z_coord = randi([2 image_dims(1,3)-1],1,1);        
    % assignin('base','zz',z_coord);
    
    % psf (as defined in config_IKK.txt) will be 256 x 256 x 65
    % assign at axial midpoint, which occurs at z=33
    psf_lim_x = [1,size(psf,1)];
    psf_lim_y = [1,size(psf,2)];
    psf_lim_z = [];
    z_start = 0;
    z_end = 0;
    
    % center of PSF (as defined in config_IKK.txt) will be a 2x2 px region,
    % w/ upper right corner of coordinates (imheight/2,imwidth/2)
    % center of PSF is technically in center of this 2x2 grid, but pixels
    % can't have non-integer locations. so, need to confirm limits 
    % for the randomized coordinates using upper right corner, then extend
    % ((dimension/2)-1) in one direction and (dimension/2) in the other,
    % for both x and y limits. 
    
    %xlim
    lower_lim_x = x_coord - 127;
    if lower_lim_x <= 0
        psf_lim_x(1,1) = psf_lim_x(1,1) + (1 + (lower_lim_x*-1));
        lower_lim_x = 1;
    end
    upper_lim_x = x_coord + 128;
    if upper_lim_x > image_dims(1,1)
        psf_lim_x(1,2) = psf_lim_x(1,2)-(upper_lim_x-image_dims(1,1));
        upper_lim_x = image_dims(1,1);
    end 
    
    %ylim
    lower_lim_y = y_coord - 127;
    if lower_lim_y < 1
        psf_lim_y(1,1) = psf_lim_y(1,1) + (1 + (lower_lim_y*-1));
        lower_lim_y = 1;
    end
    upper_lim_y = y_coord + 128;
    if upper_lim_y > image_dims(1,2)
        psf_lim_y(1,2) = psf_lim_y(1,2)-(upper_lim_y-image_dims(1,2));
        upper_lim_y = image_dims(1,2);
    end
    
    % NOTE - zlim should be rewritten to base measurements on where maximum
    % intensity value within the theoretical PSF, regardless of model,
    % appears
    
    %zlim
    mid_axial = round(size(psf,3)/2);
    loc_im_z = [];
    loc_psf_z = [];
    if z_coord < mid_axial
        lower_dist = z_coord - 1;
        upper_dist = z_coord + 32;
        psf_start_z = mid_axial - lower_dist;
        psf_end_z = mid_axial + 32;
        loc_im_z = [1 upper_dist];
        loc_psf_z = [psf_start_z psf_end_z];
    else
        lower_dist = z_coord - 32;
        upper_dist = image_dims(1,3)-z_coord;
        psf_start_z = mid_axial - 32;
        psf_end_z = mid_axial + upper_dist;
        loc_im_z = [lower_dist image_dims(1,3)];
        loc_psf_z = [psf_start_z psf_end_z];
    end
    
    im_linspace = loc_im_z(1,1):loc_im_z(1,2);
    psf_linspace = loc_psf_z(1,1):loc_psf_z(1,2);

    bright_factor = psf_coords(i,4);
    % bright_factor = intensity_dist_values(1,i);
    
    %
    for j=1:length(im_linspace)
        simulated_image(lower_lim_x:upper_lim_x,lower_lim_y:upper_lim_y,im_linspace(1,j)) = simulated_image(lower_lim_x:upper_lim_x,lower_lim_y:upper_lim_y,im_linspace(1,j)) + psf(psf_lim_x(1,1):psf_lim_x(1,2),psf_lim_y(1,1):psf_lim_y(1,2),psf_linspace(1,j))*bright_factor;
    end
    %
    
end

% simulated_image is 32 bit
image_32bit = simulated_image;

% converting 32bit image to 16bit, based on scalar val supplied by user
image_16bit = uint16(zeros(size(image_32bit)));
image_max = max(max(max(image_32bit,[],3)));
for i=1:size(image_32bit,3)
    slice_double = double(image_32bit(:,:,i));
    image_16bit(:,:,i) = uint16((slice_double/double(image_max))*scalar_val);
end

%
%%%
%%%%%
%%%
%
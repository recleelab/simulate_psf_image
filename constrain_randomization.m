function [subpixel_coords] = constrain_randomization(num_signals,image_dim,sim_cell)
%% testbed for constrained randomization
%  
%  need manner to constrain the randomization JUST ENOUGH.
%  signals at their peak look like crosses, the centroid in the middle of a
%  2 x 2 grid w/ ~2 pixels extending out at each side
% 
%           0   0   0   0   0   0   0   0   0   0
%           0   0   0   0   1   1   0   0   0   0
%           0   0   0   1   1   1   1   0   0   0
%           0   0   0   1   1   1   1   0   0   0
%           0   0   0   0   1   1   0   0   0   0
%           0   0   0   0   0   0   0   0   0   0
%
%  the idea is to constrain randomization in a manner which prevents two
%  signals occupying a space in which they wouldn't be able to physically
%  occupy. based on the pixel space the PSF's peak occupies, when comparing
%  insertion of point (xi,yi,zi) to old point (x,y,z), (xi,yi)'s distance
%  to (x,y) are only relevant if zi = z+/-3 (typical spanning z-space). 
%  
%  INPUT:
%  .  num_signals - number of signals to insert
%  .  image_dim - simulated image dimensions [x,y,z]
%  (optional)
%  .  sim_cell - polygon vertices [x y] denoting created cell.
%                only passed into argument if signals' sub-
%				 pixel coordinates should be constrained to
% 				 the cell.
%  
%  OUTPUT:
%  .  subpixel_coords - [x y z] double denoting theoretical PSF
%                       subpixel placement given the inputted 
%                       constraints.

consider_polygon = 0;

if (nargin > 2)
	disp('cell found');
	% limit x and y random seed using sim cell
	rand_xlim = [min(sim_cell(:,1)),max(sim_cell(:,1))];
	rand_ylim = [min(sim_cell(:,2)),max(sim_cell(:,2))];
	consider_polygon = 1;
else
	% limit x and y random seed using image_dims
	rand_xlim = [10 image_dim(1,1)-10];
	rand_ylim = [10 image_dim(1,2)-10];
end

subpixel_coords = zeros(1,3);

% need to delineate - two separate loops, one if cell is being considered
% and another if a cell isn't being considered.
if consider_polygon
	disp('considering polygon');
	sig_in_poly = false;
	while sig_in_poly == false
		subpixel_coords(1,1) = randi(rand_xlim,1,1);
		subpixel_coords(1,2) = randi(rand_ylim,1,1);
		subpixel_coords(1,3) = randi([2 image_dim(1,3)-1],1,1);
		
		if inpolygon(subpixel_coords(1,1),subpixel_coords(1,2),sim_cell(:,1),sim_cell(:,2))
			sig_in_poly = true;
		end		
	end
	
	for i=2:num_signals
		sig_in_poly = false;
		try_count = 1;
		while sig_in_poly == false
			new_coordinate = [randi(rand_xlim,1,1),...
				randi(rand_ylim,1,1),...
				randi([2 image_dim(1,3)-1],1,1)];
			if inpolygon(new_coordinate(1,1),new_coordinate(1,2),sim_cell(:,1),sim_cell(:,2))
				% check distance
				[k,d] = dsearchn(subpixel_coords,new_coordinate);
				if d > 3
					subpixel_coords = cat(1,subpixel_coords,new_coordinate);
					try_count = 1;
					sig_in_poly = true;
				else
					try_count = try_count + 1;
					if try_count > 500
						disp('unable to find new valid subpixel coordinate.');
						disp('new number of PSFs:');
						disp(length(psf_coords));
						break;
					end
				end
			end
		end
	end
	
else
	disp('ignoring cell.');
	subpixel_coords(1,1) = randi(rand_xlim,1,1);
	subpixel_coords(1,2) = randi(rand_ylim,1,1);
	subpixel_coords(1,3) = randi([2 image_dim(1,3)-1],1,1);
	
	try_count = 1;
	for i=2:num_signals
		disp(i);
		new_coordinate = [randi(rand_xlim,1,1),...
			randi(rand_ylim,1,1),...
			randi([2 image_dim(1,3)-1],1,1)];
		[k,d] = dsearchn(subpixel_coords,new_coordinate);
		while (d < 3) && try_count < 500
			% disp(strcat(num2str(i),{' '},'and in while loop'));
			new_coordinate = [randi([10 image_dim(1,1)-10],1,1),...
				randi([10 image_dim(1,2)-10],1,1),...
				randi([2 image_dim(1,3)-1],1,1)];
			[k,d] = dsearchn(subpixel_coords,new_coordinate);
			try_count = try_count + 1;
		end
		
		if try_count > 500
			break;
		end
		subpixel_coords = cat(1,subpixel_coords,new_coordinate);
		try_count = 1;
	end
end






%
%%%
%%%%%
%%%
%
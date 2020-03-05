function [polygon_vertices, poly_mask_16bit] = create_simulated_cell(image_dimensions)
%% fxn to handle creation of set of vertices of simulated
%  cell background.
%  
%  INPUT:
%  .  image_dimensions - [x y z] double dimensions of image 
% 						 cell will be inserted into.
%  
%  OUTPUT:
%  .  polygon_vertices - [x y] double vertices of created polygon
%						 ordered 1:end counterclockwise. last vertex
% 						 is equal to the first entry.
%  .  poly_mask_16bit - [image_dimensions(1,1),image_dimensions(1,2)] double
%						which can be added to image to simulate cell background
%						as defined by the created vertices.

% x,y upper limits
im_width = image_dimensions(1,1);
im_height = image_dimensions(1,2);

% number of initial vertices
num_vertices_seed = 15;

% get set of random points
rand_x = randi([1 im_width],1,num_vertices_seed);
rand_y = randi([1 im_height],1,num_vertices_seed);

% convhull returns indices of coordinates w/in set
% which create convhull. indexed counterclockwise.
convhull_result = convhull(rand_x,rand_y);
for i=1:size(convhull_result,1)
	polygon_vertices(i,:) = [rand_x(convhull_result(i)),rand_y(convhull_result(i))];
end

% NOTE: sub-pixel placement of theoretical PSFs is done 
% with (y,x,z), so to create a mask which places cell background
% exclusively where the PSFs are, polygon x and y coordinates 
% must be swapped.
polygon_coords = [polygon_vertices(:,2),polygon_vertices(:,1)];

% creating edges between each polygon vertex and the polygon centroid
poly_centroid = [mean(polygon_coords(:,1)),mean(polygon_coords(:,2))];
edge_arr = cell(1,size(polygon_coords,1));
for i=1:size(polygon_coords,1)
	
	% quartering the lines radiating out from the center of the polygon 
	tmp_line_x = linspace(poly_centroid(1,1),polygon_coords(i,1),5);
	tmp_line_y = linspace(poly_centroid(1,2),polygon_coords(i,2),5);
	
	% use 2nd value from linspace and poly_coords(i,:) as endpoint,
	% gradually move inwards from poly_coord(i,:) using linspace
	edge_pts_x = linspace(polygon_coords(i,1),tmp_line_x(1,3),50);
	edge_pts_y = linspace(polygon_coords(i,2),tmp_line_y(1,3),50);
	edge_arr{1,i} = [round(edge_pts_x'),round(edge_pts_y')];
	
end

% edges created along each 'triangle' (centroid,v1,v2) now converted to
% single mask which can be applied to the image later.
poly_masks = cell(1,size(edge_arr{1,1},1));
for i=1:size(edge_arr{1,1},1)
	tmp_patch = zeros(size(polygon_coords));
	for j=1:size(edge_arr,2)
		tmp_edge = edge_arr{1,j};
		tmp_patch(j,:) = tmp_edge(i,:);
	end
	poly_masks{1,i} = poly2mask(tmp_patch(:,1),tmp_patch(:,2),im_width,im_height);
end

mock_cell = uint16(zeros(im_width,im_height));
for i=1:size(poly_masks,2)
	curr_mask = poly_masks{1,i};
	if i==1
		% assign base background intensity value for cell. 
		mock_cell(curr_mask) = mock_cell(curr_mask) + uint16(100);
	else
		% increase that base value as you move towards center 
		% of cell, eventually plateauing halfway between the 
		% centroid and outer edge
		mock_cell(curr_mask) = mock_cell(curr_mask) + uint16(5);
	end
end

% finally, apply gaussian filter to blur cell slightly, make it look 
% more realistic and less regimented.
poly_mask_16bit = imgaussfilt(mock_cell);

%
%%%
%%%%%
%%%
%
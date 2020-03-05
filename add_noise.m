function [resulting_image] = add_noise(image16bit,std_deviation)
%% 
%  

%% fxn for adding noise to entire 16 bit image
% essentially just taking the normal gaussian distribution, randomly
% selecting values from the distribution, and adding them to every pixel
% within the simulated image. afterwards, per slice, if (pixel < 0), pixel
% == 0
% 
% need 2 parameters - mu, sigma
% mu = 0;
% sigma = ? (still figuring it out, need to examine real images in imagej

mu = 0;
% normal_dist = makedist('normal',mu,std);

for i=1:size(image16bit,3)
    % fill temporary matrix w/ dist values
    tmp_dist_values = uint16(std_deviation.*randn(size(image16bit,1),size(image16bit,2)) + mu);
    image_plus_noise = image16bit(:,:,i) + tmp_dist_values;
    image_plus_noise(image_plus_noise < 0) = 0;
    resulting_image(:,:,i) = image_plus_noise;
end


% BREAKING DOWN THE CODE FROM IMAGEJ
%{
if (rnd==null)
	rnd = new Random();
if (!Double.isNaN(seed))
	rnd.setSeed((int) seed);
seed = Double.NaN;
% ^^ basically cleaning out the random number generator ^^
int v, ran;
boolean inRange;
for (int y=roiY; y<(roiY+roiHeight); y++) {
	int i = y * width + roiX;
	for (int x=roiX; x<(roiX+roiWidth); x++) {
		inRange = false;
		do {
			ran = (int)Math.round(rnd.nextGaussian()*standardDeviation);
			v = (pixels[i] & 0xffff) + ran;
			inRange = v>=0 && v<=65535;
			if (inRange) pixels[i] = (short)v;
		} while (!inRange);
		i++;
	}
}
%}

%
%%%
%%%%%
%%%
%
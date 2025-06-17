function [visang_deg] = Visual_Angle (screenwidth, totdist)
%
%   [visang_deg] = Visual_Angle (screenwidth, totdist)
%  
%   visang_deg = visual angle in deg
%   Screenwidth = width of screen in
%   totdist = is viewing distance to screen (take care to use same unit as width)
%
%   written by: Tessa Dekker 16-3-2015 t.dekker@ucl.ac.uk


visang_rad = 2 * atan(screenwidth/2/totdist);
visang_deg = visang_rad * (180/pi);


end
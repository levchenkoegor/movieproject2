height_pix = 1080;
height_deg = 42.6; 
pixperdeg = height_pix/height_deg;

radius = [height_pix/2 0];
sector = [-180 180];
thchsz = 10; % 1/SF; % thchsz = wedge width - bigger number less checks per visible wedge =  Angle_per_Vol/Parameters.ChecksAng
rchsz = 3.2; % rchsz = ring width (deg) - bigger number more checks per visible ring = Eccentricity_per_Vol*Parameters.ChecksEcc)
chsz = [rchsz thchsz];

Cycles_per_Expmt = [4 3]; % Nrepetion of same polar angle and same eccentricity per block: multiplying these numbers with the first two from Volumes_per_Cycle must result in the same number!
Volumes_per_Cycle = [360/chsz(2) 360/chsz(2)*Cycles_per_Expmt(1)/Cycles_per_Expmt(2) 20]; % Angle Wedge per step, Eccentricity Ring per step, Blanks
Wedges = repmat(1:Volumes_per_Cycle(1), 1, Cycles_per_Expmt(1))';
Rings = repmat(1:Volumes_per_Cycle(2), 1, Cycles_per_Expmt(2))';

StimRect = [0 0 repmat(height_pix, 1, 2)];
Eccentricity_per_Vol_oneCycle = StimRect(3) * exp(-4+4/Volumes_per_Cycle(2):4/Volumes_per_Cycle(2):0)'; % log steps from small to 1
Eccentricity_per_Vol = Eccentricity_per_Vol_oneCycle(Rings);
Angle_per_Vol_oneStep = 360/Volumes_per_Cycle(1);  
Angle_per_Vol = Wedges .* Angle_per_Vol_oneStep - Angle_per_Vol_oneStep*2 + 90;

checkerboard = [0 1; 1 0];
img = ones(2*radius(1), 2*radius(1)) * 0.5;

for x = -radius : radius 
    for y = -radius : radius 
        [th,r] = cart2pol(x,y);
        th = th * 180/pi;     
        if th >= sector(1) && th < sector(2) && r < radius(1) && r > radius(2)
            img(y+radius(1)+1,x+radius(1)+1) = checkerboard(mod(floor(log(r)*chsz(1)),2) + 1, mod(floor((th + sector(1))/chsz(2)),2) + 1);
        end
    end
end

img = flipud(img);

close all
figure;
imagesc(img);axis square;

figure;
polarscatter(Angle_per_Vol,Eccentricity_per_Vol,10,'w')
for i = 1:length(Angle_per_Vol)
    hold on
    polarscatter(Angle_per_Vol(i),Eccentricity_per_Vol(i))
    rlim([0 max(Eccentricity_per_Vol)])
    pause(0.2)
end
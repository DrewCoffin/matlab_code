function[] = torus_plots(type, species, property, specified_day, vec_on, n)

%{
species = input('Species? ', 's');
property = input('Property? ', 's');
dayalpha = input('First day to plot? ');
dayomega = input('Last day to plot? ' );
specified_day = dayalpha:dayomega;
vec_on = input('Vector field? [1/0] ');
normin = input('Normalization? ', 's');

if strcmp(normin, 'y') == 1
    n = 'norm';
else n = normin;
end
%}

close all
format long
restoredefaultpath %Resets Path
hFig = figure; %Opens blank Figure

%%%%%%%%%%%ENTER PATH TO THE 2D MODEL FOLDER HERE%%%%%%%%%%%%%%%%
strtpath = '/home/dcoffin/2D_Model-master/plots/data/';  %Your saved 2D_Model-master location
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%ENTER PATH TO THIS TORUS PLOTS FOLDER HERE%%%%%%%%%%%%
f_path = '/home/dcoffin/torus_plots-master/torus_plots/functions';  %Your saved torus_plots location
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
addpath(genpath(f_path)); %Adds a path to all functions used for plotting
addpath(genpath(strtpath));
[folder,nl2folder] = folders(property,species,strtpath,f_path); %Adds all necessary paths and folder locations
species_save = species; %Saves species argument
property_save = property; %Saves property argument


%SIZE OF MODEL RUN
[lng,rad] = FindDimensions(strtpath);

%Added Paths=


%[min_value, max_value] = min_max_calc(specified_day,lng,rad,folder); %Calculates minimum and maximum values of data


%Creates Directories for output plots
mkdir(strcat(strtpath,'../../../output_plots'));
mkdir(strcat(strtpath,'../../../output_plots/images'));
mkdir(strcat(strtpath,'../../../output_plots/images/',species,'_',property));
mkdir(strcat(strtpath,'../../../output_plots/videos'));


%AVI initialization
filename = strcat(species, property, 'map.avi'); %Filename for movie
video_folder = strcat(strtpath,'../../../output_plots/videos/',filename); %Folder Path for Movie
writerObj = VideoWriter(video_folder);
writerObj.FrameRate = 5; %Changes framerate for output avi
open(writerObj);


for day = specified_day
    if strcmp(type,'plt') == 1
        c = -lng; %Initilizer for index counting
        v = 0; %Initilizer for index counting
        
        data = load(folder(day).name); %Loads current data file according to day
        for bin = 1:rad;
            c = c + lng + 1; %Index Counting
            v = v + lng +1; %Index Counting
            
            new_data = data(c:v,:); %Selected Data
            new_data(lng+1,1) = 360; %Changes last longitudinal bin to 360 degrees
            theta = new_data(:,1); %Selects Longitude Position
            value = new_data(:,2); %Selects Value
            radius = new_data(1,3); %Selects Radial Position
            h(bin) = subplot_tight(rad/2,2,bin,[0.05 0.05]); %Creates space for plot
            plot(theta,value); %Plots Psychedelic Figures
            colormap(jet(day)); %Changes colormap in accordance to day
            title(strcat('L = ', num2str(radius))); %Adds title to subplot
            axis([0 360  min(min_value(:,bin)) max(max_value(:,bin))]); %Axes parameters
            drawnow;
            hold on
        end
    else
        species = species_save; %Grabs saved species
        property = property_save; %Grabs saved property
        %s3pfile = dir(strcat(strtpath,'/plots/data/s3p/', property, '/', property, 's3p', '*_3D.dat'));
        data = load(folder(day).name); %Loads current data file according to day
        %data2 = load(s3pfile(day).name);
        if strcmp(n, 'norm') == 1
            %[norm_values] = normalize_values(data,data2,lng,rad); %Normalizes values on 0-1 scaling
            [norm_values] = normalize_values(data,lng,rad); %Normalizes values on 0-1 scaling
            value = norm_values; %Sets to normalized values
        elseif strcmp(n(1:3), 'bef') == 1  %Normalizes via first N days, user supplies N
            totalnorm = zeros((rad*(lng+1)),1);
            lastday = str2num(n(7:9));
            for daypast = 1:lastday
                datapast = load(folder(daypast).name);
                totalnorm = totalnorm + datapast(:,2);
            end
            pastavg = totalnorm/lastday;
            %pastavg(1:5)
            normdata = data;
            for i = 1:length(data)
                normdata(i,:) = data(i,:)/pastavg(i);
            value = normdata(:,2);
            end       
            %preerupt_values = rot90(preerupt_values,-1);    %Rotates the data set in order for torus_plots to read.
            else
                value = data(:,2); %Sets to non-normalized values
        end
        
        nl2data = load(nl2folder(day+1).name); %Loads nl2 data file according to day
        nl2current = zeros(lng+1,1,rad); %Preallocation for nl2 values
        theta = data(:,1)*(pi/180); %Selects Azimuthal position and converts to radians
        radius = data(:,3); %Selects Radial position


        [radial_max_data,nl2current,nl2currentradius] = max_data(data,nl2data,rad,lng,vec_on); %Finds maximum value for each radial bin
        ...and selects nl2 value for transport calculation
            dimension = size(value); %Finds Matrix dimensions of value set
        radial_dimension = dimension(1,1)/2;
        
        if vec_on == 1
            [rad_velocity, vaz_vel] = calculateTransport(nl2current, nl2currentradius, strtpath, rad, lng); %Calculates radial and azimuthal transport
        end
        
        
        [x,y,c] = pol2cart(theta, radius, value);
        
        X = reshape(x,lng+1, rad);
        Y = reshape(y,lng+1, rad);
        C = reshape(c,lng+1, rad);
        clf
        
        pcolor(X,Y,C); %Plots color map of Torus
        
        set(gca,'YDir', 'reverse') %Flips Torus plot
        set(gcf, 'Position', [350, 150, 730, 650]);
        shading interp
        hold on
        
        %{
        xend = 6.*cos(0:0.0001:2*pi); %Cuts off edges made from azimuthal resolution
        yend = 6.*sin(0:0.0001:2*pi); %Cuts off more edges
        plot(xend,yend,'w','LineWidth',2) %Does said cutting
        
        xend2 = 12*cos(0:0.0001:2*pi);%Cuts off edges made from azimuthal resolution
        yend2 = 12*sin(0:0.0001:2*pi);%Cuts off more edges
        plot(xend2,yend2,'w','LineWidth',2)%Does said cutting
        %}
  
        hold on
        w = warning ('off','all');
        %PlotAxisAtOrigin(x,y); %Plots an axis on top of the torus, centered at the origin.
        warning(w)
        hold on
        hC = colorbar('FontSize',12); %Adds colorbar for values
        if strcmp(n(1:3), 'bef') == 1 %Forced colorbar for past normalized plots
            highion = {'s2p', 'o2p', 's3p'};
            if any(strcmp(highion, species)) == 1
               caxis([0.7, 3])
            else
            caxis([0.7,2.5]) 
            end
        end
        %hC.FontSize = 12;
        
        colormap(jet) %Sets a nice rainbow colormap
        
        
        hold on
        
        
               % h = polar((radial_max_data(:,1)*(pi/180))+pi/18,radial_max_data(:,3), '.'); %Overlays white points of
               % ...maximum value in each radial bin
               %    set(h,'markersize', 25);
               % set(h, 'color', 'w');
        
        labels(species, property, day, n) %Adds labels of species, property, and day.
        %drawnow
        
        %Vector Field calculation
        if vec_on == 1
            vectorfield(rad,lng,theta,radius,rad_velocity,vaz_vel,data); %Overlays a velocity vector field
            ...(This may need some working on).
        end
    
    %Leading Zeros used to account for lexicographic file ordering.
    if length(num2str(day)) == 1
        leading_zero = '00';
    end
    if length(num2str(day)) == 2
        leading_zero = '0';
    end
    if length(num2str(day)) == 3
        leading_zero = '';
    end
    
    frame = getframe(hFig); %Grabs current frame
    [G,map] = frame2im(frame); %Converts frame to image
    image_file = strcat(strtpath,'../../../output_plots/images/',species,'_',property,'/',leading_zero,num2str(day),'.jpg');
    imwrite(G,image_file); %Saves image as a .jpg
    writeVideo(writerObj, frame); %Writes frame to avi
    species = species_save; %Resets species name (May not be needed).
    
    end
    
    
end
close(writerObj); %Closes video writing
hold off
image_folder = strcat(strtpath, '../../../output_plots/images/',species,'_',property,'/');
slider_plot(image_folder);
addpath(genpath(strcat(f_path,'/../')));
end
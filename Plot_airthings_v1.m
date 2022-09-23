%% init
clc
clear
close all hidden

disp('----------------------')
disp('Airthings Wave plotter')
disp('Angel Rodes, 2022')
disp('www.angelrodes.com')
disp('----------------------')
disp('Downlaod csv from:')
disp('    https://dashboard.airthings.com/devices/')

%% Select file

% first check if this is my computer
[ret, name] = system('hostname');

if strcmp(name(1:15),'angel-EliteBook')==1
    mylaptop=1;
else
    mylaptop=0;
end

% if this is my computer, select the youngest csv file in Downloads. If not, ask for file. 

if mylaptop % find in Angel's laptop
    path='/home/angel/Downloads/';
    d= dir('/home/angel/Downloads/*.csv');
    [~, index]   = max([d.datenum]);
    youngestFile = fullfile(d(index).folder, d(index).name);
    file=d(index).name;
else % ask the user to select the file downloaded
    [file,path] = uigetfile({'*.csv'}, 'Select input file (csv)');
end
selectedfile = fullfile(path,file);
[filedir, filename, fileext] = fileparts (selectedfile);

%% load data

fid = fopen(selectedfile);

disp(['File: ' selectedfile])

% recorded;RADON_SHORT_TERM_AVG Bq/m3;TEMP °C;HUMIDITY %;PRESSURE hPa;CO2 ppm;VOC ppb
mydata = textscan(fid, '%s %f %f %f %f %f %f ',...
    'HeaderLines', 1,'Delimiter',';');
fclose(fid);
timestrings=mydata{1};
Rn=mydata{2};
T=mydata{3};
H=mydata{4};
P=mydata{5};
CO2=mydata{6};
VOC=mydata{7};

disp(['Last update: ' timestrings{end}])


% get times 'yyyy-MM-ddTHH:mm:ss'
for n=1:numel(timestrings)
    thiscell=timestrings(n);
    string=thiscell{1};
    yyyy=str2double(string(1:4));
    MM=str2double(string(6:7));
    dd=str2double(string(9:10));
    HH=str2double(string(12:13));
    mm=str2double(string(15:16));
    ss=str2double(string(18:19));
    year_month_day_hour(n,1:4)=[yyyy,MM,dd,HH]; % plotting purposes
    if mod(yyyy,4)==0 % check lap year
        days_in_month=[31,29,31,30,31,30,31,3130,31,30,31];
    else
        days_in_month=[31,28,31,30,31,30,31,3130,31,30,31];
    end
    % approx posix times
    posix_time(n)=...
        (yyyy-1970)*365.25*24*60*60+...
        (sum(days_in_month(1:MM))-days_in_month(MM))*24*60*60+...
        dd*24*60*60+...
        HH*60*60+...
        mm*60+...
        ss;
    if n>1 && n<numel(timestrings)
        if dd~=previousday
            newday(n)=1;
        else
            newday(n)=0;
        end
    else
        newday(n)=1;
    end
    previousday=dd;
end

% decide how many "new days" to show
while sum(newday)>10 % if there are more than 8 days
    newday(mod(cumsum([newday,1]),2)>0)=0; % reduce the number of ticks by 2
end
newday(end)=1; % always show last
newday(1)=1; % always show first

% define limits
answer = inputdlg('How many days back?','Days',1,{num2str(sum(newday))});
if ~isempty(answer)
    daysback=str2double(answer);
else
    daysback=sum(newday);
end

posix_time_limits=[max(min(posix_time),max(posix_time)-daysback*24*60*60) max(posix_time)];
Rn_limits=[0 max(max(Rn)+10,100)];
T_limits=[min(T)-0.5 max(T)+0.5];
H_limits=[0 100];
P_limits=[min(P)-range(P)/10 max(P)+range(P)/10];
CO2_limits=[min(min(CO2)-10,400) max(CO2)+10];
VOC_limits=[0 max(max(VOC)+10,100)];


%% plot stuff

figure('units','normalized','outerposition',[0 0 1 1],'Name','Airthings Wave raw data')
set(gcf,'color','w');
hold on

plotvalues=[{'Rn'},{'VOC'},{'CO2'},{'T'},{'H'},{'P'}];
plottitles=[{'Rn [Bq/m^3]'},{'VOCs [ppb]'},{'CO_2 [ppm]'},{'T [^oC]'},{'H [%]'},{'P [hPa]'}];

for plot_number=1:6
eval(['values=' plotvalues{plot_number} ';']);
eval(['values_limits=' plotvalues{plot_number} '_limits;']);
title_string=plottitles{plot_number};

% plot
subplot(7,1,plot_number)
hold on
valid=~isnan(values);
plot(posix_time(valid),values(valid),'-b','LineWidth',2)

xlim(posix_time_limits)
ylim(values_limits)



box on
grid on

ylabel(title_string)

% xticks(posix_time(newday==1))

% if plot_number==6
%     xticklabels(timestrings(newday==1))
% else
    xticklabels([])
% end
% xtickangle(15)

% if plot_number==1
%     title('Airthings Wave raw data')
% end
end

% timestamps
subplot(7,1,7)
hold on
for n=1:size(year_month_day_hour,1)
    if n==1
        for j=1:4
            text(posix_time(n),5-j,num2str(year_month_day_hour(n,j)),'Color','b')
        end
    elseif n<size(year_month_day_hour,1)
        for j=1:4
            if year_month_day_hour(n,j)~=year_month_day_hour(n-1,j)
                text(posix_time(n),5-j,num2str(year_month_day_hour(n,j)),'Color','b')
            end
        end
    else
        for j=1:4
            text(posix_time(n),5-j,num2str(year_month_day_hour(n,j)),'Color','b')
        end
    end
end
text(min(posix_time_limits),4,'Year ', 'HorizontalAlignment', 'right','Color','k')
text(min(posix_time_limits),3,'Month ', 'HorizontalAlignment', 'right','Color','k')
text(min(posix_time_limits),2,'Day ', 'HorizontalAlignment', 'right','Color','k')
text(min(posix_time_limits),1,'Hour ', 'HorizontalAlignment', 'right','Color','k')
xlim(posix_time_limits)
ylim([0 4])
xticklabels([])
yticks([])
yticklabels([])
grid on
set(gca, 'YColor','w');

pause(3)
waitforbuttonpress () % do not close if started as a pipe (eg: wget -O - https://raw.githubusercontent.com/angelrodes/Airthings_plotter/main/Plot_airthings_v1.m | octave)


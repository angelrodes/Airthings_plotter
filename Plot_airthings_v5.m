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
elseif strcmp(name(1:14),'angel-Inspiron')==1
    mylaptop=2;
else
    mylaptop=0;
end

% if this is my computer, select the youngest csv file in Downloads. If not, ask for file.

if mylaptop>0 % find in Angel's laptop
    if mylaptop==1
        path='/home/angel/Downloads/';
        d= dir('/home/angel/Downloads/*.csv');
    else
        path='/home/angel/Descargas/';
        d= dir('/home/angel/Descargas/*.csv');
    end
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
h = waitbar(0,'Getting times from file...');
for n=1:numel(timestrings)
  waitbar(n/numel(timestrings),h)
    thiscell=timestrings(n);
    string=thiscell{1};
    if numel(string)>18
        yyyy=str2double(string(1:4));
        MM=str2double(string(6:7));
        dd=str2double(string(9:10));
        HH=str2double(string(12:13));
        mm=str2double(string(15:16));
        ss=str2double(string(18:19));
        day_in_week(n)=weekday([string(1:4) '/' string(6:7) '/' string(9:10)]); % 1: Sunday , 2: Monday , etc.
    else % if there is somthing wring with the date string
        mm=mm+5; % just add 5 minutes
        VOC(n-1)=NaN; % and remove last data (probably taken from the begining of the date string)
        day_in_week(n)=day_in_week(n-1);
    end
    
    year_month_day_hour(n,1:4)=[yyyy,MM,dd,HH]; % plotting purposes
    
    if mod(yyyy,4)==0 % check lap year
        days_in_month=[31,29,31,30,31,30,31,31,30,31,30,31];
    else
        days_in_month=[31,28,31,30,31,30,31,31,30,31,30,31];
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
close(h)

% % decide how many "new days" to show in the grid
% while sum(newday)>10 % if there are more than 8 days
%  newday(mod(cumsum([newday,1]),2)>0)=0; % reduce the number of ticks by 2
%end
newday(end)=1; % always show last
newday(1)=1; % always show first

% interpolate to have Rn data every 5 minutes
posix_time_every5min=min(posix_time):300:max(posix_time);
valid=~isnan(Rn);
Rn_every5min=interp1(posix_time(valid),Rn(valid),posix_time_every5min,'linear','extrap')';

%% Undo the Rn 24h average (inverse moving average)
% step=0;
% N=23*60*60/median(diff(posix_time_every5min)); % number of readings in the moving average time (24h)
Rn2_every5min=zeros(size(Rn_every5min))*NaN;
% Rn_index=find(~isnan(Rn_every5min))';
h = waitbar(0,'Calculating 1h Radon data...');
for n=find(~isnan(Rn))'
    waitbar(n/max(find(~isnan(Rn))),h);
%     step=step+1;
%     if Rn_index(step)~=n
%         warning(['Wrong index ' num2str(n) ' in step=' num2str(step) ]) % check indexes
%     end
    
    objective_average=Rn(n);
    last_24h_index_every5min=(posix_time_every5min<posix_time(n) & posix_time_every5min>posix_time(n)-24*60*60)';
    previous_24h_data=Rn2_every5min(last_24h_index_every5min & ~isnan(Rn2_every5min));
    step_data=Rn2_every5min(last_24h_index_every5min & isnan(Rn2_every5min));
    step_value=(...
        objective_average*(numel(previous_24h_data)+numel(step_data))-...
        sum(previous_24h_data))/...
        numel(step_data);
    step_value=max(0,step_value); % avoid negative data
    Rn2_every5min(last_24h_index_every5min & isnan(Rn2_every5min))=step_value;
end
close(h)

% calculate the moving average
y=Rn2_every5min';
yy=Rn2_every5min';
span=3*60*60/median(diff(posix_time_every5min));
moving_av_label='3h moving average';
if mod(span,2)==0
    span=span+1;
end
for i=1:length (y)
    if (i <= (span-1)/2)
        %% We're in the beginning of the vector, use as many y values as
        %% possible and still having the index i in the center.
        %% Use 2*i-1 as the span.
        idx1 = 1;
        idx2 = 2*i-1;
    elseif (i <= length (y) - (span-1)/2)
        %% We're somewhere in the middle of the vector.
        %% Use full span.
        idx1 = i-(span-1)/2;
        idx2 = i+(span-1)/2;
    else
        %% We're near the end of the vector, reduce span.
        %% Use 2*(length (y) - i) + 1 as span
        idx1 = i - (length (y) - i);
        idx2 = i + (length (y) - i);
    end
    yy(i) = mean (y(idx1:idx2));
end
Rn_moving_av=yy';
Rn_moving_av_uncert=Rn_moving_av.*(1./(max(1,6*Rn_moving_av/100)).^0.5);

% re do the 24h moving average (RN_test) to test my calculations
step=0;
Rn2_index=find(~isnan(Rn))';
Rn_test=zeros(size(Rn))*NaN;
for n=find(~isnan(Rn))'
    step=step+1;
    Rn_test(n)=mean(posix_time_every5min<posix_time(n) & posix_time_every5min>posix_time(n)-24*60*60);
end

%% ask for days to plot
default_answer=min(7,sum(newday));
answer = inputdlg('How many days back?','Days',1,{num2str(default_answer)});
if ~isempty(answer)
    daysback=str2double(answer);
else
    daysback=sum(newday);
end


%% set plotting limits
posix_time_limits=[max(min(posix_time),max(posix_time)-daysback*24*60*60) max(posix_time)];
Rn_limits=[-5 max(max(Rn)*1.15,50)];
Rn2_limits=[-5 max(max(Rn2_every5min)*1.05,50)];
T_limits=[min(T)-0.5 max(T)+0.5];
H_limits=[0 100];
P_limits=[min(P)-range(P)/10 max(P)+range(P)/10];
CO2_limits=[min(min(CO2)-10,400) max(CO2)+10];
VOC_limits=[0 max(max(VOC)+10,100)];



%% plot data
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
    if plot_number==1 % plot instant Rn2 as dots
        valid=~isnan(Rn2_every5min);
        plot(posix_time_every5min(valid),Rn2_every5min(valid),'.r')
    end
    
    xlim(posix_time_limits)
    ylim(values_limits)
    
    
    
    box on
    grid on
    
    ylabel(title_string)
    
    xticks(posix_time(newday==1))
    
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
xticks(posix_time(newday==1))
xticklabels([])
yticks([])
yticklabels([])
grid on
set(gca, 'YColor','w');


%% plot Rn only

figure('units','normalized','outerposition',[0 0 1 1],'Name','Radon raw data')
set(gcf,'color','w');
hold on

subplot(7,1,[1 6])
hold on

valid=~isnan(Rn);
plot(posix_time(valid),Rn(valid),'-b','LineWidth',2)
valid=~isnan(Rn_test);
plot(posix_time(valid),Rn_test(valid),':g','LineWidth',1) % test inverse 24h average
valid=~isnan(Rn2_every5min);
plot(posix_time_every5min(valid),Rn2_every5min(valid),'-','Color',[0.5 0.5 0.5],'LineWidth',2)
valid=~isnan(Rn_moving_av);
plot(posix_time_every5min(valid),Rn_moving_av(valid),'-r','LineWidth',2)


% legend('Reported 24h average','Modeled 24h average','Instant 1h data','12h moving average','12h uncertainty','Location','northwest')
legend('Reported 24h average','Modeled 24h average','Instant 1h data',moving_av_label,'AutoUpdate','off','Location','northwest')

% plot uncertainty
valid=~isnan(Rn_moving_av);
plot(posix_time_every5min(valid),Rn_moving_av(valid)+Rn_moving_av_uncert(valid),':r','LineWidth',1)
plot(posix_time_every5min(valid),Rn_moving_av(valid)-Rn_moving_av_uncert(valid),':r','LineWidth',1)

xlim(posix_time_limits)
% ylim(Rn2_limits)
ylim([-5 max(Rn_moving_av)])

box on
grid on

ylabel('Rn [Bq/m^3]')
xticks(posix_time(newday==1))
xticklabels([])

% timestamps
subplot(7,1,7)
hold on
for n=1:size(year_month_day_hour,1)
        if n==1
            for j=1:3
                text(posix_time(n),5-j,num2str(year_month_day_hour(n,j)),'Color','b')
            end
        elseif n<size(year_month_day_hour,1)
            for j=1:4
                if year_month_day_hour(n,j)~=year_month_day_hour(n-1,j)
                    if j<4
                        text(posix_time(n),5-j,num2str(year_month_day_hour(n,j)),'Color','b')
                    else
                        if year_month_day_hour(n,j)==22 % CET summer time
                            text(posix_time(n),5-j,'0','Color','b', 'HorizontalAlignment', 'center')
                        elseif year_month_day_hour(n,j)==4
                            text(posix_time(n),5-j,'6','Color','b', 'HorizontalAlignment', 'center')
                        elseif year_month_day_hour(n,j)==10
                            text(posix_time(n),5-j,'12','Color','b', 'HorizontalAlignment', 'center')
                        elseif year_month_day_hour(n,j)==16
                            text(posix_time(n),5-j,'18','Color','b', 'HorizontalAlignment', 'center')
                        end
                    end
                end
            end
            if day_in_week(n)~=day_in_week(n-1)
                switch day_in_week(n)
                    case 1
                        text(posix_time(n),5,'Sun.','Color','r')
                    case 2
                        text(posix_time(n),5,'Mon.','Color','k')
                    case 3
                        text(posix_time(n),5,'Tue.','Color','k')
                    case 4
                        text(posix_time(n),5,'Wed.','Color','k')
                    case 5
                        text(posix_time(n),5,'Thu.','Color','k')
                    case 6
                        text(posix_time(n),5,'Fri.','Color','k')
                    case 7
                        text(posix_time(n),5,'Sat.','Color','r')
                    otherwise
                        text(posix_time(n),5,'???','Color','r')
                end
                
            end
        else
            for j=1:3
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
xticks(posix_time(newday==1))
xticklabels([])
yticks([])
yticklabels([])
grid on
set(gca, 'YColor','w');
xlabel('CET summer time')

%% test scatter and compare with assumption (1 count per hour for each 100 Bq/m3)
%figure
%hold on
%values=Raw_Rn2(Raw_Rn2>0);
%plot(values(2:end),abs(diff(values))./(values(1:end-1)+values(2:end))*200,'*r')
%ref=0:max(Rn2_limits);
%expected=100./(ref/100).^0.5;
%plot(ref,expected,'-g')
%xlabel('Rn [Bq/m^3]')
%ylabel('% scatter')
%xlim(Rn2_limits)
%ylim([0 200])

%model=100./(((values(1:end-1)+values(2:end)))/200).^0.5;
%observed=abs(diff(values))./(values(1:end-1)+values(2:end))*200;
%figure
%hold on
%hist(model-observed,20)
%xlabel('Expected(100 Bq/m3/h) - Scatter [%]')

%% Plot radon for B/W print in my laptop
if mylaptop>0
    figure('units','normalized','outerposition',[0 0 1 1],'Name','Radon data')
set(gcf,'color','w');
hold on

subplot(7,1,[1 6])
hold on

% valid=~isnan(Rn);
% plot(posix_time(valid),Rn(valid),'-b','LineWidth',2)
% valid=~isnan(Rn_test);
% plot(posix_time(valid),Rn_test(valid),':g','LineWidth',1) % test inverse 24h average
% valid=~isnan(Rn2_every5min);
% plot(posix_time_every5min(valid),Rn2_every5min(valid),'-','Color',[0.5 0.5 0.5],'LineWidth',2)
valid=~isnan(Rn_moving_av);
plot(posix_time_every5min(valid),Rn_moving_av(valid),'-k','LineWidth',3)


% legend('Reported 24h average','Modeled 24h average','Instant 1h data','12h moving average','12h uncertainty','Location','northwest')
% legend('Reported 24h average','Modeled 24h average','Instant 1h data',moving_av_label,'AutoUpdate','off','Location','northwest')

% plot uncertainty
valid=~isnan(Rn_moving_av);
plot(posix_time_every5min(valid),Rn_moving_av(valid)+Rn_moving_av_uncert(valid),'--k','LineWidth',1)
plot(posix_time_every5min(valid),Rn_moving_av(valid)-Rn_moving_av_uncert(valid),'--k','LineWidth',1)

xlim(posix_time_limits)
% ylim(Rn2_limits)
ylim([-5 max(Rn_moving_av)])

title(moving_av_label)

box on
grid on

ylabel('Rn [Bq/m^3]')
xticks(posix_time(newday==1))
xticklabels([])

% timestamps
subplot(7,1,7)
hold on
for n=1:size(year_month_day_hour,1)
        if n==1
            for j=1:3
                text(posix_time(n),5-j,num2str(year_month_day_hour(n,j)),'Color','b')
            end
        elseif n<size(year_month_day_hour,1)
            for j=1:4
                if year_month_day_hour(n,j)~=year_month_day_hour(n-1,j)
                    if j<4
                        text(posix_time(n),5-j,num2str(year_month_day_hour(n,j)),'Color','b')
                    else
                        if year_month_day_hour(n,j)==22 % CET summer time
                            text(posix_time(n),5-j,'0','Color','b', 'HorizontalAlignment', 'center')
                        elseif year_month_day_hour(n,j)==4
                            text(posix_time(n),5-j,'6','Color','b', 'HorizontalAlignment', 'center')
                        elseif year_month_day_hour(n,j)==10
                            text(posix_time(n),5-j,'12','Color','b', 'HorizontalAlignment', 'center')
                        elseif year_month_day_hour(n,j)==16
                            text(posix_time(n),5-j,'18','Color','b', 'HorizontalAlignment', 'center')
                        end
                    end
                end
            end
            if day_in_week(n)~=day_in_week(n-1)
                switch day_in_week(n)
                    case 1
                        text(posix_time(n),5,'Sun.','Color','r')
                    case 2
                        text(posix_time(n),5,'Mon.','Color','k')
                    case 3
                        text(posix_time(n),5,'Tue.','Color','k')
                    case 4
                        text(posix_time(n),5,'Wed.','Color','k')
                    case 5
                        text(posix_time(n),5,'Thu.','Color','k')
                    case 6
                        text(posix_time(n),5,'Fri.','Color','k')
                    case 7
                        text(posix_time(n),5,'Sat.','Color','r')
                    otherwise
                        text(posix_time(n),5,'???','Color','r')
                end
                
            end
        else
            for j=1:3
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
xticks(posix_time(newday==1))
xticklabels([])
yticks([])
yticklabels([])
grid on
set(gca, 'YColor','w');
xlabel('CET summer time')
end



%% wait to exit
pause(3)
disp('Press Ctrl+C to exit')
waitforbuttonpress () % do not close if started as a pipe (eg: wget -O - https://raw.githubusercontent.com/angelrodes/Airthings_plotter/main/Plot_airthings_v2.m | octave)



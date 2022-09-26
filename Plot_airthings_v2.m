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
for n=1:numel(timestrings)
  thiscell=timestrings(n);
  string=thiscell{1};
  if numel(string)>18
    yyyy=str2double(string(1:4));
    MM=str2double(string(6:7));
    dd=str2double(string(9:10));
    HH=str2double(string(12:13));
    mm=str2double(string(15:16));
    ss=str2double(string(18:19));
  else % if there is somthing wring with the date string
    mm=mm+5; % just add 5 minutes
    VOC(n-1)=NaN; % and remove last data (probably taken from the begining of the date string)
  end
  
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

%% Undo the Rn 24h average (inverse moving average)
step=0;
N=24; % number of readings in the moving average time (24h)
Rn2=zeros(size(Rn))*NaN;
Rn_index=find(~isnan(Rn))';

for n=find(~isnan(Rn))'
  step=step+1;
  if Rn_index(step)~=n
    warning(['Wrong index ' num2str(n) ' in step=' num2str(step) ]) % check indexes
  end
  
  if step==1      % first value
    if Rn(n)<50
      Rn2(n)=Rn(n)*N; % assume first data is the first reported value
    else
      Rn2(n)=Rn(n);   % assume first data represent the first hour
    end
  else
    if step<=N    % first N values
      Rn2(n)=(Rn(n)-previous_Rn)*N; % get approx instant (1h) signal
    else          % rest of the values
      Rn2(n)=(Rn(n)-previous_Rn)*N+Rn2(Rn_index(step-N)); % get instant (1h) signal
    end
%    disp([num2str(previous_Rn) '->' num2str(Rn(n)) ' => Rn2=' num2str(Rn2(n))]) % test only
end
  previous_Rn=Rn(n);
end

% Remove negative data. These are probably artifacts due to rounding.
Raw_Rn2=Rn2; % keep "raw" data for testing
rounding_correction=-sum(Rn2(Rn2<0));
Rn2(Rn2<0)=0;
Rn2(Rn2>0)=Rn2(Rn2>0)-rounding_correction/sum(Rn2>0);

% calculate the 6h moving average Rn6h its estimated uncertainty
step=0;
Rn2_index=find(~isnan(Rn2))';
Rn6h=zeros(size(Rn2))*NaN;
Rn6h_uncert=zeros(size(Rn2))*NaN;
N6=6;
for n=find(~isnan(Rn2))'
  step=step+1;
  select=(max(1,step-N6/2):min(step+N6/2,sum(~isnan(Rn2)))); % moving average range
  Rn6h(n)=mean(Rn2(Rn2_index(select))); % select 6 hour data around
  Rn6h_uncert(n)=Rn6h(n)*1/(max(1,Rn6h(n)/100*numel(select)))^0.5; % assuming one count per 100 Bq/m3 per hour
end

% re do the 24h moving average (RN_test) to test my calculations
step=0;
Rn2_index=find(~isnan(Rn2))';
Rn_test=zeros(size(Rn2))*NaN;
for n=find(~isnan(Rn2))'
  step=step+1;
  Rn_test(n)=sum(Rn2(Rn2_index(max(1,step-N+1):step)))/N;
end

%% ask for days to plot
answer = inputdlg('How many days back?','Days',1,{num2str(sum(newday))});
if ~isempty(answer)
  daysback=str2double(answer);
else
  daysback=sum(newday);
end


%% set plotting limits
posix_time_limits=[max(min(posix_time),max(posix_time)-daysback*24*60*60) max(posix_time)];
Rn_limits=[-5 max(max(Rn)*1.15,50)];
Rn2_limits=[-5 max(max(Rn2)*1.05,50)];
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
    plot(posix_time(valid),Rn2(valid),'.r')
  end
  
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


%% plot Rn only

figure('units','normalized','outerposition',[0 0 1 1],'Name','Radon raw data')
set(gcf,'color','w');
hold on

subplot(7,1,[1 6])
hold on

Rn3=Rn2; % plot 1 hour values as steps Rn3
for n=find(~isnan(Rn2),1,'last'):-1:1
  if isnan(Rn2(n))
    Rn3(n)=next_value;
  else
    next_value=Rn2(n);
  end
end

valid=~isnan(Rn);
plot(posix_time(valid),Rn(valid),'-b','LineWidth',2)
valid=~isnan(Rn_test);
plot(posix_time(valid),Rn_test(valid),':k','LineWidth',1) % test inverse 24h average
valid=~isnan(Rn3);
plot(posix_time(valid),Rn3(valid),'-r','LineWidth',1)
valid=~isnan(Rn6h);
plot(posix_time(valid),Rn6h(valid),'-g','LineWidth',2)
valid=~isnan(Rn6h_uncert);
plot([posix_time(valid),NaN,posix_time(valid)],...
[Rn6h(valid)'-Rn6h_uncert(valid)',NaN,Rn6h(valid)'+Rn6h_uncert(valid)'],...
'--g','LineWidth',2)


legend('Reported 24h average','Modeled 24h average','Instant 1h data','6h moving average','6h uncertainty','Location','northwest')

xlim(posix_time_limits)
ylim(Rn2_limits)
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
xlabel('UTC time')

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

%% wait to exit
pause(3)
waitforbuttonpress () % do not close if started as a pipe (eg: wget -O - https://raw.githubusercontent.com/angelrodes/Airthings_plotter/main/Plot_airthings_v1.m | octave)



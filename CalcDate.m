% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This script calculates the sowing date, maturity date and start and end
% date for every run of a project
%
%
% AUTHOR: Hanne Van Gaelen
% LAST UPDATE: 26/11/2015
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function[RotationDate]=CalcDate(DatapathInput,DatapathOutput,PrStart, PrEnd)
%% 
%--------------------------------------------------------------------------
% STEP 1: LOAD NECESSARY INPUT DATA
%--------------------------------------------------------------------------

% Read individual project characteristics 
    Datafile=dir(fullfile(DatapathInput,'*PrChar.txt'));
    filename=Datafile(1).name; %retrieve filename
    filenamefull=fullfile(DatapathInput, filename); % create exact reference to file (with folders)   
    PrChar= importdata(filenamefull,'\t'); 
    
    fid=fopen(filenamefull);
            if fid==-1 % check if file was really opened
                disp ('File could not be opened')
            else    
                %carry on, file can now be read
            end
    PrChartext=textscan(fid,'%s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s');
    fclose(fid);      
               
    PrNumb(1,:)=PrChar.data(1,:);            % Project code
    np=max(PrNumb);                          % Number of projects 
    PrMode(1,1:np)=PrChar.data(2,1:np);      % Type of project (1= single run, 2= multiple linked runs/ crop rotation)  
    MainMode(1,1:np)=PrChar.data(3,1:np);    % Mode of main crop (1= calendar days, 2 = growing degree days)
    MainSowingD(1,1:np)=PrChar.data(4,1:np); % Sowing day of main crop day
    MainSowingM(1,1:np)=PrChar.data(5,1:np); % Sowing month of main crop month  
    MainLength(1,1:np)=PrChar.data(6,1:np);  % Cycle length of main crop (in CD or GDD)
    MainTbase(1,1:np)=PrChar.data(7,1:np);   % Base temp of main crop (°C)
    MainTupper(1,1:np)=PrChar.data(8,1:np);  % Upper temp of main crop (°C)
    AfterType(1,1:np)=PrChar.data(9,1:np);   % Type of after crop (1= no crop, 2= grass or cover crop)
    for p=1:np         
    PrName(1,p)=PrChartext{1,p}(1,1);        %Project names
    MainCrop(1,p)=PrChartext{1,p}(2,1);       % Main crop
    end

% Length of simulation period
    PrLength=year(PrEnd)-year(PrStart)+1;
% Read temperature file (same temperature file for all projects!)
    Datafile=dir(fullfile(DatapathInput,'*Temp.txt'));
    filename=Datafile(1).name; %retrieve filename
    filenamefull=fullfile(DatapathInput, filename); % create exact reference to file (with folders)   
    A= importdata(filenamefull); 

    Tmin=A(:,1);
    Tmax=A(:,2);
    Dates=PrStart:1:PrEnd;
    Dates=Dates.';
    
    clear DatapathInput PrChar A Datafile filename filenamefull
%% 
%--------------------------------------------------------------------------
% STEP 2: MAIN CYCLE CALCULATIONS
%--------------------------------------------------------------------------

% 2.1 CALCULATE GROWING DEGREE DAYS FOR EACH PROJECT
GDD=NaN(length(Tmax),np);
GDDcum=NaN(size(GDD));
TavgAll=NaN(size(GDD));

for Pr=PrNumb(1):PrNumb(np)
    if MainMode(1,Pr)==2; % Growing degree days 
        % Determine Tbase & Tupper for main crop of project
        Tbase=MainTbase(1,Pr);
        Tupper=MainTupper(1,Pr);
        
        % Calculate Tmax en Tmin star
        Tmaxstar=Tmax;
        Tminstar=Tmin;
        
        for day=1:length(Tmax)% check every day if corrections are necessary
            if Tmax(day,1)>Tupper
                Tmaxstar(day,1)=Tupper;
            elseif  Tmax(day,1)<Tbase;  
                Tmaxstar(day,1)=Tbase;
            else
                %Do nothing and keep the Tmax already assigned
            end
        end    
        for day=1:length(Tmin)% check every day if corrections are necessary
            if Tmin(day,1)>Tupper
                Tminstar(day,1)=Tupper;
            else
                %Do nothing and keep the Tmin already assigned
            end
        end    
        % Calculate Taverage
        Tavg=(Tminstar+Tmaxstar)/2;
        Tavg(Tavg<Tbase)=Tbase; % to assure GDD are never negative
                
        
        % Calculate growing degree days series      
        GDD(:,Pr)=Tavg-Tbase;
        GDDcum(:,Pr)=cumsum(GDD(:,Pr));
        TavgAll(:,Pr)=Tavg;
    end
end        
        
clear Pr day Tbase Tupper Tmaxstar Tminstar 

% 2.2 SOWING DATES
MainSowingDate=datetime(NaN(PrLength,3));

for Pr=PrNumb(1):PrNumb(np)
    if PrMode(1,Pr)==1 % single run project
       MainSowingDate(1,Pr)=datetime(year(PrEnd),MainSowingM(1,Pr),MainSowingD(1,Pr));   
    elseif PrMode(1,Pr)==2 % multiple run project   
       MainSowingDate(1:PrLength,Pr)=datetime(year(PrStart):year(PrEnd),MainSowingM(1,Pr),MainSowingD(1,Pr));      
    else
      error('the project mode (single run vs rotation) of project %d could not be recognized',Pr)
    end
end   
MainSowingDate.Format='dd-MM-yyyy';

clear MainSowingM MainSowingD Pr 

% 2.3 MATURITY DATES  
MainMaturityDate=datetime(NaN(PrLength,3));

for Pr=PrNumb(1):PrNumb(np)
    if PrMode(1,Pr)==1
    rownumb=1;
    elseif PrMode(1,Pr)==2
    rownumb=PrLength;
    else
      error('the project mode (single run vs rotation) of project %d could not be recognized',Pr)
    end
            
    if MainMode(1,Pr)==1;% Calendardays
        for row=1:rownumb
        MainMaturityDate(row,Pr)=MainSowingDate(row,Pr)+(MainLength(1,Pr)-1);
        end
       
    elseif MainMode(1,Pr)==2; % Growing degree days 
       GDDcumPr=GDDcum(:,Pr); % subset for relevant GDD
       
            for row=1:rownumb    
               [StartIndex,~]=find(Dates==MainSowingDate(row,Pr),1);% find rownumber for sowing date
               GDDstart=GDDcumPr(StartIndex-1,1); %find GDD at sowing date
               MaturityGDD=(MainLength(1,Pr)+GDDstart);
               if max(GDDcumPr)-MaturityGDD<0% this year can not be simulated as sowing is to late
                   MainSowingDate(row,Pr)=datetime(NaN(1,3));% delete this year as main growing cycle
                   MainMaturityDate(row,Pr)=datetime(NaN(1,3));% delete this year as main growing cycle
               else    
                   [EndIndex,~] = find(MaturityGDD-GDDcumPr<0,1); % find first index of day with necessary GDD to reach maturity
                    MainMaturityDate(row,Pr)=Dates(EndIndex,1);
               end
               
            end   
    else
        error('the main crop mode (calendar days vs GDD) of project %d could not be recognized',Pr)
    end    
end    

MainMaturityDate.Format='dd-MM-yyyy';

clear Pr rownumb row GDDstart GDDcumPr StartIndex EndIndex Dates MaturityGDD

% 2.4 SUMMARIZING MATRIX GROWING CYCLE MAIN SEASON 
CropCycle=cell(1,np);% np matrixes (for every project one matrix)
                               % 3 columns: Year, Sowing date of main crop, Maturity date of main crop
                               % a certain number of rows depending on how mainy main crop seasons there are in the project                

for Pr=1:np
   CropCycle{1,Pr}(:,1)=datetime(year(PrStart):year(PrEnd),1, 1) ;
   CropCycle{1,Pr}(:,2)=MainSowingDate(:,Pr);
   CropCycle{1,Pr}(:,3)=MainMaturityDate(:,Pr);
   %clean up additional rows
   TF=isnat(CropCycle{1,Pr}(:,2));
   CropCycle{1,Pr}=CropCycle{1,Pr}(~any(TF,2),1:3); % keep only complete rows
end

clear Pr TF 
%% 
%--------------------------------------------------------------------------
% STEP 3: AFTER CYCLE FILLING UP
%--------------------------------------------------------------------------
% define final output format
RotationDate=cell(1,np);% np matrixes (for every project one matrix)
                               % 4 columns:Start sim, end sim, Sowing date of main crop, Maturity date of main crop
                               % a certain number of rows depending on how mainy main and after crop seasons there are in the project      


% Put the dates for the main cycle on the correct lines & &add simulation
% period for those runs
for Pr=PrNumb(1):PrNumb(np)
    if PrMode(1,Pr)==1 % single run
        RotationDate{1,Pr}(1,1)=PrStart;
        RotationDate{1,Pr}(1,2)=PrEnd;
        RotationDate{1,Pr}(1,3:4)=CropCycle{1,Pr}(1,2:3);
    elseif PrMode(1,Pr)==2 % crop rotation 
        if CropCycle{1,Pr}(:,2)==PrStart; % if sowing date of first main cycle = start of sim period, then the first season = main crop, main crop cycles are uneven row numbers 
            position=1;
            for r=1:length(CropCycle{1,Pr}(:,2)) % loop over all rows of main growing cycle matrix
                RotationDate{1,Pr}(position,3:4)=CropCycle{1,Pr}(r,2:3);
                RotationDate{1,Pr}(position,1:2)=CropCycle{1,Pr}(r,2:3); % sim period= crop cycle
                position=position +2;
            end                       
        else %otherwise the first season is after crop/off season, main crop on even row numbers
            position=2;
            for r=1:length(CropCycle{1,Pr}(:,2)) % loop over all rows of main growing cycle matrix
                RotationDate{1,Pr}(position,3:4)=CropCycle{1,Pr}(r,2:3);
                RotationDate{1,Pr}(position,1:2)=CropCycle{1,Pr}(r,2:3); % sim period= crop cycle
                position=position +2;
            end    
        end
        
    else
     ate

    end
end   

% Fill in the after crop cycle dates & sim periods
 
for Pr=PrNumb(1):PrNumb(np)
    if PrMode(1,Pr)==2 % only do something if there is a rotation (not for single run projects)
        l=length(RotationDate{1,Pr}(:,3));
        
        %first row= off cycle (ALWAYS no crop)
        RotationDate{1,Pr}(1,1)=PrStart;      
        RotationDate{1,Pr}(1,2)=RotationDate{1,Pr}(2,1)-1;% end of sim period = day before start of main cycle
        RotationDate{1,Pr}(1,3)=(RotationDate{1,Pr}(1,2))-1; % first cycle = no crop (sowing is day before end of sim period)      
        RotationDate{1,Pr}(1,4)=RotationDate{1,Pr}(1,2);% first cycle = no crop (maturity is end day of sim period)    
        
        % next rows
        if AfterType(1,Pr)==1 % no cover crop
            
            for r=3:2:l
                RotationDate{1,Pr}(r,1)=RotationDate{1,Pr}(r-1,2)+1; % end of previous run +1day
                RotationDate{1,Pr}(r,2)=RotationDate{1,Pr}(r+1,1)-1; % start of next main cycle-1 day       
                RotationDate{1,Pr}(r,3)=RotationDate{1,Pr}(r+1,1)-2; % start of next main cycle-1 day 
                RotationDate{1,Pr}(r,4)=RotationDate{1,Pr}(r+1,1)-1; % start of next main cycle-1 day 
            end
        elseif AfterType(1,Pr)==2 % cover crop
            
            for r=3:2:l
                RotationDate{1,Pr}(r,1)=RotationDate{1,Pr}(r-1,4)+1; % day after end of previous cycle
                RotationDate{1,Pr}(r,2)=RotationDate{1,Pr}(r+1,1)-1;  % day before start next cycle  
                RotationDate{1,Pr}(r,3)=RotationDate{1,Pr}(r-1,4)+1; % day after end of previous cycle
                RotationDate{1,Pr}(r,4)=RotationDate{1,Pr}(r+1,1)-1; % day before start next cycle 
                
            end
        else
          error('the after crop type (no crop versus cover crop) of project %d could not be recognized',Pr)

        end
    
        % last row 
        if  RotationDate{1,Pr}(end,4)<PrEnd %add one only if necessary        
            
            if AfterType(1,Pr)==1 % no crop
                RotationDate{1,Pr}(l+1,1)=RotationDate{1,Pr}(l,2)+1; % end previous run +1 day
                RotationDate{1,Pr}(l+1,2)=PrEnd; 
                RotationDate{1,Pr}(l+1,3)=PrEnd-1;
                RotationDate{1,Pr}(l+1,4)=PrEnd;         
            elseif AfterType(1,Pr)==2 % cover crop
                RotationDate{1,Pr}(l+1,1)=RotationDate{1,Pr}(l,2)+1; % end previous run +1 day
                RotationDate{1,Pr}(l+1,2)=PrEnd;           
                RotationDate{1,Pr}(l+1,3)=RotationDate{1,Pr}(l,2)+1; % end previous run +1 day
                RotationDate{1,Pr}(l+1,4)=PrEnd;   
            else
                error('the after crop type (no crop versus cover crop) of project %d could not be recognized',Pr)
            end  
                        
       end
    end
end    

clear r l position
%%
%--------------------------------------------------------------------------
% STEP 5: CONVERT TO NUMB & WRITE OUTPUT TO EXCELL
%--------------------------------------------------------------------------
% % write output to several textfile (1 file per project)
% for Pr=PrNumb(1):PrNumb(np)
%     %txtname=['DatesProject' num2str(Pr) '.txt'];
%     txtname=PrName{1,Pr};
%     txtname=[txtname '.txt'];
%     filename = [DatapathOutput txtname];
%     PrOutput=exceltime(RotationDate{1,Pr})-366; % exceltime -366 = AquaCroptime
%     dlmwrite(filename,PrOutput,'delimiter','\t');
% end

% write output to one excel tabsheet
xlname='DateGeneration.xlsx';
%filename = [DatapathOutput xlname];
filename = fullfile(DatapathOutput,xlname);

Alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

Column='A';
ColumnNumb=1;
RowNumb=1;

for Pr=PrNumb(1):2:PrNumb(np)
Celname=[Column num2str(RowNumb)];    
PrOutput=exceltime(RotationDate{1,Pr})-366;
xlswrite(filename,PrOutput,'Dates',Celname);

ColumnNumb=ColumnNumb+4;
    if ColumnNumb-26<=0
        Column=Alphabet(ColumnNumb);
    else
        x=fix(ColumnNumb./26);
        y=rem(ColumnNumb,26);

        Column=[Alphabet(x) Alphabet(y)];
    end
end
clear DatapathOutput x y xlname txtname filename Column ColumnNumb RowNumb Celname PrOutput Alphabet Pr
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Overwrite project dates for every run, based on a matrix that contains
% the dates for each run
%
% TO ADJUST BEFORE RUNNING (see section 0)
%   1. Path where input files for date calculation are stored ('DatapathInput')
%   2. Path where template files for the projects are stored ('DatapathTemplate')
%   3. Path where output date files need to be stored ('DatapathOutput')
%   4. Start and end date of simulation period ('PrStart' & 'PrEnd')
%
% AUTHOR: Hanne Van Gaelen
% LAST UPDATE: 26/11/2015
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
close all 
clear

%% -----------------------------------------------------------------------
% 0. TO ADJUST BEFORE RUNNING
%-------------------------------------------------------------------------
% Datapath for date calculate input (*Temp.Txt and *PrChar.txt)
DatapathInput='C:\DATA_HanneV\~Onderzoek\DEEL 2 - Ecohydro model\DEEL IIB  -VHM-AC\Application\Model build up\Project create\Input\Fut1';

% Datapath fortemplate project files (with wrong dates)
DatapathTemplate='C:\DATA_HanneV\~Onderzoek\DEEL 2 - Ecohydro model\DEEL IIB  -VHM-AC\Application\Model build up\Project create\Input\Template';

% Datapath to store the results of the date calculation (in excel) and to
% store the new projectfiles with adapted dates
DatapathOutput='C:\DATA_HanneV\~Onderzoek\DEEL 2 - Ecohydro model\DEEL IIB  -VHM-AC\Application\Model build up\Project create\Output\Fut1';

PrStart=datetime(2035,1,1);       % Start date of project
PrEnd=datetime(2064,12,30);       % End date of project

%% -----------------------------------------------------------------------
% 1. CALCULATION OF NEW DATES
%-------------------------------------------------------------------------

% Calculate the new dates for all runs of every project
RotationDate=CalcDate(DatapathInput,DatapathOutput, PrStart, PrEnd);
    
clear PrStart PrEnd

%% --------------------------------------------------------------
% 2. ADAPT PROJECT FILES
%-----------------------------------------------------------------
    
% Define which type of files should be read (* is wild character)
    Datafile1=dir(fullfile(DatapathTemplate,'*.PRO'));
    Datafile2=dir(fullfile(DatapathTemplate,'*.PRM'));
    Datafile=[Datafile1; Datafile2];
    Datafile = nestedSortStruct(Datafile, 'name');
    
for Pr=1:length(Datafile)%loop over all project files with extension *PRM    
    
    [nrun,~]=size(RotationDate{1,Pr});  % number of runs
    nlines=(nrun-1)*40+63;              % number of lines in project file
    lastdateline=((nrun-2)*40)+64;      % line where dates of last project run start
    firstdateline=3;                    % line where dates of first project run start
    seconddateline=64;                  % line where dates of second project run start
    
    % OPEN FILE
     filename=Datafile(Pr).name; %retrieve filename
     filenamefull=fullfile(DatapathTemplate, filename); % create exact reference to file (with folders)
       
     fid = fopen(filenamefull,'r'); % open file 
        if fid==-1 
            disp ('File could not be opened')
        else    
            %carry on, file can now be read
        end
        
     % EXTRACT DATA FROM FILE
        mydata = cell(1, nlines);% extract data from the file
        for l = 1:nlines
           mydata{l} = fgetl(fid);
        end
        fclose(fid); 
        
     % REPLACE CERTAIN DATA (DATES of every run)
     
        % Run Nr 1  
            Run=1;
            %create new data 
            DateS1=exceltime(RotationDate{1,Pr}(Run,1))-366;
            linetext1=num2str(DateS1);
            linetext2=' : First day of simulation period - RUNNR ';
            linetext3=num2str(Run);
            newText1=[linetext1 linetext2 linetext3];

            DateS2=exceltime(RotationDate{1,Pr}(Run,2))-366;
            linetext1=num2str(DateS2);
            linetext2=' : Last day of simulation period';
            newText2=[linetext1 linetext2];

            DateC1=exceltime(RotationDate{1,Pr}(Run,3))-366;
            linetext1=num2str(DateC1);
            linetext2=' : First day of cropping period';
            newText3=[linetext1 linetext2];

            DateC2=exceltime(RotationDate{1,Pr}(Run,4))-366;
            linetext1=num2str(DateC2);
            linetext2=' : Last day of cropping period';
            newText4=[linetext1 linetext2];

            %overwrite data with new data
            mydata{firstdateline} = newText1;
            mydata{firstdateline+1} = newText2;
            mydata{firstdateline+2} = newText3;
            mydata{firstdateline+3} = newText4;
     
     if nrun>1       
     % Next runs 
        Run=2;
        for l=seconddateline:40:lastdateline % loop over all the other runs
            % create new data               
            DateS1=exceltime(RotationDate{1,Pr}(Run,1))-366;
            linetext1=num2str(DateS1);
            linetext2=' : First day of simulation period - RUNNR ';
            linetext3=num2str(Run);
            newText1=[linetext1 linetext2 linetext3];

            DateS2=exceltime(RotationDate{1,Pr}(Run,2))-366;
            linetext1=num2str(DateS2);
            linetext2=' : Last day of simulation period';
            newText2=[linetext1 linetext2];

            DateC1=exceltime(RotationDate{1,Pr}(Run,3))-366;
            linetext1=num2str(DateC1);
            linetext2=' : First day of cropping period';
            newText3=[linetext1 linetext2];

            DateC2=exceltime(RotationDate{1,Pr}(Run,4))-366;
            linetext1=num2str(DateC2);
            linetext2=' : Last day of cropping period';
            newText4=[linetext1 linetext2];            
                                
            %overwrite data with new data
            mydata{l} = newText1;
            mydata{l+1} = newText2;
            mydata{l+2} = newText3;
            mydata{l+3} = newText4;
            
            Run=Run+1;
        end
     end
   clear Run newText1 newText2 newText3 newText4 linetext1 linetext2 linetext3
   clear DateC1 DateC2 DateS1 DateS2
   
   
   % WRITE DATA BACK TO TEXT FILE
    filenamefullOut=fullfile(DatapathOutput, filename); % create empty textfile and open it
    fid = fopen(filenamefullOut,'w');
    fprintf(fid,'%s\r\n',mydata{:});%print results in this file
    fclose(fid);
end   
clear l Datafile1 Datafile2 Datafile    
clear DatapathInput DatapathOutput DatapathTemplate fid filename filenamefull firstdateline seconddateline lastdateline  mydata  filenamefullOut  
clear nlines nrun Pr ans

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Info on script build up: http://nl.mathworks.com/help/matlab/import_export/writing-to-text-data-files-with-low-level-io.html#br5_kad-1    
    
    
    
    
    
  
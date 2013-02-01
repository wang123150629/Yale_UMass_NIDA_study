classdef Profile
    properties
        name
        propertyList
        dataSettings
        normInfo
        fileList
        parNames
        chanInfo
        loadedFile
        loadedChannel
        plotView
    end
    methods
        % Constructor function loads empty profile
        function obj=Profile()                       
            obj.name='';
            obj.propertyList=[];
            obj.normInfo=[];
            obj.fileList=[];
            obj.parNames=[];
            obj.chanInfo=[];
            %obj.loadedFile=[];
            %obj.loadedChannel=[];
            obj.plotView=[]; 
            obj=obj.setupPropertyList;
            obj.dataSettings=[];
        end
        
        % Setup property list
        function obj=setupPropertyList(obj)
            obj.propertyList={...
                'FF_VERSION','2.2.1';
                'DESCRIPTION','';
                'FS','';
                'FEAT_DELIM','9';
                'OUT_FILE','';
                'PLOT_SHOWRAW','1';               
                'PLOT_SHOWPREVIEW','1';
                'PLOT_PREVIEWFEAT','1';
                'PLOT_PAR1','';
                'PLOT_PAR2','';
                'PLOT_PAR3','';
                'PLOT_PAR4','';
                'PLOT_PAR5','';
                'PLOT_PAR6','';
                'PLOT_CHAN','';
                'PLOT_REGION','';
                'PLOT_YLABEL','Amplitude (?)';
                %'PLOT_XMIN','';
                %'PLOT_XMAX','';
                %'PLOT_YMIN','';
                %'PLOT_YMAX','';
                'MIN_FILE_SAMPLES','';
                'MAX_FILE_SAMPLES','';
                'MIN_WIN_SAMPLES','';
                'MAX_WIN_SAMPLES','';
                %'RES_WIN_TIME','0.05';
                };
            %obj.saveMe;
        end
        
        % Setup filelist-dependent properties
        function obj=setupWithFiles(obj)
            obj.dataSettings=[];
            
            if ~isempty(obj.chanInfo)
                nNumChans=obj.chanInfo.numChan; % This is all channels, 
                % not just the usable ones (to make it easier if list of
                % usable ones are changed)
            else
                fprintf('ERROR: No channel information available to setupDataSettings (Profile).\n\n');
            end
            
            % If currently loaded channel isn't used, reset to first usable            
            if isempty(obj.getChannel)|~obj.chanInfo.toUse(obj.getChannel)
                sChanName=obj.chanInfo.titles{find(obj.chanInfo.toUse,1,'first')};
                obj=obj.setField('PLOT_CHAN',sChanName);
            end
            
            % Determine upper and lower limits to be used for BL and T
            % selection
            nAllMinVal=1;
            obj=obj.setField('MIN_WIN_SAMPLES',num2str(nAllMinVal));
            nAllMaxVal=inf;%nAllMaxVal=0; for shortest
            h=waitbar(0,'Checking file lengths...','WindowStyle','modal');
            for i=1:size(obj.fileList,1)
                
                sFilename=obj.fileList{i,1};
                nNumDataRows=Util_GetNumberOfDataRows(sFilename);
                nAllMaxVal=min(nAllMaxVal,nNumDataRows);%max for longest
                if ishandle(h)                    
                    waitbar(i/size(obj.fileList,1),h)
                else
                    return
                end
            end
            if ishandle(h),close(h);end
            obj=obj.setField('MAX_WIN_SAMPLES',num2str(nAllMaxVal));
            
            % Set default windows
            %nRes=str2num(obj.getField('RES_WIN_TIME'));
            Fs=str2num(obj.getField('FS'));
            nRes=(nAllMaxVal-nAllMinVal+1)/1000/Fs;
            nHP_Cutoff=ceil(0.1*Fs/2);
            nLP_Cutoff=floor(0.9*Fs/2);
            if Fs>120
                nNotch_Cutoff=[59 61];
            else
                nNotch_Cutoff=[floor(Fs/4) ceil(Fs/4)];
            end
                
            nBL_From=ceil((nAllMinVal-1)/Fs/nRes)*nRes;
            nBL_To=floor(mean([nAllMinVal-1,nAllMaxVal-1])/Fs/nRes)*nRes;
            nTarg_From=ceil(mean([nAllMinVal-1,nAllMaxVal-1])/Fs/nRes)*nRes;
            nTarg_To=floor((nAllMaxVal-1)/Fs/nRes)*nRes;         
            
            if ~isempty(nNumChans)&isnumeric(nNumChans)&nNumChans>=1
                for i=1:nNumChans
                    obj.dataSettings{i}={...
                        'PRE_NORM','0';
                        'FILT_NOTCH','0';
                        'FILT_N_FREQ1',num2str(nNotch_Cutoff(1));
                        'FILT_N_FREQ2',num2str(nNotch_Cutoff(2));
                        'FILT_N_ORDER','3';
                        'FILT_LP','0';
                        'FILT_LP_FREQ',num2str(nLP_Cutoff);
                        'FILT_LP_ORDER','3';
                        'FILT_HP','0';
                        'FILT_HP_FREQ',num2str(nHP_Cutoff);
                        'FILT_HP_ORDER','3';
                        'FILT_X_TYPE','none';
                        'FEAT_BL_FROM',num2str(nBL_From);
                        'FEAT_BL_TO',num2str(nBL_To);
                        'FEAT_TARG_FROM',num2str(nTarg_From);
                        'FEAT_TARG_TO',num2str(nTarg_To);
                        'FEAT_TYPE','DifferenceOfAverages';};
                end                
                
            else
                fprintf('ERROR:  Bad input to setupWithFiles (Profile).\n\n');
            end           
            
            % If currently loaded plot parameters aren't linked to a file,
            % set to first possibility
            cObjects=vObjects();
            for i=1:size(cObjects.PlotMenus,1)
                cPlotPar{i}=obj.getField(cObjects.PlotMenus(i,2));    
            end            
            sRawFilename=Profile_GetFilename(cPlotPar,1);
            if isempty(sRawFilename)
                sNewPars(1:size(cObjects.PlotMenus,1))={''};
                sNewPars(1:size(obj.fileList,2)-1)=...
                    obj.fileList(1,2:end);
                for i=1:length(sNewPars)
                    obj=obj.setField(cObjects.PlotMenus(i,2),sNewPars{i});
                end
            end
            
            % Clear all normalization info
            obj.normInfo=[];
        end
        
        function obj=setField(obj,sField,sVal)
           % Determine if field is in propertyList
           iInPL=strcmp(obj.propertyList(:,1),sField);          
           if any(iInPL)
               obj.propertyList{iInPL,2}=sVal;
           elseif ~isempty(obj.dataSettings) % THIS DOESN'T WORK (but is unused)
               iInDS=strcmp(obj.dataSettings(:,1),sField);
               if any(iInDS)
                   obj.dataSettings(iInDS,1)=sField;
               else
                   fprintf('Field not found (Profile,setField)\n\n');                   
               end               
           else
               fprintf('Field not found (Profile,setField)\n\n');
           end              
        end
        
        function sVal=getField(obj,sField)
           sVal='';
            % Determine if field is in propertyList
           iInPL=strcmp(obj.propertyList(:,1),sField);          
           if any(iInPL)
               sVal=obj.propertyList{iInPL,2};
           elseif ~isempty(obj.dataSettings) % THIS DOESN'T WORK (but is unused)
               iInDS=strcmp(obj.dataSettings(:,1),sField);
               if any(iInDS)
                   sVal=obj.dataSettings(iInDS,1);
               else
                   fprintf('Field not found (Profile,getField)\n\n');                   
               end               
           else
               fprintf('Field not found (Profile,getField)\n\n');
           end              
        end
        
        function cVal=getFieldForAllChans(obj,sField)
           cVal={''};
            % Determine if field is in dataSettings
           if ~isempty(obj.dataSettings) 
               iInDS=strcmp(obj.dataSettings{1}(:,1),sField);
               if any(iInDS)
                   for i=1:length(obj.dataSettings)
                        cVal(i)=obj.dataSettings{i}(iInDS,2);
                   end
               else
                   fprintf('Field not found (Profile,getFieldForAllChans)\n\n');                   
               end               
           else
               fprintf('Field not found (Profile,getFieldForAllChans)\n\n');
           end              
        end
        
        % Saves current object to a .mat file
        function saveMe(obj)
            sPaths=vPaths();
            sFilename=[sPaths.Profiles,'/',obj.name,'.mat'];
            save(sFilename,'obj');
        end
        
        % Deletes current object
        function deleteMe(obj)
            sPaths=vPaths();
            sFilename=[sPaths.Profiles,'/',obj.name,'.mat'];
            if exist(sFilename,'file')
                delete(sFilename);                
            else
                fprintf('ERROR:  File to delete doesn''t exist (Profiles, deleteMe).\n\n');
            end
        end  
        
        % Get current channel
        function nChan=getChannel(obj)            
            nChan=[];
            iRow=strcmpi(obj.propertyList(:,1),'PLOT_CHAN');
            sChanName=obj.propertyList{iRow,2};
            if ~isempty(sChanName)
                nChan=find(strcmp(obj.chanInfo.titles,sChanName));            
            end
        end
    end
        
    % Class functions
    methods (Static)        
        
        
        % Determine whether the name is a valid profile name
        function X=isProfileName(sName)
            % Verify that a string was inputted to function
            if nargin~=1 || isempty(sName) || ~ischar(sName)
                X=false;            
            % Check whether that profile exists
            elseif ~isvarname(sName)
                X=false;            
            else
                X=true;
            end
            
        end
        
        
        % Determine whether the name is unique and valid
        function X=isUniqueProfileName(sName)
            % Verify that profile name is valid
            if ~Profile.isProfileName(sName)
                X=false;
            % Check whether that profile name is already in use
            else
                % Get all profile names
                sPaths=vPaths();
                cProfileNames=Profile.getProfileNames(sPaths.Profiles,'all_versions');                
                if any(strcmp(cProfileNames,sName))
                    X=false;
                else
                    X=true;
                end               
            end            
        end
        
        % Determine the names of all valid profiles in the profile
        % directory
        function cProfileNames=getProfileNames(sPathname,sWhich)
            
            % Define current version (this should like be in a more readily
            % accessible place)
            thisV1=2;thisV2=2;thisV3=1;
            
            % Loop through files in given directory
            cFilelist=dir(sPathname);
            
            cProfileNames={};
            c=1;
            for i=1:length(cFilelist)

                % Eliminate all folders
                if cFilelist(i).isdir,continue,end

                % Eliminate all files that do not have a .mat extension
                if length(cFilelist(i).name)<5 ||...
                        ~strcmpi(cFilelist(i).name(end-3:end),'.mat')
                    continue
                end

                % Eliminate all text files without matching fields
                sFilename=[sPathname,'/',cFilelist(i).name];
                temp=load(sFilename);
                testProfile=temp.obj;
                if ~Profile.isProfile(testProfile)
                    continue
                end
                
                % Exclude all profiles that were not created with FF 2.2.x
                if strcmp(sWhich,'this_version')
                    iRow=find(strcmp(testProfile.propertyList(:,1),'FF_VERSION'));
                    if ~isempty(iRow)
                        sVersion=testProfile.propertyList{iRow,2};
                    end
                    
                    V1=[];V2=[];V3=[];
                    if ~isempty(iRow)|sum(sVersion=='.')==2                        
                        iDots=find(sVersion=='.');
                        if ~(iDots(1)==1||iDots(2)==length(sVersion)||...
                                iDots(2)-iDots(1)<2)
                            V1=str2num(sVersion(1:iDots(1)-1));
                            V2=str2num(sVersion(iDots(1)+1:iDots(2)-1));
                            V3=str2num(sVersion(iDots(2)+1:end));
                        end
                    end
                    
                    if isempty(V1)||isempty(V2)||isempty(V3)
                        fprintf(['NOTE:  Profile ''%s'' was not loaded, because it was\n ',...
                            '      not created with a compatible version of FeatureFinder.\n\n'],testProfile.name);
                        continue                    
                    end
                    
                    if V1==thisV1&&V2>thisV2
                        fprintf(['NOTE:  Profile ''%s'' was created in a slightly newer version\n',...
                            '       of FeatureFinder (V%0.0f.%0.0f.%0.0f), so some functionality\n',...
                            '       may not be available.\n\n'],testProfile.name,V1,V2,V3);
                    elseif V1>thisV1
                        fprintf(['NOTE:  Profile ''%s'' was created in a much newer version\n',...
                            '       of FeatureFinder (V%0.0f.%0.0f.%0.0f), and is not compatible\n',...
                            '       with the current version (V%0.0f.%0.0f.%0.0f).\n\n'],...
                            testProfile.name,V1,V2,V3,thisV1,thisV2,thisV3);
                        continue
                    end
           
                elseif ~strcmp(sWhich,'all_versions')
                    fprintf('WARNING:  Bad input to Profile.getProfileNames.\n\n');
                end

                % Store remaining files in menu variable (excluding .mat)
                cProfileNames{c}=cFilelist(i).name(1:end-4);
                c=c+1;    
            end
        end
        
        % Determines whether the given variable is a profile
        function X=isProfile(testProfile)
            % Create a blank profile against which to compare files
                modelProfile=Profile();
                if isempty(testProfile)||~isequal(class(testProfile),class(modelProfile))||...
                    ~isequal(properties(testProfile),properties(modelProfile))
                    X=false;
                else
                    X=true;
                end
            return
        end
        
        
    end       
end
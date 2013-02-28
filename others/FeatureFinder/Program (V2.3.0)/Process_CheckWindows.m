function bError=Process_CheckWindows(sProfile,sType,stcEventData)

bError=1;

% Get window values from file
cWindowNames={'FEAT_BL_FROM';'FEAT_BL_TO';'FEAT_TARG_FROM';'FEAT_TARG_TO'};
nWindowVals=Profile_GetField(cWindowNames,'to_num');

% Get limit on window values
%nAllMinVal=Profile_GetField('MIN_WIN_VAL','to_num'); to be added
%nAllMaxVal=Profile_GetField('MAX_WIN_VAL','to_num'); to be added

Fs=Profile_GetField('FS','to_num');

% Get limit on plotted data
%nThisMinVal=Profile_GetField('MIN_FILE_SAMPLES','to_num');
nThisMinVal=1;
nThisMinVal=(nThisMinVal-1)/Fs;

%nThisMaxVal=Profile_GetField('MAX_FILE_SAMPLES','to_num');
nThisMaxVal=Profile_GetField('MAX_WIN_SAMPLES','to_num');
nThisMaxVal=(nThisMaxVal-1)/Fs;

switch sType
    case 'all-revert'   
        % Check whether window values exceed limits for given file
        if any(nWindowVals<nThisMinVal) || any(nWindowVals>nThisMaxVal) ||...        
                nWindowVals(1)==nWindowVals(2) || nWindowVals(3)==nWindowVals(4)
            % If values not OK, alert user and revert values
            Comm_Warn(['An invalid window value exists, so all cells ',...
                'were reset to their previous values.']);            
            Profile_RevertLastSelected();
            return
        elseif (nWindowVals(1)<nWindowVals(2))&&...
                (nWindowVals(3)<nWindowVals(4))
            % If values OK, reset error variable
            bError=0;
        end

    case 'all-fix'           
        bChange=0;
        bError=0;
        
        % Trim window values that exceed limits for given file
        iBad=nWindowVals<nThisMinVal;
        if any(iBad)
            nWindowVals(iBad)=nThisMinVal;
            bChange=1;
        end
        iBad=nWindowVals>nThisMaxVal;
        if any(iBad)
            nWindowVals(iBad)=nThisMaxVal;
            bChange=1;
        end        

        % Check whether window values need to be switched
        if nWindowVals(1)>nWindowVals(2)
            temp=nWindowVals(1);
            nWindowVals(1)=nWindowVals(2);
            nWindowVals(2)=temp; 
            bChange=1;
        end
        if nWindowVals(3)>nWindowVals(4)
            temp=nWindowVals(3);
            nWindowVals(3)=nWindowVals(4);
            nWindowVals(4)=temp; 
            bChange=1;
        end
        
        % Extend BL window if it has zero length (to 1 sample)
        if nWindowVals(1)==nWindowVals(2)
            if (nWindowVals(2)+1/Fs)<=nThisMaxVal
                nWindowVals(2)=nWindowVals(2)+1/Fs;
            elseif (nWindowVals(1)-1/Fs)>=nThisMinVal
                nWindowVals(1)=nWindowVals(1)-1/Fs;
            else
                fprintf(['ERROR:  File length appears to be 0 or 1',...
                    ' samples (Process_CheckWindows)\n\n']);
                bError=1;                
            end
            bChange=1;
        end
        % Extend target window if it has zero length (to 1 sample)
        if nWindowVals(3)==nWindowVals(4)
            if (nWindowVals(3)-1/Fs)>=nThisMinVal
                nWindowVals(3)=nWindowVals(3)-1/Fs;
            elseif (nWindowVals(4)+1/Fs)<=nThisMaxVal
                nWindowVals(4)=nWindowVals(4)+1/Fs;
            else
                fprintf(['ERROR:  File length appears to be 0 or 1',...
                    ' samples (Process_CheckWindows)\n\n']);
                bError=1;
            end
            bChange=1;
        end
            
        if bChange
            %Comm_Warn(['One or more invalid window values still exist, ',...
            %    'so bad cells have been changed to the closest usable value.']); 
            Profile_SetField(cWindowNames{1},num2str(nWindowVals(1)));
            Profile_SetField(cWindowNames{2},num2str(nWindowVals(2)));
            Profile_SetField(cWindowNames{3},num2str(nWindowVals(3)));
            Profile_SetField(cWindowNames{4},num2str(nWindowVals(4)));
            Profile_Load();
        end      
            
    case 'this'
        % Determine whether the new value is outside of the data's 
        % (time) range
        if stcEventData.NewData>nThisMaxVal||...
                stcEventData.NewData<nThisMinVal
            Comm_Warn('Looks like your new window value is out of range!');
            return
        end
        
        
        % Determine whether the new value results in a zero-length window
        if stcEventData.Indices(1)==1 % If BL
            if stcEventData.Indices(2)==2&&stcEventData.NewData==nWindowVals(2)
                Comm_Warn('Windows must be longer than 0 s!');
                return
            elseif stcEventData.Indices(2)==3&&stcEventData.NewData==nWindowVals(1)
                Comm_Warn('Windows must be longer than 0 s!');
                return               
            end            
        elseif stcEventData.Indices(1)==2 % If Targ
            if stcEventData.Indices(2)==2&&stcEventData.NewData==nWindowVals(4)
                Comm_Warn('Windows must be longer than 0 s!');
                return
            elseif stcEventData.Indices(2)==3&&stcEventData.NewData==nWindowVals(3)
                Comm_Warn('Windows must be longer than 0 s!');
                return               
            end
        end
        
        bError=0;
        
end
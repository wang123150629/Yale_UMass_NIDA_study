% Store, retrieve, clear, and otherwise act on current profile
function X=vCurrentProfile(A,B,C)

    persistent thisProfile

    X=[];

    % Clear variable if requested
    if nargin==1 && strcmp(A,'clear')
        clear thisProfile

        % Set variable if requested
    elseif nargin==2 && strcmp(A,'set_value')
        if Profile.isProfile(B)
            thisProfile=B;
        else
            fprintf('ERROR:  Invalid profile value sent to vCurrentProfile\n\n');
        end
        thisProfile.saveMe;

    % Set variable with given name if requested
    elseif nargin==2 && strcmp(A,'set_name')
        % Determine if name is valid
        if Profile.isProfileName(B) && ~Profile.isUniqueProfileName(B)
            sPaths=vPaths();
            sFilename=[sPaths.Profiles,'/',B,'.mat'];
            temp=load(sFilename);
            thisProfile=temp.obj;                    
        else
            fprintf('ERROR:  Invalid profile name sent to vCurrentProfile\n\n');
        end
        
    % Retrieve variable if requested
    elseif nargin==0
        X=thisProfile;
    % If command not recognized, alert user
    else
        fprintf('WARNING:  Unrecognized command to vCurrentProfile\n\n');
    end
end
       
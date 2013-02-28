classdef HandleList
    properties
        handles
        info
    end
    methods
        % Constructor function loads empty list
        function obj=HandleList()                       
            obj.handles=[];            
            obj.info=[];
        end
        
        % Add item to list (no duplicates)
        function obj=add(obj,hNew,xInfo)
            for i=1:length(hNew)
                if ishandle(hNew(i))
                    if ~ismember(hNew(i),obj.handles)
                        obj.handles=[obj.handles;hNew(i)];
                        obj.info=[obj.info;xInfo(i)];
                    else
                        fprintf('NOTE: Handle already in list (HandleList).\n\n');
                    end
                else
                    fprintf('ERROR: Bad handle not added to HandleList.\n\n');
                end
            end
        end
        
        % Remove item from list
        function obj=remove(obj,hToRemove)
            for i=1:length(hToRemove)
                if ismember(hToRemove(i),obj.handles)
                    iToRemove=obj.handles==hToRemove(i);
                    obj.handles(iToRemove)=[];
                    obj.info(iToRemove)=[];                    
                else
                    fprintf('NOTE: Handle not present in list (HandleList).\n\n');
                end            
            end
        end
        
        % Clear list
        function obj=clear(obj)
            obj.handles=[];
            obj.info=[];
        end
    end
end
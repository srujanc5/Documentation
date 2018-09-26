function files=placeLXU_THR(videos,placementSize,track,new,filespre)

% items=length(videos);files=zeros(items,1);
% files=filespre;
% cache=cache(d_agg(cache)<=max(d_agg(new)));
% if t==1
%     files(new)=1;files(cache)=1;s=files'*videos;
%     if s>placementSize
%         track=d_agg(new);[~,c]=sort(track);
%         for j=1:length(new)
%             files(new(c(j)))=0;s=s-videos(new(c(j))); % Store recently requested files based on total aggregate demands
%             if s<=placementSize
%                 break;
%             end
%         end
%     end
% else
%     if isempty(cache)
%         files=filespre;
%     else
%         new=new(filespre(new)==0);
%         new=new(d_agg(new)>=min(d_agg(cache)));
%         files(new)=1;files(cache)=1;s=files'*videos;
%         j=1;[~,c]=sort(d_agg(cache));
%         while s>placementSize && j<=length(cache)
%             files(cache(c(j)))=0;s=s-videos(cache(c(j)));j=j+1; % eleminate least recently used ones first
%         end
% 
%         if s>placementSize
%             track=d_agg(new);[~,c]=sort(track);
%             for j=1:length(new) 
%                 files(new(c(j)))=0;s=s-videos(new(c(j))); % Store recently requested files based on total aggregate demands
%                 if s<=placementSize
%                     break;
%                 end
%             end
%         end
%     end
% end

    files=filespre;cache=[];
    if ~isempty(new)
    for i=1:length(files)
        if filespre(i)==1 && isempty(find(new==i, 1))
            cache=[cache;i];
        end
    end
    new=new(filespre(new)==0);
    if ~isempty(new) && ~isempty(cache)
        cache=cache(track(cache)<=max(track(new)));
        if ~isempty(cache)
            new=new(track(new)>=min(track(cache)));
            files(new)=1;replace=track(cache);
            [~, c]=sort(replace);j=1;s=files'*videos;
            while s>placementSize && j<=length(c)
                files(cache(c(j)))=0; s=s-videos(cache(c(j)));j=j+1;
            end
            if s>placementSize
                [~, c]=sort(track);
                for j=1:length(track)
                    if files(c(j))==1
                        files(c(j))=0;s=s-videos(c(j));
                    end
                    if s<=placementSize
                        break;
                    end
                end
            end  
        end
    end
    end

end
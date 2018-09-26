function files = placeLRUTest(videos,placementSize,track,new,filespre)
    
    files=filespre; files(new)=1;cache=[];
    if ~isempty(new)
    for i=1:length(files)
        if filespre(i)==1 && isempty(find(new==i, 1))
            cache=[cache;i];
        end
    end
    replace=track(cache);
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
%     cacheNew= find(files==1);
%     replaceNew=track(cacheNew);
%     [~, c]=sort(replaceNew);j=1;
%     while s>placementSize
%         files(cacheNew(c(j)))=0; s=s-videos(cacheNew(c(j)));j=j+1;
%     end
%     replace=track(cache);
%     [~, c]=sort(replace);j=1;s=files'*videos;
%     while s>placementSize
%         files(cache(c(j)))=0; s=s-videos(cache(c(j)));j=j+1;
%     end
    end
end
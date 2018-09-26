function files = placeTest(videos,placementSize,track)
    
    items=length(videos);files=zeros(items,1);
    [~, c]=sort(track,'descend');
    s=0;
    for i=1:items
        if s+videos(c(i))<=placementSize
            files(c(i))=1; s=s+videos(c(i));
        end
        if s==placementSize
            break;
        end
    end
    
end
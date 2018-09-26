clear all; close all; clc;
%% loading dataset
% It contains two matrices 'videoData' and 'vidID'. 'videoData' has videoids in first
% column and respective sizes in second column. 'vidID' is a vector with
% stream of videoids that are requested by the users.
load('videoData.mat');
load('videoId.mat');
load('demandDATA.mat');

%% Finding fisrt 33% of data
tI = 0; obs = 1;
TOBSMax = round(0.33*size(demandDATA{obs,1}.demands,1));
for tobs = 1:TOBSMax
    if ~isempty(demandDATA{obs,1}.demands{tobs,1})
        for vid = 1:size(demandDATA{obs,1}.demands{tobs,1},1)
            tI = tI + demandDATA{obs,1}.demands{tobs,1}(vid,3);
        end
    end
end
tMax = length(vidID)-tI; limit = 4;

costX = zeros(limit,1); outX = zeros(limit,1);

items=size(videoData,1); %total number of videos
videos=videoData(:,2); %video sizes

rhoX = 1; rhoY = 10; rho=rhoX*rhoY/(rhoX+rhoY);%price for network flows
eps = rho*0.009;
%% for different placementsizes
for alpa=1:limit
    alpa
    placementSize=sum(videos)*(0.005*alpa); % alpa percent of total library
     
    % tracking local variables with stream
    costx = zeros(tMax,1); outx = zeros(tMax,1);    
    
    % Initializing files for all the methods
    filesx = zeros(items,1); 
    
    % Initializing other parameters
    lambda = zeros(items,1); d = zeros(items,1);
    xA = zeros(items,1); yA = zeros(items,1);
    
    %% Streaming starts from here
    for t=1:tMax
        if rem(t,10000)==0
            t
        end
        %% Step I Finding anticipated flows
        xA=(1/rhoX)*lambda; yA=(1/rhoY)*lambda;
        %% Step II placement
        filesprex = filesx;
        
        if t==1
            %% random placement 
            files=zeros(items,1);
            c = randperm(items,items)'; s=0;
            for i=1:items
                if s+videos(c(i))<=placementSize
                files(c(i))=1; s=s+videos(c(i));
                end
                if s==placementSize
                break;
                end
            end
            filesx = files; 
        else
            %% Placement algorithm
            filesx=zeros(items,1);
            if filesprex(new)==1
                filesx=filesprex;
            else
                if xA(new)>=min(xA(filesprex==1))
                    filesx(new)=1; s=videos(new);
                    cache=find(filesprex==1); [~,c]=sort(xA(cache),'descend');i=1;
                    while s < placementSize && i <= length(c)
                        if s+videos(cache(c(i)))<=placementSize
                            filesx(cache(c(i)))=1;s=s+videos(cache(c(i)));
                        end
                        i=i+1;
                    end
                else
                    filesx=filesprex;
                end
            end
        end      
        %% Step III Resource alloczation
        %%% Store all the demands
        d=zeros(items,1);
        new=find(vidID(tI+t)==videoData(:,1)); d(new)=videoData(new,2);
        
        %network cost and RDV for the generated flows to serve the demands  
        x=d.*filesx; y=d-x;
        costx(t) = norm([sqrt(rhoX/2)*x;sqrt(rhoY/2)*y]); 
        outx(t) = sum(y);
        
        %% Step IV Update dual variable lambda and other variables
        lambda=lambda-eps*(xA+yA-d);
    end
    
    %% Streaming ends
    costX(alpa) = sum(costx)/tMax; outX(alpa) = sum(outx)/tMax;   
end

figure(1); hold on;  
plot((1:limit),costX,'-cyanhexagram','MarkerSize',6);xlabel('Cache size (% of main library size)','FontSize', 10); ylabel('NC','FontSize', 10); legend('2LRU','LRU','RR','PRR','Least X','Location','northeast'); box on;

figure(2); hold on; 
plot((1:limit),outX,'-cyanhexagram','MarkerSize',6);xlabel('Cache size (% of main library size)','FontSize', 10); ylabel('BBC(in minutes)','FontSize', 10); legend('2LRU','LRU','RR','PRR','Least X','Location','northeast'); box on;

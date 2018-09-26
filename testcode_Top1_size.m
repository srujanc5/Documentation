clear all;close all;clc;

%% Load all the details regarding Dataset

load('videoData.mat');
load('demandDATA.mat');
load('Results_Tuning_Parameters.mat');
items = size(videoData,1); videos = videoData(:,2); % Videos information 
obs=1; % observation period in hrs.

T_vs = [6;12;24;48]; T_vsOf = 1;
T_v = T_vs(T_vsOf)*obs; %Placement update interval
rhoX = 1; rhoY = 10; rho = rhoX*rhoY/(rhoX+rhoY);%price for network flows

tI=round(0.33*size(demandDATA{obs,1}.demands,1)); % 33%of total duration has been taken to find out the tuning parameters.
tMax = size(demandDATA{obs,1}.demands,1) - tI;

%% parameter of our alg
[epsloopx,T_lambdaX] = find(costtuneHrsX{T_vsOf,1} == min(min(costtuneHrsX{T_vsOf,1})),1);
[epslooplxu,T_lambdaLXU] = find(costtuneHrsLXU{T_vsOf,1} == min(min(costtuneHrsLXU{T_vsOf,1})),1);
[epslooplxu_thr,T_lambdaLXU_THR] = find(costtuneHrsLXU_THR{T_vsOf,1} == min(min(costtuneHrsLXU_THR{T_vsOf,1})),1);

epsX = rho*epsloopx*0.001; epsLXU = rho*epslooplxu*0.001; epsLXU_THR = rho*epslooplxu_thr*0.001;
limit = 4;
%% tracking global variables
costX = zeros(limit,1); changesX = zeros(limit,1); outX = zeros(limit,1);
costLXU = zeros(limit,1); changesLXU = zeros(limit,1); outLXU = zeros(limit,1);
costLXU_THR = zeros(limit,1); changesLXU_THR = zeros(limit,1); outLXU_THR = zeros(limit,1);

%% Algorithm starts
for alpa = 1:limit
    alpa
    placementSize=sum(videos)*0.01*alpa; %placement size is alpa percent
    % Initializing with random files for all the methods
    filesRandom = placeRandom(videos,placementSize); %Finding random files
    filesx = filesRandom; fileslxu = filesRandom; fileslxu_thr = filesRandom; 

    % Initializing other parameters
    lambdaX = zeros(items,1); 
    xAX = zeros(items,1); yAX = zeros(items,1);
    lambdaLXU = zeros(items,1); 
    xALXU = zeros(items,1); yALXU = zeros(items,1);
    lambdaLXU_THR = zeros(items,1); 
    xALXU_THR = zeros(items,1); yALXU_THR = zeros(items,1);

    d_Aggx = zeros(items,1); d_Agglxu = zeros(items,1); d_Agglxu_thr = zeros(items,1); new = [];

    % tracking local variables
    costx = zeros(tMax,1); changesx = 0; outx = zeros(tMax,1);
    costlxu = zeros(tMax,1); changeslxu = 0; outlxu = zeros(tMax,1);
    costlxu_thr = zeros(tMax,1); changeslxu_thr = 0; outlxu_thr = zeros(tMax,1);
    
    %% Streaming starts
    for t = 1:tMax
        if rem(t,1000) == 0
            t
        end
        %% Step I Aggrigate the demands and allocate resources
        %%% Store all the demands
        if ~isempty(demandDATA{obs,1}.demands{tI+t,1})
            d=zeros(items,1);
            for vid = 1:size(demandDATA{obs,1}.demands{tI+t,1},1)
                f = find(demandDATA{obs,1}.demands{tI+t,1}(vid,1)==videoData(:,1));
                d(f) = demandDATA{obs,1}.demands{tI+t,1}(vid,3)*videoData(f,2);
                new = [new; find(d~=0)];
            end
            
            d_Aggx = d_Aggx + d;
            d_Agglxu = d_Agglxu + d;
            d_Agglxu_thr = d_Agglxu_thr + d;

            x=d.*filesx; y=d-x;
            costx(t) = norm([sqrt(rhoX/2)*x;sqrt(rhoY/2)*y]);
            outx(t) = sum(y);

            x=d.*fileslxu; y=d-x;
            costlxu(t) = norm([sqrt(rhoX/2)*x;sqrt(rhoY/2)*y]);
            outlxu(t) = sum(y);

            x=d.*fileslxu_thr; y=d-x;
            costlxu_thr(t) = norm([sqrt(rhoX/2)*x;sqrt(rhoY/2)*y]);
            outlxu_thr(t) = sum(y);
        end
        %% Step II Update dual variable and anticipated flows
        if rem(t,T_lambdaX) == 0
            lambdaX = lambdaX - epsX*(xAX+yAX-d_Aggx);
            xAX=(1/rhoX)*lambdaX; yAX=(1/rhoY)*lambdaX;
            d_Aggx = zeros(items,1);
        end
        
        if rem(t,T_lambdaLXU) == 0
            lambdaLXU = lambdaLXU - epsLXU*(xALXU+yALXU-d_Agglxu);
            xALXU=(1/rhoX)*lambdaLXU; yALXU=(1/rhoY)*lambdaLXU;
            d_Agglxu = zeros(items,1);
        end
        
        if rem(t,T_lambdaLXU_THR) == 0
            lambdaLXU_THR = lambdaLXU_THR - epsLXU_THR*(xALXU_THR+yALXU_THR-d_Agglxu_thr);
            xALXU_THR=(1/rhoX)*lambdaLXU_THR; yALXU_THR=(1/rhoY)*lambdaLXU_THR;
            d_Agglxu_thr = zeros(items,1);
        end    

        %% Step III placement
        % call place function for all our techniques
        if rem(t,T_v) == 0
            filesprex = filesx; filesprelxu = fileslxu; filesprelxu_thr = fileslxu_thr; 

            filesx = placeX(videos,placementSize,xAX);
            fileslxu = placeLXU(videos,placementSize,xALXU,unique(new),filesprelxu);
            fileslxu_thr=placeLXU_THR(videos,placementSize,xALXU_THR,unique(new),filesprelxu_thr);
            
            new = [];
            %BBC in minutes.
            changesx = changesx + sum(videos(filesprex-filesx<0));
            changeslxu = changeslxu + sum(videos(filesprelxu-fileslxu<0));
            changeslxu_thr = changeslxu + sum(videos(filesprelxu_thr-fileslxu_thr<0));

        end


    end


    %% updating all global tracking variables;
    costX(alpa) = sum(costx)/tMax; changesX(alpa) = changesx/tMax; outX(alpa) = sum(outx)/tMax;
    costLXU(alpa) = sum(costlxu)/tMax; changesLXU(alpa) = changeslxu/tMax; outLXU(alpa) = sum(outlxu)/tMax;
    costLXU_THR(alpa) = sum(costlxu_thr)/tMax; changesLXU_THR(alpa) = changeslxu_thr/tMax; outLXU_THR(alpa) = sum(outlxu_thr)/tMax;
    
end

figure(1); hold on;
plot((1:limit),costLXU,'-r+','MarkerSize',6); xlabel('Cache size (% of main library size)','FontSize', 10); ylabel('NC','FontSize', 10); hold on; 
plot((1:limit),costLXU_THR,'-gpentagram','MarkerSize',6);hold on;
plot((1:limit),costX,'-cyanhexagram','MarkerSize',6);legend('Least X','Least X_{Th}','Top X','Location','northeast');hold off;box on;

figure(2); hold on;
plot((1:limit),outLXU,'-r+','MarkerSize',6); xlabel('Cache size (% of main library size)','FontSize', 10); ylabel('RDV (min.)','FontSize', 10); hold on;
plot((1:limit),outLXU_THR,'-gpentagram','MarkerSize',6);hold on;
plot((1:limit),outX,'-cyanhexagram','MarkerSize',6);legend('Least X','Least X_{Th}','Top X','Location','northeast');hold off;box on;

figure(3); hold on;
plot((1:limit),changesLXU,'-r+','MarkerSize',6); xlabel('Cache size (% of main library size)','FontSize', 10); ylabel('BBC (min.)','FontSize', 10); hold on;
plot((1:limit),changesLXU_THR,'-gpentagram','MarkerSize',6);hold on;
plot((1:limit),changesX,'-cyanhexagram','MarkerSize',6);legend('Least X','Least X_{Th}','Top X','Location','northeast');hold off;box on;



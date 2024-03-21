%analyze_length_grating.m

%   uses files created by: regressPrfSplit_length.m, getVoxPref_length.m
%   creates files used by:

%% 2. Grating voxel preference %%
prffolder = '/bwlab/Users/SeoheeHan/NSDData/rothzn/nsd/Length/prfsample_Len/';
roiNames = {'V1v','V1d','V2v','V2d','V3v','V3d','hV4','OPA','PPA','RSC'};
combinedRoiNames = {'V1','V2','V3','hV4','OPA','PPA','RSC'};

for isub = 1:8
    fprintf('%d ...\n',isub);
    clearvars -except isub roiNames combinedRoiNames prffolder
    load(fullfile([prffolder, 'voxModelPref_sub', num2str(isub), '.mat']), 'roiLen');

    % save all ROIs to create overlay
    roifolder = ['/bwdata/NSDData/nsddata/ppdata/subj0' num2str(isub) '/func1pt8mm/'];
    visualRoisFile = fullfile(roifolder,'roi/prf-visualrois.nii.gz');%V1v, V1d, V2v, V2d, V3v, V3d, and hV4
    visRoiData = niftiread(visualRoisFile);
    placesRoisFile = fullfile(roifolder,'roi/floc-places.nii.gz'); %OPA, PPA, RSC
    placeRoiData = niftiread(placesRoisFile);

    allRoiData = visRoiData;
    allRoiData(placeRoiData == 1) = 8;
    allRoiData(placeRoiData == 2) = 9;
    allRoiData(placeRoiData == 3) = 10;

    ourBrain = allRoiData;
    ourBrain(ourBrain == 2) = 1;
    ourBrain(ourBrain == 3 | ourBrain == 4) = 2;
    ourBrain(ourBrain == 5 | ourBrain == 6) = 3;
    ourBrain(ourBrain == 7) = 4;
    ourBrain(ourBrain == 8) = 5;
    ourBrain(ourBrain == 9) = 6;
    ourBrain(ourBrain == 10) = 7;

    % make a brain volume
    newBrain = ourBrain;
    newBrain(newBrain > 0) = 0;
    for visualRegion = 1:7
        curOurBrain = ourBrain;
        if visualRegion == 2
            curOurBrain(visRoiData == 3 | visRoiData == 4) = 2;
        elseif visualRegion == 3
            curOurBrain(visRoiData == 5 | visRoiData == 6) = 3;
        end
        thisfield = combinedRoiNames{visualRegion};
        newBrain(curOurBrain == visualRegion) = roiLen{visualRegion}(3,:);
    end
    newBrain(newBrain < 0) = -1;

    for visualRegion = 1:7
        curOurBrain = ourBrain;
        if visualRegion == 2
            curOurBrain(visRoiData == 3 | visRoiData == 4) = 2;
        elseif visualRegion == 3
            curOurBrain(visRoiData == 5 | visRoiData == 6) = 3;
        end
        curNewBrain = curOurBrain;
        curNewBrain(curOurBrain ~= visualRegion) = -1;
        thisfield = combinedRoiNames{visualRegion};

        curNewBrain(curOurBrain == visualRegion) = roiLen{visualRegion}(3,:);

        newBrainbyROI(:,:,:,visualRegion) =curNewBrain;
    end

    saveName = ['/bwlab/Users/SeoheeHan/NSDData/rothzn/nsd/Length/brainVolume/grating_lengthBrain_sub', num2str(isub), '.mat'];
    save(saveName, 'newBrain');

    saveName = ['/bwlab/Users/SeoheeHan/NSDData/rothzn/nsd/Length/brainVolume/grating_lengthBrainbyROI_sub', num2str(isub), '.mat'];
    save(saveName, 'newBrainbyROI');

    %% Divide by Eccentricity
    saveFolder = '/bwlab/Users/SeoheeHan/NSDData/rothzn/nsd/Length/brainVolume/';
    load([saveFolder, 'grating_lengthBrain_sub', num2str(isub), '.mat']);
    load([saveFolder, 'grating_lengthBrainbyROI_sub', num2str(isub), '.mat']);

    betasfolder = ['/bwdata/NSDData/nsddata/ppdata/subj0' num2str(isub) '/func1pt8mm/'];
    eccFile = fullfile(betasfolder,'prf_eccentricity.nii.gz');
    r2file = fullfile(betasfolder,'prf_R2.nii.gz');
    eccData = niftiread(eccFile);
    r2Data = niftiread(r2file);

    % image size 8.4° of visual angle. Cut off should be half of the size
    eccData(eccData>4.2) = NaN;
    eccData(r2Data<0) = NaN;
    % edges = [0 1 2 3 4.2];
    eccData(eccData >=  0 | eccData <  1) = 1;
    eccData(eccData >=  1 | eccData <  2) = 2;
    eccData(eccData >=  2 | eccData <  3) = 3;
    eccData(eccData >=  3 | eccData <=  4.2) = 4;

    for curEcc = 1:4
        curNewBrain = newBrain;
        curNewBrain(eccData ~= curEcc) = -1;
        newBrainbyECC(:,:,:,curEcc) =curNewBrain;
    end
 
    for visualRegion = 1:7
        for curEcc = 1:4
            curNewBrain = newBrainbyROI(:,:,:,visualRegion);
            curNewBrain(eccData ~= curEcc) = -1;
            curSubBrik = curEcc + 4*(visualRegion-1);
            newBrainbyROIbyECC(:,:,:,curSubBrik) =curNewBrain;
        end
    end

    %% save afni file
    % size(newBrain)
    cd('/bwlab/Users/SeoheeHan/NSDData/rothzn/nsd/Length/brainVolume');
    %3dinfo betas_session01.nii.gz
    %3dcalc -a betas_session01.nii.gz[1] -expr a -prefix oneBeta
    % command = ['3dinfo betas_session01_sub', num2str(isub), '.nii.gz'];
    % system(command);
    % command = ['3dcalc -a betas_session01_sub', num2str(isub), '.nii.gz[1] -expr a -prefix oneBeta_sub', num2str(isub)];
    % system(command);

    currOneBeta = ['oneBeta_sub', num2str(isub), '+orig'];
    [err,V,Info] = BrikLoad(currOneBeta);

    Info.RootName = ['grating_lengthBrain_sub', num2str(isub), '+orig'];
    opt.Prefix = ['grating_lengthBrain_sub', num2str(isub)];
    WriteBrik(newBrain,Info,opt);
    Info.RootName = ['grating_lengthBrainbyROI_sub', num2str(isub), '+orig'];
    opt.Prefix = ['grating_lengthBrainbyROI_sub', num2str(isub)];
    WriteBrik(newBrainbyROI,Info,opt);

    Info.RootName = ['grating_lengthBrainbyECC_sub', num2str(isub), '+orig'];
    opt.Prefix = ['grating_lengthBrainbyECC_sub', num2str(isub)];
    WriteBrik(newBrain,Info,opt);
    Info.RootName = ['grating_lengthBrainbyROIbyECC_sub', num2str(isub), '+orig'];
    opt.Prefix = ['grating_lengthBrainbyROIbyECC_sub', num2str(isub)];
    WriteBrik(newBrainbyROIbyECC,Info,opt);

    %% save nifti file
    % niftiwrite(newBrain,'lengthBrain_sub1.nii');
    % info_old = niftiinfo('betas_session01_sub1.nii.gz');
    % info_new = niftiinfo('lengthBrain_sub1.nii');
    %
    % info_new.PixelDimensions = [1.8, 1.8, 1.8];
    % info_new.TransformName = info_old.TransformName;
    % info_new.SpatialDimension = info_old.SpatialDimension;
    % info_new.Transform = info_old.Transform;
    % info_new.Qfactor = info_old.Qfactor;
    % info_new.AuxiliaryFile = info_old.AuxiliaryFile;
    % info_new.raw.pixdim = info_old.raw.pixdim;
    % info_new.raw.aux_file = info_old.raw.aux_file;
    % info_new.raw.sform_code = info_old.raw.sform_code;
    % info_new.raw.srow_x = info_old.raw.srow_x;
    % info_new.raw.srow_y = info_old.raw.srow_y;
    % info_new.raw.srow_z = info_old.raw.srow_z;
    %
    % niftiwrite(newBrain,'lengthBrain_sub1.nii',info_new);
end






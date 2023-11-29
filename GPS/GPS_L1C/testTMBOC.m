codeFreq = 1.023e6;
codeLength = 10230;
PRN = 1;

% Get a vector with the pilot BOC(1,1) spreading waveform replicated 10x
pilotBOC11 = repmat(generateL1Cpboc11code(PRN), 1, 10);
pilotBOC61 = repmat(generateL1Cpboc61code(PRN), 1, 10);

% Generate replica codes at 20 Msps and 2Msps
replicaBOC11 = generateL1Cpboc11code(PRN);
replicaBOC61 = generateL1Cpboc61code(PRN);
sampledReplica20 = sampleTMBOC(replicaBOC11, replicaBOC61, 20e6);
sampledReplica2 = sampleTMBOC(replicaBOC11, replicaBOC61, 2e6);

% Sample at 20 Msps and do autocorrelation
sampledCode20 = sampleTMBOC(pilotBOC11, pilotBOC61, 20e6);
autoCorr20 = xcorr(sampledCode20, sampledReplica20);
autoCorr20Length = (length(autoCorr20) +  1) /2;
autoCorr20 = autoCorr20(autoCorr20Length : autoCorr20Length * 2 - 1);

% Resample at 2 Msps and do autocorrelation
sampledCode2 = resample(sampledCode20, 1, 10);
autoCorr2 = xcorr(sampledCode2, sampledReplica2);
autoCorr2Length = (length(autoCorr2) +  1) /2;
autoCorr2 = autoCorr2(autoCorr2Length : autoCorr2Length * 2 - 1);

figure(1);

subplot(1,2,1);
plot(abs(autoCorr20));
title('AutoCorr of PRN 1 at 20 Msps');
xlabel('Samples');
ylabel('Correlation Energy');
xlim([-20000, inf]);

subplot(1,2,2);
plot(abs(autoCorr2));
title('AutoCorr of PRN 1 at Filtered 2 Msps');
xlabel('Samples');
ylabel('Correlation Energy');
xlim([-1000, inf]);

function pilot_promptCode = sampleTMBOC(pilotBOC11, pilotBOC61, samplingFreq)
    codeFreq = 1.023e6;
    codeLength = 10230;
    codePhaseStep = codeFreq / samplingFreq;
    
    % Find the size of a "block" or code period in whole samples
    blksize = ceil(codeLength / codePhaseStep);
    
    % Define index into prompt code vector
    tcode       = 0 : ...
        codePhaseStep*2 : ...
        ((blksize-1)*codePhaseStep)*2*length(pilotBOC11)/codeLength/2;
    tcode2      = floor(tcode) + 1;
    
    % Perform sampling
    pilot_promptCode   = pilotBOC11(tcode2);
    tcode3       = 0 : ...
        codePhaseStep*12 : ...
        ((blksize-1) * codePhaseStep)*12*length(pilotBOC11)/codeLength/2;
    tcode4      = floor(tcode3) + 1;
    p61_promptCode = pilotBOC61(tcode4);
    for sample=1:length(tcode2)
        sampleMod = mod(tcode2(sample)-1, 66);
        if sampleMod == 1 || sampleMod == 2 ||... %chip 0
                sampleMod == 9 || sampleMod == 10 ||... %chip 4
                sampleMod == 13 || sampleMod == 14 ||... %chip 6
                sampleMod == 59 || sampleMod == 60 % chip 29
            pilot_promptCode(sample) = p61_promptCode(sample);
        end
    end
end
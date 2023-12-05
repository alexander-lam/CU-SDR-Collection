codeFreq = 1.023e6;
codeLength = 10230;
c = 299792458; % m/s
PRN = 1;

% Get a vector with the pilot BOC(1,1) spreading waveform replicated 10x
pilotBOC11 = repmat(generateL1Cpboc11code(PRN), 1, 10);
pilotBOC61 = repmat(generateL1Cpboc61code(PRN), 1, 10);

% Generate replica codes at 50 Msps
replicaBOC11 = generateL1Cpboc11code(PRN);
replicaBOC61 = generateL1Cpboc61code(PRN);
replica50 = sampleTMBOC(pilotBOC11, pilotBOC61, 50e6);

% Full BW autocorrelation
autoCorr50 = xcorr(replica50, replica50);
autoCorr50Length = (length(autoCorr50) + 1) /2;
autoCorr50 = autoCorr50(autoCorr50Length : autoCorr50Length * 2 - 1);

% LP Filter at 5 MHz and do autocorrelation
filteredCode10 = lowpass(replica50, 5e6, 50e6);
autoCorr10 = xcorr(filteredCode10, replica50);
autoCorr10Length = (length(autoCorr10) +  1) /2;
autoCorr10 = autoCorr10(autoCorr10Length : autoCorr10Length * 2 - 1);

% LP Filter at 2.5 MHz and do autocorrelation
filteredCode5 = lowpass(replica50, 2.5e6, 50e6);
autoCorr5 = xcorr(filteredCode5, replica50);
autoCorr5Length = (length(autoCorr5) +  1) /2;
autoCorr5 = autoCorr5(autoCorr5Length : autoCorr5Length * 2 - 1);

% LP Filter at 1 MHz and do autocorrelation
filteredCode2 = lowpass(replica50, 1e5, 50e6);
autoCorr2 = xcorr(filteredCode2, replica50);
autoCorr2Length = (length(autoCorr2) +  1) /2;
autoCorr2    = autoCorr2(autoCorr2Length : autoCorr2Length * 2 - 1);

figure(1);

subplot(2,2,1);
plot(linspace(-2, 2, 201), abs(autoCorr50(500001-100:500001+100)));
title('AutoCorr of PRN 1 at 50 MHz BW');
xlabel('Samples Relative to Peak');
ylabel('Correlation Energy');

subplot(2,2,2);
plot(linspace(-2, 2, 201), abs(autoCorr10(500001-100:500001+100)));
title('AutoCorr of PRN 1 at 10 MHz BW');
xlabel('Samples Relative to Peak');
ylabel('Correlation Energy');

subplot(2,2,3);
plot(linspace(-2, 2, 201), abs(autoCorr5(500001-100:500001+100)));
title('AutoCorr of PRN 1 at 5 MHz BW');
xlabel('Samples Relative to Peak');
ylabel('Correlation Energy');

subplot(2,2,4);
plot(linspace(-2, 2, 201), abs(autoCorr2(500001-100:500001+100)));
title('AutoCorr of PRN 1 at 2 MHz BW');
xlabel('Samples Relative to Peak');
ylabel('Correlation Energy');

figure(2);

subplot(2,2,1);
plot(linspace(-0.3, 0.3, 31)/codeFreq*c, abs(autoCorr50(500001-15:500001+15)));
title('Zoomed AutoCorr of PRN 1 at 50 MHz BW');
xlabel('Pseudorange Relative to Peak [m]');
ylabel('Correlation Energy');

subplot(2,2,2);
plot(linspace(-0.3, 0.3, 31)/codeFreq*c, abs(autoCorr10(500001-15:500001+15)));
title('Zoomed AutoCorr of PRN 1 at 10 MHz BW');
xlabel('Pseudorange Relative to Peak [m]');
ylabel('Correlation Energy');

subplot(2,2,3);
plot(linspace(-0.3, 0.3, 31)/codeFreq*c, abs(autoCorr5(500001-15:500001+15)));
title('Zoomed AutoCorr of PRN 1 at 5 MHz BW');
xlabel('Pseudorange Relative to Peak [m]');
ylabel('Correlation Energy');

subplot(2,2,4);
plot(linspace(-0.3, 0.3, 31)/codeFreq*c, abs(autoCorr2(500001-15:500001+15)));
title('Zoomed AutoCorr of PRN 1 at 2 MHz BW');
xlabel('Pseudorange Relative to Peak [m]');
ylabel('Correlation Energy');

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
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
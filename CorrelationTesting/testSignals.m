addpath include;

codeFreq_L1CA = 1.023e6;
codeLength_L1CA = 1023;
codeFreq_L1C = 1.023e6;
codeLength_L1C = 1023;
codeFreq_L5 = 10.23e6;
codeLength_L5 = 10230;
codeFreq_E1C = 1.023e6;
codeLength_E1C = 4092;

c = 299792458; % m/s
samplingFreq = 50e6; % Hz
PRN = 19;

%% L1 C/A
% Get a vector with the C/A code replicated 10x
caCode = repmat(generateCAcode(PRN), 1, 10);

% Generate replica code at 50 Msps
codePhaseStep_L1CA = codeFreq_L1CA / samplingFreq;
blksize = ceil(codeLength_L1CA / codePhaseStep_L1CA);
tcode       = 0 : ...
    codePhaseStep_L1CA : ...
    ((blksize-1)*codePhaseStep_L1CA)*length(caCode)/codeLength_L1CA;
tcode2      = floor(tcode) + 1;
replica50_L1CA = caCode(tcode2);

% Full BW autocorrelation
autoCorr50_L1CA = xcorr(replica50_L1CA, replica50_L1CA);
autoCorr50Length_L1CA = (length(autoCorr50_L1CA) + 1) /2;
autoCorr50_L1CA = autoCorr50_L1CA(autoCorr50Length_L1CA : autoCorr50Length_L1CA * 2 - 1);

%% L1C
% Get a vector with the pilot spreading waveforms replicated 10x
pilotBOC11 = repmat(generateL1Cpboc11code(PRN), 1, 10);
pilotBOC61 = repmat(generateL1Cpboc61code(PRN), 1, 10);

% Generate replica codes at 50 Msps
replica50_L1C = sampleTMBOC(pilotBOC11, pilotBOC61, samplingFreq);

% Full BW autocorrelation
autoCorr50_L1C = xcorr(replica50_L1C, replica50_L1C);
autoCorr50Length_L1C = (length(autoCorr50_L1C) + 1) /2;
autoCorr50_L1C = autoCorr50_L1C(autoCorr50Length_L1C : autoCorr50Length_L1C * 2 - 1);

%% L5
% Get a vector with the L5C pilot code replicated 10x
pilotL5 = repmat(generateL5Qcode(PRN), 1, 10);

% Generate replica code at 50 Msps
codePhaseStep_L5 = codeFreq_L5 / samplingFreq;
blksize = ceil(codeLength_L5 / codePhaseStep_L5);
tcode       = 0 : ...
    codePhaseStep_L5 : ...
    ((blksize-1)*codePhaseStep_L5)*length(pilotL5)/codeLength_L5;
tcode2      = floor(tcode) + 1;
replica50_L5 = pilotL5(tcode2);

% Full BW autocorrelation
autoCorr50_L5 = xcorr(replica50_L5, replica50_L5);
autoCorr50Length_L5 = (length(autoCorr50_L5) + 1) /2;
autoCorr50_L5 = autoCorr50_L5(autoCorr50Length_L5 : autoCorr50Length_L5 * 2 - 1);

%% E1C
% Get a vector with the E1C pilot code replicated 10x
pilotE1C = repmat(generateE1Ccode(PRN), 1, 10);

% Generate replica code at 50 Msps
codePhaseStep_E1C = codeFreq_E1C / samplingFreq;
blksize = ceil(codeLength_E1C / codePhaseStep_E1C);
tcode       = 0 : ...
    codePhaseStep_E1C*2 : ...
    ((blksize-1)*codePhaseStep_E1C)*length(pilotE1C)/codeLength_E1C;
tcode2      = floor(tcode) + 1;
replica50_E1C = pilotE1C(tcode2);

% Full BW autocorrelation
autoCorr50_E1C = xcorr(replica50_E1C, replica50_E1C);
autoCorr50Length_E1C = (length(autoCorr50_E1C) + 1) /2;
autoCorr50_E1C = autoCorr50_E1C(autoCorr50Length_E1C : autoCorr50Length_E1C * 2 - 1);

%% Plots
L1CA_chipsToShow = 0.3;
figure(1);
clf(1);
set(groot,'defaultLineLineWidth',2.0)

hold on;
plot(linspace(-L1CA_chipsToShow, L1CA_chipsToShow, 100*L1CA_chipsToShow+1)*c/codeFreq_L1CA,...
    abs(autoCorr50_L1CA(50001-50*L1CA_chipsToShow:50001+50*L1CA_chipsToShow)/...
    max(autoCorr50_L1CA(50001-50*L1CA_chipsToShow:50001+50*L1CA_chipsToShow))));

plot(linspace(-L1CA_chipsToShow, L1CA_chipsToShow, 100*L1CA_chipsToShow+1)*c/codeFreq_L1CA,...
    abs(autoCorr50_L1C(500001-50*L1CA_chipsToShow:500001+50*L1CA_chipsToShow)/...
    max(autoCorr50_L1C(500001-50*L1CA_chipsToShow:500001+50*L1CA_chipsToShow))));

plot(linspace(-L1CA_chipsToShow, L1CA_chipsToShow, 100*L1CA_chipsToShow+1)*c/codeFreq_L1CA,...
    abs(autoCorr50_L5(50001-50*L1CA_chipsToShow:50001+50*L1CA_chipsToShow)/...
    max(autoCorr50_L5(50001-50*L1CA_chipsToShow:50001+50*L1CA_chipsToShow))));

plot(linspace(-L1CA_chipsToShow, L1CA_chipsToShow, 100*L1CA_chipsToShow+1)*c/codeFreq_L1CA,...
    abs(autoCorr50_E1C(400001-50*L1CA_chipsToShow:400001+50*L1CA_chipsToShow)/...
    max(autoCorr50_E1C(400001-50*L1CA_chipsToShow:400001+50*L1CA_chipsToShow))));

title('Autocorrelation of GNSS Signals');
xlabel('Pseudorange Relative to Peak [m]');
ylabel('Normalized Correlation Energy');
axis('tight');
legend('GPS L1 C/A', 'GPS L1C', 'GPS L5', 'GAL E1C');

hold off;
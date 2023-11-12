function acqResults = acquisition(longSignal, settings)
%Function performs cold start acquisition on the collected "data". It
%searches for GPS signals of all satellites, which are listed in field
%"acqSatelliteList" in the settings structure. Function saves code phase
%and frequency of the detected signals in the "acqResults" structure.
%
%acqResults = acquisition(longSignal, settings)
%
%   Inputs:
%       longSignal    - 11 ms of raw signal from the front-end
%       settings      - Receiver settings. Provides information about
%                       sampling and intermediate frequencies and other
%                       parameters including the list of the satellites to
%                       be acquired.
%   Outputs:
%       acqResults    - Function saves code phases and frequencies of the
%                       detected signals in the "acqResults" structure. The
%                       field "carrFreq" is set to 0 if the signal is not
%                       detected for the given PRN number.

%--------------------------------------------------------------------------
%                         CU Multi-GNSS SDR
% (C) Updated by Yafeng Li, Nagaraj C. Shivaramaiah and Dennis M. Akos
% Based on the original work by Darius Plausinaitis,Peter Rinder,
% Nicolaj Bertelsen and Dennis M. Akos
%--------------------------------------------------------------------------
%This program is free software; you can redistribute it and/or
%modify it under the terms of the GNU General Public License
%as published by the Free Software Foundation; either version 2
%of the License, or (at your option) any later version.
%
%This program is distributed in the hope that it will be useful,
%but WITHOUT ANY WARRANTY; without even the implied warranty of
%MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%GNU General Public License for more details.
%
%You should have received a copy of the GNU General Public License
%along with this program; if not, write to the Free Software
%Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301,
%USA.
%--------------------------------------------------------------------------

%CVS record:
%$Id: acquisition.m,v 1.1.2.12 2006/08/14 12:08:03 dpl Exp $

%% Condition input signal to speed up acquisition ===================
if (settings.samplingFreq > settings.resamplingThreshold && ...
        settings.resamplingflag == 1)
    % Mix to baseband
    ts = 1/settings.samplingFreq;
    phasePoints = (0 : (length(longSignal) - 1)) * 2 * pi * ts;
    sigCarr = exp(-1i * settings.IF * phasePoints);
    I      = real(sigCarr .* longSignal);
    Q      = imag(sigCarr .* longSignal);
    longSignal = I + 1i*Q;
    oldIF = settings.IF;
    settings.IF = 0;

    % Resample data
    desiredReSamplingFreq = 2e6;
    sampleDuration = length(longSignal)/settings.samplingFreq;
    [resample_numer,resample_denom] = ...
        rat((desiredReSamplingFreq*sampleDuration)/ ...
        (settings.codeLength*sampleDuration*1000* ...
        (settings.samplingFreq/settings.codeFreqBasis)));
    longSignal = resample(longSignal, resample_numer, resample_denom);

    oldFreq = settings.samplingFreq;
    settings.samplingFreq = length(longSignal)/sampleDuration;
end % resampling input IF signals

%% Initialization ===================================================
%--- Varaibles for coarse acquisition -------------------------------------
% Find number of samples per spreading code
samplesPerCode = round(settings.samplingFreq / ...
    (settings.codeFreqBasis / settings.codeLength));
% Find sampling period
ts = 1 / settings.samplingFreq;
% Find phase points of 2ms local carrier wave (1ms for local duplicate,
% the other 1ms for zero padding) - twice the coherent integration time
phasePoints = (0 : (samplesPerCode * 2 * settings.acqCohTime -1)) * 2 * pi * ts;
% Number of the frequency bins for the specified search band
numberOfFreqBins = round(settings.acqSearchBand * 2 / settings.acqSearchStep) + 1;
% Carrier frequency bins to be searched
coarseFreqBin = zeros(1, numberOfFreqBins);

%--- Initialize acqResults ------------------------------------------------
% Carrier frequencies of detected signals
acqResults.carrFreq     = zeros(1, 32);
% C/A code phases of detected signals
acqResults.codePhase    = zeros(1, 32);
% Correlation peak ratios of the detected signals
acqResults.peakMetric   = zeros(1, 32);

% Perform search for all listed PRN numbers ...
fprintf('(');
for PRN = settings.acqSatelliteList
    %% Coarse acquisition ===========================================
    % Generate pilot codes and sample them according to the sampling freq.
    caCodesTable = makeL1Cpboc11Table(PRN,settings);
    % Add zero-padding samples to double CA code length
    caCodes2ms = [caCodesTable zeros(1,samplesPerCode*settings.acqCohTime)];
    % Search results of all frequency bins and code shifts (for one satellite)
    results = zeros(numberOfFreqBins, samplesPerCode);
    %--- Perform DFT of C/A code ------------------------------------------
    caCodeFreqDom = conj(fft(caCodes2ms));

    %--- Make the correlation for all frequency bins
    for freqBinIndex = 1:numberOfFreqBins
        % Generate carrier wave frequency grid
        coarseFreqBin(freqBinIndex) = settings.IF + settings.acqSearchBand - ...
            settings.acqSearchStep * (freqBinIndex - 1);
        % Generate local sine and cosine
        sigCarr = exp(-1i * coarseFreqBin(freqBinIndex) * phasePoints);

        %--- Do correlation -----------------------------------------------
        for nonCohIndex = 1: settings.acqNonCohTime / settings.acqCohTime
            % Take 2ms vectors of input data to do correlation
            signal = longSignal((nonCohIndex - 1) * samplesPerCode * settings.acqCohTime + ...
                1 : (nonCohIndex + 1) * samplesPerCode * settings.acqCohTime);
            % "Remove carrier" from the signal
            I      = real(sigCarr .* signal);
            Q      = imag(sigCarr .* signal);
            % Convert the baseband signal to frequency domain
            IQfreqDom = fft(I + 1i*Q);
            % Multiplication in the frequency domain (correlation in
            % time domain)
            convCodeIQ = IQfreqDom .* caCodeFreqDom;
            % Perform inverse DFT and store correlation results
            cohResult = abs(ifft(convCodeIQ));
            [~, maxIndex] = max(cohResult);
            codePeriodStart = floor((maxIndex-1)/samplesPerCode)*samplesPerCode+1;
            codePeriodEnd = codePeriodStart + samplesPerCode - 1;
            cohResult = cohResult(codePeriodStart:codePeriodEnd);
            % Non-coherent integration
            results(freqBinIndex, :) = results(freqBinIndex, :) + cohResult; %nonCohResult;
        end % nonCohIndex = 1: settings.acqNonCohTime
    end % frqBinIndex = 1:numberOfFreqBins

    %% Look for correlation peaks for coarse acquisition ============
    % Find the correlation peak and the carrier frequency
    [~, acqCoarseBin] = max(max(results, [], 2));
    maxFreqBin = results(acqCoarseBin, :);
    %--- Find time constants --------------------------------------------------
    % Compute code phase offset array by sampling frequency
    tc = 1/settings.codeFreqBasis;  % C/A chip period in sec
    codePhaseOffset = (ts * (1:samplesPerCode)) / tc;
    codePhaseOffset = [0 codePhaseOffset(1:end-1)];

    % Find code phase of the same correlation peak
    [highestPeak, codePhase] = max(maxFreqBin);
    % Remove +/- 1 chip of data surrounding correlation peak
    maxFreqBin(max(0, floor(codePhase-samplesPerCode/settings.codeLength)):min(length(maxFreqBin), ceil(codePhase+samplesPerCode/settings.codeLength))) = [];

    % Compute next highest peak and read out acquisition metric
    nextHighestPeak = max(maxFreqBin);
    acqResults.peakMetric(PRN) = highestPeak/nextHighestPeak;

    % If the result is above threshold, then there is a signal ...
    if acqResults.peakMetric(PRN) > settings.acqThreshold
        acqResults.carrFreq(PRN) = coarseFreqBin(acqCoarseBin);
        acqResults.codePhase(PRN) = codePhase;
        % Indicate PRN number of the detected signal
        fprintf('%02d ', PRN);

        %% Downsampling recovery ====================================
        % Find acquisition results corresponding to orignal sampling freq
        if (exist('oldFreq', 'var') && settings.resamplingflag == 1)
            % Find code phase
            acqResults.codePhase(PRN) = floor((codePhase - 1)/ ...
                settings.samplingFreq * oldFreq)+1;

            % Doppler frequency
            if (settings.IF >= settings.samplingFreq/2)
                % In this condition, the FFT computed freq. is symmetric
                % with the true frequemcy about half of the sampling
                % frequency, so we have the following:
                IF_temp = settings.samplingFreq - settings.IF;
                doppler = IF_temp - acqResults.carrFreq(PRN);
            else
                doppler = acqResults.carrFreq(PRN) - settings.IF;
            end

            % Carrier freq. corresponding to orignal sampling freq
            acqResults.carrFreq(PRN) = doppler + oldIF;
            coarseFreqBin = coarseFreqBin + oldIF;
        end

        % Plots
        figure(900+PRN);
        subplot(3,2,1);
        plot(coarseFreqBin/1e6, max(results, [], 2));
        xlabel('IF (MHz)');
        ylabel('Correlation Energy');
        title('Frequency Bin for Maximum Code Phase');
        axis tight;

        subplot(3,2,2);
        plot(codePhaseOffset, results(acqCoarseBin, :));
        xlabel('Code Phase Offset (chips)');
        ylabel('Correlation Energy');
        title('Code Phase for Maximum Frequency Bin');
        axis tight;

        subplot(3,2,3:6);
        if length(codePhaseOffset) * length(coarseFreqBin) > 5e6
            numFreqBins = 5e6 / length(codePhaseOffset);
            plotFreqBins = coarseFreqBin(ceil(max(1, acqCoarseBin-numFreqBins/2)):floor(min(acqCoarseBin+numFreqBins/2, length(coarseFreqBin))));
            results2Plot = results(ceil(max(1, acqCoarseBin-numFreqBins/2)):floor(min(acqCoarseBin+numFreqBins/2, length(coarseFreqBin))), :);
        else
            plotFreqBins = coarseFreqBin;
            results2Plot = results;
        end
        [X,Y] = meshgrid(codePhaseOffset, plotFreqBins/1e6);
        surf(X, Y, results2Plot, 'EdgeColor','none');
        xlabel('Code Phase Offset (chips)');
        ylabel('IF (MHz)');
        zlabel('Correlation Energy');
        title(['Exhaustive Acquisition Results for PRN ' num2str(PRN) ' - Acq Metric = ' num2str(acqResults.peakMetric(PRN))]);
        axis tight;

    else
        %--- No signal with this PRN --------------------------------------
        fprintf('. ');
    end   % if (peakSize/secondPeakSize) > settings.acqThreshold

end    % for PRN = satelliteList

%=== Acquisition is over ==================================================
fprintf(')\n');

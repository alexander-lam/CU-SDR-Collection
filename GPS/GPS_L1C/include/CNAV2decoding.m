function [eph, firstSubFrame,TOW] = CNAV2decoding(trackResults,channelNr,settings)
% Frame synchronization is completed by correlating the L1C overlay code
% with the L1C pilot channel. Polarity checks completed by verifying valid
% result for subframe 1. CRC-24Q parity check included for subframes 2 and
% 3. Subframes 1 and 2 are decoded, subframe 3 is ignored.
%[eph, firstSubFrame,TOW] = CNAV2decoding(trackResults,channelNr,settings)
%
%   Inputs:
%       I_P_InputBits   - output from the tracking function
%
%   Outputs:
%       firstSubframe   - Starting positions of the first message in the
%                       input bit stream I_P_InputBits in each channel.
%                       The position is CNAV bit(20ms before convolutional decoding)
%                       count since start of tracking. Corresponding value will
%                       be set to inf if no valid preambles were detected in
%                       the channel.
%       TOW             - Time Of Week (TOW) of the first message(in seconds).
%                       Corresponding value will be set to inf if no valid preambles
%                       were detected in the channel.
%       eph             - SV ephemeris.

%--------------------------------------------------------------------------
%
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

%--- Initialize ephemeris structute  --------------------------------------
% This is in order to make sure variable 'eph' for each SV has a similar
% structure when ephemeris for a given PRN is not decoded.
eph = eph_structure_init();

% Starting positions of the first message in the input bit stream
firstSubFrame = inf;

% TOW of the first message
TOW = inf;

%% frame sync using pilot channel secondary code ====================
bits = trackResults(channelNr).Pilot_I_P;

% Now threshold the output and convert it to -1 and +1
bits(bits > 0)  =  1;
bits(bits <= 0) = -1;

% Generate B1C secondary code of pilot channel for frame sync
Secondary = generateL1CoCode(trackResults(channelNr).PRN);

%--- Find at what index the preambles start -------------------------------
XcorrResult = xcorr(bits, Secondary);

% Take the second half of the correlation values
xcorrLength = (length(XcorrResult) +  1) /2;
XcorrResult = XcorrResult(xcorrLength : xcorrLength * 2 - 1);

clear index;
% Each L1C frame has 1800 bits
index = find(abs(XcorrResult)>= 1799.5)';

% The whole CNAV-2 frame bits (original) before encoding
decodedNav = zeros(1,883);

% Creates a CRC detector System object
crcDet = comm.CRCDetector([24 23 18 17 14 11 10 7 6 5 4 3 1 0]);

%% L1C data decoding and ephemeris extract ==========================
for i = 1:size(index) % For each occurrence
    I_P = trackResults(channelNr).I_P(index(i): index(i) + 1799);
    Q_P = trackResults(channelNr).Q_P(index(i): index(i) + 1799);
    
    % Take the CNAV-2 symbols with one-frame length from data-channel
    % prompt correlation values and change them to "1" and "0"
    bits = I_P;
    bits(bits > 0)  =  1;
    bits(bits <= 0) = 0;

    % Retain raw data for LDPC decoding and compute noise variance
    rawData = I_P + 1j * Q_P;
    Z = I_P.^2 + Q_P.^2;
    % Calculate the mean and variance of the Power
    Zm = mean(Z);
    Zv = var(Z);
    % Calculate the average carrier power
    Pav = sqrt(Zm^2 - Zv);
    % Calculate the variance of the noise
    Nv = 0.5 * (Zm - Pav);
    
    %--- First subframe decoding ------------------------------------------
    % Covert symbol polarity: 0 -> 1 and 1 -> -1
    checkBits  = 1 - 2 * bits(2:52);
    % BCH(51,8) decoding
    [flag,decodedBits] = BCH51_8Decoding(checkBits);
    
    % If BCH(51,8) check passes, the CNAV-2 symbol polarity is right;
    % otherwise try another bit polarity and do BCH check gagain
    if flag ==0
        % Change polarity
        bits = 1- bits;
        % Covert symbol polarity: 0 -> 1 and 1 -> -1
        checkBits  = 1- 2 * bits(2:52);
        [flag,decodedBits] = BCH51_8Decoding(checkBits);
        % BCH decoding fails, then try another frame start position
        if flag ==0
            continue
        end
        % Compute LLR for LDPC decoding with flipped bits
        llr = pskdemod(rawData, 2, 0, 'NoiseVariance', Nv, 'OutputType', 'approxllr');
    else
        % Compute LLR for LDPC decoding with non-flipped bits
        llr = pskdemod(rawData, 2, pi, 'NoiseVariance', Nv, 'OutputType', 'approxllr');
    end
    
    % BCH decoding OK, store subframe 1 result
    decodedNav(1:9) = decodedBits;
    
    %--- Perform deinterleaving for sub-frames #2 and #3 ------------------
    % Deinterleaving of LLR values follows IS-GPS-800J
    temp_llr = reshape(llr(53:end),[38,46]);
    sf2_llr = [reshape(temp_llr(1:26, :)', 1, []) temp_llr(27, 1:4)]';
    sf3_llr = [temp_llr(27, 5:end) reshape(temp_llr(28:end, :)', 1 ,[])]';
    
    %--- LDPC decoding for sub-frames #2 and #3 --------------------------- 
    % Second subframe: last 24 bits are the CRC
    [ldpcError1, decodedNav(10:609)] = ldpcDecoding(sf2_llr, 2);
    % Third subframe: last 24 bits are the CRC
    [ldpcError2, decodedNav(610:end)] = ldpcDecoding(sf3_llr, 3);
    
    %--- To do CRC-24Q check ----------------------------------------------
    % CRC check for 2nd subframe
    checkBits = (decodedNav(10:609) > 0.5);
    [~,frmError1] = step(crcDet,checkBits');
    
    % CRC check for 2nd subframe
    checkBits = (decodedNav(610:end) > 0.5);
    [~,frmError2] = step(crcDet,checkBits');
    
    %--- Ephemeris decoding -----------------------------------------------
    % CRC-24Q check was OK. Then to decode ephemeris.
    if (~ldpcError1) && (~ldpcError2) && (~frmError1) && (~frmError2)
        % Convert from decimal to binary: The function ephemeris expects
        % input in binary form. In Matlab, it is a string array containing
        % only "0" and "1" characters.
        decodedNav = dec2bin(decodedNav);
        
        % Call the ephemeris decoding function
        eph = ephemeris(decodedNav',eph);
        if isinf(TOW)
            TOW = eph.TOW;
            firstSubFrame  = index(i);
        end
    end
end

function [eph, firstSubFrame,TOW] = CNAV2decoding(trackResults,channelNr,settings)
% findPreambles finds the first preamble occurrence in the bit stream of
% each channel. The preamble is verified by check of the spacing between
% preambles (6sec) and parity checking of the first two words in a
% subframe. At the same time function returns list of channels, that are in
% tracking state and with valid preambles in the nav data stream.
%
%[eph, firstSubFrame,TOW] = BCNAV1decoding(trackResults,channelNr,settings)
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
%                         CU Multi-GNSS SDR  
% (C) Written by Yafeng Li, Nagaraj C. Shivaramaiah and Dennis M. Akos

% Reference: Li, Y., Shivaramaiah, N.C. & Akos, D.M. Design and 
% implementation of an open-source BDS-3 B1C/B2a SDR receiver. 
% GPS Solut (2019) 23: 60. https://doi.org/10.1007/s10291-019-0853-z
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

% CVS record:
% $Id: findPreambles.m,v 1.1.2.10 2017/01/19 21:13:22 dpl Exp $


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
%index = find(abs(XcorrResult)>= 1799.5)';
index = find(abs(XcorrResult) >= 900)';

% The whole CNAV-2 frame bits (original) before encoding
decodedNav = zeros(1,883);

% Creates a CRC detector System object
crcDet = comm.CRCDetector([24 23 18 17 14 11 10 7 6 5 4 3 1 0]);

%% L1C data decoding and ephemeris extract ==========================
for i = 1:size(index) % For each occurrence
    
    % Take the CNAV-2 symbols with one-frame length from data-channel
    % prompt correlation values and change them to "1" and "0"
    bits = trackResults(channelNr).I_P(index(i): index(i) + 1799);
    bits(bits > 0)  =  1;
    bits(bits <= 0) = 0;
    
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
    end
    
    % BCH decoding OK, store subframe 1 result
    decodedNav(1:9) = decodedBits;
    
    %--- Perform deinterleaving for sub-frames #2 and #3 ------------------
    % Deinterleaving follows fix flow as indicated by the IS-GPS-800J
    temp_Bits = reshape(bits(53:end),[38,46]);
    Frame2 = [reshape(temp_Bits(1:26, :)', 1, []) temp_Bits(27, 1:4)];
    Frame3 = [temp_Bits(27, 5:end) reshape(temp_Bits(28:end, :)', 1, [])];
    
    %--- LDPC decoding for sub-frames #2 and #3 ---------------------------
    % No LDPC decoding is performed temporarily,take it directly.
    % Here should the LDPC decoding be sadded ...
    
    % Second subframe: last 24 bits are the CRC
    decodedNav(10:609) = Frame2(1:600);
    % Third subframe: last 24 bits are the CRC
    decodedNav(610:end) = Frame3(1:274);
    
    %--- To do CRC-24Q check ----------------------------------------------
    % CRC check for 2nd subframe
    checkBits = (Frame2(1:600) > 0.5);
    [~,frmError1] = step(crcDet,checkBits');
    
    % CRC check for 2nd subframe
    checkBits = (Frame3(1:274) > 0.5);
    [~,frmError2] = step(crcDet,checkBits');
    
    %--- Ephemeris decoding -----------------------------------------------
    % CRC-24Q check was OK. Then to decode ephemeris.
    if (~frmError1) && (~frmError2)
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

function [eph] = ephemeris(navBitsBin,eph)
%Function decodes ephemerides and TOW from the given bit stream. The stream
%(array) in the parameter BITS must contain 883 bits. The first element in
%the array must be the first bit of a subframe. The subframe ID of the
%first subframe in the array is not important.
%
%Function does not check parity!
%
%[eph] = ephemeris(navBitsBin,eph)
%
%   Inputs:
%       navBitsBin  - bits of the navigation messages.Type is character array
%                   and it must contain only characters '0' or '1'.
%       eph         - The ephemeris for each PRN is decoded message by message.
%                   To prevent lost of previous decoded messages, the eph sturcture
%                   must be passed onto this function.
%   Outputs:
%       TOW         - Time Of Week (TOW) of the first sub-frame in the bit
%                   stream (in seconds)
%       eph         - SV ephemeris

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

%% Check if the parameters are strings ==============================
if ~ischar(navBitsBin)
    error('The parameter BITS must be a character array!');
end

% 'bits' should be row vector for 'bin2dec' function.
[a, b] = size(navBitsBin);
if a > b
    navBitsBin = navBitsBin';
end

% Pi used in the GPS coordinate system
gpsPi = 3.1415926535898;

%% ===== Decode the first subframe ==================================
eph.PRN = bin2dec(navBitsBin(610:617));
if (eph.PRN < 1) || ((eph.PRN > 63) && (eph.PRN < 193)) || (eph.PRN > 202)
    return
end

if ~eph.flag
    % Decode subframe 1
    eph.TOI = bin2dec(navBitsBin(1:9));

    % Mark start index of subframe 2
    sf2 = 10;

    % Decode subframe 2
    eph.weekNumber      = bin2dec(navBitsBin(sf2:sf2+12));
    eph.ITOW            = bin2dec(navBitsBin(sf2+13:sf2+20));
    eph.t_op            = bin2dec(navBitsBin(sf2+21:sf2+31))*300;
    eph.health          = bin2dec(navBitsBin(sf2+32));
    eph.t_oe            = bin2dec(navBitsBin(sf2+38:sf2+48))*300;
    eph.deltaA          = twosComp2dec(navBitsBin(sf2+49:sf2+74))*2^(-9);
    eph.aDot            = twosComp2dec(navBitsBin(sf2+75:sf2+99))*2^(-21);
    eph.deltaN0         = twosComp2dec(navBitsBin(sf2+100:sf2+116))*2^(-44)*gpsPi;
    eph.deltaN0Dot      = twosComp2dec(navBitsBin(sf2+117:sf2+139))*2^(-57)*gpsPi;
    eph.M_0             = twosComp2dec(navBitsBin(sf2+140:sf2+172))*2^(-32)*gpsPi;
    eph.e               = bin2dec(navBitsBin(sf2+173:sf2+205))*2^(-34);
    eph.w               = twosComp2dec(navBitsBin(sf2+206:sf2+238))*2^(-32)*gpsPi;
    eph.omega_0         = twosComp2dec(navBitsBin(sf2+239:sf2+271))*2^(-32)*gpsPi;
    eph.i_0             = twosComp2dec(navBitsBin(sf2+272:sf2+304))*2^(-32)*gpsPi;
    eph.deltaOmegaDot   = twosComp2dec(navBitsBin(sf2+305:sf2+321))*2^(-44)*gpsPi;
    eph.IDOT            = twosComp2dec(navBitsBin(sf2+322:sf2+336))*2^(-44)*gpsPi;
    eph.C_is            = twosComp2dec(navBitsBin(sf2+337:sf2+352))*2^(-30);
    eph.C_ic            = twosComp2dec(navBitsBin(sf2+353:sf2+368))*2^(-30);
    eph.C_rs            = twosComp2dec(navBitsBin(sf2+369:sf2+392))*2^(-8);
    eph.C_rc            = twosComp2dec(navBitsBin(sf2+393:sf2+416))*2^(-8);
    eph.C_us            = twosComp2dec(navBitsBin(sf2+417:sf2+437))*2^(-30);
    eph.C_uc            = twosComp2dec(navBitsBin(sf2+438:sf2+458))*2^(-30);
    eph.a_f0            = twosComp2dec(navBitsBin(sf2+470:sf2+495))*2^(-35);
    eph.a_f1            = twosComp2dec(navBitsBin(sf2+496:sf2+515))*2^(-48);
    eph.a_f2            = twosComp2dec(navBitsBin(sf2+516:sf2+525))*2^(-60);
    eph.T_GD            = twosComp2dec(navBitsBin(sf2+526:sf2+538))*2^(-35);
    eph.ISC_L1Cp        = twosComp2dec(navBitsBin(sf2+539:sf2+551))*2^(-35);
    eph.ISC_L1Cd        = twosComp2dec(navBitsBin(sf2+552:sf2+564))*2^(-35);
    eph.WN_op           = bin2dec(navBitsBin(sf2+566:sf2+573))+2048;

    % Subframe 3 not decoded
end

% TOW count is for next subframe, so subtract one TOI
if ~eph.flag
    eph.TOW = eph.ITOW * 7200 + (eph.TOI-1) * 18;
end

% All required NAV data has been decoded
eph.flag = 1;
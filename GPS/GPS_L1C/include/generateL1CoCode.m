function L1Co = generateL1CoCode(PRN)
% This function generates GPS L1Co code in bipolar format (-1, +1)
% PRNs 1 to 32 and PRNs 193 - 202
%
% L1Co = generateL1Cocode(PRN)
%
%   Inputs:
%       PRN         - PRN number of the sequence.
%
%   Outputs:
%       L1Co        - a vector containing the desired L1Co code sequence
%                   (chips).

%--------------------------------------------------------------------------
%                         CU Multi-GNSS SDR  
% (C) Written by Yafeng Li, Nagaraj C. Shivaramaiah and Dennis M. Akos

% Reference: Li, Y., Shivaramaiah, N.C. & Akos, D.M. Design and 
% implementation of an open-source BDS-3 B1C/B2a SDR receiver. 
% GPS Solut (2019) 23: 60. https://doi.org/10.1007/s10291-019-0853-z
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
%$Id: generateE5BIcode.m,v 1.1.2.5 2017/11/27 22:00:00 dpl Exp $

% Account for QZSS PRNs
if PRN > 33
    PRN = PRN - 160;
end

% S1 polynomial coefficients in octal for PRNs 1-32
s1OctCoeff = [5111, 5421, 5501, 5403, 6417, 6141, 6351, 6501,...
    6205, 6235, 7751, 6623, 6733, 7627, 5667, 5051,...
    7665, 6325, 4365, 4745, 7633, 6747, 4475, 4225,...
    7063, 4423, 6651, 4161, 7237, 4473, 5477, 6163,...
    ... S1 polynomial coefficients for QZSS PRNs 193-202
    ... Offset is truePRN - 160
    5403, 5403, 5403, 5403, 5403, 6501, 6501, 6501,...
    6501, 6501];

% S1 initial condition in octal for PRNs 1-32
s1OctInit = [3266, 2040, 1527, 3307, 3756, 3026, 562, 420,...
    3415, 337, 265, 1230, 2204, 1440, 2412, 3516,...
    2761, 3750, 2701, 1206, 1544, 1774, 546, 2213,...
    3707, 2051, 3650, 1777, 3203, 1762, 2100, 571,...
    ... S1 initial condition for QZSS PRNs 193-202
    ... Offset is truePRN - 160
    500, 254, 3445, 2542, 1257, 0211, 0534, 1420,...
    3401, 714];

% S2 initial condition not used for PRNs 1-32
s2OctInit = [nan, nan, nan, nan, nan, nan, nan, nan,...
    nan, nan, nan, nan, nan, nan, nan, nan,...
    nan, nan, nan, nan, nan, nan, nan, nan,...
    nan, nan, nan, nan, nan, nan, nan, nan,...
    ... S2 initial condition for QZSS PRNs 193-202
    ... Offset is truePRN - 160
    3261, 1760, 430, 3477, 1676, 1636, 2411, 1473,...
    2266, 2104];

% Initialize
S1 = double(dec2bin(OCT2DEC(s1OctInit(PRN)))=='1');
S1 = flip([zeros(1, 11-length(S1)) S1], 2);
s1BinCoeff = double(dec2bin(OCT2DEC(s1OctCoeff(PRN)))=='1');
s1BinCoeff = flip([zeros(1, 10-length(s1BinCoeff)) s1BinCoeff(1:end-1)], 2)';
if PRN > 32
    S2 = double(dec2bin(OCT2DEC(s2OctInit(PRN)))=='1');
    S2 = flip([zeros(1, 11-length(S2)) S2], 2);
end
L1Co = nan(1, 1800);

for i = 1:1800
    s1Output = S1(end);
    S1 = [mod(S1*s1BinCoeff, 2) S1(1:10)];

    if PRN > 32
        s2Output = S2(end);
        S2 = [mod(S2(9)+S2(11), 2) S2(1:10)];
        L1Co(i) = mod(s1Output+s2Output, 2);
    else
        L1Co(i) = s1Output;
    end
end

L1Co = (L1Co==0)*(1) + (L1Co==1)*(-1);
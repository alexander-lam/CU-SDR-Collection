function eph= eph_structure_init()
% This is in order to make sure variable 'eph' for each SV has a similar 
% structure when only one or even none of the three requisite messages
% is decoded for a given PRN.
%--------------------------------------------------------------------------
%                         CU Multi-GNSS SDR  
% (C) Written by Yafeng Li, Nagaraj C. Shivaramaiah and Dennis M. Akos
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

% Flags for message data decoding. 0 indicates decoding fail, 1 is
% successful decoding.
eph.flag = 0;

% Subframe 1
eph.TOI             = [];

% Subframe 2
eph.weekNumber      = [];
eph.ITOW            = [];
eph.t_op            = [];
eph.health          = [];
eph.t_oe            = [];
eph.deltaA          = [];
eph.aDot            = [];
eph.deltaN0         = [];
eph.deltaN0Dot      = [];
eph.M_0             = [];
eph.e               = [];
eph.w               = [];
eph.omega_0         = [];
eph.i_0             = [];
eph.deltaOmegaDot   = [];
eph.IDOT            = [];
eph.C_is            = [];
eph.C_ic            = [];
eph.C_rs            = [];
eph.C_rc            = [];
eph.C_us            = [];
eph.C_uc            = [];
eph.a_f0            = [];
eph.a_f1            = [];
eph.a_f2            = [];
eph.T_GD            = [];
eph.ISC_L1Cp        = [];
eph.ISC_L1Cd        = [];
eph.WN_op           = [];

% Subframe 3 not decoded
eph.PRN             = [];
eph.TOW             = [];
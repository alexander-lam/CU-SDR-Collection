function boccode = generateL1Cpboc11code(PRN)
% generateL1Cboc11pcode generates L1C code modulated using BOC(1,1) for
% PRNs 1 to 32
%
% CAcode = generateCAcode(PRN)
%
%   Inputs:
%       PRN         - PRN number of the sequence.
%
%   Outputs:
%       boccode      - a vector containing the desired L1C code sequence 
%                   modulated with BOC(1,1) (2 subchips per chip). 

% Account for QZSS PRNs
if PRN > 33
    PRN = PRN - 160;
end

% Weil index and insertion index for PRNs 1-32
w = [5111, 5109, 5108, 5106, 5103, 5101, 5100, 5098,...
    5095, 5094, 5093, 5091, 5090, 5081, 5080, 5069,...
    5068, 5054, 5044, 5027, 5026, 5014, 5004, 4980,...
    4915, 4909, 4893, 4885, 4832, 4824, 4591, 3706,...
    ... Weil index for QZSS PRNs 193-202
    ... Offset is truePRN - 160
    4311, 5024, 4352, 4678, 5034, 5085, 3646, 4868,...
    3688, 4211];

p = [412, 161, 1, 303, 207, 4971, 4496, 5,...
    4557, 485, 253, 4676, 1, 66, 4485, 282,...
    5211, 729, 4848, 982, 5955, 9805, 670, 464,...
    29, 429, 394, 616, 9457, 4429, 4771, 365,...
    ... Insertion index for QZSS PRNs 193-202
    ... Offset is truePRN - 160
    9864, 9753, 9859, 328, 1, 4733, 164, 135,...
    174, 132];

% Expansion sequence
exp_seq = [0 1 1 0 1 0 0];

% Generate Legendre sequence
L = ones(1,10223);
for t = 0:10222
    L(mod(t^2,10223)+1) = -1;
end
L(1) = 1;

% Get proper Weil index and insertion index
w_p = w(PRN);
p_p = p(PRN);

% Create Weil code
W_p = zeros(10223);
for t = 0:10222
    W_p(t+1) = L(t+1)*L(mod(t+w_p, 10223)+1);
end

% Insert expansion sequence
L1Cp(1:p_p-2+1) = W_p(1:p_p-2+1);
L1Cp(p_p-1+1:p_p+5+1) = exp_seq;
L1Cp(p_p+6+1:10229+1) = W_p(p_p-1+1:10222+1);

% Modulate using BOC(1,1)
m=6;
n=1;
N = 2*m/n;
boccode=zeros(1,N*length(L1Cp));
for ii=0:length(L1Cp)-1
    for jj=0:N-1
        boccode(N*ii+jj+1) = L1Cp(ii+1);
    end
end

% Mix sub carrier
for ii=0:N*length(L1Cp)/2-1
    boccode(2*ii+1)=-boccode(2*ii+1);
end
end
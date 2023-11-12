function boccode = generateL1Cdboc11code(PRN)
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
w = [5097, 5110, 5079, 4403, 4121, 5043, 5042, 5104,...
    4940, 5035, 4372, 5064, 5084, 5048, 4950, 5019,...
    5076, 3736, 4993, 5060, 5061, 5096, 4983, 4783,...
    4991, 4815, 4443, 4769, 4879, 4894, 4985, 5056,...
    ... Weil index for QZSS PRNs 193-202
    ... Offset is truePRN - 160
    4834, 4456, 4056, 3804, 3672, 4205, 3348, 4152,...
    3883, 3473];

p = [181, 359, 72, 1110, 1480, 5034, 4622, 1,...
    4547, 826, 6284, 4195, 368, 1, 4796, 523,...
    151, 713, 9850, 5734, 34, 6142, 190, 644,...
    467, 5384, 801, 594, 4450, 9437, 4307, 5906,...
    ... Insertion index for QZSS PRNs 193-202
    ... Offset is truePRN - 160
    9753, 4799, 10126, 241, 1245, 1274, 1456, 9967,...
    235, 512];

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
L1Cd(1:p_p-2+1) = W_p(1:p_p-2+1);
L1Cd(p_p-1+1:p_p+5+1) = exp_seq;
L1Cd(p_p+6+1:10229+1) = W_p(p_p-1+1:10222+1);

% Modulate using BOC(1,1)
m=1;
n=1;
N = 2*m/n;
boccode=zeros(1,N*length(L1Cd));
for ii=0:length(L1Cd)-1
    for jj=0:N-1
        boccode(N*ii+jj+1) = L1Cd(ii+1);
    end
end

% Mix sub carrier
for ii=0:N*length(L1Cd)/2-1
    boccode(2*ii+1)=-boccode(2*ii+1);
end
end
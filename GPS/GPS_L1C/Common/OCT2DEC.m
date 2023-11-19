function decNum = OCT2DEC(octNum)
% Implementation of Matlab's oct2dec function but without Communications
% Toolbox
octNumString = num2str(octNum);
decNum = 0;
for i = 1:length(octNumString)
    curNum = str2double(octNumString(i));
    curPow = length(octNumString)-i;
    decNum = decNum + curNum * 8^curPow;
end
end
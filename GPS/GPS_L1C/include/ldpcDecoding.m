function [error,decodedBits] = ldpcDecoding(llr, subframeNum)
% Performs error correction for subframes 2 and 3 in accordance with
% IS-GPS-800

% Error of 0 means decoding successful
% Error of 1 means decoding failure

if subframeNum == 2
    parityMatrix = generateSubframe2ParityMatrix();
else
    parityMatrix = generateSubframe3ParityMatrix();
end

ldpcDecoder = ldpcDecoderConfig(parityMatrix);

[decodedBits, ~, parity] = ldpcDecode(llr, ldpcDecoder, 10);

if nnz(parity) == 0
    error = 0;
else
    error = 1;
end
end
function parityMatrix = generateSubframe3ParityMatrix()
% Generate parity matrix for subframe 3 in accordance with IS-GPS-800

A = zeros(273, 274);
oneIndices = readmatrix('sf3_submatrixA.txt');
for i = 1:size(oneIndices, 1)
    A(oneIndices(i,1), oneIndices(i,2)) = 1;
end

B = zeros(273, 1);
oneIndices = readmatrix('sf3_submatrixB.txt');
for i = 1:size(oneIndices, 1)
    B(oneIndices(i,1), oneIndices(i,2)) = 1;
end

C = zeros(1, 274);
oneIndices = readmatrix('sf3_submatrixC.txt');
for i = 1:size(oneIndices, 1)
    C(oneIndices(i,1), oneIndices(i,2)) = 1;
end

D = zeros(1, 1);
oneIndices = readmatrix('sf3_submatrixD.txt');
for i = 1:size(oneIndices, 1)
    D(oneIndices(i,1), oneIndices(i,2)) = 1;
end

E = zeros(1, 273);
oneIndices = readmatrix('sf3_submatrixE.txt');
for i = 1:size(oneIndices, 1)
    E(oneIndices(i,1), oneIndices(i,2)) = 1;
end

T = zeros(273, 273);
oneIndices = readmatrix('sf3_submatrixT.txt');
for i = 1:size(oneIndices, 1)
    T(oneIndices(i,1), oneIndices(i,2)) = 1;
end

parityMatrix = sparse(logical([A B T; C D E]));
end
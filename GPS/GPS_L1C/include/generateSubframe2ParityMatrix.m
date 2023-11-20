function parityMatrix = generateSubframe2ParityMatrix()
% Generate parity matrix for subframe 2 in accordance with IS-GPS-800

A = zeros(599, 600);
oneIndices = readmatrix('sf2_submatrixA.txt');
for i = 1:size(oneIndices, 1)
    A(oneIndices(i,1), oneIndices(i,2)) = 1;
end

B = zeros(599, 1);
oneIndices = readmatrix('sf2_submatrixB.txt');
for i = 1:size(oneIndices, 1)
    B(oneIndices(i,1), oneIndices(i,2)) = 1;
end

C = zeros(1, 600);
oneIndices = readmatrix('sf2_submatrixC.txt');
for i = 1:size(oneIndices, 1)
    C(oneIndices(i,1), oneIndices(i,2)) = 1;
end

D = zeros(1, 1);
oneIndices = readmatrix('sf2_submatrixD.txt');
for i = 1:size(oneIndices, 1)
    D(oneIndices(i,1), oneIndices(i,2)) = 1;
end

E = zeros(1, 599);
oneIndices = readmatrix('sf2_submatrixE.txt');
for i = 1:size(oneIndices, 1)
    E(oneIndices(i,1), oneIndices(i,2)) = 1;
end

T = zeros(599, 599);
oneIndices = readmatrix('sf2_submatrixT.txt');
for i = 1:size(oneIndices, 1)
    T(oneIndices(i,1), oneIndices(i,2)) = 1;
end

parityMatrix = sparse(logical([A B T; C D E]));
end
function [rho, B, f] = computeReceiverPosition(GPS, Approximate_Coor, Obs, SxClockError)
    % Compute receiver position components
    % Geometric distance
    rho = sqrt((Approximate_Coor(1,1) - GPS(1))^2 + (Approximate_Coor(2,1) - GPS(2))^2 + (Approximate_Coor(3,1) - GPS(3))^2);

    % B matrix
    B(1) = (Approximate_Coor(1,1) - GPS(1)) / rho;
    B(2) = (Approximate_Coor(2,1) - GPS(2)) / rho;
    B(3) = (Approximate_Coor(3,1) - GPS(3)) / rho;
    B(4) = 1;

    % Function f
    f = Obs.C1 - rho + SxClockError;
end

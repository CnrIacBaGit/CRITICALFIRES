%% File: renorm_veg.m
% Rinormalizza (B,G,S,P,H) a somma 1 per cella.

function [B,G,S,P,H] = renorm_veg(B,G,S,P,H)

    tot = B + G + S + P + H;
    tot = max(tot, eps);

    B = B ./ tot;
    G = G ./ tot;
    S = S ./ tot;
    P = P ./ tot;
    H = H ./ tot;

end

function a = rothc_temp_factor_centered(temp, Temp0)
    A = 47.91;
    B = 106.06;

    % Costante scelta per avere ka(Temp0)=1:
    % exp(B/C) = A-1  =>  C = B / log(A-1)
    C = B / log(A - 1);   % = 106.06/log(46.91)

    den = temp + C - Temp0;

    % protezione numerica: evita den <= 0 (temperatura estremamente bassa)
    den = max(den, 0.1);

    a = A ./ (1 + exp(B ./ den));
end

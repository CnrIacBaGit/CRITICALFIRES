function clim = make_climate(p, nMonths, Ny, Nx)

    m = (1:nMonths)';



idx = mod((1:nMonths)-1, 12) + 1;      % 1..12 ciclico (Jan..Dec)




   % --- Acc. TSMD come in RothC guide pag. 13 (con segno NEGATIVO)

% Dati (Spotorno)
 temp12_old = [6 6 9 12 15 19 25 25 19 15 10 7];
% rain12 = [100 90 90 82 76 38 21 43 55 106 97 79];   % mm
% epan12 = [20 40 90 120 140 160 130 90 65 50 40 30];  % mm (open pan)
% 

% Scenario aumento delle temperature/ siccità
% Dati (Spotorno)
temp12 = [6 6 9 12 15 19 25 25 19 15 10 7];
rain12 = [100 90 90 82 76 38 21 43 55 106 97 79];   % mm
epan12 = [20 40 90 120 140 160 130 90 65 50 40 30];  % mm (open pan)


% dati RothC
% temp12 = [3.4 3.6 5.1 7.3 11 13.9 16 16 13.5 10.2 6.1 4.6];
% rain12 = [74 59 62 51 52 57 34 55 58 56 75 71];   % mm
% epan12 = [ 8 10 27 49 83 99 103 91 69 34 16  8];  % mm (open pan)


temp = temp12(idx)'; 
rain = rain12(idx)';     % nMonths x 1
epan = epan12(idx)';     % nMonths x 1

% Per replicare Rothamsted: clay=23.4, depth=23 cm  => MaxTSMD=-44.94 (pag.11)
clay  = p.site.clay_pct;
depth = p.site.soil_depth_cm;

max_tsmd_23 = -(20.0 + 1.3*clay - 0.01*clay^2);  % NOTA: negativo in guida
max_tsmd    = max_tsmd_23 * (depth/23);          % negativo


acc_tsmd = zeros(nMonths,1);
tsmd_acc = 0;  % 1 Gennaio: field capacity 

for t = 1:nMonths
    
    net = rain(t) - epan(t);     

    % somma e clamp tra [max_tsmd, 0]
    tsmd_acc = tsmd_acc + net;
    tsmd_acc = min(tsmd_acc, 0);      % non può andare >0 (più umido di FC)
    tsmd_acc = max(tsmd_acc, max_tsmd); % non può andare < MaxTSMD (più secco del massimo)

    acc_tsmd(t) = tsmd_acc;
end

tsmd = acc_tsmd;

   
 % --- Umidità: opposto del deficit 
    M = -max_tsmd;
    Mb = 0.444 *M; 
    m =  min(abs(tsmd), M);           % deficit positivo (0..)

rho_moisture = ones(size(m));
mask = (m >= Mb);
rho_moisture(mask) = 0.2 + 0.8 * (M - m(mask)) ./ (M - Mb);   % = 0.556*M
rho_moisture = min(max(rho_moisture, 0.2), 1.0);

    % Espandi su griglia
    clim.temp = repmat(reshape(temp, [nMonths 1 1]), [1 Ny Nx]);
    clim.tsmd = repmat(reshape(tsmd, [nMonths 1 1]), [1 Ny Nx]);
    clim.rho_moisture    = repmat(reshape(rho_moisture,    [nMonths 1 1]), [1 Ny Nx]);
    clim.Temp0 = mean(temp12_old);
    clim.max_tsmd = M;
end

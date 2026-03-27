function rho = rothc_rho(p, temp, Temp0, rho_moisture, st)
%ROTHC_RHO  Moltiplicatore ambientale del modello RothC.
%
%   rho = rothc_rho(p, temp, Temp0, rho_moisture, st)
%
% Calcola il fattore complessivo:
%   rho = rhoT .* rho_moisture .* rhoCover
% dove:
%   - rhoT       : fattore di temperatura (centrato su Temp0)
%   - rho_moisture: fattore di umidita' del suolo (da make_climate)
%   - rhoCover   : fattore di copertura (media pesata delle frazioni di vegetazione)

% --- Fattore temperatura (centrato su temperatura media annua di riferimento Temp0)
rhoT = rothc_temp_factor_centered(temp, Temp0);

% --- Fattore copertura: media pesata sulle frazioni vegetazionali
rhoCover = st.B .* 1.0 + ...
           st.G .* p.roth.rho_grass + ...
           st.S .* p.roth.rho_shrub + ...
           (st.P + st.H) .* p.roth.rho_wood;

% --- Fattore complessivo (operazioni elemento-per-elemento)
rho = rhoT .* rho_moisture .* rhoCover;

end
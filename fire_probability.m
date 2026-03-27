%% File: fire_probability.m
% Probabilità mensile di incendio in cella:
%   F = f(s,month) * (nu_g*G + nu_s*S + nu_p*P + nu_h*H)
% con:
%   f_month = 1 - (1 - f0_annual)^(1/12)    (conversione esatta annua->mensile)
% e stagionalità normalizzata (media annua = 1).

function F = fire_probability(p, st, s, monthIndex)

    % --- baseline mensile (conversione esatta da probabilità annua)
    %f0 = min(max(p.fire.f0_annual, 0), 1);      % clamp sicurezza
    f0 = p.fire.f0_annual;
    h = p.sim.h;
 

    % --- stagionalità (opzionale), normalizzata a media 1
    season = 1;
    if isfield(p.fire,'use_seasonality') && p.fire.use_seasonality
        mm = mod(monthIndex-1, 12) + 1;

        % profilo stagionale ( picco verso agosto)
         % season12 = 0.7 + 0.6 * exp(-0.5*(( (1:12) - 8)/1.8).^2);
         % season12 = season12 / mean(season12);   % NORMALIZZAZIONE: media = 1
        A=0.6;
        season12 = (1 + A*cos(2*pi*((1:12) - 8)/12));
        
         
        season = season12(mm);
    end

    % --- dipendenza da umidità
  
    moistFactor = (1-s);

    % baseline finale per cella e mese
    f = f0 .* season.* moistFactor;

    % --- combinazione con flammabilità e coperture 
    F = h.*f .* (p.fire.nu_g .* st.G + p.fire.nu_s .* st.S + ...
              p.fire.nu_p .* st.P + p.fire.nu_h .* st.H);

    % clamp [0,1]
    %F = min(max(F, 0), 1);

end


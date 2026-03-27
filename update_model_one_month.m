function [st, BA] = update_model_one_month(p, st, ign, temp, temp0, rho_moisture)
%UPDATE_MODEL_ONE_MONTH Un passo mensile Vegetazione + Fuoco + Suolo (RothC)
%   [st, BA] = update_model_one_month(p, st, ign, temp, temp0, s)
%
% Vegetazione:
%   - successione (beta/12)
%   - incendio (Phi = ign)
%
% Suolo:
%   - input C (DPM/RPM)
%   - decomposizione RothC con fattore rho(temp, umidità, ...)

%% Incendio: indicatore (0/1)
Phi = double(ign);
h = p.sim.h;
% Area bruciata potenziale nel mese (BA)
BA = p.fire.alpha_g .* st.G + ...
     p.fire.alpha_s .* st.S + ...
     p.fire.alpha_p .* st.P + ...
     p.fire.alpha_h .* st.H;

%% Vegetazione: beta con feedback SOC + umidità
SOC    = st.DPM + st.RPM + st.BIO + st.HUM;
Cproxy = (st.BIO + st.HUM) ./ max(SOC, eps);
beta   = compute_betas(p, Cproxy, rho_moisture);

% Successione mensile
bg = beta.bg ;
gs = beta.gs ;
sp = beta.sp ;
sh = beta.sh ;
ph = beta.ph ;

% Aggiornamento frazioni vegetazione
Bn = st.B - h.* bg .* st.B + Phi .* BA;

Gn = st.G + h.*(bg .* st.B - gs .* st.G) - Phi .* (p.fire.alpha_g .* st.G);

Sn = st.S + h.*(gs .* st.G - sp .* st.S - sh .* st.S) - Phi .* (p.fire.alpha_s .* st.S);

Pn = st.P + h.*(sp .* st.S - ph .* st.P) - Phi .* (p.fire.alpha_p .* st.P);

Hn = st.H  +h.*(sh .* st.S + ph .* st.P) - Phi .* (p.fire.alpha_h .* st.H);

%% Suolo (RothC): input di carbonio
% gamma = p.input.gamma;
% Vtot  = vegetation_carbon_input(p, st, ign, s); % input totale C
% DPMin = gamma .* Vtot;
% RPMin = (1 - gamma) .* Vtot;

% % Suolo (RothC): input di carbonio
gamma = p.input.gamma;

% New: compute separated inputs (metabolic limited by s; fire deposited & partitioned)
vin = vegetation_carbon_input(p, st, ign, rho_moisture);

% Metabolic input is split between DPM/RPM using gamma
DPMin = gamma .* vin.Vmeta;
RPMin = (1 - gamma) .* vin.Vmeta;

% Fire residues go to RPM only (labile), char goes to IOM (inert)
RPMin = RPMin + vin.Vres;



% Parametri RothC
kDPM = p.roth.kDPM;
kRPM = p.roth.kRPM;
kBIO = p.roth.kBIO;
kHUM = p.roth.kHUM;

dBIO = p.roth.deltaBIO;
dHUM = p.roth.deltaHUM;

% Pool correnti
DPM = st.DPM;
RPM = st.RPM;
BIO = st.BIO;
HUM = st.HUM;
IOM = st.IOM;

% Fattore ambientale (temp/umidità/altro)
rho = rothc_rho(p, temp, temp0, rho_moisture, st);

% Decomposizioni
decDPM = rho .* kDPM .* DPM;
decRPM = rho .* kRPM .* RPM;
decBIO = rho .* kBIO .* BIO;
decHUM = rho .* kHUM .* HUM;

% Aggiornamento pool (implementazione diretta eq. (4))
DPMn = DPM - h.* decDPM + DPMin - Phi .* (p.fire.sigma .* DPM);
RPMn = RPM - h.* decRPM + RPMin - Phi .* (p.fire.sigma .* RPM);

BIOn = BIO ...
    - h.* rho .* kBIO .* (1 - dBIO) .* BIO ...
    + h.* rho.* dBIO .* (kDPM .* DPM + kRPM .* RPM + kHUM .* HUM)- Phi .* (p.fire.sigma .* BIO);

HUMn = HUM ...
    - h.*rho .* kHUM .* (1 - dHUM) .* HUM ...
    + h.*rho.* dHUM .* (kDPM .* DPM + kRPM .* RPM + kBIO .* BIO)- Phi .* (p.fire.sigma .* HUM);

% IOM update (only if not constant)
IOM = st.IOM;

    IOMn = IOM + vin.Vchar;



%% Aggiorna stato (clamp non-negatività)
Bn = max(Bn, 0);
Gn = max(Gn, 0);
Sn = max(Sn, 0);
Pn = max(Pn, 0);
Hn = max(Hn, 0);

% rinormalizza a somma 1
[st.B, st.G, st.S, st.P, st.H] = renorm_veg(Bn, Gn, Sn, Pn, Hn);

st.DPM = max(DPMn, 0);
st.RPM = max(RPMn, 0);
st.BIO = max(BIOn, 0);
st.HUM = max(HUMn, 0);
st.IOM = max(IOMn, 0);

end

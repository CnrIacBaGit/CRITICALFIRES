function vin = vegetation_carbon_input(p, st, ign, rho_moisture)
%VEGETATION_CARBON_INPUT Compute monthly vegetation -> soil C inputs (t ha^-1 month^-1).
%
% Outputs (struct vin):
%   Vmeta : metabolic litter input (moisture-limited)
%   Vfire : post-fire deposited input (active only where ign==1)
%   Vres  : labile post-fire residues (to RPM; active only where ign==1)
%   Vchar : inert pyrogenic C (to IOM; active only where ign==1)
%   Vtot  : total input (Vmeta + Vfire)

h   = p.sim.h;
Phi = double(ign);

% --- Metabolic input (ton/ha/month)
Vmeta0 = h .* ( ...
    (p.input.xi_g * p.input.mu_g) .* st.G + ...
    (p.input.xi_s * p.input.mu_s) .* st.S + ...
    (p.input.xi_p * p.input.mu_p) .* st.P + ...
    (p.input.xi_h * p.input.mu_h) .* st.H );

% Moisture limitation on metabolic inputs only:
%   f_W(rho) = (rho - 0.2) / 0.8  in [0,1] if rho in [0.2,1]
fW    = (rho_moisture - 0.2) ./ 0.8;
Vmeta = Vmeta0 .* fW;

% --- Fire-affected carbon (ton/ha in fire month, before deposition fraction)
Vfire0 = (p.input.xi_g * p.fire.alpha_g) .* st.G + ...
         (p.input.xi_s * p.fire.alpha_s) .* st.S + ...
         (p.input.xi_p * p.fire.alpha_p) .* st.P + ...
         (p.input.xi_h * p.fire.alpha_h) .* st.H;

% Only a fraction reaches the soil (deposited / non-volatilized)
Vfire = p.fire.eta_dep .* Vfire0;

% Partition deposited fire input into inert char vs labile residues
Vchar = p.fire.omega_char .* Vfire;          % -> IOM
Vres  = (1 - p.fire.omega_char) .* Vfire;    % -> RPM

% Apply fire indicator (0/1) cell-by-cell
vin.Vmeta = Vmeta;
vin.Vfire = Phi .* Vfire;
vin.Vres  = Phi .* Vres;
vin.Vchar = Phi .* Vchar;
vin.Vtot  = Vmeta + vin.Vfire;

end
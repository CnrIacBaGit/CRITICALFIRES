%% File: compute_betas.m
% Beta annuali (1/yr) con feedback di carbonio e (opzionale) umidità.

function beta = compute_betas(p, Cproxy, rho_moisture)

    fC = 1 + p.veg.kappaC .* Cproxy;

    beta.bg = p.veg.beta0_bg .* fC;
    beta.gs = p.veg.beta0_gs .* fC;
    beta.sp = p.veg.beta0_sp .* fC;
    beta.sh = p.veg.beta0_sh .* fC;
    beta.ph = p.veg.beta0_ph .* fC;

    if p.veg.use_moisture_on_beta
        %moistFactor = p.veg.epsilon .*  min(s ./ p.veg.s0, 1);
        moistFactor = p.veg.epsilon .* rho_moisture;
        beta.gs = beta.gs .* moistFactor;
        beta.sp = beta.sp .* moistFactor;
        beta.sh = beta.sh .* moistFactor;
        beta.ph = beta.ph .* moistFactor;
    end

end

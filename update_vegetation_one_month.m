%% File: update_vegetation_one_month.m
% Aggiorna vegetazione con eq. (3): successione (beta/12) e incendio (Phi=ign).

function [st, BA] = update_vegetation_one_month(p, st, beta, ign)

    Phi = double(ign);

    % Area bruciata (BA) nel mese (eq. 2.3)
    BA = p.fire.alpha_g .* st.G + p.fire.alpha_s .* st.S + p.fire.alpha_p .* st.P + p.fire.alpha_h .* st.H;

    % Successione mensile = beta_annuale / 12
    bg = beta.bg / 12;
    gs = beta.gs / 12;
    sp = beta.sp / 12;
    sh = beta.sh / 12;
    ph = beta.ph / 12;

    Bn = st.B - bg .* st.B + Phi .* BA;

    Gn = st.G + bg .* st.B - gs .* st.G - Phi .* (p.fire.alpha_g .* st.G);

    Sn = st.S + gs .* st.G - sp .* st.S - sh .* st.S - Phi .* (p.fire.alpha_s .* st.S);

    Pn = st.P + sp .* st.S - ph .* st.P - Phi .* (p.fire.alpha_p .* st.P);

    Hn = st.H + sh .* st.S + ph .* st.P - Phi .* (p.fire.alpha_h .* st.H);

    % evita negatività numeriche
    Bn = max(Bn, 0); Gn = max(Gn, 0); Sn = max(Sn, 0); Pn = max(Pn, 0); Hn = max(Hn, 0);

    % rinormalizza a somma 1
    [st.B, st.G, st.S, st.P, st.H] = renorm_veg(Bn, Gn, Sn, Pn, Hn);
    gamma = p.input.gamma;

    DPMin = gamma .* Vtot; 
    RPMin = (1 - gamma) .* Vtot; 
    kDPM = p.roth.kDPM;
    kRPM = p.roth.kRPM;
    kBIO = p.roth.kBIO;
    kHUM = p.roth.kHUM;

    dBIO = p.roth.deltaBIO;
    dHUM = p.roth.deltaHUM;

    DPM = st.DPM; RPM = st.RPM; BIO = st.BIO; HUM = st.HUM; IOM = st.IOM;

    % decomposizioni
    decDPM = rho .* kDPM .* DPM;
    decRPM = rho .* kRPM .* RPM;
    decBIO = rho .* kBIO .* BIO;
    decHUM = rho .* kHUM .* HUM;

    % eq (4) del report (implementata in modo diretto)
    DPMn = DPM - decDPM + DPMin;
    RPMn = RPM - decRPM + RPMin;

    % BIO: perdita = rho*kBIO*(1-dBIO)*BIO, guadagno = dBIO*rho*(kDPM*DPM + kRPM*RPM + kHUM*HUM)
    BIOn = BIO - rho .* kBIO .* (1 - dBIO) .* BIO + ...
           dBIO .* rho .* (kDPM .* DPM + kRPM .* RPM + kHUM .* HUM);

    % HUM: perdita = rho*kHUM*(1-dHUM)*HUM, guadagno = dHUM*rho*(kDPM*DPM + kRPM*RPM + kBIO*BIO)
    HUMn = HUM - rho .* kHUM .* (1 - dHUM) .* HUM + ...
           dHUM .* rho .* (kDPM .* DPM + kRPM .* RPM + kBIO .* BIO);

    % IOM costante (se vuoi un modello più completo, puoi farlo evolvere)
    % if p.roth.IOM_const
    %     IOMn = IOM;
    % else
         IOMn = IOM; % placeholder
    % end

    % clamp non-negatività
    st.DPM = max(DPMn, 0);
    st.RPM = max(RPMn, 0);
    st.BIO = max(BIOn, 0);
    st.HUM = max(HUMn, 0);
    st.IOM = max(IOMn, 0);

end

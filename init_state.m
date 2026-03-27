%% File: init_state.m
% Inizializza vegetazione (B,G,S,P,H) e pools RothC (DPM,RPM,BIO,HUM,IOM).
% Tutte le grandezze suolo sono in ton/ha (per cella, su base areale).

function st = init_state(p, Ny, Nx)

    % % Vegetazione: esempio iniziale V1-V2
    % st.B = 0.15 * ones(Ny, Nx);
    % st.G = 0.45 * ones(Ny, Nx);
    % st.S = 0.25 * ones(Ny, Nx);
    % st.P = 0.10 * ones(Ny, Nx);
    % st.H = 0.05 * ones(Ny, Nx);

%   % Vegetazione: esempio iniziale V3-V4
%     st.B = 0.05 * ones(Ny, Nx);
%     st.G = 0.20 * ones(Ny, Nx);
%     st.S = 0.35 * ones(Ny, Nx);
%     st.P = 0.15 * ones(Ny, Nx);
%     st.H = 0.25 * ones(Ny, Nx);
% 
% % Vegetazione: esempio iniziale fuori dalle aree
    st.B = 0.08 * ones(Ny, Nx);
    st.G = 0.25 * ones(Ny, Nx);
    st.S = 0.35 * ones(Ny, Nx);
    st.P = 0.12 * ones(Ny, Nx);
    st.H = 0.20 * ones(Ny, Nx);
%% Equilibrio senza fuoco
%     st.B = 0 * ones(Ny, Nx);
%     st.G = 0 * ones(Ny, Nx);
%     st.S = 0 * ones(Ny, Nx);
%     st.P = 0 * ones(Ny, Nx);
%     st.H = 1 * ones(Ny, Nx);
% Equilibrio con il fuoco f0=0.2
%     st.B = 0.014 * ones(Ny, Nx);
%     st.G = 0.0205 * ones(Ny, Nx);
%     st.S = 0.0195 * ones(Ny, Nx);
%     st.P = 0.0610347 * ones(Ny, Nx);
%     st.H = 0.883688 * ones(Ny, Nx);

    % Equilibrio con il fuoco f0=0.3
%     st.B = 0.0243 * ones(Ny, Nx);
%     st.G = 0.0330 * ones(Ny, Nx);
%     st.S = 0.030244 * ones(Ny, Nx);
%     st.P = 0.0862199 * ones(Ny, Nx);
%     st.H = 0.826992 * ones(Ny, Nx);
    
%       % Equilibrio con il fuoco f0=0.4
%     st.B = 0.38 * ones(Ny, Nx);
%     st.G = 0.25 * ones(Ny, Nx);
%     st.S = 0.125 * ones(Ny, Nx);
%     st.P = 0.0768 * ones(Ny, Nx);
%     st.H = 0.17 * ones(Ny, Nx);

%       % Equilibrio con il fuoco f0=0.3575
%     st.B = 0.4 * ones(Ny, Nx);
%     st.G = 0.3 * ones(Ny, Nx);
%      st.S = 0.1025 * ones(Ny, Nx);
%      st.P = 0.055 * ones(Ny, Nx);
%      st.H = 0.1479 * ones(Ny, Nx);
%      
     



    % Rinormalizza
    %[st.B, st.G, st.S, st.P, st.H] = renorm_veg(st.B, st.G, st.S, st.P, st.H);

    % Pools RothC: valori equilibrio(ton/ha) senza fuoco (nuovo modello)
    st.DPM = 0.27866  * ones(Ny, Nx);
    st.RPM = 6.21385  * ones(Ny, Nx);
    st.BIO = 0.9473   * ones(Ny, Nx);
    st.HUM = 36.8378  * ones(Ny, Nx);
%     
    
%     % Pools RothC: valori equilibrio(ton/ha) con fuoco f0=0.3575
%      st.DPM = 0.076358   * ones(Ny, Nx);
%     st.RPM = 26.8953    * ones(Ny, Nx);
%     st.BIO = 1.8888    * ones(Ny, Nx);
%     st.HUM = 73.3149  * ones(Ny, Nx);
    
     % Pools RothC: valori equilibrio(ton/ha) con fuoco f0=0.3
%      st.DPM = 0.22935   * ones(Ny, Nx);
%     st.RPM = 7.7804    * ones(Ny, Nx);
%     st.BIO = 0.861584    * ones(Ny, Nx);
%     st.HUM = 12.268  * ones(Ny, Nx);

 % Pools RothC: valori equilibrio(ton/ha) con fuoco f0=0.3(nuovo modello)
%      st.DPM = 0.2586   * ones(Ny, Nx);
%     st.RPM = 7.7736    * ones(Ny, Nx);
%     st.BIO = 0.844851    * ones(Ny, Nx);
%     st.HUM = 11.3523  * ones(Ny, Nx);



    % Pools RothC: valori equilibrio(ton/ha) con fuoco f0=0.2
%      st.DPM = 0.2667   * ones(Ny, Nx);
%     st.RPM = 7.6438    * ones(Ny, Nx);
%     st.BIO = 1.0125    * ones(Ny, Nx);
%     st.HUM = 39.4055   * ones(Ny, Nx);

    
%     
%     st.DPM = 0.1533* ones(Ny, Nx);
%     st.RPM = 4.4852  * ones(Ny, Nx);
%     st.BIO = 0.6671  * ones(Ny, Nx);
%     st.HUM = 25.8576 * ones(Ny, Nx);
   
    % --- Falloon et al. IOM initialization ---
% soc(t) := c_dpm + c_rpm + c_bio + c_hum
SOC = st.DPM + st.RPM + st.BIO + st.HUM;

% Solve: 0.049*TOC^1.139 - TOC + SOC = 0  for TOC (element-wise)
TOC = max(SOC + 1.0, 1e-6);    % initial guess: SOC slightly above soc
tol = 1e-10;
maxit = 50;

for k = 1:maxit
    g  = 0.049 .* (TOC.^1.139) - TOC + SOC;
    gp = 0.049*1.139 .* (TOC.^0.139) - 1.0;   % derivative wrt SOC

    dTOC = - g ./ gp;
    TOCn = TOC + dTOC;

    % enforce SOC >= soc (so that IOM = SOC - soc is non-negative)
    TOCn = max(TOCn, SOC + 1e-12);

    % convergence check (relative)
    if max(abs(dTOC(:)) ./ max(TOC(:),1)) < tol
        TOC = TOCn;
        break
    end

    TOC = TOCn;
end

% IOM from Falloon-consistent SOC
st.IOM = TOC - SOC;                 % equivalent to 0.049*(SOC.^1.139)
% st.IOM = 0.049 .* (SOC.^1.139);   % (equivalently, if you prefer)
   % st.IOM = 2.9641  * ones(Ny, Nx);

end

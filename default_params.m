%% File: default_params.m
% Parametri base (ispirati alla Tabella 1 del report, con correzioni di naming).
% NOTA: nel report alcuni valori di rho_cover (shrub/wood) compaiono con
% valori diversi in testo/tabella: qui li lasciamo parametrizzati.

function p = default_params()


    % --- Simulazione
    p.sim.years = 150;                 % anni simulati
    p.sim.store_maps_every = 1;        % 0 = non salvare mappe, altrimenti ogni N mesi
    p.sim.keep_last_year_maps = true;   % conserva SOLO le mappe degli ultimi mesi
    p.sim.keep_last_months    = 12;     % 12 = ultimo anno (12 mesi)
    p.sim.h = 1/12;

    % --- Griglia
    p.grid.Ny = 300;
    p.grid.Nx = 300;
    p.grid.cellsize_ha = 0.04;         % ha (es. 20x20 m = 400 m2 = 0.04 ha)
    
    % Sito
    p.site.clay_pct =30;
    p.site.soil_depth_cm = 23;
   

    % --- Vegetazione: beta0 annuali (1/yr), poi si usa /12 nel passo mensile
    p.veg.beta0_bg = 0.5;    % B -> G
    p.veg.beta0_gs = 0.3;    % G -> S
    p.veg.beta0_sp = 0.2;    % S -> P
    p.veg.beta0_sh = 0.1;    % S -> H
    p.veg.beta0_ph = 0.05;   % P -> H

    % Feedback carbonio (BIO+HUM)/SOC
    p.veg.kappaC = 1.0;

    
  
    % Dipendenza da umidità del suolo per le transizioni "verso legnoso"
    p.veg.use_moisture_on_beta = true;
    p.veg.epsilon = 1.0;     % fattore moltiplicativo (nel report: "enhancement")
    
    

    % --- Fuoco
    p.fire.use_seasonality = true;
    p.fire.f0_annual = 0.35;% 0.2;          % baseline annuale; diviso 12 -> mensile
    %p.fire.zeta = 0.2;               % riduzione con s
    %p.fire.delta = 1.0;              % termine max(1 - delta*s,0) 

    p.fire.nu_g = 0.6;
    p.fire.nu_s = 0.5;
    p.fire.nu_p = 0.4;
    p.fire.nu_h = 0.2;
    
    
    % --- Fire -> soil deposition + pyrogenic partition
    p.fire.eta_dep    = 0.30;   % [-] fraction of fire-affected C that is NOT volatilized and reaches soil
    p.fire.omega_char = 0;   % [-] fraction of deposited fire C routed to inert (char) pool
    p.fire.sigma=0.2;
    
    % If char is routed to IOM, IOM cannot remain constant
    p.roth.IOM_const = false;

    % Severità (frazioni bruciate per tipo)
    p.fire.alpha_g = 1;
    p.fire.alpha_s = 0.6;
    p.fire.alpha_p = 0.6;
    p.fire.alpha_h = 0.3;

    % Propagazione semplice (opzionale): soglia su F del vicino
    
p.fire.use_propagation = true;
p.fire.neighborhood = 8;              % 8-neighbors per avere cluster più evidenti
p.fire.propagation_threshold = 0.015; % <-- F_threshold (mensile) in scala con F (0.01–0.03 tipico)
p.fire.propagation_max_iter = 10;      % 1 = solo vicini immediati (come “attorno”)




    % --- RothC: tassi annuali  
    p.roth.kDPM = 10;
    p.roth.kRPM = 0.3;
    p.roth.kBIO = 0.66;
    p.roth.kHUM = 0.02;

    x=1.67*(1.85+1.60*exp(-0.0786*p.site.clay_pct));
    p.roth.deltaBIO = 0.46/(x+1);
    p.roth.deltaHUM = 1/(x+1)-p.roth.deltaBIO;

    % Inert organic matter: qui la teniamo costante e inizializzata in init_state
    p.roth.IOM_const = true;

    % Fattori ambientali RothC
   
    % Fattore copertura suolo (peso medio per frazioni vegetazionali)
    p.roth.rho_grass = 0.6;
    p.roth.rho_shrub = 0.5;  
    p.roth.rho_wood  = 0.4;  

    % --- Input vegetazione -> suolo
    p.input.gamma = 0.59; % quota su DPM (1-gamma su RPM)

    % Biomassa carbonio (ton/ha) per frazione di copertura
    p.input.xi_g = 20;
    p.input.xi_s = 30;
    p.input.xi_p = 50;
    p.input.xi_h = 50;

    % Frazione annua di C che finisce nel suolo per metabolismo (ton/ton/yr)
    p.input.mu_g = 0.05;
    p.input.mu_s = 0.05;
    p.input.mu_p = 0.03;
    p.input.mu_h = 0.03;

end

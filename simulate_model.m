function out = simulate_model(p, clim, st)
%SIMULATE_MODEL Loop principale mensile (Vegetazione–Fuoco–Suolo/RothC).
%   out = simulate_model(p, clim, st)
%
%   Per ogni mese:
%     1) calcola probabilità incendio e ignizione (Bernoulli)
%     2) opzionale propagazione
%     3) aggiorna vegetazione + pool suolo (update_model_one_month)
%     4) salva serie temporali e, opzionalmente, snapshot di mappe

%% Dimensioni
nMonths = size(clim.tsmd, 1);
[Ny, Nx] = size(st.B);

%% Prealloc output (serie temporali: include stato iniziale t=0)
out.time_months   = (0:nMonths)';         % mesi, include t=0
out.veg_sys       = zeros(nMonths+1, 5);  % [B G S P H]
out.soc_sys       = zeros(nMonths+1, 1);  % SOC medio
out.fire_frac_sys = zeros(nMonths, 1);    % frazione celle bruciate al mese t

% Stato iniziale (t=0)
out.veg_sys(1,:) = veg_means(st);
out.pool_sys(1,:) = pool_means(st);
SOC0 = soc_total(st);
out.soc_sys(1) = mean(SOC0(:));

%% Snapshot mappe (opzionale)
storeMaps = isfield(p,'sim') && isfield(p.sim,'store_maps_every') && p.sim.store_maps_every > 0;

% Se true: conserva SOLO le mappe dell'ultimo anno (es. ultimi 12 mesi)
keepLastYearMaps = storeMaps && isfield(p.sim,'keep_last_year_maps') && p.sim.keep_last_year_maps;
keepMonths = 12;
if keepLastYearMaps && isfield(p.sim,'keep_last_months')
    keepMonths = p.sim.keep_last_months;
end

if storeMaps
    every = p.sim.store_maps_every;

    if keepLastYearMaps
        % Prealloc solo per l'ultimo anno (numero snapshot dipende da 'every')
        nSnapKeep = max(1, ceil(keepMonths / every));
        out.maps.veg  = cell(nSnapKeep, 1);   % Ny x Nx x 5
        out.maps.soc  = cell(nSnapKeep, 1);   % Ny x Nx
        out.maps.pool = cell(nSnapKeep, 1);   % Ny x Nx x 5
        out.maps.burn = cell(nSnapKeep, 1);   % Ny x Nx logical
        out.maps.t    = zeros(nSnapKeep, 1);  % mese snapshot
        snapIdx = 0;                           % inizierà a riempire nell'ultimo anno
    else
        nSnap = floor(nMonths / every) + 1;   % include t=0

        out.maps.veg  = cell(nSnap, 1);       % Ny x Nx x 5
        out.maps.soc  = cell(nSnap, 1);       % Ny x Nx
        out.maps.pool = cell(nSnap, 1);       % Ny x Nx x 5
        out.maps.burn = cell(nSnap, 1);       % Ny x Nx logical
        out.maps.t    = zeros(nSnap, 1);      % mese snapshot

        snapIdx = 1;
        out.maps.veg{snapIdx}  = veg_stack(st);
        out.maps.soc{snapIdx}  = SOC0;
        out.maps.pool{snapIdx} = pool_stack(st);
        out.maps.burn{snapIdx} = false(Ny, Nx);
        out.maps.t(snapIdx)    = 0;
    end
end

%% Costanti/clima non dipendenti dal tempo 
temp0    = clim.Temp0;      % se usata in update_model_one_month
F_threshold = p.fire.propagation_threshold;
%% Loop mensile
for t = 1:nMonths

    % Forzanti climatiche al mese t (Ny x Nx)
    temp = clim.temp(t,:,:);  temp = temp(1,:,:);  temp = squeeze(temp);
    rho_moisture    = clim.rho_moisture(t,:,:);     rho_moisture    = rho_moisture(1,:,:);     rho_moisture    = squeeze(rho_moisture);

    % Probabilità di incendio e ignizione (Bernoulli)
    F   = fire_probability(p, st, rho_moisture, t);   % Ny x Nx
    ign = rand(Ny, Nx) < F;               % Ny x Nx logical
        
     % Propagazione 
    if isfield(p,'fire') && isfield(p.fire,'use_propagation') && p.fire.use_propagation
       
    ign = propagate_fire_simple(ign, F, F_threshold, p.fire.neighborhood, p.fire.propagation_max_iter);
    
    end

   

    out.fire_frac_sys(t) = mean(ign(:));

    % Aggiornamento stato (vegetazione + pool suolo)
    st = update_model_one_month(p, st, ign, temp, temp0, rho_moisture);

    % Salva serie temporali (dopo aggiornamento)
    out.veg_sys(t+1,:) = veg_means(st);
    out.pool_sys(t+1,:) = pool_means(st);
    SOC = soc_total(st);
    out.soc_sys(t+1)   = mean(SOC(:));

    % Salva snapshot mappe (se richiesto)
    if storeMaps && mod(t, every) == 0
        if keepLastYearMaps
            % salva solo negli ultimi 'keepMonths' mesi
            if t > nMonths - keepMonths
                snapIdx = snapIdx + 1;
                out.maps.veg{snapIdx}  = veg_stack(st);
                out.maps.soc{snapIdx}  = SOC;
                out.maps.pool{snapIdx} = pool_stack(st);
                out.maps.burn{snapIdx} = ign;
                out.maps.t(snapIdx)    = t;
            end
        else
            snapIdx = snapIdx + 1;
            out.maps.veg{snapIdx}  = veg_stack(st);
            out.maps.soc{snapIdx}  = SOC;
            out.maps.pool{snapIdx} = pool_stack(st);
            out.maps.burn{snapIdx} = ign;
            out.maps.t(snapIdx)    = t;
        end
    end
end

%% Trim mappe se si è scelto di conservare solo l'ultimo anno
if storeMaps && keepLastYearMaps
    out.maps.veg  = out.maps.veg(1:snapIdx);
    out.maps.soc  = out.maps.soc(1:snapIdx);
    out.maps.pool = out.maps.pool(1:snapIdx);
    out.maps.burn = out.maps.burn(1:snapIdx);
    out.maps.t    = out.maps.t(1:snapIdx);
end

end % simulate_model

%% Helper locali (leggibilità)
function v = veg_means(st)
v = [mean(st.B(:)) mean(st.G(:)) mean(st.S(:)) mean(st.P(:)) mean(st.H(:))];
end

function cp = pool_means(st)
cp = [mean(st.DPM(:)) mean(st.RPM(:)) mean(st.BIO(:)) mean(st.HUM(:)) mean(st.IOM(:))];
end

function SOC = soc_total(st)
SOC = st.DPM + st.RPM + st.BIO + st.HUM; % + st.IOM;
end

function V = veg_stack(st)
V = cat(3, st.B, st.G, st.S, st.P, st.H);
end

function CP = pool_stack(st)
CP = cat(3, st.DPM, st.RPM, st.BIO, st.HUM, st.IOM);
end





% function out = simulate_model(p, clim, st)
% %SIMULATE_MODEL Loop principale mensile (Vegetazione–Fuoco–Suolo/RothC).
% %   out = simulate_model(p, clim, st)
% %
% %   Per ogni mese:
% %     1) calcola probabilità incendio e ignizione (Bernoulli)
% %     2) opzionale propagazione
% %     3) aggiorna vegetazione + pool suolo (update_model_one_month)
% %     4) salva serie temporali e, opzionalmente, snapshot di mappe
% 
% %% Dimensioni
% nMonths = size(clim.tsmd, 1);
% [Ny, Nx] = size(st.B);
% 
% %% Prealloc output (serie temporali: include stato iniziale t=0)
% out.time_months   = (0:nMonths)';         % mesi, include t=0
% out.veg_sys       = zeros(nMonths+1, 5);  % [B G S P H]
% out.soc_sys       = zeros(nMonths+1, 1);  % SOC medio
% out.fire_frac_sys = zeros(nMonths, 1);    % frazione celle bruciate al mese t
% 
% % Stato iniziale (t=0)
% out.veg_sys(1,:) = veg_means(st);
% out.pool_sys(1,:) = pool_means(st);
% SOC0 = soc_total(st);
% out.soc_sys(1) = mean(SOC0(:));
% 
% %% Snapshot mappe (opzionale)
% storeMaps = isfield(p,'sim') && isfield(p.sim,'store_maps_every') && p.sim.store_maps_every > 0;
% if storeMaps
%     every = p.sim.store_maps_every;
%     nSnap = floor(nMonths / every) + 1;   % include t=0
% 
%     out.maps.veg  = cell(nSnap, 1);       % Ny x Nx x 5
%     out.maps.soc  = cell(nSnap, 1);       % Ny x Nx
%     out.maps.burn = cell(nSnap, 1);       % Ny x Nx logical
%     out.maps.t    = zeros(nSnap, 1);      % mese snapshot
% 
%     snapIdx = 1;
%     out.maps.veg{snapIdx}  = veg_stack(st);
%     out.maps.soc{snapIdx}  = SOC0;
%     out.maps.burn{snapIdx} = false(Ny, Nx);
%     out.maps.t(snapIdx)    = 0;
% end
% 
% %% Costanti/clima non dipendenti dal tempo 
% temp0    = clim.Temp0;      % se usata in update_model_one_month
% F_threshold = p.fire.propagation_threshold;
% %% Loop mensile
% for t = 1:nMonths
% 
%     % Forzanti climatiche al mese t (Ny x Nx)
%     temp = clim.temp(t,:,:);  temp = temp(1,:,:);  temp = squeeze(temp);
%     rho_moisture    = clim.rho_moisture(t,:,:);     rho_moisture    = rho_moisture(1,:,:);     rho_moisture    = squeeze(rho_moisture);
% 
%     % Probabilità di incendio e ignizione (Bernoulli)
%     F   = fire_probability(p, st, rho_moisture, t);   % Ny x Nx
%     ign = rand(Ny, Nx) < F;               % Ny x Nx logical
%         
%      % Propagazione 
%     if isfield(p,'fire') && isfield(p.fire,'use_propagation') && p.fire.use_propagation
%        
%     ign = propagate_fire_simple(ign, F, F_threshold, p.fire.neighborhood, p.fire.propagation_max_iter);
%     
%     end
% 
%    
% 
%     out.fire_frac_sys(t) = mean(ign(:));
% 
%     % Aggiornamento stato (vegetazione + pool suolo)
%     st = update_model_one_month(p, st, ign, temp, temp0, rho_moisture);
% 
%     % Salva serie temporali (dopo aggiornamento)
%     out.veg_sys(t+1,:) = veg_means(st);
%     out.pool_sys(t+1,:) = pool_means(st);
%     SOC = soc_total(st);
%     out.soc_sys(t+1)   = mean(SOC(:));
% 
%     % Salva snapshot mappe (se richiesto)
%     if storeMaps && mod(t, every) == 0
%         snapIdx = snapIdx + 1;
%         out.maps.veg{snapIdx}  = veg_stack(st);
%         out.maps.soc{snapIdx}  = SOC;
%         out.maps.pool{snapIdx}  = pool_stack(st);
%         out.maps.burn{snapIdx} = ign;
%         out.maps.t(snapIdx)    = t;
%     end
% end
% 
% end % simulate_model
% 
% %% Helper locali (leggibilità)
% function v = veg_means(st)
% v = [mean(st.B(:)) mean(st.G(:)) mean(st.S(:)) mean(st.P(:)) mean(st.H(:))];
% end
% 
% function cp = pool_means(st)
% cp = [mean(st.DPM(:)) mean(st.RPM(:)) mean(st.BIO(:)) mean(st.HUM(:)) mean(st.IOM(:))];
% end
% 
% function SOC = soc_total(st)
% SOC = st.DPM + st.RPM + st.BIO + st.HUM; % + st.IOM;
% end
% 
% function V = veg_stack(st)
% V = cat(3, st.B, st.G, st.S, st.P, st.H);
% end
% 
% function CP = pool_stack(st)
% CP = cat(3, st.DPM, st.RPM, st.BIO, st.HUM, st.IOM);
% end

%% main_soilVegFire.m
% Modello integrato Vegetazione–Fuoco–Suolo (RothC) a scala mensile.
% Implementa eq. (2)-(3) per vegetazione+fuoco e (4) per RothC,
% con feedback di SOC su beta e dipendenza da umidità.
%
% Uso:
%   out = main_soilVegFire();

clearvars
close all
clc

rng(1,'twister')  % riproducibilità

%% Parametri e dominio
p = default_params();

Ny = p.grid.Ny;
Nx = p.grid.Nx;

nMonths = p.sim.years * 12;

%% Clima/forzanti (temperatura, tsmd, umidità relativa s)
clim = make_climate(p, nMonths, Ny, Nx);

%% Stato iniziale (vegetazione + pools RothC)
st = init_state(p, Ny, Nx);

%% Simulazione
out = simulate_model(p, clim, st);


%% Grafici rapidi (medie di sistema)
tYears = out.time_months / 12;

% Colori RGB (0-1) “naturali” per B,G,S,P,H
vegRGB = [
    0.85 0.80 0.70  % B (sabbia)
    0.20 0.70 0.20  % G (verde)
    0.55 0.60 0.20  % S (olivastro)
    0.10 0.45 0.15  % P (verde scuro)
    0.35 0.20 0.10  % H (marrone/terra)
];

% --- Vegetazione
figure('Name','Vegetation','Color','w');
hh = semilogx(tYears, out.veg_sys(:,1:5), 'LineWidth', 1.2);
for k = 1:5
    hh(k).Color = vegRGB(k,:);
end
ylim([-0.05 1.05]);
xlim([1/12 p.sim.years]);
legend({'B','G','S','P','H'}, 'Location','best');
xlabel('years');
ylabel('System means');
title('Vegetation');
grid on;




% Pool carbonio
figure('Name','Carbon pools','Color','w');
h = loglog(tYears, out.pool_sys(:,1:5), 'LineWidth', 1.2);
% for k = 1:5
%     h(k).Color = vegRGB(k,:);
% end
legend({'DPM','RPM','BIO','HUM','IOM'}, 'Location','best');
ylim([0 60]);
xlim([1/12 p.sim.years]);
xlabel('years');
ylabel('System means');
title('Carbon Pools');
grid on;


% --- SOC
figure('Name','SOC','Color','w');
semilogx(tYears, out.soc_sys, 'LineWidth', 1.2);
legend({'SOC'}, 'Location','best');
ylim([0 50]);
xlim([1/12 p.sim.years]);
xlabel('years');
ylabel('SOC (ton/ha, system mean)');
title('Soil Organic Carbon (SOC)');
grid on;

% --- % celle bruciate (per mese)
figure('Name','Burned cells %','Color','w');

tYears_fire = tYears(2:end);              % mesi 1..nMonths (t=0 escluso)
burnPct = 100 * out.fire_frac_sys(:);     % percentuale

semilogx(tYears_fire, burnPct, 'LineWidth', 1.2);
%ylim([0 100]);
xlim([1/12 p.sim.years]);
xlabel('years');
ylabel('% burned cells');
title('Burned cells per month');
grid on;



%% Animazione 

 %   animate_veg_fire(out);

% Con p.sim.keep_last_year_maps=true, out.maps contiene solo gli ultimi 12 mesi
animate_veg_fire_multifig(out);   % anima solo l'ultimo anno

fs = 12;
set(findall(0,'-property','FontSize'),'FontSize',fs);

% --- tempo in anni
tYears = out.time_months / 12;

% --- percentuale bruciata (0..100), associata ai mesi 1..end
tYears_fire = tYears(2:end);
burnPct = 100 * out.fire_frac_sys(:);

% --- finestra ultimi 10 anni
T = 10;
t0 = tYears(end) - T;

mask_all  = (tYears >= t0);
mask_fire = (tYears_fire >= t0);

% --- figura 2x2
figure('Name',sprintf('System time series - last %d years',T),'Color','w');
tiledlayout(2,2,'TileSpacing','compact','Padding','compact');

% Vegetazione
nexttile;
hh = semilogx(tYears(mask_all), out.veg_sys(mask_all,1:5), 'LineWidth', 1.2);
% Se hai vegRGB definito nel workspace, puoi colorare come prima:
for k = 1:5, hh(k).Color = vegRGB(k,:); end
ylim([-0.1 1.1]);
xlim([max(0,t0) tYears(end)]);
legend({'B','G','S','P','H'}, 'Location','best');
xlabel('years'); ylabel('System means'); title(sprintf('Vegetation (last %d y)',T));
grid on;

% Carbon pools
nexttile;
semilogx(tYears(mask_all), out.pool_sys(mask_all,1:5), 'LineWidth', 1.2);
xlim([max(0,t0) tYears(end)]);
legend({'DPM','RPM','BIO','HUM','IOM'}, 'Location','best');
xlabel('years'); ylabel('System means'); title(sprintf('Carbon Pools (last %d y)',T));
grid on;

% SOC
nexttile;
semilogx(tYears(mask_all), out.soc_sys(mask_all), 'LineWidth', 1.2);
xlim([max(0,t0) tYears(end)]);
xlabel('years'); ylabel('SOC (ton/ha, system mean)');
title(sprintf('SOC (last %d y)',T));
grid on;

% % bruciato
nexttile;
plot(tYears_fire(mask_fire), burnPct(mask_fire), 'LineWidth', 1.2);
%ylim([0 100]);
xlim([max(0,t0) tYears(end)]);
xlabel('years'); ylabel('% burned cells');
title(sprintf('Burned cells per month (last %d y)',T));
grid on;

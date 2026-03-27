%% File: animate_veg_fire_multifig.m
% Crea UNA FIGURA PER OGNI FRAME (es. 12 mesi) invece di sovrascrivere sempre la stessa.
% Non salva GIF/MP4: apre tante finestre quante sono i frame richiesti.
%
% Uso:
%   animate_veg_fire_multifig(out);                         % default: 12 frame da out.maps.veg{1}
%   animate_veg_fire_multifig(out,'startSnap',13);          % parte da un altro snapshot
%   animate_veg_fire_multifig(out,'nFrames',12,'stride',1); % 12 mesi consecutivi
%   animate_veg_fire_multifig(out,'pauseSec',0.05);         % piccola pausa tra aperture finestre
%
% Opzioni (name/value):
%   'startSnap'  (default 1)   primo snapshot da plottare
%   'nFrames'    (default 12)  numero di figure da generare
%   'stride'     (default 1)   1 frame ogni 'stride' snapshot
%   'burnAlpha'  (default 0.75) trasparenza overlay rosso incendio
%   'pauseSec'   (default 0)   pausa tra una figura e l'altra

function animate_veg_fire_multifig(out, varargin)

    % --- parsing argomenti
    startSnap = 1;
    nFrames   = 12;
    stride    = 1;
    burnAlpha = 0.75;
    pauseSec  = 0;

    i = 1;
    while i <= numel(varargin)
        key = string(varargin{i});
        switch key
            case "startSnap"
                startSnap = varargin{i+1}; i = i + 2;
            case "nFrames"
                nFrames = varargin{i+1}; i = i + 2;
            case "stride"
                stride = varargin{i+1}; i = i + 2;
            case "burnAlpha"
                burnAlpha = varargin{i+1}; i = i + 2;
            case "pauseSec"
                pauseSec = varargin{i+1}; i = i + 2;
            otherwise
                i = i + 1;
        end
    end

    assert(isfield(out,'maps') && isfield(out.maps,'veg') && isfield(out.maps,'burn') && isfield(out.maps,'t'), ...
        'Serve out.maps.veg, out.maps.burn e out.maps.t.');

    vegNames = {'B','G','S','P','H'};

    % Colori RGB (0-1) “naturali”
    vegRGB = [
        0.85 0.80 0.70  % B
        0.20 0.70 0.20  % G
        0.55 0.60 0.20  % S
        0.10 0.45 0.15  % P
        0.35 0.20 0.10  % H
    ];
    burnRGB = [1 0 0];

    nSnap = numel(out.maps.veg);

    % Se l'utente chiede più frame di quelli disponibili, riduci automaticamente
    maxFrames = floor((nSnap - startSnap)/stride) + 1;
    if maxFrames < 1
        error('startSnap (%d) fuori range: nSnap=%d.', startSnap, nSnap);
    end
  if nFrames > maxFrames
    fprintf('[animate_veg_fire_multifig] nFrames=%d ridotto a %d (snapshot disponibili).\n', ...
        nFrames, maxFrames);
    nFrames = maxFrames;
end



    % --- loop: una FIGURA nuova per ogni frame
    s = startSnap;
    for k = 1:nFrames

        veg  = out.maps.veg{s};      % Ny x Nx x 5
        burn = logical(out.maps.burn{s}); % Ny x Nx logical
        tMonth = out.maps.t(s);      % mese globale (1..)

        [Ny, Nx, ~] = size(veg);

        % dominante
        [~, dom] = max(veg, [], 3); % 1..5

        % costruisci RGB della vegetazione dominante
        rgb = zeros(Ny, Nx, 3);
        for cls = 1:5
            mask = (dom == cls);
            for c = 1:3
                rgb(:,:,c) = rgb(:,:,c) + mask * vegRGB(cls,c);
            end
        end

        % overlay incendio in rosso (blend)
        if any(burn(:))
            for c = 1:3
                rgb(:,:,c) = rgb(:,:,c).*(1 - burnAlpha*double(burn)) + ...
                             (burnAlpha*double(burn))*burnRGB(c);
            end
        end

        % --- FIGURA NUOVA
        mm = mod(tMonth-1, 12) + 1;        % mese dell'anno 1..12
        fracBurn = mean(burn(:));

        f = figure('Color','w', ...
                   'Name', sprintf('Mese %d (snap %d)', mm, s), ...
                   'NumberTitle','off');

        ax = axes('Parent', f);
        axis(ax,'image'); axis(ax,'off');
        imshow(rgb, 'Parent', ax);

        makeLegend(vegNames, vegRGB);

        title(ax, sprintf('Mese %d (%.2f anni) — Celle incendiate: %.1f%%', ...
            mm, tMonth/12, 100*fracBurn), 'FontWeight','bold');

        drawnow;

        if pauseSec > 0
            pause(pauseSec);
        end

        s = s + stride;
    end

end

function makeLegend(names, rgb)
    % leggenda laterale con annotation
    x0 = 0.82; y0 = 0.85; dy = 0.05; w = 0.03; h = 0.03;

    for i = 1:numel(names)
        annotation('rectangle', [x0 y0-(i-1)*dy w h], ...
            'FaceColor', rgb(i,:), 'EdgeColor', [0 0 0]);
        annotation('textbox', [x0+w+0.01 y0-(i-1)*dy 0.16 h], ...
            'String', names{i}, 'LineStyle','none', 'FontSize', 10, ...
            'VerticalAlignment','middle');
    end

    % incendio
    % annotation('rectangle', [x0 y0-(numel(names))*dy w h], ...
    %     'FaceColor', [1 0 0], 'EdgeColor', [0 0 0]);
    % annotation('textbox', [x0+w+0.01 y0-(numel(names))*dy 0.16 h], ...
    %     'String', 'Incendio (mese)', 'LineStyle','none', 'FontSize', 10, ...
    %     'VerticalAlignment','middle');
end






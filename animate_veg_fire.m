%% File: animate_veg_fire.m
% Animazione griglia: vegetazione dominante (colori) + incendi (rosso) sovrapposti.
%
% Uso:
%   animate_veg_fire(out);                       % animazione a schermo
%   animate_veg_fire(out, 'gif', 'anim.gif');    % salva GIF
%   animate_veg_fire(out, 'mp4', 'anim.mp4');    % salva MP4
%
% Opzioni (name/value):
%   'fps'        (default 10)
%   'burnAlpha'  (default 0.75) trasparenza rosso incendio
%   'stride'     (default 1)    mostra 1 frame ogni 'stride' snapshot

function animate_veg_fire(out, varargin)

    % --- parsing argomenti
    saveMode = "";   % "", "gif", "mp4"
    saveName = "";
    fps = 10;
    burnAlpha = 0.75;
    stride = 1;

    i = 1;
    while i <= numel(varargin)
        if ischar(varargin{i}) || isstring(varargin{i})
            key = string(varargin{i});
            if key == "gif" || key == "mp4"
                saveMode = key;
                saveName = string(varargin{i+1});
                i = i + 2;
                continue;
            end
            if key == "fps"
                fps = varargin{i+1}; i = i + 2; continue;
            end
            if key == "burnAlpha"
                burnAlpha = varargin{i+1}; i = i + 2; continue;
            end
            if key == "stride"
                stride = varargin{i+1}; i = i + 2; continue;
            end
        end
        i = i + 1;
    end

    assert(isfield(out,'maps') && isfield(out.maps,'veg') && isfield(out.maps,'burn'), ...
        'Serve out.maps.veg e out.maps.burn. Imposta p.sim.store_maps_every e salva ign in simulate_model.');

    vegNames = {'B (bare)','G (grass)','S (shrub)','P (pine)','H (hardwood)'};

    % Colori RGB (0-1) “naturali”
    % B: sabbia, G: verde, S: olivastro, P: verde scuro, H: marrone/terra
    vegRGB = [
        0.85 0.80 0.70  % B
        0.20 0.70 0.20  % G
        0.55 0.60 0.20  % S
        0.10 0.45 0.15  % P
        0.35 0.20 0.10  % H
    ];
    burnRGB = [1 0 0];

    nSnap = numel(out.maps.veg);

    % --- setup figura
    f = figure('Color','w');
    ax = axes('Parent', f);
    axis(ax,'image'); axis(ax,'off');

    % Mini-leggenda a lato (patch colorate)
    makeLegend(vegNames, vegRGB);

    % --- setup salvataggio
    vw = [];
    if saveMode == "mp4"
        vw = VideoWriter(saveName, 'MPEG-4');
        vw.FrameRate = fps;
        open(vw);
    end

    dt = 1 / fps;

    for s = 1:stride:nSnap

        veg = out.maps.veg{s};      % Ny x Nx x 5
        burn = out.maps.burn{s};    % Ny x Nx logical
        tMonth = out.maps.t(s);

        [Ny, Nx, ~] = size(veg);

        % dominante
        [~, dom] = max(veg, [], 3); % 1..5

        % costruisci RGB della vegetazione dominante
        rgb = zeros(Ny, Nx, 3);
        for k = 1:5
            mask = (dom == k);
            for c = 1:3
                rgb(:,:,c) = rgb(:,:,c) + mask * vegRGB(k,c);
            end
        end

        % overlay incendio in rosso (blend)
        burn = logical(burn);
        if any(burn(:))
            for c = 1:3
                rgb(:,:,c) = rgb(:,:,c).*(1 - burnAlpha*double(burn)) + ...
                             (burnAlpha*double(burn))*burnRGB(c);
            end
        end

        % mostra
        if isgraphics(ax)
            imshow(rgb, 'Parent', ax);
        
        end

        fracBurn = mean(burn(:));
        title(ax, sprintf('Mese %d (%.2f anni) — Celle incendiate: %.1f%%', ...
            tMonth, tMonth/12, 100*fracBurn), 'FontWeight','bold');

        drawnow;

        % salva frame
        if saveMode == "gif"
            frame = getframe(f);
            [im, cm] = rgb2ind(frame2im(frame), 256);
            if s == 1
                imwrite(im, cm, saveName, 'gif', 'LoopCount', inf, 'DelayTime', dt);
            else
                imwrite(im, cm, saveName, 'gif', 'WriteMode','append', 'DelayTime', dt);
            end
        elseif saveMode == "mp4"
            frame = getframe(f);
            writeVideo(vw, frame);
        else
            pause(dt);
        end
    end

    if saveMode == "mp4"
        close(vw);
    end

end

function makeLegend(names, rgb)
    % leggenda laterale semplice con annotation
    % (una per voce, colorata)
    x0 = 0.82; y0 = 0.85; dy = 0.05; w = 0.03; h = 0.03;

    for i = 1:numel(names)
        annotation('rectangle', [x0 y0-(i-1)*dy w h], ...
            'FaceColor', rgb(i,:), 'EdgeColor', [0 0 0]);
        annotation('textbox', [x0+w+0.01 y0-(i-1)*dy 0.16 h], ...
            'String', names{i}, 'LineStyle','none', 'FontSize', 10, ...
            'VerticalAlignment','middle');
    end

    % incendio
    annotation('rectangle', [x0 y0-(numel(names))*dy w h], ...
        'FaceColor', [1 0 0], 'EdgeColor', [0 0 0]);
    annotation('textbox', [x0+w+0.01 y0-(numel(names))*dy 0.16 h], ...
        'String', 'Incendio (mese)', 'LineStyle','none', 'FontSize', 10, ...
        'VerticalAlignment','middle');
end

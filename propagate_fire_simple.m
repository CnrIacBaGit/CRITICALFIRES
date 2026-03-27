%% File: propagate_fire_simple.m
% Propagazione semplice (report Sec. 2.4):
% attorno a celle ignited, bruciano tutte le celle con F > delta.
%
% burned = propagate_fire_simple(ignition, F, delta, neighborhood, maxIter)

function burned = propagate_fire_simple(ignition, F, F_threshold, neighborhood, maxIter)
    if nargin < 5 || isempty(maxIter)
        maxIter = 1; % default: solo vicini immediati
    end

    burned = logical(ignition);

    if neighborhood == 8
        K = ones(3); K(2,2) = 0;   % Moore neighborhood
    else
        K = [0 1 0; 1 0 1; 0 1 0]; % Von Neumann
    end

    it = 0;
    while true
        it = it + 1;

        neigh = conv2(double(burned), K, 'same') > 0;      % celle adiacenti a bruciate
        add   = neigh & ~burned & (F > F_threshold);             % regola soglia su F

        if ~any(add(:))
            break;
        end

        burned = burned | add;

        if isfinite(maxIter) && it >= maxIter
            break;
        end
    end
end

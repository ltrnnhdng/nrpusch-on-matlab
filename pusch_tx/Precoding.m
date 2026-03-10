function z = Precoding (y, txconfig, transformPrecoding, nlayer, nantenna)
% cho trường hợp 1 antenna 
    if txconfig ~= "codebook"
        w = eye(nlayer);
    else
        if nlayer == 1 && nantenna == 1
            w = 1;
        % elseif nlayer == 1 && nantenna == 2 
        %     % w = table 6 3 1 5 1
        % elseif nlayer == 1 && nantenna == 4 && transformPrecoding == 'enable'
        %     % w = table 6 3 1 5 2
        % elseif nlayer == 1 && nantenna == 4 && transformPrecoding == 'disable'
        %     % w = table 6 3 1 5 3
        % elseif nlayer == 2 && nantenna == 2 && transformPrecoding == 'enable'
        %     % w = table 6 3 1 5 4
        % elseif nlayer == 2 && nantenna == 4 && transformPrecoding == 'disable'
        %     % w = table 6 3 1 5 5
        % elseif nlayer == 3 && nantenna == 4 && transformPrecoding == 'disable'
        %     % w = table 6 3 1 5 6
        % elseif nlayer == 4 && nantenna == 4 && transformPrecoding == 'disable'
        %     % w = table 6 3 1 5 7    
        else
            error("gia tri nlayer va nantenna khong phu hop");
        end
    end
    z = y*w;
end
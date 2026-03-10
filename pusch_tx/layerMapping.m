function x = layerMapping(d, Nlayer)
    dlen = length(d);
    if mod(dlen, Nlayer) ~=0
        error("So symbol khong chia het cho layer");
    end

    MSymbolPLayer = dlen / Nlayer;

    x = zeros(MSymbolPLayer, Nlayer);
    
    for j = 0:MSymbolPLayer-1
        x(j+1,:) = d(j*Nlayer+1:j*Nlayer+Nlayer);
    end
end

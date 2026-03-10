function [data_out_crc, crc_bits] = add_crc(data_in_crc, poly) 
% Initialize CRC polynomial (gPoly) 
switch poly 
    case '6' 
        gPoly = [1 1 0 0 0 0 1]'; 
    case '11' 
        gPoly = [1 1 1 0 0 0 1 0 0 0 0 1]'; 
    case '16' 
        gPoly = [1 0 0 0 1 0 0 0 0 0 0 1 0 0 0 0 1]'; 
    case {'24a','24A'} 
        gPoly = [1 1 0 0 0 0 1 1 0 0 1 0 0 1 1 0 0 1 1 1 1 1 0 1 1]'; 
    case {'24b','24B'} 
        gPoly = [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 1 1]'; 
    otherwise % {'24c','24C'} 
        gPoly = [1 1 0 1 1 0 0 1 0 1 0 1 1 0 0 0 1 0 0 0 1 0 1 1 1]'; 
end 
L = length(gPoly)-1; 
array = [data_in_crc; zeros(L,1)]; % them L bit 0 vao chuoi 
% tinh crc = cach xor data và genpoly tu trai qua phai 
for i = 1:length(data_in_crc) 
    if array(i) == 1 
        array(i:i+L) = xor(array(i:i+L), gPoly); 
    end 
end     
% outputs 
crc_bits = array(end-L+1 : end); 
data_out_crc = [data_in_crc; crc_bits]; 
end 
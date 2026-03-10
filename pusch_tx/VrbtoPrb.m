function Prb = VrbtoPrb(Vrb, mappingType)
% ánh xạ Vrb ra Prb, 
% input: Vrb, mappingType
%   mappingtype = 0 => non interleaving: prb = vrb
%   mappingtype = 1 => interleaving: đảo....
% output: Prb
% code này mới hoàn thiện cho quy trình = 0; 
    if mappingType == 0
        Prb = Vrb;
    else
        error("chua trien khai truonng hop interleaving....");
    end
end
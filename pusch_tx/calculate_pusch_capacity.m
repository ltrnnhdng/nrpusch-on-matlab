function [G_total] = calculate_pusch_capacity(nPrb, nPuschSym, dmrsSymLoc_array, numDmrsCdmGrpsNoData, nLayers, Qm)
% INPUT:
%   nPrb: Số lượng Resource Block (ví dụ: 50)
%   nPuschSym: Tổng số symbol (ví dụ: 14)
%   dmrsSymLoc_array: Vị trí symbol DMRS (ví dụ: [3])
%   numDmrsCdmGrpsNoData: Số nhóm CDM không chứa dữ liệu (1 hoặc 2)
%   nLayers: Số lớp MIMO
%   Qm: Bậc điều chế (2, 4, 6, 8)
% OUTPUT:
%   G_total: Tổng số bit vật lý có thể truyền trên PUSCH (bao gồm cả Data + UCI)

    % 1. Số lượng Subcarrier trên miền tần số
    nSc = nPrb * 12; 
    
    % 2. Tính tổng số Resource Elements (REs) khả dụng trên miền thời gian
    total_REs = 0;
    
    for l = 1:nPuschSym
        % Kiểm tra xem symbol hiện tại (l) có phải là DMRS không
        if ismember(l, dmrsSymLoc_array)
            % Nếu là symbol DMRS
            if numDmrsCdmGrpsNoData >= 2
                % DMRS chiếm hết, không còn chỗ cho data [cite: 625]
                re_in_symbol = 0; 
            else
                % DMRS chiếm 1 phần, còn lại cho data (thường là một nửa) [cite: 620]
                re_in_symbol = nSc * 0.5; 
            end
        else
            % Symbol dữ liệu bình thường -> Dùng hết subcarriers
            re_in_symbol = nSc;
        end
        
        total_REs = total_REs + re_in_symbol;
    end
    
    % 3. Tính tổng dung lượng bit (G_total)
    % Công thức: Số RE * Số bit/RE * Số lớp
    G_total = total_REs * Qm * nLayers;
end
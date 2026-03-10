function [crk, Kp, Kb, Zc, K] = CBSegmentationAndCRC(data, base_graph) 
% Hàm này thưc hiện ước lượng và chia data vào thành các code block dựa vào
% giá trị base_graph rồi thực hiện thêm các bit kiểm tra crc để đủ Kp bit và fill giá
% trị NULL vào để đủ K bit mỗi khối mã 
    if base_graph == 1 
        Kcb = 8448; 
    else %base graph 2 
        Kcb = 3840; 
    end 
    %s Tinh toan so luong khoi ma 
    B = length(data); 
    if B <= Kcb 
        L = 0; 
        C = 1; 
        Bp = B; 
    else 
        L = 24; 
        C = ceil(B/(Kcb-L)); %làm tròn lên 
        Bp = B + L*C; 
    end 
    % Number of bits per block (data + crc)
    Kp = ceil(Bp/C); 


    if base_graph == 1 
        Kb = 22; 
    else 
        if B > 640 
            Kb = 10; 
        elseif B > 560 
            Kb = 9; 
        elseif B >192 
            Kb = 8; 
        else 
            Kb = 6; 
        end 
    end 
    Z_set = [2, 4, 8, 16, 32, 64, 128, 256, ... 
        3, 6, 12, 24, 48, 96, 192, 384, ... 
        5, 10, 20, 40, 80, 160, 320, ... 
        7, 14, 28, 56, 112, 224, ... 
        9, 18, 36, 72, 144, 288, ... 
        11, 22, 44, 88, 176, 352, ... 
        13, 26, 52, 104, 208, ... 
        15, 30, 60, 120, 240]; 
    Z_set = sort(Z_set); 
    % Tìm Zc sao cho Kb * Zc >= K' 
    Zc = 0; 
    for i = 1:length(Z_set) 
        if Kb*Z_set(i) >= Kp 
            Zc = Z_set(i); 
            break;
        end 
    end 

    % K là tổng số hàng của ma trận đầu ra, bao gồm NULL 
    if base_graph == 1, K = 22 * Zc; else, K = 10 * Zc; end
    
    % Khởi tạo ma trận K hàng x C cột. Mặc định là -1 (Filler bits)
    crk = -1 * ones(K, C);
    s = 0;
    data_per_block = Kp - L; % Số hàng dành cho dữ liệu trong mỗi cột

    for r = 1:C
        for k = 0:Kp-L-1
            if s < B  % Kiểm tra còn dữ liệu không
                crk(k+1,r) = data(s+1);
                s = s+1;
            else
                crk(k+1,r) = 0;  % Điền 0 nếu hết dữ liệu
            end
        end
        
        % Chèn CRC khối mã (nếu C > 1) vào cuối phần dữ liệu của cột
        if C > 1
            [~, cb_crc] = add_crc(crk(1:data_per_block, r), '24B');
            % Gán 24 bit CRC vào các hàng tiếp theo của cột r
            crk(Kp-L + 1: Kp, r) = cb_crc(1:L);
        end
        % Các hàng từ Kp+1 đến K đã là -1 nhờ khởi tạo ban đầu
    end    
end
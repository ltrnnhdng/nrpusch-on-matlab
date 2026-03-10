function RateMatchingAndConcatOut = RateMatchingAndConcat(data, outlen, rv, Mod, nLayers, bgn, Zc, Nref)
% thực hiện ....
    
    C = size(data, 2); %number of code block 
    N = size(data, 1); % number of code bit

    if ~isempty(Nref) && Nref > 0, NCB = min(N, Nref); else, NCB = N; end 
    L = nLayers;

    switch Mod
        case {'pi/2-BPSK', 'BPSK'}
            Qm = 1;
        case 'QPSK'
            Qm = 2;
        case '16QAM'
            Qm = 4;
        case '64QAM'
            Qm = 6;
        case '256QAM'
            Qm = 8;
        otherwise   % '1024QAM' 
            Qm = 10;
    end


    G = outlen; % tong so bit ma lop vat ly truyen di tren RE 

    if bgn == 1
        if rv == 0
            k0 = 0;
        elseif rv == 1
            k0 = floor(17*NCB/(66*Zc))*Zc;
        elseif rv == 2
            k0 = floor(33*NCB/(66*Zc))*Zc;
        else % rv is equal to 3
            k0 = floor(56*NCB/(66*Zc))*Zc;
        end
    else
        if rv == 0
            k0 = 0;
        elseif rv == 1
            k0 = floor(13*NCB/(50*Zc))*Zc;
        elseif rv == 2
            k0 = floor(25*NCB/(50*Zc))*Zc;
        else % rv is equal to 3
            k0 = floor(43*NCB/(50*Zc))*Zc;
        end
    end
    
    E = zeros(C,1);
    for r = 0:(C-1)
        %ignore the 1st condition : if the r-th coded block is not scheduled for transmission as indicated by CBGTI according to Clause 5.1.7.2 for DL-SCH and 6.1.5.2 for UL-SCH in [6, TS 38.214]       
        if r <= ( C - mod( G/(L*Qm),C ) - 1 )
            E(r+1) = L * Qm * floor(G/(L*Qm*C));
        else 
            E(r+1) = L * Qm * ceil(G/(L*Qm*C));
        end 
    end 
    
    RateMatchingAndConcatOut = [];
    RM_each_CB = zeros(max(E(:)),C);
    for c = 1:C
        Er  = E(c);
        k   = 0;
        j   = 0;
        e   = zeros(Er,1);
        d   = data(:,c);
        
        % truyền dữ liệu vào mảng e cho đến khi đủ Er phần tử 
        while k < Er
            idx = mod(k0 + j, NCB) + 1;
            if d(idx) ~= -1 
                e(k+1) = d(idx);
                k = k+1;
            end 
            j=j+1;
        end 
        
        
        for j = 0:Er/Qm-1
            for i=0:Qm-1
                RM_each_CB(i+j*Qm+1,c) = e(i*(Er/Qm)+j+1);
            end 
        end 

    end 

    % concatenation , nối từng chuối theo thứ tự 
    for c = 1:C
        Er = E(c);
        RateMatchingAndConcatOut = [RateMatchingAndConcatOut; RM_each_CB(1:Er, c)];
    end
end
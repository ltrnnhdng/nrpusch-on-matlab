function [bBar] = PUSCH_Scrambling(b, nRNTI, nID, q, isMsgA, nRAPID)
% Input:
%   b       : Vector bits đầu vào (bao gồm cả data và placeholder x, y)
%   nRNTI   : Radio Network Temporary Identifier
%   nID     : Data Scrambling Identity (0..1023)
%   q       : Codeword index (thường là 0)
%   isMsgA  : Boolean (true nếu là MsgA trên PUSCH, false nếu là PUSCH thường)
%   nRAPID  : Random Access Preamble Index (chỉ dùng nếu isMsgA = true)

    % 1. Tính giá trị khởi tạo c_init dựa trên công thức trong ảnh
    if nargin < 5, isMsgA = false; end
    if nargin < 6, nRAPID = 0; end

    if isMsgA
        % Công thức cho msgA trên PUSCH
        % c_init = nRNTI * 2^16 + nRAPID * 2^10 + nID
        cinit = nRNTI * 2^16 + nRAPID * 2^10 + nID;
    else
        % Công thức PUSCH thông thường
        % c_init = nRNTI * 2^15 + q * 2^14 + nID
        cinit = nRNTI * 2^15 + q * 2^14 + nID;
    end

    % 2. XỬ LÝ PLACEHOLDER (Các bit giữ chỗ từ bước Multiplexing)
    % Trong bước Multiplexing, các bit HARQ-ACK hoặc CSI có thể được đánh dấu
    % bằng các giá trị đặc biệt (x, y) thay vì 0, 1.
    % Theo chuẩn:
    % - Các vị trí 'x' (HARQ) được coi là bit 1 khi Scrambling.
    % - Các vị trí 'y' (CSI) được coi là bit giữ chỗ, giá trị lặp lại bit trước đó.
    x = -1;  % Tag cho HARQ-ACK
    y = -2;  % Tag cho CSI
    seq_len = length(b);
    c = PRBSGen(cinit, [0, seq_len]);
    bBar = zeros(size(b));

    i = 0;
    while i<length(b)
        if b(i+1) == x 
            bBar(i+1) = 1;
        else
            if b(i+1) == y 
                bBar(i+1) = bBar(i);
            else
                bBar(i+1) = mod((b(i+1)+c(i+1)),2);
            end
        end
        i = i + 1;
    end
end

function seq = PRBSGen(cinit,n)
% Hàm này để tạo chuỗi giả ngẫu nhiên c(n) từ 2 chuỗi x1 và x2 với giá trị
% cinit seed để khởi tạo giá trị ngẫu nhiên, n gồm 2 phần tử [start long]
% với start là vị trí bắt đầu và long là độ dài chuỗi cần lấy.
% chuỗi được tạo ngẫu nhiên sẽ cắt đi 1600 phần tử đầu tiên để tăng sự ngẫu
% nhiên
    subLen = n(1) + n(2);
    %constant
    Nc = 1600;
    len = subLen + Nc; %total len of both arrays x1 and x2
    
    % generate x1
    x1 = zeros(1,len)';
    % x(1)->x(30)
    x1(1) = 1;
    for i = 1:30
        x1(i+1) = 0;
    end
    % x(30)->...
    for i = 1:(len-31)
        x1(i+31) = mod(x1(i+3)+x1(i),2);
    end
    
    
    % Generate x_2
    x2 = zeros(1,len)';
    % x(1)->x(30)
    x2_init =zeros(1,31);
    for i = 0:30
        x2_init(i+1) = bitget(cinit,i+1);
    end
    x2(1:31) = x2_init;
    % x(30)->...
    for i = 1:len-31
        x2(i+31)=mod(x2(i+3)+x2(i+2)+x2(i+1)+x2(i),2);
    end
    
    % Long sequence
    c = mod((x1(Nc+1:Nc+subLen)+x2(Nc+1:Nc+subLen)),2);
    
    % Cut
    seq = c(end-n(2)+1:end);
end
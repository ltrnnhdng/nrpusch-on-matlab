function channel_coding_out = ChanneCoding(codeBlockMatrix,base_graph, Zc)
    
    if base_graph==1, N = 66*Zc; else, N=50*Zc; end 

    %find iLS set
    Z_set = {
        [2, 4, 8, 16, 32, 64, 128, 256], ... 
        [3, 6, 12, 24, 48, 96, 192, 384], ... 
        [5, 10, 20, 40, 80, 160, 320], ...
        [7, 14, 28, 56, 112, 224], ... 
        [9, 18, 36, 72, 144, 288], ... 
        [11, 22, 44, 88, 176, 352], ... 
        [13, 26, 52, 104, 208], ... 
        [15, 30, 60, 120, 240]
    }; 

    iLS = -1;
    for i = 1:length(Z_set)
        if ismember(Zc,Z_set{i})
            iLS=i;
            break;
        end 
    end
    if iLS == -1
        error("gia tri Zc khong ton tai");
    end 
    
    channel_coding_out=zeros(N,size(codeBlockMatrix,2));
    
    %channel coding cho từng codeb block 
    for r = 1:size(codeBlockMatrix,2)% each block
        % dùng hàm có sẵn của matlab để tính w 
        channel_coding_out(:,r) = nrLDPCEncode(codeBlockMatrix(:,r),base_graph);
        % for k=2*Zc+1:K
        %     %copy values from data to output (2*Zc+1:K)
        %     if codeBlockMatrix(k,r) ~= -1
        %         channel_coding_out(k-2*Zc,r)=codeBlockMatrix(k,r);
        %     else 
        %         codeBlockMatrix(k,r)=0;
        %         channel_coding_out(k-2*Zc,r) = -1;
        %     end 
        % end 
        % 
        % % tạo ma trận H từ HBG có sẵn 
        % H = Return_LDPC_BG(iLS,base_graph,Zc);
        % 
        % c = codeBlockMatrix(:,r);
        % 
        % Hsyn = H(:,1:K);
        % Hparity= H(:,K+1:end);
        % 
        % %nhân c và Hsyn để tạo syndrome 
        % s = mod(Hsyn*c,2);
        % %giải w 
        % w = solvegf2(s,Hparity);
        % %Gán kết quả w ra d 
        % channel_coding_out(K-2*Zc+1:N,r)=w(:);

    end 
end 
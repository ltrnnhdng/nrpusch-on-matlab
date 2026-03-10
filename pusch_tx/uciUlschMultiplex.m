function [cw, idxinfo]=uciUlschMultiplex(G_harq,G_harq_rvd,G_csi1,G_csi2,G,...
                                     g_harq,g_csi1,g_csi2,g_ulsch,...
                                     nPuschSym,dataSymLoc_array,dmrsSymLoc_array,...
                                     nPrb,Nl,Qm,startSym, numDmrsCdmGrpsNoData,...
                                     isDataPresent)
% Input parameters

% G_harq: rate matched sequence length for HARQ-ACK 
% G_harq_rvd: rate matched sequence length for HARQ reserved resources (nHarqBits <=2)
% G_csi1: rate matched sequence length for CSI part 1
% G_csi2: rate matched sequence length for CSI part 2
% G: rate matched sequence length for UL-SCH
% g_harq: rate matched sequence for HARQ
% g_csi1: rate matched sequence for CSI-1
% g_csi2: rate matched sequence for CSI-2
% g_ulsch: rate matched sequence for UL-SCH
% nPuschSym: number of symbols allocated for PUSCH (including DMRS)
% dataSymLoc_array: symbol index for PUSCH data (MATLAB 1 indexing)
% dmrsSymLoc_array: symbol index for PUSCH DMRS (MATLAB 1 indexing)
% nPrb: Number of PRBs allocated for PUSCH
% nL: Number of layers per UE
% Qm: Modulation order
% startSym: Starting symbol index of PUSCH (0 indexing)


% Output 

% CW (CODEWORD):
% Chứa dữ liệu thực tế (Payload). Đây là chuỗi bit hỗn hợp bao gồm:
% - Dữ liệu người dùng (UL-SCH)
% - Thông tin điều khiển (UCI: HARQ-ACK, CSI)
% Chuỗi này sẽ được mang đi Scrambling và Modulation.

% IDXINFO (INDEX INFORMATION / cwMap):
% Vì CW là chuỗi hỗn hợp, ta cần IDXINFO để biết bit nào là loại gì.
% Các giá trị đánh dấu (Flag):
%   -1: HARQ-ACK (Phản hồi nhận/gửi)
%   -2: CSI Part 1 (Thông tin kênh quan trọng: Rank, CQI)
%   -3: CSI Part 2 (Thông tin kênh chi tiết: PMI)
%   -4: UL-SCH (Dữ liệu người dùng)
%   Giá trị > 0 (ví dụ +5): Đánh dấu vị trí bị Puncturing (Đục lỗ - ghi đè HARQ lên Data).

% Reference : TS 38.212 Sec. 6.2.7

% Assumptions:

% No DFT-s-OFDM for UL-SCH
% No frequency hopping
% No PT-RS
% No data REs at DMRS symbols (i.e. nDmrsCdmGroupsWithoutData = 2)

mScPusch = nPrb*12;         % Tổng số bit được cấp phát 
NlQm = Nl*Qm;               % Product of number of layers and Modulation order

phiUlschGrid = zeros (nPuschSym,mScPusch);                  % Resource grid for PUSCH 
mScUlschGrid = repmat(      numel(phiUlschGrid(1,:))     ,nPuschSym   ,    1); % array of number of REs on each OFDM symbol in the resource grid  
%repmat: lặp lại mảng theo kích thước đã cho
% kết quả: mScUlschGrid là ma trận có kích thước (nPuschSym x 1) với mỗi phần tử đều bằng mScPusch

mScUlsch = mScUlschGrid; % Resource grid for UL-SCH
% Chuyển đổi vị trí symbol sang chỉ số 1-based của MATLAB và trừ đi offset bắt đầu
dmrsSymLoc_array_from_startSym = dmrsSymLoc_array - startSym + 1;
dataSymLoc_array_from_startSym = dataSymLoc_array - startSym + 1;

% Xử lý DMRS
% kiểm tra số nhóm CDM DMRS không có dữ liệu
if numDmrsCdmGrpsNoData == 1 
    mScUlsch(dmrsSymLoc_array_from_startSym,:) = 0.5*mScUlsch(dmrsSymLoc_array_from_startSym,:);   % Half of the REs at DMRS symbols are available for data 
else 
    mScUlsch(dmrsSymLoc_array_from_startSym,:) = 0;                     % No data REs at DMRS symbols
end
mScUci = mScUlschGrid;              % Resource grid for UCI
mScUci(dmrsSymLoc_array_from_startSym,:) = 0;   


% Tập hợp các sub carrier khả dụng tại vi trí symbol l
phiUlsch = cell(1, nPuschSym);
for j = 1:nPuschSym
    phiUlsch{j} = (0:mScUlsch(j,1)-1)'; % Available RE indices at symbol l
end

% Tập hợp vị trí RE khả dụng cho UCI 
phiUci = cell(1, nPuschSym);
for j = 1:nPuschSym
    phiUci{j} = (0:mScUci(j,1)-1)'; % Available RE indices at symbol l
end

%freq hopping not considered

% l1Csi: Symbol đầu tiên chứa dữ liệu (không phải DMRS)
% Đây là nơi bắt đầu ánh xạ CSI (Part 1 & 2)
if ~isempty(dataSymLoc_array_from_startSym)
    l1Csi = dataSymLoc_array_from_startSym(1);                                
end

% l1: Symbol đầu tiên ngay SAU nhóm DMRS đầu tiên
% Đây là nơi bắt đầu ánh xạ HARQ-ACK (để hưởng lợi từ kênh truyền tốt nhất gần DMRS)

% l1Csi : Dùng cho CSI mapping. CSI bắt đầu điền từ symbol dữ liệu khả dụng đầu tiên.
% l1    : Dùng cho HARQ-ACK mapping. HARQ quan trọng hơn nên nó "đợi" cho đến khi gặp DMRS, rồi điền vào symbol ngay sau đó để đảm bảo độ chính xác giải mã cao nhất.
if~isempty(dmrsSymLoc_array_from_startSym)&& any(dmrsSymLoc_array_from_startSym(1)<dataSymLoc_array_from_startSym)
    l1 = dataSymLoc_array_from_startSym(find(dmrsSymLoc_array_from_startSym(1)<dataSymLoc_array_from_startSym,1));
else
    l1 = l1Csi;
end

GAck1 = G_harq;           % G_ACK (number of coded HARQ-ACK bits)
GCsiPart11= G_csi1;       % G_CSI-Part1 (number of coded CSI part 1 bits)
GCsiPart21= G_csi2;       % G_CSI-Part2 (number of coded CSI part 2 bits)
nHopPusch = 1;            % No freq. hopping is supported

GAck2 = 0;               % No freq. hopping
GCsiPart12 = 0;          % No freq. hopping
GCsiPart22 = 0;          % No freq. hopping
l2 = 0;                  % No freq. hopping
l2Csi = 0;               % No freq. hopping

% Tạo lưới 3 chiều: [Thời gian (Symbol) x Tần số (Subcarrier) x Không gian (Layer*Modulation)]
gBar = zeros(nPuschSym, mScPusch, NlQm);

% Tạo bản đồ để đánh dấu (dùng cho debug/output idxinfo)
gBarMap = zeros(nPuschSym, mScPusch, NlQm); % Đây là bản đồ chỉ mục (index map) dùng để đánh dấu loại dữ liệu nào đang nằm ở vị trí tương ứng trên gBar. Nó không chứa nội dung tin, mà chứa "nhãn" (label) của loại tin đó.

% ======================step 1: Xác định vị trí dự trữ cho HARQ-ACK nhỏ (HARQ Reserved Bits)=
phiBarUlsch = phiUlsch; % Khởi tạo phiBarUlsch với tất cả các RE khả dụng
mBarScUlsch   = mScUlsch; % Khởi tạo mBarScUlsch với tất cả các RE khả dụng
phiBarUci   = phiUci;   % Khởi tạo phiBarUci với tất cả các RE khả dụng
mBarScUci     = mScUci;   % Khởi tạo mBarScUci với tất cả các RE khả dụng

%Initialize phiBarRvd as the reserved resource elements for potential HARQ-ACK transmission
phiBarRvd = cell(nPuschSym,1); 
for j = 1:nPuschSym
    phiBarRvd{j} = zeros(0,1); % <nSymAllPuschx1> cell arrray of empty elements {0 x1 double}
end

if G_harq_rvd % nếu có HARQ reserved bits
    %the number of reserved resource elements for potential HARQ-ACK transmission is calculated according to Clause 6.3.2.4.2.1, by setting O_ACK = 2;

    GAckRvd1 = G_harq_rvd;% G_ACK_rvd (number of coded HARQ-ACK reserved bits)
    GAckRvd2 = 0;         % G_ACK_rvd (number of coded HARQ-ACK reserved bits)
    GAckRvdVal = [GAckRvd1 GAckRvd2];
    phiBarRvd = cell(1, nPuschSym);
    lPrime  = [l1 l2];
    mAckCount = [0 0]; % Count of reserved REs for HARQ-ACK in two hops

    for i = 1:nHopPusch     % For each hop (only 1 hop supported here)
        l = lPrime(i);      % Starting symbol for HARQ-ACK mapping in this hop
        while mAckCount(i) < GAckRvdVal(i) % While we haven't reserved enough REs for HARQ-ACK
            if mBarScUci(l) > 0
                if GAckRvdVal(i)-mAckCount(i) >= mBarScUci(l)*NlQm  % If we can reserve all REs in this symbol for HARQ-ACK
                    d = 1; % step size
                    mCountRE = mBarScUlsch(l);   % Number of REs to be reserved in this symbol
                else
                    d = ceil(mBarScUci(l)*NlQm/(GAckRvdVal(i)-mAckCount(i)));   % step size
                    mCountRE = ceil((GAckRvdVal(i)-mAckCount(i))/NlQm);         % Number of REs to be reserved in this symbol
                end

                % Reserve REs for HARQ-ACK in symbol l
                for j = 0:mCountRE-1
                    idx = j*d + 1;   % MATLAB indexing
                    phiBarRvd{l} = union(phiBarRvd{l}, phiBarUlsch{l}(idx));
                    mAckCount(i) = mAckCount(i) + NlQm;
                end
            end
            l = l+1; % Move to the next symbol
        end 
    end
else 
    % phiBarRvd = cell(1, nPuschSym);
    % giá trị khởi tạo ở trên đã được thực hiện trước đó
end

% Number of reserved elements in each OFDM symbol
mBarPhiBarScRvd = zeros(nPuschSym,1);
for i = 1:nPuschSym
    mBarPhiBarScRvd(i) = numel(phiBarRvd{i});
end

% =============================Step 2: if HARQ-ACK is present for transmission on the PUSCH and the number of HARQ-ACK information bits is more than 2 or if both HARQ-ACK and CG-UCI are present on the same PUSCH with UL-SCH
if ~G_harq_rvd && G_harq % G_harq_rvd = 1 khi số bit harq <= 2 
    mCountAck = [0 0];
    mCountAckAll = 0;
    
    lPrime = [l1 l2];
    GHarqAck = [GAck1 GAck2];
    gAckMap = ones(G_harq,1)*(-1);

    for i = 1:nHopPusch
        l = lPrime(i);
        while mCountAck(i) < GHarqAck(i)
            if l > nPuschSym
                break;              % Check for error: symbol index cannot be more than number of PUSCH symbols
            end
            if mBarScUci(l) > 0
                if GHarqAck(i)-mCountAck(i) >= mBarScUci(l)*NlQm % If we can map all REs in this symbol for HARQ-ACK
                    d = 1; % step size
                    mCountRE = mBarScUci(l); % Number of REs to be used in this symbol
                else
                    d = floor(mBarScUci(l)*NlQm/(GHarqAck(i)-mCountAck(i))); % step size
                    mCountRE = ceil((GHarqAck(i)-mCountAck(i))/NlQm); % Number of REs to be used in this symbol
                end

                % Map HARQ-ACK bits to REs in symbol l
                for j = 0:mCountRE-1
                    k = phiBarUci{l}(j*d+1);
                    for v = 0:NlQm-1
                        if mCountAckAll >= G_harq
                             break; % Dừng vòng lặp v nếu đã hết bit HARQ
                        end
                        gBar(l,k+1,v+1) = g_harq(mCountAckAll + 1);% Map HARQ-ACK bit to RE
                        gBarMap(l,k+1,v+1) = gAckMap(mCountAckAll + 1); % Mark the mapping in gBarMap
                        mCountAckAll = mCountAckAll + 1;
                        mCountAck(i) = mCountAck(i) + 1;
                    end
                end

                phiBarUciTmp = zeros(0,1);
                phiBarUciTmp = union(phiBarUciTmp,phiBarUci{l}((0:mCountRE-1)*d+1));
                phiBarUci{l} = setdiff(phiBarUci{l},phiBarUciTmp);
                phiBarUlsch{l} = setdiff(phiBarUlsch{l},phiBarUciTmp);
                mBarScUci(l) = numel(phiBarUci{l});
                mBarScUlsch(l) = numel(phiBarUlsch{l});
            end
            l = l + 1; % Move to the next symbol
        end
    end
end

% ==================================Step 3: Map CSI 
if G_csi1
    mCountCsiPart1 = [0 0];
    mCountCsiPart1All = 0;
    lPrimeCsi = [l1Csi l2Csi];
    GCsiPart1 = [GCsiPart11 GCsiPart12];
    gCsiPart1Map = ones(G_csi1,1)*-2;

    for i = 1:nHopPusch
        l = lPrimeCsi(i);
        while mBarScUci(l) - mBarPhiBarScRvd(l) <= 0
            l = l + 1; % Skip symbols with no available REs for UCI
        end
        while mCountCsiPart1(i) < GCsiPart1(i)
            if mBarScUci(l) - mBarPhiBarScRvd(l) > 0
                if GCsiPart1(i)-mCountCsiPart1(i) >= (mBarScUci(l) - mBarPhiBarScRvd(l))*NlQm % If we can map all REs in this symbol for CSI part 1
                    d = 1; % step size
                    mCountRE = mBarScUci(l) - mBarPhiBarScRvd(l); % Number of REs to be used in this symbol
                else
                    d = floor((mBarScUci(l) - mBarPhiBarScRvd(l))*NlQm/(GCsiPart1(i)-mCountCsiPart1(i))); % step size
                    mCountRE = ceil((GCsiPart1(i)-mCountCsiPart1(i))/NlQm); % Number of REs to be used in this symbol
                end
                phiBartemp = setdiff(phiBarUci{l},phiBarRvd{l});% Available REs for CSI part 1 in symbol l

                for j = 0:mCountRE-1
                    k = phiBartemp(j*d+1);
                    for v = 0:NlQm-1
                        if mCountCsiPart1All >= G_csi1
                            break; 
                        end
                        gBar(l,k+1,v+1) = g_csi1(mCountCsiPart1All + 1); % Map CSI part 1 bit to RE
                        gBarMap(l,k+1,v+1) = gCsiPart1Map(mCountCsiPart1All + 1); % Mark the mapping in gBarMap
                        mCountCsiPart1All = mCountCsiPart1All + 1;
                        mCountCsiPart1(i) = mCountCsiPart1(i) + 1;
                    end
                end
                phiBarUciTmp = zeros(0,1);
                phiBarUciTmp = union(phiBarUciTmp,phiBartemp((0:mCountRE-1)*d+1));

                phiBarUci{l} = setdiff(phiBarUci{l},phiBarUciTmp);
                phiBarUlsch{l} = setdiff(phiBarUlsch{l},phiBarUciTmp);
                mBarScUci(l) = numel(phiBarUci{l});
                mBarScUlsch(l) = numel(phiBarUlsch{l});
            end
            l = l + 1; % Move to the next symbol
        end
    end
end 

%% Step 3b (CSI Part-2 bits)
if G_csi2
    mCountCsiPart2 = [0 0];
    mCountCsiPart2All = 0;
    lPrimeCsi = [l1Csi l2Csi];
    GCsiPart2 = [GCsiPart21 GCsiPart22];
    gCsiPart2Map = ones(G_csi2,1)*-3;
    
    for i = 1:nHopPusch
        l = lPrimeCsi(i);
        while mBarScUci(l) <= 0
            l = l+1;
            if l > nPuschSym
                break;              % Check for error: symbol index cannot be more than number of PUSCh symbols
            end
        end
        while mCountCsiPart2(i) < GCsiPart2(i)
            if l > nPuschSym
                break;              % Check for error: symbol index cannot be more than number of PUSCh symbols
            end
            if mBarScUci(l) > 0
                GCsi2Diff = GCsiPart2(i) - mCountCsiPart2(i);
                if GCsi2Diff >= mBarScUci(l)*NlQm
                    d = 1;
                    mReCount = mBarScUci(l);
                else
                    d = floor(mBarScUci(l)*NlQm/GCsi2Diff);
                    mReCount = ceil(GCsi2Diff/NlQm);
                end
                % Placing coded CSI Part2 bits in the gBar sequence at right
                % positions (multiplexing with data and other UCIs)
                for j = 0:mReCount-1
                    k = phiBarUci{l}(j*d+1);    %MATLAB indexing
                    for nu = 0:NlQm-1
                        if mCountCsiPart2All >= G_csi2
                            break; 
                        end
                        gBar(l,k+1,nu+1) = g_csi2(mCountCsiPart2All+1); %+1 for Matlab indexing
                        gBarMap(l,k+1,nu+1) = gCsiPart2Map(mCountCsiPart2All+1);
                        mCountCsiPart2All = mCountCsiPart2All+1;
                        mCountCsiPart2(i)= mCountCsiPart2(i)+1;
                    end
                end                
                phiBarUciTmp = zeros(0,1);                
                phiBarUciTmp = union(phiBarUciTmp,phiBarUci{l}((0:mReCount-1)*d+1));
                
                phiBarUci{l} = setdiff(phiBarUci{l}, phiBarUciTmp);
                phiBarUlsch{l} = setdiff(phiBarUlsch{l}, phiBarUciTmp);
                mBarScUci(l) = numel(phiBarUci{l});
                mBarScUlsch(l) = numel(phiBarUlsch{l});
            end
            l = l+1;
        end
    end
end
%% Step 4 (UL-SCH data bits)

if G
    mCountUlsch =0;
    gUlschMap = ones(G,1)*-4;
    
    for l = 0:nPuschSym-1
        if mBarScUlsch(l+1)>0  %MATLAB indexing
            %Placing coded UL-SCH data bits in gBar sequence at right
            %positions (multiplexing with UCI)
            for j = 0:(mBarScUlsch(l+1)-1)
                k = phiBarUlsch{l+1}(j+1);           %MATLAB indexing
                for nu = 0:NlQm-1
                    if mCountUlsch >= G
                        break; % Dừng nếu đã điền hết bit dữ liệu
                    end
                    gBar(l+1,k+1,nu+1) = g_ulsch(mCountUlsch+1);       %MATLAB indexing
                    gBarMap(l+1,k+1,nu+1) = gUlschMap(mCountUlsch+1); 
                    mCountUlsch = mCountUlsch+1; %MATLAB indexing
                end
            end
        end
    end
end

%% Step 5(HARQ-ACK bits <=2)
if G_harq_rvd && G_harq
    mCountAck = [0 0];
    mCountAckAll = 0;
    lPrime = [l1 l2];
    GHarqAck = [GAck1 GAck2];
    
    for i = 1:nHopPusch
        l = lPrime(i);
        while mCountAck(i) <GHarqAck(i)
            if l > nPuschSym
                break;              % Check for error: symbol index cannot be more than number of PUSCh symbols
            end
            if mBarPhiBarScRvd(l) > 0
                GAckDiff = GHarqAck(i) - mCountAck(i);
                if GAckDiff >= mBarPhiBarScRvd(l)*NlQm
                    d = 1;
                    mReCount = mBarPhiBarScRvd(l);
                else
                    d = floor(mBarPhiBarScRvd(l)*NlQm/GAckDiff);
                    mReCount = ceil(GAckDiff/NlQm);
                end
                % Placing coded HARQ-ACK bits (<=2)in gBar sequence at right
                % positions (at HARQ ACK reserved bit locations)
                for j = 0:mReCount-1
                    k = phiBarRvd{l}(j*d+1); % MATLAB indexing
                    for nu = 0:NlQm-1
                        if mCountAckAll  >= G_harq
                            break; 
                        end
                        gBar(l,k+1,nu+1) = g_harq(mCountAckAll+1); % MATLAB indexing (value =2 if CSI-2 punctured and =1 if UL-SCH punctured)
                        gBarMap(l,k+1,nu+1) = gBarMap(l,k+1,nu+1)+5;
                        mCountAckAll = mCountAckAll+1;
                        mCountAck(i) = mCountAck(i)+1;
                    end
                end
            end
            l = l+1;
        end
    end
end

%% STEP 6  (data and control indexes in the multiplexed sequence)

if G || G_csi1 || G_csi2 ||G_harq
    t = 0;
    cwMapLen = sum(mScUlsch(:))*NlQm;
    cw = zeros(cwMapLen,1);
    cwMap = zeros(cwMapLen,1);
    for l = 0:nPuschSym-1
        for j = 0:mScUlsch(l+1)-1
            k = phiUlsch{l+1}(j+1);
            for nu = 0:NlQm-1
                cw(t+1) = gBar(l+1,k+1,nu+1);
                cwMap(t+1) = gBarMap(l+1,k+1,nu+1);
                t = t+1;
            end
        end
    end
end
ackInd = sort([find(cwMap==-1); find(cwMap>0)]);
csi1Ind = find(cwMap==-2);
ackRvdCsi2Ind = find(cwMap==2);
csi2Ind = sort([find(cwMap==-3);ackRvdCsi2Ind]);
ackRvdUlschInd = find(cwMap==1);
ulschInd = sort([find(cwMap==-4);ackRvdUlschInd]);

idxinfo = struct;
idxinfo.ackInd = ackInd;
idxinfo.csi1Ind = csi1Ind;
idxinfo.ackRvdCsi2Ind = ackRvdCsi2Ind;
idxinfo.csi2Ind = csi2Ind;
idxinfo.ackRvdUlschInd = ackRvdUlschInd;
idxinfo.ulschInd = ulschInd;
end 
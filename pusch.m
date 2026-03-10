%% --- CẤU HÌNH THAM SỐ HỆ THỐNG (SYSTEM CONFIGURATION) ---
% Cấu hình cơ bản cho PUSCH
% note on: https://ltadung.notion.site/pusch
carrier = nrCarrierConfig;
carrier.NCellID = 0;
carrier.NSizeGrid = 270;
carrier.SubcarrierSpacing = 15;
carrier.CyclicPrefix = "normal";
carrier.NStartGrid = 0; 
carrier.NSlot = 0;

%adding dmrs 
pusch = nrPUSCHConfig;
pusch.Modulation = "QPSK";
pusch.TransformPrecoding = false;
pusch.NumAntennaPorts = 1;
pusch.RNTI = 0;
pusch.NumLayers = 1;
pusch.PRBSet = 0:269;
pusch.MappingType = "A";
pusch.SymbolAllocation = [0 14];
CodeRate = 0.513671875;     % Tỉ lệ mã hóa mcs = 7
rv = 0;                     % Redundancy Version 
Nref = [];                  % Giới hạn bộ nhớ HARQ (để trống hoặc set giá trị)
txConfig = "noncodebook"; 
q = 0;                      % Codeword index (0 cho Single Codeword)


pusch.DMRS.DMRSTypeAPosition = 3;
pusch.DMRS.DMRSAdditionalPosition = 0;
pusch.DMRS.DMRSLength = 1;
pusch.DMRS.NIDNSCID = [];
pusch.DMRS.NSCID = 0;
pusch.DMRS.GroupHopping = 0;
pusch.DMRS.SequenceHopping = 0;
pusch.DMRS.DMRSConfigurationType = 1;  
% Cấu hình vị trí DMRS và Data (Ví dụ cấu hình Mapping Type A)
dmrsSymLoc_array = 3;               % Vị trí symbol DMRS (MATLAB index 1-based, ví dụ symbol thứ 3)
dataSymLoc_array = [1:2, 4:14];     % Các symbol còn lại dành cho Data
numDmrsCdmGrpsNoData = 2;           % Số nhóm CDM DMRS không chứa dữ liệu 





% Tính toán các tham số phụ trợ
if pusch.Modulation == "QPSK"
    Qm = 2;
elseif pusch.Modulation == "16QAM"
    Qm = 4;
elseif pusch.Modulation == "64QAM"
    Qm = 6;
elseif pusch.Modulation == "256QAM"
    Qm = 8;
else
    error("Unsupported modulation scheme");
end

% HARQ-ACK
G_harq = 0;              % Số bit HARQ sau rate match
g_harq = randi([0 1], G_harq, 1); 
G_harq_rvd = 0;            % Số bit Reserved HARQ (thường dùng nếu HARQ <= 2 bit) [cite: 493]

% CSI Part 1
G_csi1 = 0;               % Số bit CSI Part 1 sau rate match
g_csi1 = randi([0 1], G_csi1, 1);

% CSI Part 2
G_csi2 = 0;                % Giả sử không có CSI Part 2
g_csi2 = [];


% Tổng số bit dành cho Control (UCI)
G_uci_total = G_harq + G_csi1 + G_csi2;
G_phy_total = calculate_pusch_capacity(carrier.NSizeGrid, pusch.SymbolAllocation(2), dmrsSymLoc_array, numDmrsCdmGrpsNoData, pusch.NumLayers, Qm);

% Đây là số bit Data thực sự cần tạo ra để lấp đầy lưới
outlen = G_phy_total ;

%% --- BƯỚC 1 ĐẾN 5: XỬ LÝ DỮ LIỆU UL-SCH (DATA CHAIN) ---
data = data_rep; 

% Thêm CRC (Bước 1)
% Xác định đa thức CRC dựa trên độ dài dữ liệu 
if length(data) > 3824
    poly = '24A';
else
    poly = '16';
end
[data_out_crc, crc_bits] = add_crc(data_rep, poly)
% Chọn Base Graph (Bước 2)
base_graph = LDPC_BG_select(length(data), CodeRate)
% Phân đoạn Code Block và thêm CRC (Bước 3)
[crk, Kp, Kb, Zc, K] = CBSegmentationAndCRC(data_out_crc, base_graph)
% Channel Coding (Bước 4)
ChannelCoding_out = ChanneCoding(crk, base_graph, Zc)
% 6. Rate Matching và Concatenation (Bước 5)
% Tính toán độ dài đầu ra mong muốn (G_ulsch)
% G_ulsch phụ thuộc vào số RE khả dụng, ở đây ta giả định một giá trị outlen
% hoặc tính toán dựa trên carrier.NSizeGrid và nSymbol.
g_ulsch = RateMatchingAndConcat(ChannelCoding_out, outlen, rv, pusch.Modulation, pusch.NumLayers, base_graph, Zc, 0) %[cite: 60]
% -- done ulsch ------

% Độ dài dữ liệu UL-SCH thực tế (G) đầu vào cho bước Multiplexing
G = length(g_ulsch);

%% --- BƯỚC 6: DATA AND CONTROL MULTIPLEXING ---
% Gọi hàm uciUlschMultiplexing như mô tả trong trang 12-13
[cwmixi, idxinfo] = uciUlschMultiplex(G_harq, G_harq_rvd, G_csi1, G_csi2, G, ...
                                     g_harq, g_csi1, g_csi2, g_ulsch, ...
                                     pusch.SymbolAllocation(2), dataSymLoc_array, dmrsSymLoc_array, ...
                                     carrier.NSizeGrid, pusch.NumLayers, Qm, pusch.SymbolAllocation(1), numDmrsCdmGrpsNoData, ...
                                     1) % 1 là isDataPresent
%% --- BƯỚC 8: SCRAMBLING ---
scrambled_cwmixi = PUSCH_Scrambling(cwmixi, pusch.RNTI, carrier.NCellID, q)
%% Bước 9: Modulation
mod_symbols = PUSCH_Modulation(scrambled_cwmixi, pusch.TransformPrecoding, pusch.Modulation)
%% BƯỚC 10: LAYER MAPPING
x_layers = layerMapping(mod_symbols, pusch.NumLayers) 
%% BƯỚC 11: TRANSFORM PRECODING
y_precoded = TransformPreCoding(x_layers, pusch.TransformPrecoding) 
%% BƯỚC 12: PRECODING
z_precoded = Precoding(y_precoded, txConfig, 'disable', pusch.NumLayers, pusch.NumAntennaPorts) 
%% BƯỚC 13: MAPPING PUSCH TO VRB (VIRTUAL RESOURCE BLOCKS)
% nVrb: số lượng Resource Block
% symData: Các symbol dành cho Data (1-based cho hàm mapping_pusch_vrb)
% dmrsSym: Các symbol DMRS
nVrb = carrier.NSizeGrid; 
symData = 0:pusch.SymbolAllocation(2)-1; % Giả sử dùng toàn bộ slot
ptrsSym = []; % Giả định không có PTRS
nPorts = pusch.NumAntennaPorts;

vrbGrid = mapping_pusch_vrb(z_precoded, nVrb, symData, dmrsSymLoc_array, ptrsSym, nPorts)
% mapping from Vrb to Prb
mappingType = 0;    % non interleaving
PrbGrid = VrbtoPrb(vrbGrid, mappingType);
%% 8. VẼ LƯỚI TÀI NGUYÊN Vrb = Prb(Frequency x Time)
dmrssymbol = nrPUSCHDMRS(carrier,pusch);
dmrsindies = nrPUSCHDMRSIndices(carrier,pusch);

prbdmrs = PrbGrid;
prbdmrs(dmrsindies) = dmrssymbol

drawGrid(prbdmrs);
% waveform_ofdm = nrOFDMModulate(carrier,PrbGrid)
[waveform_ofdm, ofdmInfo] = nrOFDMModulate(carrier,prbdmrs, 'Windowing', 0, 'SampleRate', 122880000, 'CarrierFrequency', 0)
log_folder = 'E:\data\letrananhdung\MatlabPUSCH\vsa';
if ~exist(log_folder,'dir')
    mkdir(log_folder);
end
filename = "pusch_test_sc15_nslot1";
filepath = fullfile(log_folder,filename); 
sva_signal = repmat(waveform_ofdm , 30, 1);
saveVsaRecord(filepath,sva_signal, 122880000,0,0);

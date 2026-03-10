function a = drawGrid(Grid)
% Lấy kích thước từ Grid
[nSC, nSym, nPorts] = size(Grid);

% Chọn antenna port để vẽ
port_idx = 1;

% Lấy lưới 2D: frequency × time
grid_2d = Grid(:,:,port_idx);

% Dùng độ lớn để hiển thị (NaN = không được cấp tài nguyên)
grid_mag = abs(grid_2d);

figure('Name','5G PUSCH VRB Resource Grid', ...
       'Color','w', ...
       'Position',[100 100 1100 600]);

imagesc(grid_mag);
set(gca,'YDir','normal');   % tần số thấp → cao
colormap(jet);
colorbar;

title('PUSCH VRB Resource Grid (Port 0)');
xlabel('OFDM Symbol Index (Time)');
ylabel('Subcarrier Index (Frequency)');

% Tick theo OFDM symbol (0-based hiển thị)
xticks(1:nSym);
xticklabels(0:nSym-1);

% %% Đánh dấu DMRS symbol
% hold on;
% for d = dmrsSym+1   % dmrsSym ban đầu là 0-based
%     xline(d,'r--','LineWidth',2);
% end
% legend('Magnitude','DMRS','Location','best');
a = 1;
end 
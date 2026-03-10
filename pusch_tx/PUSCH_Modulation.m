function modOut = PUSCH_Modulation(data, TransformPrecoding, modType)

% Input:
%   data: Vector bit đầu vào (từ bước Scrambling)
%   modType: Kiểu điều chế ('pi/2-BPSK', 'QPSK', '16QAM', '64QAM', '256QAM')
%   TransformPrecoding: true/false (DFT-s-OFDM hoặc CP-OFDM)
    if nargin < 3, TransformPrecoding = false; end
    
    % Đảm bảo data là vector cột
    data = data(:);

    if TransformPrecoding == 1 && modType == "pi/2-BPSK"
        modOut = pi2BPSKMod(data);
    else
        switch modType
            case 'QPSK'
                modOut = qpskMod(data);
            case '16QAM'
                modOut = qam16Mod(data);
            case '64QAM'
                modOut = qam64Mod(data);
            case '256QAM'
                modOut = qam256Mod(data);
            otherwise
                error('Unknown modulation type');
        end
    end
end

function modOut = pi2BPSKMod(data)
    s = 1-2*data;
    i = (0:length(s)-1).';
    modOut = exp(1j*(pi/2)*i).*(s + s*1j)/sqrt(2);

    modOut = modOut(:);
end

function modOut = qpskMod(data)
    if mod(length(data), 2) ~= 0
        error('Data length must be multiple of 2 for QPSK');
    end
    dataReshape = reshape(data,2,[]);
    re = 1-2*dataReshape(1,:);
    im = 1-2*dataReshape(2,:);
    modOut = (re + 1j*im)/sqrt(2);

    modOut = modOut(:);
end

function modOut = qam16Mod(data)
    if mod(length(data), 4) ~= 0
        error('Data length must be multiple of 4 for 16QAM');
    end
    dataReshape = reshape(data,4,[]);
    s = 1-2*dataReshape;
    re = s(1,:).*(2-s(3,:));
    im = s(2,:).*(2-s(4,:));
    modOut = (re + 1j*im)/sqrt(10);

    modOut = modOut(:);
end

function modOut = qam64Mod(data)
    if mod(length(data), 6) ~= 0
        error('Data length must be multiple of 6 for 64QAM');
    end
    dataReshape = reshape(data,6,[]);
    s = 1-2*dataReshape;
    re = s(1,:).*(4-s(3,:).*(2-s(5,:)));
    im = s(2,:).*(4-s(4,:).*(2-s(6,:)));
    modOut = (re + 1j*im)/sqrt(42);

    modOut = modOut(:);
end

function modOut = qam256Mod(data)
    if mod(length(data), 8) ~= 0
        error('Data length must be multiple of 8 for 256QAM');
    end
    dataReshape = reshape(data,8,[]);
    s = 1-2*dataReshape;
    re = s(1,:).*(8 - s(3,:).*(4 - s(5,:).*(2 - s(7,:))));
    im = s(2,:).*(8 - s(4,:).*(4 - s(6,:).*(2 - s(8,:))));
    modOut = (re + 1j*im)/sqrt(170);

    modOut = modOut(:);
end
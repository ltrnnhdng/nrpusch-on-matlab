function vrbGrid = mapping_pusch_vrb(z, nVrb, symData, dmrsSym, ptrsSym, nPorts)
%==========================================================================
% Map PUSCH data symbols to VRB grid (frequency × time × port)
% According to 3GPP TS 38.211 Section 6.3.1.6
%==========================================================================

    % Convert to 1-based indexing
    symData = symData + 1;
    dmrsSym = dmrsSym + 1;
    ptrsSym = ptrsSym + 1;

    nSym = max(symData);
    nSC  = nVrb * 12;   % total subcarriers

    % Initialize VRB grid: frequency × time × port
    vrbGrid = zeros(nSC, nSym, nPorts);

    n = 1; % index over z

    for p = 1:nPorts
        for l = symData
            % Skip DMRS / PTRS symbols
            if ismember(l, dmrsSym) || ismember(l, ptrsSym)
                continue;
            end

            % Loop over frequency (k')
            for kp = 1:nSC
                if n > length(z)
                    return;
                end
                vrbGrid(kp, l, p) = z(n);
                n = n + 1;
            end
        end
    end
end

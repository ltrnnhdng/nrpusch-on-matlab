function [base_graph] = LDPC_BG_select(block_size, code_rate) 
     if block_size <= 292 || (block_size <=3824 && code_rate <= 0.67) || code_rate <=0.25 
         base_graph = 2; 
     else 
         base_graph = 1; 
     end 
 end 
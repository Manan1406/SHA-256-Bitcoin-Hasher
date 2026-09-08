module bitcoin_hash (input logic        clk, reset_n, start,
                     input logic [15:0] message_addr, output_addr,
                    output logic        done, mem_clk, mem_we,
                    output logic [15:0] mem_addr,
                    output logic [31:0] mem_write_data,
                     input logic [31:0] mem_read_data);

parameter num_nonces = 16;

enum logic [2:0] {IDLE, READ, BLOCK, COMPUTE, WRITE} state;
logic [31:0] hout[num_nonces];

parameter int k[64] = '{
    32'h428a2f98,32'h71374491,32'hb5c0fbcf,32'he9b5dba5,32'h3956c25b,32'h59f111f1,32'h923f82a4,32'hab1c5ed5,
    32'hd807aa98,32'h12835b01,32'h243185be,32'h550c7dc3,32'h72be5d74,32'h80deb1fe,32'h9bdc06a7,32'hc19bf174,
    32'he49b69c1,32'hefbe4786,32'h0fc19dc6,32'h240ca1cc,32'h2de92c6f,32'h4a7484aa,32'h5cb0a9dc,32'h76f988da,
    32'h983e5152,32'ha831c66d,32'hb00327c8,32'hbf597fc7,32'hc6e00bf3,32'hd5a79147,32'h06ca6351,32'h14292967,
    32'h27b70a85,32'h2e1b2138,32'h4d2c6dfc,32'h53380d13,32'h650a7354,32'h766a0abb,32'h81c2c92e,32'h92722c85,
    32'ha2bfe8a1,32'ha81a664b,32'hc24b8b70,32'hc76c51a3,32'hd192e819,32'hd6990624,32'hf40e3585,32'h106aa070,
    32'h19a4c116,32'h1e376c08,32'h2748774c,32'h34b0bcb5,32'h391c0cb3,32'h4ed8aa4a,32'h5b9cca4f,32'h682e6ff3,
    32'h748f82ee,32'h78a5636f,32'h84c87814,32'h8cc70208,32'h90befffa,32'ha4506ceb,32'hbef9a3f7,32'hc67178f2
};

// Student to add rest of the code here
logic [31:0] w[8][16];
logic [31:0] message[19];
logic [31:0] h0, h1, h2, h3, h4, h5, h6, h7;
logic [31:0] ha0[7:0], ha1[7:0], ha2[7:0], ha3[7:0], ha4[7:0], ha5[7:0], ha6[7:0], ha7[7:0];
logic [31:0] a[7:0], b[7:0], c[7:0], d[7:0], e[7:0], f[7:0], g[7:0], h[7:0];
logic [7:0] i;
logic [1:0] phase;
logic [3:0] nonce;
logic [7:0] offset;
logic [15:0] cur_addr;
logic cur_we;
logic [31:0] cur_write_data;
logic [31:0] hb0, hb1, hb2, hb3, hb4, hb5, hb6, hb7;


assign mem_addr = cur_addr + offset;
assign mem_write_data = hout[offset];
assign mem_we = cur_we;
assign mem_clk = clk;

function logic [255:0] sha256_op(input logic [31:0] a, b, c, d, e, f, g, h, w,
                                 input logic [7:0] t);
    logic [31:0] S1, S0, ch, maj, t1, t2; // internal signals
begin
    S1 = rightrotate(e, 6) ^ rightrotate(e, 11) ^ rightrotate(e, 25);
    // Student to add remaning code below
    // Refer to SHA256 discussion slides to get logic for this function
    ch = (e & f) ^ (~e & g);
    t1 = h + S1 + ch + k[t] + w;
    S0 = rightrotate(a,2) ^ rightrotate(a,13) ^ rightrotate(a,22);
    maj = (a & b) ^ (a & c) ^ (b & c);
    t2 = maj + S0;
    sha256_op = {t1 + t2, a, b, c, d + t1, e, f, g};
end
endfunction

function logic [31:0] wnew(input logic [2:0] u);
  logic [31:0] s0, s1;
  s0 = rightrotate(w[u][1], 7) ^ rightrotate(w[u][1], 18) ^ (w[u][1] >> 3);
  s1 = rightrotate(w[u][14], 17) ^ rightrotate(w[u][14], 19) ^ (w[u][14] >> 10);
  wnew = w[u][0] + s0 + w[u][9] + s1;
endfunction

function logic [31:0] rightrotate(input logic [31:0] x,
                                  input logic [ 7:0] r);
   rightrotate = (x >> r) | (x << (32 - r));
endfunction


always_ff@(posedge clk, negedge reset_n) begin 

    if(!reset_n) begin
        state <= IDLE;
        cur_we <= 1'b0;
        done <= 1'b0;
    end else begin
        case(state) 
            IDLE: begin
					$display("MARKER123");
                if(start) begin
                    done <= 1'b0;
                    cur_we <= 1'b0;
                    a[u] <= 0;
                    b[u] <= 0;
                    c[u] <= 0;
                    d[u] <= 0;
                    e[u] <= 0;
                    f[u] <= 0;
                    g[u] <= 0;
                    h[u] <= 0;
                    h0 <= 32'h6a09e667;
                    h1 <= 32'hbb67ae85;
                    h2 <= 32'h3c6ef372;
                    h3 <= 32'ha54ff53a;
                    h4 <= 32'h510e527f;
                    h5 <= 32'h9b05688c;
                    h6 <= 32'h1f83d9ab;
                    h7 <= 32'h5be0cd19;
                    i <= 0;
                    offset <= 0;
                    phase <= 0;
                    nonce <= 0;
                    cur_addr <= message_addr;
                    state <= READ;
                end else begin
                    state <= IDLE;
                end
            end

            READ: begin
                if(offset <= 19) begin
                    if(offset > 0) begin
                        message[offset - 1] <= mem_read_data;
                    end
                    offset <= offset + 1;
                    state <= READ;
                end else begin
                    offset <= 0;
                    state <= BLOCK;
						  $display("READ DONE: message[0]=%h message[1]=%h message[2]=%h message[3]=%h",
						   message[0], message[1], message[2], message[3]);
                end    
            end

            BLOCK: begin
                if(phase == 0) begin
                    a[0] <= h0;
                    b[0] <= h1;
                    c[0] <= h2;
                    d[0] <= h3;
                    e[0] <= h4;
                    f[0] <= h5;
                    g[0] <= h6;
                    h[0] <= h7; 
                    i <= 0;
                    for(int n = 0; n < 16; n++) begin
                        w[0][n] <= message[n];
                    end
                    state <= COMPUTE;
                end else if(phase == 1) begin
                    for(int u = 0; u < 8; u++) begin
                        a[u] <= hb0;
                        b[u] <= hb1;
                        c[u] <= hb2;
                        d[u] <= hb3;
                        e[u] <= hb4;
                        f[u] <= hb5;
                        g[u] <= hb6;
                        h[u] <= hb7;
                        ha0[u] <= hb0;
                        ha1[u] <= hb1;
                        ha2[u] <= hb2;
                        ha3[u] <= hb3;
                        ha4[u] <= hb4;
                        ha5[u] <= hb5;
                        ha6[u] <= hb6;
                        ha7[u] <= hb7;
                        for(int n = 16; n < 19; n++) begin
                            w[u][n - 16] <= message[n];
                        end
                        for(int n = 5; n < 15; n++) begin
                            w[u][n] <= 32'd0;
                        end
                        w[u][4] <= 32'h80000000;
                        w[u][3] <= nonce + u;
                        w[u][15] <= 32'd640;
                    end
                    i <= 0;
                    state <= COMPUTE;
                end else begin
                    for(int u = 0; u < 8; u++) begin
                        w[u][0] <= ha0[u];
                        w[u][1] <= ha1[u];
                        w[u][2] <= ha2[u];
                        w[u][3] <= ha3[u];
                        w[u][4] <= ha4[u];
                        w[u][5] <= ha5[u];
                        w[u][6] <= ha6[u];
                        w[u][7] <= ha7[u];
                        w[u][8] <= 32'h80000000;
                        for(int n = 9; n < 15; n++) begin
                            w[u][n] <= 32'd0;
                        end
                        a[u] <= 32'h6a09e667;
                        b[u] <= 32'hbb67ae85;
                        c[u] <= 32'h3c6ef372;
                        d[u] <= 32'ha54ff53a;
                        e[u] <= 32'h510e527f;
                        f[u] <= 32'h9b05688c;
                        g[u] <= 32'h1f83d9ab;
                        h[u] <= 32'h5be0cd19;
						ha0[u] <= 32'h6a09e667;
						ha1[u] <= 32'hbb67ae85;
						ha2[u] <= 32'h3c6ef372;
						ha3[u] <= 32'ha54ff53a;
						ha4[u] <= 32'h510e527f;
						ha5[u] <= 32'h9b05688c;
					    ha6[u] <= 32'h1f83d9ab;
					  	ha7[u] <= 32'h5be0cd19;
                        w[u][15] <= 32'd256;
                    end
                    i <= 0;
                    state <= COMPUTE;
                end
            end

            COMPUTE: begin
                if(i < 65) begin
                    if(i == 0 && phase == 1) begin
                        $display("PHASE1 START base_nonce=%0d: a0=%h b0=%h c0=%h d0=%h e0=%h f0=%h g0=%h h0=%h  w0_5=%h w0_6=%h w0_7=%h w0_8=%h w0_9=%h w0_10=%h w0_11=%h w0_12=%h w0_13=%h w0_14=%h",
                                nonce, a[0], b[0], c[0], d[0], e[0], f[0], g[0], h[0],
                                w[0][5], w[0][6], w[0][7], w[0][8], w[0][9], w[0][10], w[0][11], w[0][12], w[0][13], w[0][14]);
                    end
                    if(i == 1 && phase == 1) begin
                        $display("PHASE1 ROUND1 base_nonce=%0d: a0=%h b0=%h c0=%h d0=%h e0=%h f0=%h g0=%h h0=%h",
                                nonce, a[0], b[0], c[0], d[0], e[0], f[0], g[0], h[0]);
                    end
                    for(int u = 0; u < 8; u++) begin
                        if(i < 16) begin
                            {a[u], b[u], c[u], d[u], e[u], f[u], g[u], h[u]} <= sha256_op(a[u], b[u], c[u], d[u], e[u], f[u], g[u], h[u], w[u][i], i);
                        end else if(i == 16) begin
                            w[u][0] <= w[u][1]; w[u][1] <= w[u][2]; w[u][2] <= w[u][3]; w[u][3] <= w[u][4]; w[u][4] <= w[u][5];
                            w[u][5] <= w[u][6]; w[u][6] <= w[u][7]; w[u][7] <= w[u][8]; w[u][8] <= w[u][9]; w[u][9] <= w[u][10];
                            w[u][10] <= w[u][11]; w[u][11] <= w[u][12]; w[u][12] <= w[u][13]; w[u][13] <= w[u][14]; w[u][14] <= w[u][15];
                            w[u][15] <= wnew(u);
                        end else begin
                            {a[u], b[u], c[u], d[u], e[u], f[u], g[u], h[u]} <= sha256_op(a[u], b[u], c[u], d[u], e[u], f[u], g[u], h[u], w[u][15], i-1);
                            w[u][0] <= w[u][1]; w[u][1] <= w[u][2]; w[u][2] <= w[u][3]; w[u][3] <= w[u][4]; w[u][4] <= w[u][5];
                            w[u][5] <= w[u][6]; w[u][6] <= w[u][7]; w[u][7] <= w[u][8]; w[u][8] <= w[u][9]; w[u][9] <= w[u][10];
                            w[u][10] <= w[u][11]; w[u][11] <= w[u][12]; w[u][12] <= w[u][13]; w[u][13] <= w[u][14]; w[u][14] <= w[u][15];
                            w[u][15] <= wnew(u);
                        end
                    end
                    i <= i + 1;
                    state <= COMPUTE;
                end else begin
                    i <= 0;
                    if(phase == 0) begin
                        h0 <= h0 + a[0];
                        h1 <= h1 + b[0];
                        h2 <= h2 + c[0];
                        h3 <= h3 + d[0];
                        h4 <= h4 + e[0];
                        h5 <= h5 + f[0];
                        h6 <= h6 + g[0];
                        h7 <= h7 + h[0];
                        hb0 <= h0 + a[0];
                        hb1 <= h1 + b[0];
                        hb2 <= h2 + c[0];
                        hb3 <= h3 + d[0];
                        hb4 <= h4 + e[0];
                        hb5 <= h5 + f[0];
                        hb6 <= h6 + g[0];
                        hb7 <= h7 + h[0];
                        $display("PHASE0 DONE: h0=%h h1=%h h2=%h h3=%h h4=%h h5=%h h6=%h h7=%h",
                            h0 + a[0], h1 + b[0], h2 + c[0], h3 + d[0], h4 + e[0], h5 + f[0], h6 + g[0], h7 + h[0]);
                        phase <= phase + 1;
                        state <= BLOCK;
                    end else if(phase == 1) begin
                        for(int u = 0; u < 8; u++) begin
                            ha0[u] <= ha0[u] + a[u];
                            ha1[u] <= ha1[u] + b[u];
                            ha2[u] <= ha2[u] + c[u];
                            ha3[u] <= ha3[u] + d[u];
                            ha4[u] <= ha4[u] + e[u];
                            ha5[u] <= ha5[u] + f[u];
                            ha6[u] <= ha6[u] + g[u];
                            ha7[u] <= ha7[u] + h[u];
                            $display("PHASE1 DONE nonce=%0d: ha0=%h ha1=%h ha2=%h ha3=%h ha4=%h ha5=%h ha6=%h ha7=%h",
                                nonce + u, ha0[u] + a[u], ha1[u] + b[u], ha2[u] + c[u], ha3[u] + d[u],
                                ha4[u] + e[u], ha5[u] + f[u], ha6[u] + g[u], ha7[u] + h[u]);
                        end
                        phase <= phase + 1;
                        state <= BLOCK;
                    end else begin
                        for(int u = 0; u < 8; u++) begin
                            hout[nonce + u] <= ha0[u] + a[u];
                            $display("PHASE2 DONE nonce=%0d: H0=%h", nonce + u, ha0[u] + a[u]);
                        end
                        if(nonce == 0) begin
                            nonce <= 8;
                            phase <= 1;
                            state <= BLOCK;
                        end else begin
                            state <= WRITE;
                            cur_we <= 1'b1;
                            cur_addr <= output_addr;
                        end
                    end
                end
            end
                        WRITE: begin
                offset <= offset + 1;
                if(offset == 15) begin
                    cur_we <= 1'b0;
                    done <= 1'b1;
                    state <= IDLE;
                end else begin
                    state <= WRITE;
                end
            end
        endcase

    end
end


endmodule

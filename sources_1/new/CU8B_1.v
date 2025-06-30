module REGBANK(input CJR, Et, Ip, Is, Ds, Clk, Clr, [4:0] Rs1, Rs2, [15:0] Win, output [15:0] Wout);
    reg [7:0] B, C, D, E, H, L, W, Z; 
    reg [15:0] SP, PC, Wassign;
    always @* 
        begin
            case (Rs2)
                5'b00000: Wassign = {8'b00, B};
                5'b00001: Wassign = {8'b00, C};
                5'b00010: Wassign = {8'b00, D};
                5'b00011: Wassign = {8'b00, E};
                5'b00100: Wassign = {8'b00, H};
                5'b00101: Wassign = {8'b00, L};
                5'b00110: Wassign = {8'b00, W};
                5'b00111: Wassign = {8'b00, Z};
                5'b01000: Wassign = {8'b00, PC[15:8]};
                5'b01001: Wassign = {8'b00, PC[7:0]};
                5'b01010: Wassign = {B, C};
                5'b01011: Wassign = {D, E};
                5'b01100: Wassign = {H, L};
                5'b01101: Wassign = {W, Z};
                5'b01110: Wassign = SP;
                5'b01111: Wassign = PC;
                5'b10000: Wassign = Win;
                default : Wassign = 16'hzzzz;
            endcase
        end    
    assign Wout = (Rs1 == 5'b10000 && Et) ? Wassign : 16'hzzzz;
    always @ (posedge (Clk || CJR) or posedge Clr)
        begin
            if(Clr) begin
                B<=0; C<=0; D<=0; E<=0; H<=8'h08; L<=8'h08; W<=0; Z<=0;
                SP<=16'h0ff0; PC<=0;
            end else begin
                if(Ip) 
                    begin
                        if(CJR) PC <= PC + 3;
                        else PC <= PC + 1;
                    end
                if(Is) SP <= SP + 1'b1;
                if(Ds) SP <= SP - 1'b1;
                if(Et)
                    case (Rs1)
                        5'b00000: B <= Wassign[7:0];
                        5'b00001: C <= Wassign[7:0];
                        5'b00010: D <= Wassign[7:0];
                        5'b00011: E <= Wassign[7:0];
                        5'b00100: H <= Wassign[7:0];
                        5'b00101: L <= Wassign[7:0];
                        5'b00110: W <= Wassign[7:0];
                        5'b00111: Z <= Wassign[7:0];
                        5'b01000: PC[15:8] <= Wassign[7:0];
                        5'b01001: PC[7:0] <= Wassign[7:0];
                        5'b01010: {B,C} <= Wassign;
                        5'b01011: {D,E} <= Wassign;
                        5'b01100: {H,L} <= Wassign;
                        5'b01101: {W,Z} <= Wassign;
                        5'b01110: SP <= Wassign;
                        5'b01111: PC <= Wassign;
                    endcase
               end             
        end
endmodule

module MEMAR(input Lm, Mr, Mw, Clk, Clr, [15:0] Win, output [15:0] Wout);
    reg [7:0] MEM [65535:0];
    reg [15:0] MAR;
    reg [7:0] MDR;
    assign Wout = Mr ? {8'hz, MDR} : 16'hz;
    initial $readmemb("RAM.data", MEM);
    always @ (posedge Clk or posedge Clr)
        if(Clr) begin
            MAR<=0; MDR<=0;
        end else begin
            if(Lm && !Mw) 
                begin
                    MAR <= Win;
                    MDR <= MEM[Win];
                end             
            if(!Lm && Mw) 
                begin
                    MDR <= Win[7:0];
                    MEM[MAR] <= Win[7:0];
                end  
        end
endmodule


module IR(input Li, Clk, Clr, [7:0] Wlow, output reg [7:0] OpCode=0);
    always @ (posedge Clk)
    begin
        if(Li) OpCode = Wlow;
    end
endmodule

module ALU(input La, Ea, Lt, Df, Ef, Lc, Clk, Clr, [3:0] Su, [7:0] Wlowin, output [7:0] Wlowout, output reg [3:0] FLGS);
    reg [7:0] A, TMP;  
    assign Wlowout = (!La && Ea) ? A : 
                     (Ef && !Lc) ? {4'h0, FLGS} : 
                     (Ef && Lc) ? {7'h0, FLGS[0]} : 8'hzz;
    always @ (posedge Clk or posedge Clr)
        if(Clr) begin
            A <= 0; TMP <= 0;
        end else begin
            if(Lt && !Df) TMP <= Wlowin; 
            if(Lt && Df) FLGS <= Wlowin[3:0]; 
            if(!Ef && Lc) FLGS[0] <= Wlowin[0];
            if(La && !Ea) A <= Wlowin;
            if(La && Ea) begin
                case(Su)
                    4'b0000: 
                        begin
                            if(!Lt && !Df) {FLGS[0],A} = A - TMP;
                            else A = A - TMP; 
                        end
                    4'b0001:
                        begin
                            if(!Lt && !Df) {FLGS[0],A} = A + TMP;
                            else A = A + TMP; 
                        end
                    4'b0010: A = ~A;
                    4'b0011: A = A & TMP; 
                    4'b0100: A = A | TMP; 
                    4'b0101: A = A ^ TMP; 
                    4'b0110:
                        begin
                            if(!Lt && !Df) {FLGS[0],A} = {A,FLGS[0]};
                            else A = {A[6:0],A[7]};
                        end
                    4'b0111: 
                        begin
                            if(!Lt && !Df) {FLGS[0],A} = {A[0],FLGS[0],A[7:1]};
                            else A = {A[0],A[7:1]};
                        end                     
                    4'b1000:
                        begin
                            if(!Lt && !Df) {FLGS[0],A} = {A[7],A[6:0],A[7]};
                            else A = {A[6:0],A[7]};
                        end                 
                    4'b1001:
                        begin
                            if(!Lt && !Df) {FLGS[0],A} = {A[0],A[0],A[7:1]};
                            else A = {A[0],A[7:1]};
                        end   
                    4'b1010:
                        if(!Lt && !Df) {FLGS[0],A} = A + 1'b1;
                        else A = A + 1'b1;
                    4'b1011:
                        if(!Lt && !Df) {FLGS[0],A} = A - 1'b1;
                        else A = A - 1'b1;       
                    default {FLGS[0],A} = 0; 
                endcase
                if(!Lt && !Df)
                    begin
                        FLGS[1] = A[7];
                        FLGS[2] = ~|A;
                        FLGS[3] = ~^A; 
                    end
            end
    end
endmodule

module IP1(input Clk, Clr, Ei1, [15:0] HEXENC, output [15:0] W);
    reg [15:0] IP1;
    assign W = Ei1 ? IP1 : 16'hzzzz;
    always @ (posedge Clk or posedge Clr)
        begin
            if(Clr) IP1 <= 0;
            else IP1 <= HEXENC;
        end
endmodule

module IP2(input Clk, Clr, Ei2, [7:0] IPWORD, output [7:0] Wlow);
    reg [7:0] IP2;
    assign Wlow = Ei2 ? IP2 : 8'hzz;
    always @ (posedge Clk or posedge Clr)
        begin
            if(Clr) IP2 <= 0;
            else IP2 <= IPWORD;
        end
endmodule

module OP3(input Clk, Clr, Lo3, [15:0] W, output reg [15:0] OP3);
    always @ (posedge Clk or posedge Clr)
        begin
            if(Clr) OP3 <= 0;
            else if(Lo3) OP3 <= W;
        end
endmodule

module OP4(input Clk, Clr, Lo4, [7:0] Wlow, output reg [7:0] OP4);
    always @ (posedge Clk or posedge Clr)
        begin
            if(Clr) OP4 <= 0;
            else if(Lo4) OP4 <= Wlow;
        end
endmodule

module HEXENCODER(input Clk, Clr, Ack, CNTRPIN, [15:0] IN, output reg Ready, output reg [15:0] IP);
 always @ (posedge Clk or posedge Clr) begin
        if(Clr) begin
            Ready <= 0; IP <= 0;
        end else begin
                if(CNTRPIN) begin IP <= IN; Ready <= 1'b1; end             
                else if(Ack) Ready <= 1'b0;  
            end
        end
endmodule

module CLKCTR(input Clk, Clr, CountClr, output T2);
    reg [7:0] Count;
    assign T2 = Count == 2;
    always @ (posedge Clr or negedge Clk) 
        begin
            if(Clr) Count <= 0;
            else begin
                if(!CountClr) Count <= Count + 1;
                else Count <= 1;
            end
        end
endmodule

module ADDROM(output [9:0] OpCodeStart, input [7:0] OpCode);
    reg [9:0] ADDROM [255:0];
    assign OpCodeStart = ADDROM[OpCode]; 
    initial $readmemb("ADDROM.data", ADDROM); 
endmodule

module CONTROM(output [31:0] ContWord, input [9:0] OpCodeAdd);
    reg [31:0] CONTROM [1023:0];
    assign ContWord = CONTROM[OpCodeAdd];
    initial $readmemb("CONTROM.data", CONTROM);
endmodule

module PRESCNTR (output [9:0] OpCodeAdd, input [9:0] OpCodeStart, input load, Clr, CountClr, Clk);
    reg [9:0] COUNT;
    assign OpCodeAdd = COUNT;
    always @ (negedge Clk or posedge Clr) 
        begin
            if(Clr) COUNT <= 0;
            else begin
                if (!CountClr && !load) COUNT <= COUNT + 1;
                else if (!CountClr && load) COUNT <= OpCodeStart;
                else COUNT <= 0;
            end
        end
endmodule


module DATAPATH(input Clk, Clr, CJR, CNTRPIN, [15:0] HEXIN, [31:0] ContWord, output [3:0] FLGS, [7:0] OpCode, [15:0] HEXOUT, [15:0] W);
    wire [4:0] Rs1, Rs2; wire [3:0] Su;
    wire Et, Ip, Is, Ds, Lm, Mr, Mw, Li, La, Ea, Lt, Df, Ef, Lc, Ei1, Ei2, Lo3, Lo4;
    assign {Et, Ip, Is, Ds, Rs1, Rs2, Lm, Mr, Mw, Li, La, Ea, Lt, Df, Ef, Lc, Su, Ei1, Ei2, Lo3, Lo4} = ContWord;
    
    wire [15:0] Wrbo, Wrbi;
    assign  W = (Rs1 == 5'b10000) ? Wrbo : 16'hzzzz, 
            Wrbi = (Rs2 == 5'b10000) ? W : 16'hzzzz; 
    REGBANK rgbk(CJR, Et, Ip, Is, Ds, Clk, Clr, Rs1, Rs2, Wrbi, Wrbo);
    
    wire [15:0] Wmo, Wmi;
    assign  W = Mr ? Wmo : 16'hzzzz, 
            Wmi = (Mw || Lm) ? W : 16'hzzzz; 
    MEMAR mmr(Lm, Mr, Mw, Clk, Clr, Wmi, Wmo);
    
    wire [7:0] Wii;
    assign  Wii = Li ? W[7:0] : 8'hzz;
    IR ir(Li, Clk, Clr, Wii, OpCode);
    
    wire [7:0] Walo, Wali;
    assign  W[7:0] = (Ea || Ef || Ef && Lc) ? Walo : 8'hzz, 
            Wali = (La || Lt || Lc || Lt && Df) ? W[7:0] : 8'hzz; 
    ALU alu(La, Ea, Lt, Df, Ef, Lc, Clk, Clr, Su, Wali, Walo, FLGS);
    
    wire [15:0] HEXENC;
    IP1 ip1(Clk, Clr, Ei1, HEXENC, W);
    
    wire Ready; wire [7:0] IPWORD, OPWORD;
    assign IPWORD = {7'b0, Ready};
    IP2 ip2(Clk, Clr, Ei2, IPWORD, W[7:0]);
    
    OP3 op3(Clk, Clr, Lo3, W, HEXOUT);
    
    OP4 op4(Clk, Clr, Lo4, W[7:0], OPWORD);
    HEXENCODER hexenc(Clk, Clr, OPWORD[7], CNTRPIN, HEXIN, Ready, HEXENC);
endmodule

module CU8B_1(input Clk, Clr, CNTRPIN, [15:0] HEXIN, output HLT, [15:0] HEXOUT);
    wire CountClr, CALL, JMP, RET, STC, EXT, P, Z, S, C; wire [3:0] FLGS;
    wire [7:0] OpCode; wire [9:0] OpCodeStart, OpCodeAdd; wire [15:0] W; wire [31:0] ContWord;
    assign 
        load = T3, 
        {P, Z, S, C} = FLGS,
        CALL = (OpCode==8'h29 & Z==1) || (OpCode==8'h2e & Z==0) || (OpCode==8'h28 & C==1) || (OpCode==8'h1d & C==0) || (OpCode==8'h2d & P==1) || (OpCode==8'h2b & P==0) || (OpCode==8'h2a & S==1) || (OpCode==8'h1e & S==0),
        JMP = (OpCode==8'h4f & Z==1) || (OpCode==8'h53 & Z==0) || (OpCode==8'h4e & C==1) || (OpCode==8'h4b & C==0) || (OpCode==8'h52 & P==1) || (OpCode==8'h51 & P==0) || (OpCode==8'h50 & S==1) || (OpCode==8'h4c & S==0),
        RET = (OpCode==8'hb3 & Z==1) || (OpCode==8'hb8 & Z==0) || (OpCode==8'hb2 & C==1) || (OpCode==8'hae & C==0) || (OpCode==8'hb6 & P==1) || (OpCode==8'hb5 & P==0) || (OpCode==8'hb4 & S==1) || (OpCode==8'hb1 & S==0),
        EXT = (W[7:0]==8'h29 || W[7:0]==8'h2e || W[7:0]==8'h28 || W[7:0]==8'h1d || W[7:0]==8'h2d || W[7:0]==8'h2b || W[7:0]==8'h2a || W[7:0]==8'h1e || W[7:0]==8'h4f || W[7:0]==8'h53 || W[7:0]==8'h4e || W[7:0]==8'h4b || W[7:0]==8'h52 || W[7:0]==8'h51 || W[7:0]==8'h50 || W[7:0]==8'h4c || W[7:0]==8'hb3 || W[7:0]==8'hb8 || W[7:0]==8'hb2 || W[7:0]==8'hae || W[7:0]==8'hb6  || W[7:0]==8'hb5 || W[7:0]==8'hb4 || W[7:0]==8'hb1),
        STC = (OpCode==8'hc3 & C==1),
        CJR = (OpCodeAdd === 8'h01 && EXT) ? CALL || JMP || RET : 0,
        HLT = OpCode==8'h3d,
        CountClr = (ContWord === 32'h08400000) || CJR || STC || Clr; 
    CLKCTR cc(Clk, Clr, CountClr, T3); 
    ADDROM ar(OpCodeStart, OpCode);
    PRESCNTR c(OpCodeAdd, OpCodeStart, load, Clr, CountClr, Clk);
    CONTROM cr(ContWord, OpCodeAdd);
    DATAPATH dp(Clk, Clr, CJR, CNTRPIN, HEXIN, ContWord, FLGS, OpCode, HEXOUT, W);
endmodule
`timescale 1ns / 1ps

module TESTCU8B_1;
    reg Clr, Clk, CNTRPIN; reg [15:0] HEXIN; wire HLT;
    wire [15:0] HEXOUT; 
    CU8B_1 CU8B1(Clk, Clr, CNTRPIN, HEXIN, HLT, HEXOUT);
    initial 
        begin   
            Clk = 0;
            Clr = 1'b1;
            #3;
            Clr = 1'b0;
            #5;
        end
    always 
        begin
            Clk = #5 ~Clk;
        end 
    initial
        begin
            HEXIN = 16'h000b; #80; 
            HEXIN = 16'h000b; CNTRPIN = 1; #300;
            HEXIN = 16'h0010; CNTRPIN = 0; #840; 
            HEXIN = 16'h0010; CNTRPIN = 1; #300;
            HEXIN = 16'h000c; CNTRPIN = 0; #9000; 
            HEXIN = 16'h000c; CNTRPIN = 1; #300; 
            HEXIN = 16'h000d; CNTRPIN = 0; #9000; 
            HEXIN = 16'h000d; CNTRPIN = 1; #300;
            HEXIN = 16'h000d; CNTRPIN = 0; 
        end
    initial #1000 $finish;                   
endmodule

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


//module testcountdiv2;
//// count_div(input pin_clk, rst, CNTRPIN, [15:0] HEXIN, output [7:0] CATHODES, [3:0] ANODES);
//    reg Clk, rst, CNTRPIN; reg [15:0] HEXIN;
//    wire diffClk1, diffClr; wire [7:0] CATHODES; wire [3:0] ANODES;
//    count_div CD(Clk, rst, CNTRPIN, HEXIN, diffClk1, diffClr, CATHODES, ANODES);
//    initial Clk = 0;
//    always Clk = #5 ~Clk;
//    initial
//        begin
//            HEXIN = 16'hxxxx; #20000000; 
//            HEXIN = 16'h0500; CNTRPIN = 1; #2000000;
//            HEXIN = 16'hxxxx; CNTRPIN = 0;
//        end
//    initial #1000 $finish;   
//endmodule
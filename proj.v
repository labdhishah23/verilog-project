`timescale 1ns/1ps

module rv32i_cpu_tb;

reg clk;
reg reset;

rv32i_cpu uut (
    .clk(clk),
    .reset(reset)
);

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin
    reset = 1;
    #20;
    reset = 0;
    #300;
    $finish;
end

endmodule

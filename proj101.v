`timescale 1ns/1ps

module rv32i_cpu_tb;

    reg clk;
    reg reset;

    rv32i_cpu uut(
        .clk(clk),
        .reset(reset)
    );
    always #5 clk = ~clk;
    initial begin

        clk = 0;
        reset = 1;

        #20;
        reset = 0;

        #200;

        $display("==================================");

        $display("x1 = %d",
            uut.RF.registers[1]);

        $display("x2 = %d",
            uut.RF.registers[2]);

        $display("x3 = %d",
            uut.RF.registers[3]);

        $display("x4 = %d",
            uut.RF.registers[4]);

        $display("x5 = %d",
            uut.RF.registers[5]);

        $display("MEM[2] = %d",
            uut.DMEM.memory[2]);

        $display("PC = %d",
            uut.PC);

        $display("==================================");

        $finish;

    end

endmodule

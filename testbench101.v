`timescale 1ns/1ps

module cpu16_tb;

    reg clk;
    reg reset;
    reg interrupt;

    wire halted;

    cpu16 uut(
        .clk(clk),
        .reset(reset),
        .interrupt(interrupt),
        .halted(halted)
    );

    always #5 clk = ~clk;

    initial begin

        clk = 0;
        reset = 1;
        interrupt = 0;

        #20;
        reset = 0;
        #200;
        $display("=======================================");
        $display("CPU EXECUTION FINISHED");
        $display("=======================================");

        $display("R1 = %d", uut.REG[1]);
        $display("R2 = %d", uut.REG[2]);

        $display("MEM[22] = %d", uut.memory[22]);

        $display("PC = %d", uut.PC);
        $display("SP = %d", uut.SP);

        $display("HALTED = %b", halted);

        $display("=======================================");

        if(uut.memory[22] == 150)
            $display("TEST PASSED");
        else
            $display("TEST FAILED");

        $finish;

    end

endmodule

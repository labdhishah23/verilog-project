// 16-BIT RISC STYLE CPU
module alu16(
    input [15:0] A,
    input [15:0] B,
    input [3:0] opcode,
    output reg [15:0] result,
    output zero
);

always @(*) begin
    case(opcode)

        4'b0001: result = A + B;
        4'b0010: result = A - B;
        4'b0011: result = A & B;
        4'b0100: result = A | B;

        default: result = 16'h0000;

    endcase
end

assign zero = (result == 16'h0000);

endmodule
module uart_tx(
    input clk,
    input start,
    input [7:0] data,
    output reg tx_done
);

always @(posedge clk) begin

    if(start)
        tx_done <= 1;
    else
        tx_done <= 0;

end

endmodule

module cpu16(
    input clk,
    input reset,
    input interrupt,
    output reg halted
);
    reg [15:0] REG [0:7];

    reg [15:0] PC;
    reg [15:0] SP;

    reg [15:0] IR;

    reg zero_flag;
    reg [15:0] memory [0:255];

    reg [15:0] fetch_instr;
    reg [15:0] decode_instr;
    wire [3:0] opcode;
    wire [2:0] rd;
    wire [2:0] rs;
    wire [5:0] imm;

    assign opcode = decode_instr[15:12];
    assign rd     = decode_instr[11:9];
    assign rs     = decode_instr[8:6];
    assign imm    = decode_instr[5:0];
    wire [15:0] alu_result;
    wire alu_zero;

    alu16 ALU(
        .A(REG[rd]),
        .B(REG[rs]),
        .opcode(opcode),
        .result(alu_result),
        .zero(alu_zero)
    );


    reg uart_start;
    wire uart_done;

    uart_tx UART(
        .clk(clk),
        .start(uart_start),
        .data(REG[rd][7:0]),
        .tx_done(uart_done)
    );

    integer i;
    initial begin

        halted = 0;

        PC = 0;
        SP = 16'h00FF;

        zero_flag = 0;

        for(i = 0; i < 8; i = i + 1)
            REG[i] = 0;

        for(i = 0; i < 256; i = i + 1)
            memory[i] = 0;
        memory[0] = 16'b0101_001_000_010100;
        memory[1] = 16'b0101_010_000_010101;
        memory[2] = 16'b0001_001_010_000000;
        memory[3] = 16'b0110_001_000_010110;
        memory[4] = 16'b1101_001_000_000000;
        memory[5] = 16'b1111_000_000_000000;
        memory[20] = 16'd100;
        memory[21] = 16'd50;

    end
    always @(posedge clk or posedge reset) begin

        if(reset) begin

            halted <= 0;
            PC <= 0;
            SP <= 16'h00FF;
            zero_flag <= 0;

        end

        else if(!halted) begin
            if(interrupt) begin

                memory[SP] <= PC;
                SP <= SP - 1;

                PC <= 16'h00F0;

            end
            fetch_instr <= memory[PC];
            PC <= PC + 1;
            decode_instr <= fetch_instr;
            case(opcode)
                4'b0000: begin
                end
                4'b0001,
                4'b0010,
                4'b0011,
                4'b0100: begin

                    REG[rd] <= alu_result;
                    zero_flag <= alu_zero;

                end
                4'b0101: begin

                    REG[rd] <= memory[imm];

                end
                4'b0110: begin

                    memory[imm] <= REG[rd];

                end
                4'b0111: begin

                    PC <= imm;

                end
               
                4'b1000: begin

                    if(zero_flag)
                        PC <= imm;

                end
                4'b1001: begin

                    memory[SP] <= REG[rd];
                    SP <= SP - 1;

                end
                4'b1010: begin

                    SP <= SP + 1;
                    REG[rd] <= memory[SP + 1];

                end

              
                4'b1011: begin

                    memory[SP] <= PC;
                    SP <= SP - 1;

                    PC <= imm;

                end

                4'b1100: begin

                    SP <= SP + 1;
                    PC <= memory[SP + 1];

                end

                4'b1101: begin

                    uart_start <= 1;

                end

                4'b1111: begin

                    halted <= 1;

                end

                default: begin

                    halted <= 1;

                end

            endcase

        end

    end

endmodule
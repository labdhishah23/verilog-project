//==============================================================
// RV32I SINGLE-CYCLE CPU
//==============================================================
// Supported Instructions:
// ADD
// SUB
// AND
// OR
// ADDI
// LW
// SW
// BEQ
//
// 32-bit RISC-V Single Cycle Processor
//==============================================================

module alu(
    input [31:0] A,
    input [31:0] B,
    input [3:0] ALUControl,
    output reg [31:0] Result,
    output Zero
);

always @(*) begin

    case(ALUControl)

        4'b0000: Result = A + B; // ADD
        4'b0001: Result = A - B; // SUB
        4'b0010: Result = A & B; // AND
        4'b0011: Result = A | B; // OR

        default: Result = 32'b0;

    endcase

end

assign Zero = (Result == 32'b0);

endmodule

//==============================================================
// REGISTER FILE
//==============================================================

module regfile(
    input clk,
    input RegWrite,

    input [4:0] rs1,
    input [4:0] rs2,
    input [4:0] rd,

    input [31:0] WriteData,

    output [31:0] ReadData1,
    output [31:0] ReadData2
);

    reg [31:0] registers [0:31];

    integer i;

    initial begin

        for(i = 0; i < 32; i = i + 1)
            registers[i] = 0;

    end

    assign ReadData1 = registers[rs1];
    assign ReadData2 = registers[rs2];

    always @(posedge clk) begin

        if(RegWrite && rd != 0)
            registers[rd] <= WriteData;

    end

endmodule

//==============================================================
// DATA MEMORY
//==============================================================

module datamemory(
    input clk,
    input MemWrite,
    input MemRead,

    input [31:0] Address,
    input [31:0] WriteData,

    output [31:0] ReadData
);

    reg [31:0] memory [0:255];

    integer i;

    initial begin

        for(i = 0; i < 256; i = i + 1)
            memory[i] = 0;

        memory[0] = 32'd100;
        memory[1] = 32'd50;

    end

    assign ReadData = (MemRead) ? memory[Address[7:2]] : 32'b0;

    always @(posedge clk) begin

        if(MemWrite)
            memory[Address[7:2]] <= WriteData;

    end

endmodule

//==============================================================
// INSTRUCTION MEMORY
//==============================================================

module instructionmemory(
    input [31:0] Address,
    output [31:0] Instruction
);

    reg [31:0] memory [0:255];

    initial begin

        //------------------------------------------------------
        // Program
        //------------------------------------------------------

        // LW x1,0(x0)
        memory[0] = 32'h00002083;

        // LW x2,4(x0)
        memory[1] = 32'h00402103;

        // ADD x3,x1,x2
        memory[2] = 32'h002081B3;

        // SW x3,8(x0)
        memory[3] = 32'h00302423;

        // BEQ x3,x3,+8
        memory[4] = 32'h00318463;

        // ADDI x4,x0,1
        memory[5] = 32'h00100213;

        // ADDI x5,x0,9
        memory[6] = 32'h00900293;

    end

    assign Instruction = memory[Address[7:2]];

endmodule

//==============================================================
// CONTROL UNIT
//==============================================================

module controlunit(
    input [6:0] opcode,

    output reg RegWrite,
    output reg MemRead,
    output reg MemWrite,
    output reg MemtoReg,
    output reg ALUSrc,
    output reg Branch,

    output reg [1:0] ALUOp
);

always @(*) begin

    RegWrite = 0;
    MemRead = 0;
    MemWrite = 0;
    MemtoReg = 0;
    ALUSrc = 0;
    Branch = 0;
    ALUOp = 2'b00;

    case(opcode)

        // R-Type
        7'b0110011: begin

            RegWrite = 1;
            ALUOp = 2'b10;

        end

        // LW
        7'b0000011: begin

            RegWrite = 1;
            MemRead = 1;
            MemtoReg = 1;
            ALUSrc = 1;
            ALUOp = 2'b00;

        end

        // SW
        7'b0100011: begin

            MemWrite = 1;
            ALUSrc = 1;
            ALUOp = 2'b00;

        end

        // BEQ
        7'b1100011: begin

            Branch = 1;
            ALUOp = 2'b01;

        end

        // ADDI
        7'b0010011: begin

            RegWrite = 1;
            ALUSrc = 1;
            ALUOp = 2'b00;

        end

    endcase

end

endmodule

//==============================================================
// ALU CONTROL
//==============================================================

module alucontrol(
    input [1:0] ALUOp,
    input [6:0] funct7,
    input [2:0] funct3,

    output reg [3:0] ALUControl
);

always @(*) begin

    case(ALUOp)

        // ADD
        2'b00:
            ALUControl = 4'b0000;

        // SUB
        2'b01:
            ALUControl = 4'b0001;

        // R-Type
        2'b10: begin

            case({funct7,funct3})

                10'b0000000000:
                    ALUControl = 4'b0000; // ADD

                10'b0100000000:
                    ALUControl = 4'b0001; // SUB

                10'b0000000111:
                    ALUControl = 4'b0010; // AND

                10'b0000000110:
                    ALUControl = 4'b0011; // OR

                default:
                    ALUControl = 4'b0000;

            endcase

        end

    endcase

end

endmodule

//==============================================================
// TOP CPU MODULE
//==============================================================

module rv32i_cpu(
    input clk,
    input reset
);

    //----------------------------------------------------------
    // PROGRAM COUNTER
    //----------------------------------------------------------

    reg [31:0] PC;

    wire [31:0] Instruction;

    //----------------------------------------------------------
    // FETCH
    //----------------------------------------------------------

    instructionmemory IMEM(
        .Address(PC),
        .Instruction(Instruction)
    );

    //----------------------------------------------------------
    // DECODE
    //----------------------------------------------------------

    wire [6:0] opcode;
    wire [4:0] rd;
    wire [2:0] funct3;
    wire [4:0] rs1;
    wire [4:0] rs2;
    wire [6:0] funct7;

    assign opcode = Instruction[6:0];
    assign rd     = Instruction[11:7];
    assign funct3 = Instruction[14:12];
    assign rs1    = Instruction[19:15];
    assign rs2    = Instruction[24:20];
    assign funct7 = Instruction[31:25];

    //----------------------------------------------------------
    // IMMEDIATE GENERATION
    //----------------------------------------------------------

    wire [31:0] imm;

    assign imm = (opcode == 7'b0000011 ||
                  opcode == 7'b0010011)
                  ? {{20{Instruction[31]}},Instruction[31:20]}
                  :
                  {{20{Instruction[31]}},
                    Instruction[31:25],
                    Instruction[11:7]};

    //----------------------------------------------------------
    // CONTROL UNIT
    //----------------------------------------------------------

    wire RegWrite;
    wire MemRead;
    wire MemWrite;
    wire MemtoReg;
    wire ALUSrc;
    wire Branch;

    wire [1:0] ALUOp;

    controlunit CU(
        .opcode(opcode),

        .RegWrite(RegWrite),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .MemtoReg(MemtoReg),
        .ALUSrc(ALUSrc),
        .Branch(Branch),
        .ALUOp(ALUOp)
    );

    //----------------------------------------------------------
    // REGISTER FILE
    //----------------------------------------------------------

    wire [31:0] ReadData1;
    wire [31:0] ReadData2;

    wire [31:0] WriteBackData;

    regfile RF(
        .clk(clk),
        .RegWrite(RegWrite),

        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),

        .WriteData(WriteBackData),

        .ReadData1(ReadData1),
        .ReadData2(ReadData2)
    );

    //----------------------------------------------------------
    // ALU CONTROL
    //----------------------------------------------------------

    wire [3:0] ALUControl;

    alucontrol ALUCTRL(
        .ALUOp(ALUOp),
        .funct7(funct7),
        .funct3(funct3),
        .ALUControl(ALUControl)
    );

    //----------------------------------------------------------
    // ALU
    //----------------------------------------------------------

    wire [31:0] ALUInputB;
    wire [31:0] ALUResult;
    wire Zero;

    assign ALUInputB = (ALUSrc) ? imm : ReadData2;

    alu ALU(
        .A(ReadData1),
        .B(ALUInputB),
        .ALUControl(ALUControl),
        .Result(ALUResult),
        .Zero(Zero)
    );

    //----------------------------------------------------------
    // DATA MEMORY
    //----------------------------------------------------------

    wire [31:0] MemReadData;

    datamemory DMEM(
        .clk(clk),
        .MemWrite(MemWrite),
        .MemRead(MemRead),

        .Address(ALUResult),
        .WriteData(ReadData2),

        .ReadData(MemReadData)
    );

    //----------------------------------------------------------
    // WRITEBACK
    //----------------------------------------------------------

    assign WriteBackData =
        (MemtoReg) ? MemReadData : ALUResult;

    //----------------------------------------------------------
    // PC UPDATE
    //----------------------------------------------------------

    wire PCSrc;

    assign PCSrc = Branch & Zero;

    always @(posedge clk or posedge reset) begin

        if(reset)
            PC <= 0;

        else begin

            if(PCSrc)
                PC <= PC + imm;
            else
                PC <= PC + 4;

        end

    end

endmodule

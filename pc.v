module pc(input clk, input [31:0] pc_in, output reg [31:0] pc_out);

	always @ (posedge clk)
		begin
			pc_out <= pc_in;
		end
endmodule


module adder(input [31:0] add_in, output reg [31:0] add_out);
	initial begin
		add_out = 100;
	end
 
	always @ (*)
		begin
			add_out <= add_in + 4;
		end	
endmodule


module inst_mem( input [31:0] mem_in, output reg [31:0] inst_out);

	reg [31:0] inst_mem [0:511];
	
	initial begin
		inst_mem [100] <= 32'b10001100001000100000000000000000;
		inst_mem [104] <= 32'b10001100001000110000000000000100;
		inst_mem [108] <= 32'b10001100001001000000000000001000;
		inst_mem [112] <= 32'b10001100001001010000000000001100;
		inst_mem [116] <= 32'b00000000010010100011000000100000;
	end
	
	always @ (*)
		begin
		inst_out <= inst_mem[mem_in];
	end
endmodule


module IF_ID ( input clk, input [31:0] fd_in, output reg [5:0] op_code, output reg [5:0] func, output reg [4:0] rd, 
	output reg [4:0] rs, output reg [4:0] rt, output reg [15:0] imm );
	
	reg fd_out;
	always @ (posedge clk)
		begin
			fd_out <= fd_in;
			op_code <= fd_in[31:26];
			func <= fd_in[5:0];
			rd <= fd_in[15:11];
			rs <= fd_in[25:21];
			rt <= fd_in[20:16];
			imm <= fd_in[15:0];
		end
endmodule


module ctrl_unit( input [5:0] op, input [5:0] func, output reg wreg, output reg m_to_reg, output reg wmem, output reg [3:0] aluc, 
	output reg aluimm, output reg regrt );

	always @ (*) begin
		case(op)
			6'b100011:
			begin
			wreg = 1;
			m_to_reg = 1;
			wmem = 0;
			aluc = 4'b0010;
			aluimm = 1;
			regrt = 1;
			end
			
			6'b000000:
			begin
			wreg = 1;
			m_to_reg = 0;
			wmem = 0;
			aluc = 4'b0010; 
			aluimm = 0;
			regrt = 0;
			end
		endcase
	end
endmodule


module MUX_ID( input [4:0] rd, input [4:0] rt, input regrt, output reg [4:0] MUX_ID_out);
	always @ (*) begin
		if (regrt == 0) begin
			MUX_ID_out <= rd;
		end
		
		if (regrt == 1) begin
			MUX_ID_out <= rt;
		end
	end
endmodule


module reg_file( input clk, input we, input [4:0] rs, input [4:0] rt, input [4:0] wn, input [31:0] d,
					output reg [31:0] qa, output reg [31:0] qb );
	reg [31:0] reg_files [31:0]; 
	integer i;
	
	initial begin
		for (i=0; i<32; i=i+1)begin
			reg_files[i] = 32'h00000000;
		end
	end
	
//	always @ (*) begin
//		qa <= reg_files[rs];
//		qb <= reg_files[rt];
//		
//		if ( we == 1 )begin
//			reg_files[wn] <= d;
//		end
//	end
//		
	
	always @ (negedge clk) begin
		qa <= reg_files[rs];
		qb <= reg_files[rt];
	end
	
	always @ (posedge clk) begin
		if ( we == 1 )begin
			reg_files[wn] <= d;
		end
	end
endmodule


module bit_extention( input [15:0] imm, output reg [31:0] extented_imm);
	reg [15:0] extra_bits;
	always @(*) begin
		if (imm[15]==1) begin
			extra_bits = 16'hffff;
		end
		
		if (imm[15]==0) begin
			extra_bits = 16'h0000;
		end
		
		extented_imm[31:16] <= extra_bits[15:0];
		extented_imm[15:0] <= imm[15:0];
	end
endmodule


module ID_EXE( input clk, input wreg, input m2reg, input wmem, input [3:0] aluc, input aluimm, input [4:0] rd_rt, 
	input [31:0] qa, input [31:0] qb, input [31:0] extended_imm, output reg EXE_wreg, output reg EXE_m2reg, output reg EXE_wmem, 
	output reg [3:0] EXE_aluc, output reg EXE_aluimm, output reg [4:0] EXE_rd_rt, output reg [31:0] EXE_qa, output reg [31:0] EXE_qb,
	output reg [31:0] EXE_extended_imm);
	
	always @ (posedge clk) begin
		EXE_wreg <= wreg;
		EXE_m2reg <= m2reg;
		EXE_wmem <= wmem;
		EXE_aluc <= aluc;
		EXE_aluimm <= aluimm;
		EXE_rd_rt <= rd_rt;
		EXE_qa <= qa;
		EXE_qb <= qb;
		EXE_extended_imm <= extended_imm;
	end
endmodule


module MUX_EXE( input EXE_aluimm, input [31:0] EXE_qb, input [31:0] EXE_extended_imm, output reg [31:0] MUX_EXE_out );
	
	always @(*)begin
		if (EXE_aluimm == 0)begin
			MUX_EXE_out <= EXE_qb;
		end
		if (EXE_aluimm == 1)begin
			MUX_EXE_out <= EXE_extended_imm;
		end
	end
endmodule


module ALU( input [3:0] EXE_aluc, input [31:0] ALU_a, input [31:0] ALU_b, output reg [31:0] ALU_out );
	reg [31:0] reg_files [31:0]; 
	
	always @(*)begin
		case(EXE_aluc)
			4'b0010:
			begin
			ALU_out <= ALU_a + ALU_b;
			end
		endcase
	end
endmodule


module EXE_MEM( input clk, input EXE_wreg, input EXE_m2reg, input EXE_wmem, 
	input [4:0] EXE_rd_rt, input [31:0] EXE_ALU_out, input [31:0] EXE_qb,
	output reg MEM_wreg, output reg MEM_m2reg, output reg MEM_wmem, output reg [4:0] MEM_rd_rt, 
	output reg [31:0] MEM_ALU_out, output reg [31:0] MEM_qb );
	
	always @ (posedge clk) begin
		MEM_wreg <= EXE_wreg;
		MEM_m2reg <= EXE_m2reg;
		MEM_wmem <= EXE_wmem;
		MEM_rd_rt <= EXE_rd_rt;
		MEM_ALU_out <= EXE_ALU_out;
		MEM_qb <= EXE_qb;
	end
endmodule


module Data_mem( input we, input [31:0] a, input [31:0] di, output reg [31:0] do );
	
	reg [31:0] data_mem [0:255];
	
	initial begin
		data_mem [0] <= 32'ha00000aa;
		data_mem [4] <= 32'h10000011;
		data_mem [8] <= 32'h20000022;
		data_mem [12] <= 32'h30000033;
		data_mem [16] <= 32'h40000044;
		data_mem [20] <= 32'h50000055;
		data_mem [24] <= 32'h60000066;
		data_mem [28] <= 32'h70000077;
		data_mem [32] <= 32'h80000088;
		data_mem [36] <= 32'h90000099;
	end
	
	always @(*)begin
		if ( we == 0 ) begin
			do <= data_mem [a];
		end
	end
endmodule


module MEM_WB(input clk, input mwreg, input mm2reg, input [4:0] MEM_rd_rt, input [31:0] MEM_ALU_out, input [31:0] do,
	  output reg WB_wreg, output reg WB_m2reg, output reg [4:0] WB_rd_rt, output reg [31:0] WB_ALU_out, output reg [31:0] WB_do);
	  
	  always @ (posedge clk) begin
		WB_wreg <= mwreg;
		WB_m2reg <= mm2reg;
		WB_rd_rt <= MEM_rd_rt;
		WB_ALU_out <= MEM_ALU_out;
		WB_do <= do;
	end
endmodule

module WB_MUX(input wm2reg, input [31:0] WB_ALU_out, input [31:0] do, output reg [31:0] mux_out);

	always @ (*) begin
	 if ( wm2reg == 0 ) begin
		mux_out <= WB_ALU_out;
	 end
	 if ( wm2reg == 1 ) begin
		mux_out <= do;
	 end
	end
endmodule
	
	
		
`timescale 1ns/1ps
module testbench();
	reg clk_tb;
	wire [31:0] pc_in;
	wire [31:0] pc_out;
	wire [31:0] inst_mem_out;

	wire [5:0] opcode_tb;
	wire [5:0] func_tb;
	wire [4:0] rd_tb;
	wire [4:0] rs_tb;
	wire [4:0] rt_tb;
	wire [15:0] imm_tb;
	wire wreg_tb;
	wire m2reg_tb;
	wire wmem_tb;
	wire [3:0] aluc_tb;
	wire aluimm_tb;
	wire regrt_tb;
	wire [4:0] mux_out_tb;
	wire [31:0] qa_tb;
	wire [31:0] qb_tb;
	wire [31:0] extented_imm_tb ;
	
	wire EXE_wreg;
	wire EXE_m2reg;
	wire EXE_wmem;
	wire [3:0] EXE_aluc;
	wire EXE_aluimm;
	wire [4:0] EXE_MUX_tb;
	wire [31:0] EXE_qa;
	wire [31:0] EXE_qb;
	wire [31:0] EXE_extended_imm;
	
	wire [31:0] EXE_ALU_MUX_out;
	wire [31:0] EXE_ALU_out;
	
	wire MEM_wreg;
	wire MEM_m2reg;
	wire MEM_wmem;
	wire [4:0] MEM_MUX_rd_rt;
	wire [31:0] MEM_ALU_out;
	wire [31:0] MEM_qb;
	wire [31:0] MEM_do;
	
	wire WB_wreg;
	wire WB_m2reg;
	wire [4:0] WB_rd_rt;
	wire [31:0] WB_ALU_out;
	wire [31:0] WB_do;
	wire [31:0] WB_MUX_out;
	
	//PC
	pc pc_tb (clk_tb, pc_in, pc_out);
	
	//IF stage
	adder ader_tb (pc_out, pc_in);
	inst_mem inst_mem_tb (pc_out,inst_mem_out);
	
	//IF/ID
	IF_ID IF_ID_tb (clk_tb,inst_mem_out, opcode_tb, func_tb, rd_tb, rs_tb, rt_tb, imm_tb);
	
	//ID stage
	ctrl_unit ctrl_unit_tb ( opcode_tb, func_tb, wreg_tb, m2reg_tb, wmem_tb, aluc_tb, aluimm_tb, regrt_tb);
	MUX_ID mux_id_tb (rd_tb, rt_tb, regrt_tb, mux_out_tb);
	reg_file reg_file_tb (clk_tb, WB_wreg, rs_tb, rt_tb, WB_rd_rt, WB_MUX_out, qa_tb, qb_tb );
	bit_extention bit_extention_tb (imm_tb, extented_imm_tb);
	
	//ID/EXE
	ID_EXE ID_EXE_tb(clk_tb, wreg_tb, m2reg_tb, wmem_tb, aluc_tb, aluimm_tb, mux_out_tb, qa_tb, qb_tb, extented_imm_tb, EXE_wreg,
		EXE_m2reg, EXE_wmem, EXE_aluc, EXE_aluimm, EXE_MUX_tb, EXE_qa, EXE_qb, EXE_extended_imm);
		
	//EXE stage
	MUX_EXE MUX_EXE_tb ( EXE_aluimm, EXE_qb, EXE_extended_imm, EXE_ALU_MUX_out);
	ALU ALU_tb ( EXE_aluc, EXE_qa, EXE_ALU_MUX_out, EXE_ALU_out );
	
	//EXE/MEM
	EXE_MEM EXE_MEM_tb ( clk_tb, EXE_wreg, EXE_m2reg, EXE_wmem, EXE_MUX_tb, EXE_ALU_out, EXE_qb, 
		MEM_wreg, MEM_m2reg, MEM_wmem, MEM_MUX_rd_rt, MEM_ALU_out, MEM_qb);
		
	//MEM stage
	Data_mem Data_mem_tb ( MEM_wmem, MEM_ALU_out, MEM_qb, MEM_do);
	
	//MEM/WB
	MEM_WB MEM_WB_tb ( clk_tb, MEM_wreg, MEM_m2reg, MEM_MUX_rd_rt, MEM_ALU_out, MEM_do, WB_wreg, WB_m2reg, WB_rd_rt, WB_ALU_out,
		 WB_do );
		 
	//WB
	WB_MUX WB_MUX_tb ( WB_m2reg, WB_ALU_out, WB_do, WB_MUX_out );
	
	
	initial begin
		clk_tb = 1;
	end
	
	always begin
		#5;
		clk_tb = ~clk_tb;
	end
endmodule

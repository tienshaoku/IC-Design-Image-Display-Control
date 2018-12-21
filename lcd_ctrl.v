module LCD_CTRL(clk, reset, IROM_Q, cmd, cmd_valid, IROM_EN, IROM_A, IRB_RW, IRB_D, IRB_A, busy, done);
input            clk;
input            reset;
input      [7:0] IROM_Q;
input      [3:0] cmd;
input            cmd_valid;
output reg       IROM_EN;
output     [5:0] IROM_A;
output reg       IRB_RW;
output     [7:0] IRB_D;
output     [5:0] IRB_A;
output reg       busy;
output reg       done;


reg        [2:0] state, nx_state;
reg        [6:0] cnt;
reg              cnt_re, cnt_en;
reg        [3:0] ctrl1, ctrl2, ctrl3, ctrl4;
reg        [7:0] position [3:0];
reg        [8:0] buffer [63:0];
wire       [9:0] average;

integer          i;

assign           IROM_A = cnt[5:0];
assign           IRB_A  = cnt[5:0];


parameter  [2:0] ST_IN = 3'b000,
		         ST_RE = 3'b001,
		         ST_OP = 3'b010,
	             ST_WR = 3'b011,
		         ST_DO = 3'b100;

// FSM: 1s
always@ (posedge clk or posedge reset) begin
	if (reset)
            state <= ST_IN;
	else
	    state <= nx_state;
end

// 2c
always@ (*) begin
	nx_state  = state;

	case(state)
 	    ST_IN  : nx_state = ST_RE;
	    ST_RE  : nx_state = cnt[6]              ? ST_OP : ST_RE;
	    ST_OP  : nx_state = (cmd_valid & ~|cmd) ? ST_WR : ST_OP;
	    ST_WR  : nx_state = cnt[6]              ? ST_DO : ST_WR;
	    ST_DO  : begin end   // done
	endcase
end


always@ (*) begin
	busy      = 1'b1;
	done      = 1'b0;
	IROM_EN   = 1'b1;
	IRB_RW    = 1'b1;
	cnt_re    = 1'b0;
	cnt_en    = 1'b0;
	
	case(state)
		ST_IN : begin
			busy      = 1'b1;
			done      = 1'b0;
			IROM_EN   = 1'b1;
			IRB_RW    = 1'b1;
			cnt_re    = 1'b0;
			cnt_en    = 1'b0;
		end
		ST_RE : begin
			busy      = 1'b1;
			done      = 1'b0;
			IROM_EN   = 1'b0;
			IRB_RW    = 1'b1;
			cnt_re    = cnt[6];
			cnt_en    = 1'b1;
		end
		ST_OP : begin
			busy      = 1'b0;
			done      = 1'b0;
			IROM_EN   = 1'b1;
			IRB_RW    = 1'b1;
			cnt_re    = 1'b0;
			cnt_en    = 1'b0;
		end
		ST_WR : begin
			busy      = 1'b1;
			done      = 1'b0;
			IROM_EN   = 1'b1;
			IRB_RW    = 1'b0;
			cnt_re    = cnt[6];
			cnt_en    = 1'b1;
		end
		ST_DO : begin
			busy      = 1'b0;
			done      = 1'b1;
			IROM_EN   = 1'b1;
			IRB_RW    = 1'b1;
			cnt_re    = 1'b0;
			cnt_en    = 1'b0;
		end
	endcase
end


// ===================================

// counter
always@ (posedge clk or posedge reset) begin
	if (reset)
        cnt     <= 7'b0;
	else begin
	    if (cnt_re)
		    cnt <= 7'b0;
	    else if (cnt_en) 
		    cnt <= cnt + 7'b1;
	end
end



// functions
assign    IRB_D  = (state == ST_WR) ? buffer[cnt[5:0]] : 8'b00000000;


parameter [3:0] CTRL_SU   = 4'b1110,
                CTRL_SD   = 4'b0001,
                CTRL_SL   = 4'b0010,
                CTRL_SR   = 4'b0011,
                CTRL_AV   = 4'b0100,
                CTRL_DOWN = 4'b0101,
                CTRL_UP   = 4'b0110,
                CTRL_RIGHT= 4'b0111,
                CTRL_LEFT = 4'b1000,
                CTRL_RE   = 4'b1001,
                CTRL_EN   = 4'b1010,
                CTRL_DE   = 4'b1011,
                CTRL_TH   = 4'b1100,
                CTRL_INTH = 4'b1101;

	
always@ (*) begin
	ctrl1 = 4'b0000;
	ctrl2 = 4'b0000;
	ctrl3 = 4'b0000;
	ctrl4 = 4'b0000;
	if (state == ST_OP) begin
		case (cmd) 
		4'b0001 : begin
			ctrl1 = CTRL_SU;
			ctrl2 = CTRL_SU;
			ctrl3 = CTRL_SU;
			ctrl4 = CTRL_SU;
		end
		4'b0010 : begin
			ctrl1 = CTRL_SD;
			ctrl2 = CTRL_SD;
			ctrl3 = CTRL_SD;
			ctrl4 = CTRL_SD;
		end
		4'b0011 : begin
			ctrl1 = CTRL_SL;
			ctrl2 = CTRL_SL;
			ctrl3 = CTRL_SL;
			ctrl4 = CTRL_SL;
		end
		4'b0100 : begin
			ctrl1 = CTRL_SR;
			ctrl2 = CTRL_SR;
			ctrl3 = CTRL_SR;
			ctrl4 = CTRL_SR;
		end
		4'b0101 : begin
			ctrl1 = CTRL_AV;
			ctrl2 = CTRL_AV;
			ctrl3 = CTRL_AV;
			ctrl4 = CTRL_AV;
		end
		4'b0110 : begin
		    ctrl1 = CTRL_DOWN;
			ctrl2 = CTRL_DOWN;
		    ctrl3 = CTRL_UP;
			ctrl4 = CTRL_UP;
		end
		4'b0111 : begin
		    ctrl1 = CTRL_RIGHT;
			ctrl2 = CTRL_LEFT;
		    ctrl3 = CTRL_RIGHT;
			ctrl4 = CTRL_LEFT;
		end
		4'b1000 : begin
			ctrl1 = CTRL_RE;
			ctrl2 = CTRL_RE;
			ctrl3 = CTRL_RE;
			ctrl4 = CTRL_RE;
		end
		4'b1001 : begin
			ctrl1 = CTRL_EN;
			ctrl2 = CTRL_EN;
			ctrl3 = CTRL_EN;
			ctrl4 = CTRL_EN;
		end
		4'b1010: begin
			ctrl1 = CTRL_DE;
			ctrl2 = CTRL_DE;
			ctrl3 = CTRL_DE;
			ctrl4 = CTRL_DE;
		end
		4'b1011: begin
			ctrl1 = CTRL_TH;
			ctrl2 = CTRL_TH;
			ctrl3 = CTRL_TH;
			ctrl4 = CTRL_TH;
		end
		4'b1100: begin
			ctrl1 = CTRL_INTH;
			ctrl2 = CTRL_INTH;
			ctrl3 = CTRL_INTH;
			ctrl4 = CTRL_INTH;
		end
		endcase
	end
end



always@ (posedge clk) begin 						
    if (reset) begin
        position[0] <= 27;
        position[1] <= 28;
        position[2] <= 35;
        position[3] <= 36;
    end
    else begin
        case (ctrl1)
            CTRL_SU   :  position[0] <= (position[0] >= 8) ? position[0] - 8 : position[0];
            CTRL_SD   :  position[0] <= (position[3] <= 55) ? position[0] + 8 : position[0];
            CTRL_SL   :  position[0] <= ((position[0] != 0) & (position[0] != 8) & (position[0] != 16) & (position[0] != 32) & (position[0] != 40) & (position[0] != 48) & (position[0] != 56)) ? position[0] - 1 : position[0];
            CTRL_SR   :  position[0] <= ((position[1] != 7) & (position[1] != 15) & (position[1] != 23) & (position[1] != 31) & (position[1] != 39) & (position[1] != 47) & (position[1] != 55)) ? position[0] + 1 : position[0];
            CTRL_RE   :  position[0] <= 27;
        endcase 

        case (ctrl2)
            CTRL_SU   :  position[1] <= (position[0] >= 8) ? position[1] - 8 : position[1];
            CTRL_SD   :  position[1] <= (position[3] <= 55) ? position[1] + 8 : position[1];
            CTRL_SL   :  position[1] <= ((position[0] != 0) & (position[0] != 8) & (position[0] != 16) & (position[0] != 32) & (position[0] != 40) & (position[0] != 48) & (position[0] != 56)) ? position[1] - 1 : position[1];
            CTRL_SR   :  position[1] <= ((position[1] != 7) & (position[1] != 15) & (position[1] != 23) & (position[1] != 31) & (position[1] != 39) & (position[1] != 47) & (position[1] != 55)) ? position[1] + 1 : position[1];
            CTRL_RE   :  position[1] <= 28;
        endcase 
            
        case (ctrl3)
            CTRL_SU   :  position[2] <= (position[0] >= 8) ? position[2] - 8 : position[2];
            CTRL_SD   :  position[2] <= (position[3] <= 55) ? position[2] + 8 : position[2];
            CTRL_SL   :  position[2] <= ((position[0] != 0) & (position[0] != 8) & (position[0] != 16) & (position[0] != 32) & (position[0] != 40) & (position[0] != 48) & (position[0] != 56)) ? position[2] - 1 : position[2];
            CTRL_SR   :  position[2] <= ((position[1] != 7) & (position[1] != 15) & (position[1] != 23) & (position[1] != 31) & (position[1] != 39) & (position[1] != 47) & (position[1] != 55)) ? position[2] + 1 : position[2];
            CTRL_RE   :  position[2] <= 35;
        endcase 
            
        case (ctrl4)
            CTRL_SU   :  position[3] <= (position[0] >= 8) ? position[3] - 8 : position[3];
            CTRL_SD   :  position[3] <= (position[3] <= 55) ? position[3] + 8 : position[3];
            CTRL_SL   :  position[3] <= ((position[0] != 0) & (position[0] != 8) & (position[0] != 16) & (position[0] != 32) & (position[0] != 40) & (position[0] != 48) & (position[0] != 56)) ? position[3] - 1 : position[3];
            CTRL_SR   :  position[3] <= ((position[1] != 7) & (position[1] != 15) & (position[1] != 23) & (position[1] != 31) & (position[1] != 39) & (position[1] != 47) & (position[1] != 55)) ? position[3] + 1 : position[3];
            CTRL_RE   :  position[3] <= 36;
        endcase 
    end
end



assign average = (buffer[position[0]] + buffer[position[1]] + buffer[position[2]] + buffer[position[3]]) >> 2;

always@ (posedge clk) begin 						
    if (reset) begin
        for (i = 0; i <= 63; i = i + 1)
            buffer[i] <= 9'b0;
    end
    else begin
        if (state == ST_RE)  begin
            buffer[cnt - 1] <= {1'b0, IROM_Q};
        end
        else if (state == ST_OP) begin
            case (ctrl1)
                CTRL_DOWN :  buffer[position[0]] <= buffer[position[2]];
                CTRL_RIGHT:  buffer[position[0]] <= buffer[position[1]];
                CTRL_AV   :  buffer[position[0]] <= average[8:0];
                CTRL_EN   :  buffer[position[0]] <= (buffer[position[0]] + 64 > 255) ? 255 : buffer[position[0]] + 64; 
                CTRL_DE   :  buffer[position[0]] <= (buffer[position[0]] - 64 > 255)   ? 9'b0: buffer[position[0]] - 64;
                CTRL_TH   :  buffer[position[0]] <= (buffer[position[0]] > 128)      ? 255 : 0;
                CTRL_INTH :  buffer[position[0]] <= (buffer[position[0]] < 128)      ? 255 : 0;
            endcase 

            case (ctrl2)
                CTRL_DOWN :  buffer[position[1]] <= buffer[position[3]];
                CTRL_LEFT :  buffer[position[1]] <= buffer[position[0]];
                CTRL_AV   :  buffer[position[1]] <= average[8:0];
                CTRL_EN   :  buffer[position[1]] <= (buffer[position[1]] + 64 > 255) ? 255 : buffer[position[1]] + 64; 
                CTRL_DE   :  buffer[position[1]] <= (buffer[position[1]] - 64 > 255)   ? 9'b0: buffer[position[1]] - 64;
                CTRL_TH   :  buffer[position[1]] <= (buffer[position[1]] > 128)      ? 255 : 0;
                CTRL_INTH :  buffer[position[1]] <= (buffer[position[1]] < 128)      ? 255 : 0;
            endcase 
                
            case (ctrl3)
                CTRL_UP   :  buffer[position[2]] <= buffer[position[0]];
                CTRL_RIGHT:  buffer[position[2]] <= buffer[position[3]];
                CTRL_AV   :  buffer[position[2]] <= average[8:0];
                CTRL_EN   :  buffer[position[2]] <= (buffer[position[2]] + 64 > 255) ? 255 : buffer[position[2]] + 64; 
                CTRL_DE   :  buffer[position[2]] <= (buffer[position[2]] - 64 > 255)   ? 9'b0: buffer[position[2]] - 64;
                CTRL_TH   :  buffer[position[2]] <= (buffer[position[2]] > 128)      ? 255 : 0;
                CTRL_INTH :  buffer[position[2]] <= (buffer[position[2]] < 128)      ? 255 : 0;
            endcase 
                
            case (ctrl4)
                CTRL_UP   :  buffer[position[3]] <= buffer[position[1]];
                CTRL_LEFT :  buffer[position[3]] <= buffer[position[2]];
                CTRL_AV   :  buffer[position[3]] <= average[8:0];
                CTRL_EN   :  buffer[position[3]] <= (buffer[position[3]] + 64 > 255) ? 255 : buffer[position[3]] + 64; 
                CTRL_DE   :  buffer[position[3]] <= (buffer[position[3]] - 64 > 255)   ? 9'b0: buffer[position[3]] - 64;
                CTRL_TH   :  buffer[position[3]] <= (buffer[position[3]] > 128)      ? 255 : 0;
                CTRL_INTH :  buffer[position[3]] <= (buffer[position[3]] < 128)      ? 255 : 0;
            endcase 
        end
    end
end

endmodule

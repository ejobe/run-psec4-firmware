------------------------------
-- psec4a_eval_top.vhd
------------------------------
-- author: eric oberla
-- eric.oberla@gmail.com
-- date  : 2018-1-31, onwards

library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.defs.all;

entity psec4a_eval_top is
port(
	psec4a_write_clk_i	:	in		std_logic;  --//clock from mezzanine board
	psec4a_vcdl_output_i	:	in		std_logic;
	psec4a_read_clk_o		:	out	std_logic;
	psec4a_d_i				:	in		std_logic_vector(10 downto 0);
	psec4a_xferadr_o		:	out	std_logic_vector(3 downto 0);
	psec4a_latchsel_o		:	out	std_logic_vector(3 downto 0);
	psec4a_dllspeed_o		:	inout	std_logic;  --//also controllable with serial interface
	psec4a_reset_xfer_en_o: inout std_logic;  --//also controllable with serial interface
	psec4a_ringosc_en_o	:	out	std_logic;
	psec4a_ringosc_mon_i	:	in		std_logic;
	psec4a_trigger_i		:	in		std_logic_vector(5 downto 0);
	psec4a_compsel_o		:	out	std_logic_vector(2 downto 0);
	psec4a_chansel_o		:	out	std_logic_vector(2 downto 0);
	psec4a_rampstart_o	:	out	std_logic;
	psec4a_dllstart_o		:	out	std_logic;
	psec4a_sclk_o			:	out	std_logic;  --//serial prog clock
	psec4a_sle_o			:	out	std_logic;  --//serial prog load enable 
	psec4a_sdat_o			:	out	std_logic;  --//serial prog data
	
	--FPGA_aux_io				:	inout	std_logic;
	debug						:	inout std_logic_vector(19 downto 2);
	
	USB_IFCLK				:	inout std_logic;
	USB_WAKEUP_n			:	inout std_logic;
	USB_CTL					:	inout std_logic_vector(2 downto 0);
	USB_CLKOUT				:	in		std_logic;
	USB_PA					:	inout	std_logic_vector(7 downto 0);
	USB_FD					:	inout	std_logic_vector(15 downto 0);
	USB_RDY					:	inout	std_logic_vector(1 downto 0);
	
	led_0						:	out	std_logic;
	led_1						:	out	std_logic;
	led_2						:	out	std_logic;
	
	DACone					: inout 	std_logic_vector(4 downto 0); --//external DAC
	DACtwo					: inout 	std_logic_vector(4 downto 0); --//external DAC
	
	master_clock			: 	in		std_logic); --//clock on motherboard 
end psec4a_eval_top;

architecture rtl of psec4a_eval_top is

signal global_reset_sig	:	std_logic;
signal reset_pwrup_sig	:	std_logic;
signal clk_25MHz_sig		: 	std_logic;
signal clk_100kHz_sig 	:	std_logic; 
signal clk_1Hz_sig		: 	std_logic;
signal clk_10Hz_sig		:	std_logic;

signal usb_done_sig		:	std_logic;
signal usb_slwr_sig		:	std_logic;
signal usb_instr_sig		:	std_logic_vector(31 downto 0);
signal usb_instr_rdy_sig:	std_logic;
signal usb_start_wr_sig	:	std_logic;

signal register_array 	:	register_array_type;
signal reg_addr_sig		:  std_logic_vector(define_address_size-1 downto 0);
signal readout_reg_sig  :  std_logic_vector(define_register_size-1 downto 0);
signal usb_dataout_sig	:  std_logic_vector(15 downto 0);

signal refresh_clk_1Hz				: std_logic := '0';
signal refresh_clk_counter_1Hz 	: std_logic_vector(19 downto 0);
signal REFRESH_CLK_MATCH_1HZ		: std_logic_vector(19 downto 0) := x"186A0";
--//---------------------------------------------------------------------------
begin

--//simple test for DACs:
--apply reset on serial interface/clock the load enable:
process(global_reset_sig)
begin
	if global_reset_sig = '1' then
		psec4a_latchsel_o <= "1110";
	else
		psec4a_latchsel_o <= "0110";
	end if;
end process;
--psec4a_sle_o <= clk_100kHz_sig;
--psec4a_sclk_o <= '0';

psec4a_compsel_o <= "000";
psec4a_chansel_o <= "000";
psec4a_xferadr_o <= "0000";
psec4a_read_clk_o <= '0';
psec4a_ringosc_en_o <= '0';
psec4a_rampstart_o <= '1';

xCLK_GEN_10Hz : entity work.Slow_Clocks
generic map(clk_divide_by => 5000)
port map(clk_100kHz_sig, global_reset_sig, clk_10Hz_sig);
		
xCLK_GEN_1Hz : entity work.Slow_Clocks
generic map(clk_divide_by => 50000)
port map(clk_100kHz_sig, global_reset_sig, clk_1Hz_sig);

xRESET : entity work.reset
port map(
	clk_i	=> clk_25MHz_sig, reg_i=>register_array, 
	power_on_rst_o => reset_pwrup_sig, reset_o => global_reset_sig);
	
proc_make_refresh_pulse : process(clk_100kHz_sig)
begin
	if rising_edge(clk_100kHz_sig) then			
		if refresh_clk_1Hz = '1' then
			refresh_clk_counter_1Hz <= (others=>'0');
		else
			refresh_clk_counter_1Hz <= refresh_clk_counter_1Hz + 1;
		end if;
		--//pulse refresh when refresh_clk_counter = REFRESH_CLK_MATCH
		case refresh_clk_counter_1Hz is
			when REFRESH_CLK_MATCH_1HZ =>
				refresh_clk_1Hz <= '1';
			when others =>
				refresh_clk_1Hz <= '0';
		end case;
	end if;
end process;
	
xPLL0 : entity work.pll0
port map(
	areset	=> '0',
	inclk0	=> master_clock,
	c0			=> clk_25MHz_sig,
	c1			=> clk_100kHz_sig,
	locked	=> open);

xUSB : entity work.usb_32bit
port map(
	CORE_CLK				=> clk_25MHz_sig,
	USB_IFCLK			=> USB_IFCLK,	
	USB_RESET    		=> global_reset_sig,  
	USB_BUS  			=> USB_FD,  
	FPGA_DATA			=> usb_dataout_sig, 
   USB_FLAGB    		=> USB_CTL(1),		
   USB_FLAGC    		=> USB_CTL(2),		
	USB_START_WR		=> usb_start_wr_sig,		
	USB_NUM_WORDS		=> x"0004",
   USB_DONE  			=> usb_done_sig,	   
   USB_PKTEND    		=> USB_PA(6),	
   USB_SLWR  			=> usb_slwr_sig,		
   USB_WBUSY 			=> open,     			
   USB_FLAGA    		=> USB_CTL(0),   
   USB_FIFOADR  		=> USB_PA(5 downto 4),
   USB_SLOE     		=> USB_PA(2),
   USB_SLRD     		=> USB_RDY(0),		
   USB_RBUSY 			=> open,		
   USB_INSTRUCTION	=> usb_instr_sig,
	USB_INSTRUCT_RDY	=> usb_instr_rdy_sig);
	
xREGISTERS : entity work.registers
port map(
		rst_powerup_i	=> reset_pwrup_sig,	
		rst_i				=> global_reset_sig,
		clk_i				=> clk_25MHz_sig,
		write_reg_i		=> usb_instr_sig,
		write_rdy_i		=> usb_instr_rdy_sig,
		read_reg_o 		=> readout_reg_sig,
		registers_io	=> register_array,
		address_o		=> reg_addr_sig);
		
xRDOUT_CNTRL : entity work.rdout_controller 
	port map(
		rst_i					=> global_reset_sig,	
		clk_i					=> clk_25MHz_sig,					
		rdout_reg_i			=> readout_reg_sig,	
		reg_adr_i			=> reg_addr_sig,	
		registers_i			=> register_array,	      
		tx_rdy_o				=> usb_start_wr_sig,	
		tx_ack_i				=> usb_done_sig,	
		rdout_fpga_data_o	=> usb_dataout_sig);	
		
xPSEC4A_SERIAL : entity work.psec4a_serial
port map(		
	clk_i				=> clk_100kHz_sig,
	rst_i				=> global_reset_sig,
	registers_i		=> register_array,
	write_i			=> refresh_clk_1Hz,	
	serial_clk_o	=> psec4a_sclk_o,
	serial_le_o		=> psec4a_sle_o,
	serial_dat_o	=> psec4a_sdat_o);
	
xLTC2600 : entity work.DAC_MAIN_LTC2600
port map(
	xCLKDAC			=> clk_100kHz_sig,
	xCLK_REFRESH	=> refresh_clk_1Hz,
	xCLR_ALL			=> global_reset_sig,
	registers_i		=> register_array,
	SDATOUT1			=> DACone(2),
	SDATOUT2			=> DACtwo(2),
	DACCLK1			=> DACone(0),
	DACCLK2			=> DACtwo(0),
	LOAD1				=> DACone(4),
	LOAD2				=> DACtwo(4),
	CLR_BAR1			=> DACone(3),
	CLR_BAR2			=> DACtwo(3),
	SDATIN1			=> DACone(1),
	SDATIN2			=> DACtwo(1));
		
led_0 <= not global_reset_sig;
led_1 <= clk_10Hz_sig;
led_2 <= psec4a_dllspeed_o;

end rtl;
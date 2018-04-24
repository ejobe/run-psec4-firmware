-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- e oberla                                                                  --
-- DATE: April 2010                                                           --
-- PROJECT: psec3 tester firmware                                          --
-- NAME: TOP asic/dac functionality                                                                --
-- Description:                                                              --
--      psTDC top module                                                     --
--    -- 																	 --
--    --                                                                     --
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity psec4_main is
	port(
		--MCLK			:	in	std_logic;
		xCLK40M			:	in	std_logic;
		xTRIG_CLK		:	in	std_logic;
		EXT_TRIGin		:	in	std_logic;
		xSOFT_TRIG		:	in	std_logic;
		INT_TRIG		:	in	std_logic_vector(5 downto 0);
		triggerOR		:	in  std_logic;
		TRIG_EXT		:	out	std_logic;
		trigENABLE		:	out	std_logic;
		trigSIGN		:	out std_logic;
		trigCLEAR		:	out std_logic;
		-------
		RAMP			:	out std_logic;
		adcCLEAR		:	out std_logic;
		RO_enable		: 	out	std_logic;
		RO_freq			: 	out	std_logic;
		ADClatch_select	: 	out	std_logic;
		-------
		xCLR_ALL		:	in	std_logic;
		xUSB_DONE		:	in	std_logic;
		-------
		DATA			:	in	std_logic_vector(11 downto 0);
		dat_overflow	:	in	std_logic;
		TOKout1			:	in	std_logic;
		TOKout2			: 	in	std_logic;
		xRAM_CLK		:	in	std_logic;
		xRD_CLK			:	in 	std_logic;
		xRAMREAD_EN		:	in	std_logic;
		xRDADDR			:	in 	std_logic_vector(10 downto 0);
		xRAMWRITE_EN	:	out	std_logic;
		xADC_DAT		:	out	std_logic_vector(12 downto 0);
		TOKin1			:	out std_logic;
		TOKin2			:	out	std_logic;
		CHANselect		:	out std_logic_vector(2 downto 0);
		TOKselect		:	out std_logic_vector(2 downto 0);
		xUSB_START		:	out	std_logic;
		-------
		xCLKDAC			: in 	std_logic;  --internal DACclk
		xCLK_REFRESH	: in	std_logic;  --internal REFRESHclk
		SDATOUT1		: in	std_logic;
		SDATOUT2		: in	std_logic;
		xROVDD			: out	std_logic_vector (11 downto 0);
		xPROVDD			: out	std_logic_vector (11 downto 0);
		DACCLK1			: out	std_logic;  --copy of DACclk to external
		DACCLK2			: out	std_logic;  --ditto, second DAC
		LOAD1			: out 	std_logic;
		LOAD2			: out	std_logic;  --Load signal (active low)
		CLR_BAR1		: out 	std_logic;
		CLR_BAR2		: out	std_logic;  --Clear (currently inactive)
		SDATIN1			: out 	std_logic;  --serial data to DAC1
		SDATIN2			: out	std_logic; --serial data to DAC2
		------
		xVBIAS			:	in 	std_logic_vector(11 downto 0);
		DEBUG_out		:	out std_logic_vector(9 downto 0);
		
		--writeCLK		: 	out	std_logic;
		--writeCLK_copy	: 	out std_logic;
		readCLK1		:   out std_logic;
		readCLK2		: 	out std_logic;
		
		ROmon			:	in std_logic;
		VDLout			:	in std_logic;
		
		
		xEVT_CNT		: 	out std_logic_vector(10 downto 0);
		pulse_out_10Hz_o	: out std_logic;

		xTRIG_CNTRL		:	in std_logic_vector(1 downto 0);
		xTRIG_THRSH		: 	in std_logic_vector(11 downto 0);
		xTRIG_LOCATE	:	out std_logic_vector(5 downto 0);
		xRO_CNT_VALUE	:	out std_logic_vector(15 downto 0);
		MCLK				:	in	std_logic;
		xPLL_LOCK		:	in	std_logic;
		xRESET_TRIG_SFT:  in	std_logic;
		xSAMPLE_BIN		:	out std_logic_vector(3 downto 0);
		INT_TRIG_MASK	:	in	std_logic_vector(5 downto 0);
		xDLL_RESET		: 	in	std_logic);
		
	end psec4_main;
		
architecture Behavioral of psec4_main is
---SIGNALS-----------------------------------
	signal trig_flag	:	std_logic;
	signal ramp_done	: 	std_logic;
	signal clk_master	:   std_logic;	
	signal clk_master2	: 	std_logic;
	signal readCLK		:	std_logic;
	signal RO_DAC_CNTRL :   std_logic_vector(11 downto 0);
	signal RO_CNT 		: 	std_logic_vector(15 downto 0); 
	signal read_clk_en	:	std_logic;
	signal Trig_signal_from_self : std_logic;
	
	signal refresh_clk_10Hz				: std_logic := '0';
	signal refresh_clk_counter_10Hz : std_logic_vector(23 downto 0);
	signal REFRESH_CLK_MATCH_10HZ : std_logic_vector(23 downto 0) := x"3D0900";
	
---COMPONENTS--------------------------------
	component psec4_trigger
		port(
			xTRIG_CLK		: in 	std_logic;   --fast clk (320MHz) to trigger all chans once internally triggered
			xMCLK				: in	std_logic;   --ext trig sync with write clk
			xCLR_ALL			: in	std_logic;   --wakeup reset (clears high)
			xDONE				: in	std_logic;	-- USB done signal		
			
			xCC_TRIG			: in	std_logic;   -- software trig
			xDC_TRIG			: in	std_logic;
			xSELFTRIG 		: in	std_logic_vector(5 downto 0); --internal trig sgnl
			xSELFTRIG_MASK : in	std_logic_vector(5 downto 0);
			
			xSET_SMPL_RATE				: in	std_logic;
			xSET_ENABLE_SELF_TRIG	: in	std_logic;
			xRESET_TRIG_FLAG			: in	std_logic;
			
			xDLL_RESET		: in	std_logic;
			xPLL_LOCK		: in	std_logic;
			xTRIG_FEEDIN	: in	std_logic;		
			xTRIG_FEEDOUT	: out	std_logic; 
			
			xTRIGGER_OUT	: out	std_logic;
			xLATCHED_SELF_TRIG: out	std_logic_vector(5 downto 0);
			xTRIG_CLEAR		: out	std_logic;
			
			xEVENT_CNT		: out std_logic_vector(10 downto 0);
			xSAMPLE_BIN		: out	std_logic_vector(3 downto 0));
		end component;
	
	component internal_trig_mgmt
		port(
			xTRIG_CLK			: 	in		std_logic;   --fast clk (320MHz) to trigger all chans once internally triggered
			xMCLK					:  in		std_logic;
			xSLOW_CLK			: 	in		std_logic;
			xSELFTRIG			: 	in 	std_logic_vector(5 downto 0);
			xSELFTRIG_MASK 	:	in		std_logic_vector(5 downto 0);
			xSELFTRIG_EN		:	in		std_logic;
			
			xDLL_RESET			: 	in 	std_logic;
			
			xCLR_ALL				: 	in		std_logic;
			xDONE					:	in		std_logic;
			
			xRESET_TRIG_FLAG  :	in		std_logic;
			
			xSELFTRIG_RESET	: 	out	std_logic;
			
			xSELFTRIG_EVT_PATTERN : out std_logic_vector(5 downto 0);
			
			xRATE_0				: 	out 	std_logic_vector(15 downto 0);
			xRATE_1				: 	out 	std_logic_vector(15 downto 0);
			xRATE_2				: 	out 	std_logic_vector(15 downto 0);
			xRATE_3				: 	out 	std_logic_vector(15 downto 0);
			xRATE_4				: 	out 	std_logic_vector(15 downto 0);
			xRATE_5				: 	out 	std_logic_vector(15 downto 0);
			
			xSELFTRIG_TRIG		:	out	std_logic);
		end component;

	component RAMP_psTDC_3
		port(
			xCLK		: in	std_logic; 
			xCLR_ALL	: in	std_logic;
			xTRIGHIT	: in	std_logic;
			xDONE   	: in	std_logic;
			xRAMP		: out	std_logic;	
			xRAMPDONE	: out	std_logic;
			xCLEARADC	: out	std_logic;
			xRO_enable	: out	std_logic;
			xRO_freq	: out	std_logic;
			ADClatch_select:out	std_logic);
		end component;
	
	component READ_RAM_4
		port(
			xRD_CLK		: in	std_logic;
			xRAM_CLK	: in	std_logic;
			xW_EN		: out	std_logic;
			xR_EN		: in	std_logic;
			xDONE		: in	std_logic;
			xRD_ADDRESS	: in	std_logic_vector(10 downto 0);
			xRAMPDONE   : in	std_logic;
			xCLR_ALL	: in	std_logic;
			xDATIN		: in 	std_logic_vector(11 downto 0);
			dat_overflow: in	std_logic;
			xDATOUT		: out 	std_logic_vector(12 downto 0);
			xTOK_OUT1	: in	std_logic;	
			xTOK_OUT2	: in	std_logic;
			xCLK_EN		: out std_logic;
			xTOK_IN1	: out	std_logic;
			xTOK_IN2	: out	std_logic;
			xCHAN_SEL	: out	std_logic_vector(2 downto 0);
			xBLOCK_SEL	: out	std_logic_vector(2 downto 0);
			xSTART		: out	std_logic);		--USB start
		end component;
	
	component DAC_MAIN 
	port(
			xCLKDAC			: in 	std_logic;  --internal DACclk
			xCLK_REFRESH	: in	std_logic;  --internal REFRESHclk
			xCLR_ALL		: in	std_logic;
			SDATOUT1		: in	std_logic;
			SDATOUT2		: in	std_logic;
			xVBIAS			: in	std_logic_vector (11 downto 0);
			xTRIG_THRESH	: in	std_logic_vector (11 downto 0);
			xROVDD			: out	std_logic_vector (11 downto 0);
			xPROVDD			: in	std_logic_vector (11 downto 0);
			DACCLK1			: out	std_logic;  --copy of DACclk to external
			DACCLK2			: out	std_logic;  --ditto, second DAC
			LOAD1			: out 	std_logic;
			LOAD2			: out	std_logic;  --Load signal (active low)
			CLR_BAR1		: out 	std_logic;
			CLR_BAR2		: out	std_logic;  --Clear (currently inactive)
			SDATIN1			: out 	std_logic;  --serial data to DAC1
			SDATIN2			: out	std_logic); --serial data to DAC2
	end component;
	
	component Wilkinson_Feedback_Loop
	Port (
                                ENABLE_FEEDBACK     : in std_logic;
                                RESET_FEEDBACK      : in std_logic;
                                REFRESH_CLOCK       : in std_logic; --One period of this clock defines how long we count Wilkinson rate pulses
                                DAC_SYNC_CLOCK      : in std_logic; --This clock should be the same that is used for setting DACs, and should be used to avoid race conditions on setting the desired DAC values
                                WILK_MONITOR_BIT    : in std_logic;
                                DESIRED_COUNT_VALUE : in std_logic_vector(15 downto 0);
                                CURRENT_COUNT_VALUE : out std_logic_vector(15 downto 0);
                                DESIRED_DAC_VALUE   : out std_logic_vector(11 downto 0));
    end component;
---------------------------------------------------------------------
	begin
	--clk_master <= xCLK40M;
	--clk_master2 <= xCLK40M;
	--writeCLK <= MCLK;
	--writeCLK_copy <= MCLK;
	TRIG_EXT <= trig_flag;
	readCLK <= xRD_CLK;
	readCLK1 <= (readCLK and read_clk_en);
	readCLK2 <= (readCLK and read_clk_en);
	DEBUG_out(0) <= VDLout;
	xPROVDD <= RO_DAC_CNTRL;
	RO_CNT <= x"CA00"; -- CA00


	pulse_out_10Hz_o <= refresh_clk_10Hz;
	proc_make_refresh_pulse : process(xCLK40M)
	begin
	if rising_edge(xCLK40M) then			
		if refresh_clk_10Hz = '1' then
			refresh_clk_counter_10Hz <= (others=>'0');
		else
			refresh_clk_counter_10Hz <= refresh_clk_counter_10Hz + 1;
		end if;
		--//pulse refresh when refresh_clk_counter = REFRESH_CLK_MATCH
		case refresh_clk_counter_10Hz is
			when REFRESH_CLK_MATCH_10HZ =>
				refresh_clk_10Hz <= '1';
			when others =>
				refresh_clk_10Hz <= '0';
		end case;
	end if;
	end process;
	
		xTRIG	:	psec4_trigger
		port map(
			
			xTRIG_CLK		=>	xTRIG_CLK,
			xMCLK				=>	MCLK,
			xCLR_ALL			=> xCLR_ALL,
			xDONE				=> xUSB_DONE,	
			
			xCC_TRIG			=> xSOFT_TRIG,
			xDC_TRIG			=> EXT_TRIGin,
			xSELFTRIG 		=> INT_TRIG,
			xSELFTRIG_MASK => INT_TRIG_MASK,
			
			xSET_SMPL_RATE				=> xTRIG_CNTRL(0),
			xSET_ENABLE_SELF_TRIG	=> xTRIG_CNTRL(1),
			xRESET_TRIG_FLAG			=> xRESET_TRIG_SFT,
			
			xDLL_RESET		=> xDLL_RESET,
			xPLL_LOCK		=>	xPLL_LOCK,
			xTRIG_FEEDIN	=> Trig_signal_from_self,		
			xTRIG_FEEDOUT	=> open, 
			
			xTRIGGER_OUT	=> trig_flag,
			xLATCHED_SELF_TRIG =>	xTRIG_LOCATE,
			xTRIG_CLEAR		=>	open,
			
			xEVENT_CNT		=> xEVT_CNT,
			xSAMPLE_BIN		=> xSAMPLE_BIN);
	   
		xSELF_TRIG : internal_trig_mgmt
			port map(
				xTRIG_CLK		=>	xTRIG_CLK,	
				xMCLK				=>	MCLK,	
				xSLOW_CLK		=> xCLK_REFRESH,	
				xSELFTRIG		=>	INT_TRIG,
				xSELFTRIG_MASK =>	INT_TRIG_MASK,
				xSELFTRIG_EN	=> xTRIG_CNTRL(1),	
			
				xDLL_RESET		=> xDLL_RESET,	
			
				xCLR_ALL			=> xCLR_ALL,	
				xDONE				=> xUSB_DONE,		
			
				xRESET_TRIG_FLAG  => xRESET_TRIG_SFT,
			
				xSELFTRIG_RESET	=>	trigCLEAR,
			
				xSELFTRIG_EVT_PATTERN => open,
			
				xRATE_0	=> open,			
				xRATE_1	=> open,			
				xRATE_2	=> open,			
				xRATE_3	=> open,			
				xRATE_4	=> open,			
				xRATE_5	=> open,			
			
				xSELFTRIG_TRIG	 => Trig_signal_from_self);
		
	   xRAMP	:	RAMP_psTDC_3
	      port map(
			xCLK		=> xCLK40M, 
			xCLR_ALL	=> xCLR_ALL,
			xTRIGHIT	=> trig_flag,
			xDONE       => xUSB_DONE,
			xRAMP		=> RAMP,	
			xRAMPDONE	=> ramp_done,
			xCLEARADC	=> adcCLEAR,
			xRO_enable	=> RO_enable,
			xRO_freq	=> RO_freq,
			ADClatch_select => ADClatch_select);
			
		xREAD_RAM	:	READ_RAM_4
		port map(
			xRD_CLK		=>	xRD_CLK,
			xRAM_CLK	=>	xRAM_CLK,
			xW_EN		=>	xRAMWRITE_EN,
			xR_EN		=>	xRAMREAD_EN,
			xDONE		=>  xUSB_DONE,
			xRD_ADDRESS	=> 	xRDADDR,
			xRAMPDONE   => 	ramp_done,
			xCLR_ALL	=> 	xCLR_ALL,
			xDATIN		=>  DATA,
			dat_overflow=>  dat_overflow,
			xDATOUT		=>	xADC_DAT,
			xTOK_OUT1	=>	TOKout1,	
			xTOK_OUT2	=>	TOKout2,
			xCLK_EN		=> read_clk_en,
			xTOK_IN1	=>	TOKin1,
			xTOK_IN2	=>	TOKin2,
			xCHAN_SEL	=> 	CHANselect,
			xBLOCK_SEL	=> 	TOKselect,
			xSTART		=> 	xUSB_START);		--USB start
			
		xDAC_MAIN	:	DAC_MAIN
		port map(
			xCLKDAC		=> xCLKDAC,
			xCLK_REFRESH=> xCLK_REFRESH,
			xCLR_ALL	=> xCLR_ALL,	
			SDATOUT1	=> SDATOUT1,	
			SDATOUT2	=> SDATOUT2,	
			xVBIAS		=> xVBIAS,
			xTRIG_THRESH=> xTRIG_THRSH,
			xROVDD		=> xROVDD,	
			xPROVDD		=> RO_DAC_CNTRL,	
			DACCLK1		=> DACCLK1,	
			DACCLK2		=> DACCLK2,	
			LOAD1		=> LOAD1,	
			LOAD2		=> LOAD2,	
			CLR_BAR1	=> CLR_BAR1,	
			CLR_BAR2	=> CLR_BAR2,	
			SDATIN1		=> SDATIN1,	
			SDATIN2		=> SDATIN2);
			
		xWILK_FDBK	:	Wilkinson_Feedback_Loop
		port map(
								ENABLE_FEEDBACK => not(xCLR_ALL),     
                                RESET_FEEDBACK => '0',      
                                REFRESH_CLOCK  => xCLK_REFRESH,     
                                DAC_SYNC_CLOCK   => xCLKDAC,   
                                WILK_MONITOR_BIT   => ROmon, 
                                DESIRED_COUNT_VALUE => RO_CNT,
                                CURRENT_COUNT_VALUE => xRO_CNT_VALUE,
                                DESIRED_DAC_VALUE   => RO_DAC_CNTRL);
				
	end Behavioral;
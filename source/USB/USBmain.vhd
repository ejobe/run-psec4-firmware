---usb main
---e oberla april 2010
------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity USBmain is
	port( 
		IFCLK		: 	in		std_logic;
		WAKEUP		:	in 		std_logic;
		CTL     	:	in		std_logic_vector(2 downto 0);
		PA			: 	inout 	std_logic_vector(7 downto 0);
		
		CLKOUT		:	in		std_logic;
		xUSBstart	:	in		std_logic;
		xRESET		: 	in		std_logic;
		FD			:	inout	std_logic_vector(15 downto 0);
		RDY			:	out		std_logic_vector(1 downto 0);
		xUSBdone	:	out		std_logic;
		xSOFT_TRIG	:	out		std_logic;
		xUSB_CNTRL	:	out		std_logic_vector(15 downto 0);
		xPED_SCAN	:	out		std_logic_vector(11 downto 0);
		xSLWR		:	out		std_logic;
		
		xCLR_ALL	: in   std_logic;
		xADC		: in   std_logic_vector (12 downto 0);
		xROVDD		: in   std_logic_vector (11 downto 0);
		xPROVDD		: in   std_logic_vector (11 downto 0);
		xRADDR		: out  std_logic_vector (10 downto 0);
		xUSBusy		: out  std_logic;
	--	xUSB_SYNC_MODE:out std_logic;
		xDLL_RESET_FLAG	: out	std_logic;
		xTRIG_RESET_FLAG: out	std_logic;
		xTRIG_SIGN		: out	std_logic;
		xTRIG_ENABLE	: out 	std_logic;
		xSAMPLE_SPEED	: out	std_logic;
		xTRIG_MASK		: out std_logic_vector(5 downto 0);
		
		xRO_CNT		: in	std_logic_vector(15 downto 0);
		xTRIG_LO	: in	std_logic_vector(5 downto 0);
		xSAMPLESPEEDBIT	:	in	std_logic;
		xSAMPLE_BIN		:	in	std_logic_vector(3 downto 0));
		
end USBmain;
		
architecture BEHAVIORAL of USBmain is
		
-----signals-----------		
	signal SYNC_USB		: 	std_logic;
	signal WBUSY		:	std_logic;
	signal RBUSY		:	std_logic;
	signal TOGGLE		:	std_logic;
	signal USB_DATA		:	std_logic_vector(15 downto 0);
	signal SLWR			:	std_logic;
	signal FPGA_DATA	:	std_logic_vector(15 downto 0);
	signal usb_done		: 	std_logic;
	signal PED_SCAN		:	std_logic_vector(11 downto 0);
	signal TRIG_ENABLE	: 	std_logic;
	signal TRIG_SIGN	:	std_logic;	
	signal trig_mask  : std_logic_vector(5 downto 0);
-----components--------
	component IO16
		port( 	xTOGGLE	:	in	std_logic;
				FDIN	:	in	std_logic_vector(15 downto 0);
				FD		:	inout	std_logic_vector(15 downto 0);
				FDOUT	:	out	std_logic_vector(15 downto 0));
	end component;	
	
	component USBread
		port( 
			xIFCLK     		: in    std_logic;
			xUSB_DATA  		: in    std_logic_vector (15 downto 0);
			xFLAGA    		: in    std_logic;
			xRESET    		: in    std_logic;
			xWBUSY    		: in    std_logic;
			xFIFOADR  		: out   std_logic_vector (1 downto 0);
			xRBUSY    		: out   std_logic;
			xSLOE     		: out   std_logic;
			xSLRD     		: out   std_logic;
			xSYNC_USB 		: out   std_logic;
			xSOFT_TRIG		: out   std_logic;
			xDLL_RESET		: out		std_logic;
			xPED_SCAN		: out   std_logic_vector (11 downto 0);
			xTRIG_RESET		: out	std_logic;
			xTRIG_SIGN		: out 	std_logic;
			xTRIG_ENABLE	: out	std_logic;
			xTRIG_MASK			: out std_logic_vector(5 downto 0);
			xSAMPLE_SPEED	: out	std_logic;
			xDEBUG 		  	: out   std_logic_vector (15 downto 0);
			xTOGGLE   		: out   std_logic);
	end component;
	
	component USBwrite
		port ( 
			xIFCLK    : in    std_logic;
			xFLAGB    : in    std_logic;	
			xFLAGC    : in    std_logic;	
			xRBUSY    : in    std_logic;	
			xRESET    : in    std_logic;	
			xSTART    : in    std_logic;	
			xSYNC_USB : in    std_logic; 
			xDONE     : out   std_logic; 	
			xPKTEND   : out   std_logic;	
			xSLWR     : out   std_logic;	
			xWBUSY    : out   std_logic);	
     end component;
    
    component MESS
		port(
			xSLWR			: in   std_logic;
			xSTART		 	: in   std_logic;
			xDONE		 	: in   std_logic;
			xCLR_ALL	 	: in   std_logic;
			xADC			: in   std_logic_vector (12 downto 0);
			xROVDD			: in   std_logic_vector (11 downto 0);
			xPROVDD			: in   std_logic_vector (11 downto 0);
			xRO_CNT			: in   std_logic_vector	(15 downto 0);
			xLOC_TRIG		: in   std_logic_vector (5 downto 0);
			xVBIAS			: in   std_logic_vector (11 downto 0);
			xUSB_SYNC		: in   std_logic;
			xSAMPLESPEED	:	in	std_logic;
			xSAMPLE_BIN		:	in	std_logic_vector(3 downto 0);
			xTRIG_ENABLE	: in	std_logic;
			xTRIG_SIGN		: in	std_logic;
			xTRIG_MASK		: in	std_logic_vector(5 downto 0);
			xFPGA_DATA     	: out  std_logic_vector (15 downto 0);
			xRADDR			: out  std_logic_vector (10 downto 0));
		end component;
-----------------------------
--begin-------
begin	
--------------	
	RDY(1) <= SLWR;
	xSLWR <= SLWR;
	xUSBdone <= usb_done;
	xUSBusy <= (WBUSY or RBUSY);
	xPED_SCAN <= PED_SCAN;
	xTRIG_ENABLE <= TRIG_ENABLE;
	xTRIG_SIGN	<=	TRIG_SIGN;
	xTRIG_MASK <= trig_mask;
--	xUSB_SYNC_MODE <= SYNC_USB;
	
	IOBUF : IO16
	port map( 	xTOGGLE => TOGGLE,
				FDIN(15 downto 0)	=>  FPGA_DATA(15 downto 0),	
				FD(15 downto 0)		=>	FD(15 downto 0),
				FDOUT(15 downto 0)	=>	USB_DATA(15 downto 0));

	xUSBread : USBread
	port map(  	xIFCLK     		=> IFCLK,
				xUSB_DATA(15 downto 0)  => USB_DATA(15 downto 0),
				xFLAGA    		=> CTL(0),
				xRESET    		=> xRESET,
				xWBUSY    		=> WBUSY,
				xFIFOADR(1 downto 0)	=> PA(5 downto 4),
				xRBUSY    		=> RBUSY,
				xSLOE     		=> PA(2),
				xSLRD     		=> RDY(0),
				xSYNC_USB 		=> SYNC_USB,
				xSOFT_TRIG		=> xSOFT_TRIG,
				xDLL_RESET		=>	xDLL_RESET_FLAG,
				xPED_SCAN		=> PED_SCAN,
				xTRIG_RESET		=> xTRIG_RESET_FLAG,	
				xTRIG_SIGN		=> TRIG_SIGN,
				xTRIG_ENABLE	=> TRIG_ENABLE,
				xTRIG_MASK		=> trig_mask,
				xSAMPLE_SPEED	=> xSAMPLE_SPEED,
				xDEBUG 		  	=> xUSB_CNTRL,
				xTOGGLE   		=> TOGGLE);
				
	xUSBwrite : USBwrite
	port map(	xIFCLK    => IFCLK,
				xFLAGB    => CTL(1),	
				xFLAGC    => CTL(2),	
				xRBUSY    => RBUSY,	
				xRESET    => xRESET,	
				xSTART    => xUSBstart,	 
				xSYNC_USB => SYNC_USB, 
				xDONE     => usb_done, 	
				xPKTEND   => PA(6),	
				xSLWR     => SLWR,	
				xWBUSY    => WBUSY);
	
	xMESS	: MESS
	port map(
			xSLWR			=> SLWR,
			xSTART		 	=> xUSBstart,
			xDONE		 	=> usb_done,
			xCLR_ALL	 	=> xCLR_ALL,
			xADC			=> xADC,
			xROVDD			=> xROVDD,
			xPROVDD			=> xPROVDD,
			xRO_CNT			=> xRO_CNT,
			xLOC_TRIG		=> xTRIG_LO,
			xVBIAS			=> PED_SCAN,
			xUSB_SYNC       => SYNC_USB,
			xSAMPLESPEED	 => xSAMPLESPEEDBIT,
			xSAMPLE_BIN		=>	xSAMPLE_BIN,
			xTRIG_ENABLE	=> TRIG_ENABLE,
			xTRIG_SIGN		=> TRIG_SIGN,
			xTRIG_MASK		=> trig_mask,
			xFPGA_DATA     	=> FPGA_DATA,
			xRADDR			=> xRADDR);
				
end BEHAVIORAL;
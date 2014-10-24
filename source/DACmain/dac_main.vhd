-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- e oberla                                                                  --
-- DATE: Mar. 2010                                                           --
-- PROJECT: psTDC_2 tester firmware                                          --
-- NAME: DAC_MAIN                                                            --
-- Description:                                                              --
--      DAC module                                                           --
--    -- for use with DAC_SERIALIZATION.vhd--                                --
--    -- parallel control to two octal DACs--                                                                      --
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity DAC_MAIN is
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
	end DAC_MAIN;
	
architecture Behavioral of DAC_MAIN is
-------------------------------------------------------------------------------
-- SIGNALS 
-------------------------------------------------------------------------------	
	signal CLR		: std_logic;
	--signal DATIN1	: std_logic;
	--signal DATIN2   : std_logic;
	signal UPDATE   : std_logic;
	
	signal DAC_A_0	: std_logic_vector(23 downto 0);
	signal DAC_B_0	: std_logic_vector(23 downto 0);
	signal DAC_C_0	: std_logic_vector(23 downto 0);
	signal DAC_D_0	: std_logic_vector(23 downto 0);
	signal DAC_E_0	: std_logic_vector(23 downto 0);
	signal DAC_F_0	: std_logic_vector(23 downto 0);
	signal DAC_G_0	: std_logic_vector(23 downto 0);
	signal DAC_H_0	: std_logic_vector(23 downto 0);
	signal DAC_A_1	: std_logic_vector(23 downto 0);
	signal DAC_B_1	: std_logic_vector(23 downto 0);
	signal DAC_C_1	: std_logic_vector(23 downto 0);
	signal DAC_D_1	: std_logic_vector(23 downto 0);
	signal DAC_E_1	: std_logic_vector(23 downto 0);
	signal DAC_F_1	: std_logic_vector(23 downto 0);
	signal DAC_G_1	: std_logic_vector(23 downto 0);
	signal DAC_H_1	: std_logic_vector(23 downto 0);
---  DAC signals:    ----------------------------------------
	
	signal VCN		: std_logic_vector(15 downto 0);
	signal xVCN		: std_logic_vector(11 downto 0);
	signal ROVDD	: std_logic_vector(11 downto 0);
	signal VCP		: std_logic_vector(15 downto 0);
	signal TTHRSH1	: std_logic_vector(15 downto 0);
	signal TTHRSH2	: std_logic_vector(15 downto 0);
	signal TTHRSH3	: std_logic_vector(15 downto 0);
	signal TTHRSH4	: std_logic_vector(15 downto 0);
	signal TTHRSH5	: std_logic_vector(15 downto 0);
	signal TTHRSH6 : std_logic_vector(15 downto 0);
	signal TTHRSH	: std_logic_vector(11 downto 0);
	signal DLLbias1	: std_logic_vector(15 downto 0);  --ideally pdown res
	signal DLLbias2	: std_logic_vector(15 downto 0);  --ideally pdown res
	signal xV2GN	: std_logic_vector(11 downto 0);
	signal V2GN		: std_logic_vector(15 downto 0);
	signal PROVDD	: std_logic_vector(11 downto 0);
	signal V2GP		: std_logic_vector(15 downto 0);
	signal DLLpol	: std_logic_vector(15 downto 0);
	signal VBIAS	: std_logic_vector(15 downto 0);
-------------------------------------------------------------------------------
-- COMPONENTS 
-------------------------------------------------------------------------------
	component DAC_SERIALIZER    --call DAC_SERIALIZER.vhd
	port(
		xCLK             : in    std_logic;      -- DAC clk ( < 50MHz ) 
        xCLR_ALL		 : in	 std_logic;
        xUPDATE          : in    std_logic;
        xDAC_A           : in    std_logic_vector (23 downto 0);  --DAC takes
        xDAC_B           : in    std_logic_vector (23 downto 0);  --24 bit word
        xDAC_C           : in    std_logic_vector (23 downto 0);  
        xDAC_D           : in    std_logic_vector (23 downto 0);
        xDAC_E           : in    std_logic_vector (23 downto 0); 
        xDAC_F           : in    std_logic_vector (23 downto 0); 
        xDAC_G           : in    std_logic_vector (23 downto 0); 
        xDAC_H           : in    std_logic_vector (23 downto 0); 
        xLOAD            : out   std_logic;     -- load DACs- active low
        xCLR_BAR         : out   std_logic;     -- Asynch clear
        xSERIAL_DATOUT   : out   std_logic);    -- Serial data to DAC reg
	end component;
-------------------------------------------------------------------------------  
begin  -- Behavioral
-------------------------------------------------------------------------------
	UPDATE <= xCLK_REFRESH;       --1 Hz
	DACCLK1 <= xCLKDAC;	
	DACCLK2	<= xCLKDAC;
	TTHRSH <= xTRIG_THRESH;
	--TTHRSH <= x"FFF";
-------------------------------------------------------------------------------
--assign DAC values
--   for 12 bit DAC, input word is 24 bits: 4 COMMAND-4 ADDRESS-12 DATA-4 DON'T CARE
--     assign 12 DATA-4 DON'T CARE here (set DON'T CARE = 0b1111 = 0xF) 
-------------------------------------------------------------------------------
-- temporary--	
		ROVDD <= x"A00";
	--    ROVDD <= DEBUG;
		PROVDD <= xPROVDD;	
	--	PROVDD<= x"780";
	--	PROVDD <= DEBUG;
---------------------------------------------	
	xVCN		<=  x"FFF" - ROVDD;
	VCN			<=  xVCN & x"0";
	TTHRSH1 	<=	TTHRSH			& 	x"0";
	TTHRSH2 	<=	TTHRSH			& 	x"0";
	TTHRSH3 	<=	TTHRSH			& 	x"0";
	TTHRSH4 	<=	TTHRSH			& 	x"0";
	TTHRSH5 	<=	TTHRSH			& 	x"0";
	TTHRSH6  <= TTHRSH			& 	x"0";
	DLLbias1 	<=	x"300"			& 	x"F";	
	DLLbias2	<=  x"CFF0";
	--DLLbias1 	<=	x"000"			& 	x"F";	--test
	--DLLbias2	<=  x"FFFF";                    --test
	xV2GN 		<=	x"FFF"	- PROVDD;
	V2GN 		<=	xV2GN 			& 	x"0";
	DLLpol	 	<=	x"FFF"			& 	x"F";
	VCP			<=  ROVDD			&	x"0";
	V2GP		<=  PROVDD			&	x"0";
	xROVDD		<=	ROVDD;   
	--xPROVDD		<=	PROVDD;
-------------------- 	
	--VBIAS 		<=	x"840"			& 	x"0";  -- uncomment for set bias level
	VBIAS      	<=  xVBIAS			& 	x"0"; --uncomment for ped scan
--------------------	
	
--------------------------------------------------------------------------------
-- update DAC values with 4 COMMAND and 4 ADDRESS bits
-- note: these assignments are easily changed to match board layout
--------------------------------------------------------------------------------	
	DAC_A_0		<=	"11110000"	&	DLLpol;
	--DAC_B_0		<=	"00110001"	&	VCP;  --uncomment only if R200 connection removed 
	DAC_B_0		<=	"11110001"	&	VCP;    --uncomment to use internal DLL
	--DAC_C_1		<=	"00110010"	&	VCN;  --uncomment only if R204 connection removed
	DAC_C_0		<=	"11110010"	&	VCN;    --uncomment to use internal DLL
	DAC_D_0		<=	"00110011"	&	TTHRSH1;
	DAC_E_0		<=	"00110100"	&	TTHRSH2;
	DAC_F_0		<=	"00110101"	&	VBIAS;	
	DAC_G_0		<=	"00110110"	&	VBIAS;
	DAC_H_0		<=	"00110111"	&	VBIAS;
--	DAC_H_0		<=	"00110111"	&	x"FFFF";		
	
	DAC_A_1		<=	"00110000"	&	TTHRSH3;	
	DAC_B_1		<=	"00110001"	&	TTHRSH4;
	DAC_C_1		<=	"00110010"	&	TTHRSH5;   
	DAC_D_1		<=	"00110011"	&	TTHRSH6;
	DAC_E_1		<=	"00110100"	&	V2GN;
	DAC_F_1		<=	"00110101"	&	V2GP;
	DAC_G_1		<=	"00110110"	&	DLLbias1;   
	DAC_H_1		<=	"00110111"	&	DLLbias2;  
-------------------------------------------------------------------------------
	xDAC_SERIALIZER_0 : DAC_SERIALIZER
	port map(
		xCLK         => xCLKDAC,    
        xCLR_ALL	 => xCLR_ALL,
        xUPDATE      => '0', --UPDATE,    
        xDAC_A       => DAC_A_0,    
        xDAC_B       => DAC_B_0,    
        xDAC_C       => DAC_C_0,  
        xDAC_D       => DAC_D_0,    
        xDAC_E       => DAC_E_0,    
        xDAC_F       => DAC_F_0,    
        xDAC_G       => DAC_G_0,    
        xDAC_H       => DAC_H_0,    
  --      xSERIAL_DATIN	=> SDATOUT1,
        xLOAD        => LOAD1,
        xCLR_BAR     => CLR_BAR1,    
        xSERIAL_DATOUT	=> SDATIN1);

 ------------------------------------------------------------------------------- 
	xDAC_SERIALIZER_1 : DAC_SERIALIZER
	port map(
		xCLK         => xCLKDAC,    
        xCLR_ALL	 => xCLR_ALL,
        xUPDATE      => '0', --UPDATE,    
        xDAC_A       => DAC_A_1,    
        xDAC_B       => DAC_B_1,    
        xDAC_C       => DAC_C_1,  
        xDAC_D       => DAC_D_1,    
        xDAC_E       => DAC_E_1,    
        xDAC_F       => DAC_F_1,    
        xDAC_G       => DAC_G_1,    
        xDAC_H       => DAC_H_1,    
    --    xSERIAL_DATIN	=> SDATOUT2,
        xLOAD        => LOAD2,    
        xCLR_BAR     => CLR_BAR2, 
        xSERIAL_DATOUT	=> SDATIN2);
--------------------------------------------------------------------------------
end Behavioral;
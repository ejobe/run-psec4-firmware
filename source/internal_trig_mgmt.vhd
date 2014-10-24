--------------------------------------------------
-- University of Chicago
-- LAPPD system firmware
--------------------------------------------------
-- module		: 	psec4_trigger
-- author		: 	ejo
-- date			: 	6/2012
-- description	:  psec4 trigger generation
--------------------------------------------------
	
library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity INTERNAL_TRIG_MGMT is
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
	end INTERNAL_TRIG_MGMT;
	
architecture Behavioral	of INTERNAL_TRIG_MGMT is
	type 	HANDLE_TRIG_TYPE	is (WAIT_FOR_TRIG, HOLD_TRIG, RESET_TRIG);
	signal HANDLE_TRIG_0 : HANDLE_TRIG_TYPE;
	signal HANDLE_TRIG_1 : HANDLE_TRIG_TYPE;
	signal HANDLE_TRIG_2 : HANDLE_TRIG_TYPE;
	signal HANDLE_TRIG_3 : HANDLE_TRIG_TYPE;
	signal HANDLE_TRIG_4 : HANDLE_TRIG_TYPE;
	signal HANDLE_TRIG_5 : HANDLE_TRIG_TYPE;
	
	type 	RESET_TRIG_TYPE	is (RESETT, RELAXT);
	signal	RESET_TRIG_STATE:	RESET_TRIG_TYPE;
	
	signal RATE_COUNT_0 : std_logic_vector(15 downto 0);
	signal RATE_COUNT_1 : std_logic_vector(15 downto 0);
	signal RATE_COUNT_2 : std_logic_vector(15 downto 0);
	signal RATE_COUNT_3 : std_logic_vector(15 downto 0);
	signal RATE_COUNT_4 : std_logic_vector(15 downto 0);
	signal RATE_COUNT_5 : std_logic_vector(15 downto 0);
	
	signal SELF_TRIG_LATCHED_0 : std_logic;
	signal SELF_TRIG_LATCHED_1 : std_logic;
	signal SELF_TRIG_LATCHED_2 : std_logic;
	signal SELF_TRIG_LATCHED_3 : std_logic;
	signal SELF_TRIG_LATCHED_4 : std_logic;
	signal SELF_TRIG_LATCHED_5 : std_logic;

	signal SELF_TRIG_RESET_0 : std_logic;
	signal SELF_TRIG_RESET_1 : std_logic;
	signal SELF_TRIG_RESET_2 : std_logic;
	signal SELF_TRIG_RESET_3 : std_logic;
	signal SELF_TRIG_RESET_4 : std_logic;
	signal SELF_TRIG_RESET_5 : std_logic;
	
	signal SELF_TRIG_CLR	: 	std_logic;
	signal SELF_TRIG_EXT	:	std_logic;
	
	signal RESET_TRIG_FROM_SOFTWARE	:	std_logic := '0';
	signal RESET_TRIG_COUNT				:	std_logic := '1';
		
begin

xSELFTRIG_TRIG <= SELF_TRIG_EXT;
xSELFTRIG_RESET <= SELF_TRIG_CLR or RESET_TRIG_FROM_SOFTWARE;

--this process looks for a single channel triggered according to mask
--to add: multiple channels to trigger, i.e. pattern
process(xCLR_ALL, xDONE, xSELFTRIG(0), xSELFTRIG_MASK)
begin
	if xCLR_ALL = '1'  or xDONE = '1' or xSELFTRIG_EN = '0' or SELF_TRIG_CLR = '1' 
		or RESET_TRIG_FROM_SOFTWARE = '1' then		
		SELF_TRIG_LATCHED_0 <= '0';	
	elsif rising_edge(xSELFTRIG(0)) and xSELFTRIG_MASK = 1 then
		SELF_TRIG_LATCHED_0 <= '1';
	end if;
end process;

process(xCLR_ALL, xDONE, xSELFTRIG(1), xSELFTRIG_MASK)
begin
	if xCLR_ALL = '1'  or xDONE = '1' or xSELFTRIG_EN = '0' or SELF_TRIG_CLR = '1' 
		or RESET_TRIG_FROM_SOFTWARE = '1' then		
		SELF_TRIG_LATCHED_1 <= '0';	
	elsif rising_edge(xSELFTRIG(1)) and xSELFTRIG_MASK = 2 then
		SELF_TRIG_LATCHED_1 <= '1';
	end if;
end process;

process(xCLR_ALL, xDONE, xSELFTRIG(2), xSELFTRIG_MASK)
begin
	if xCLR_ALL = '1'  or xDONE = '1' or xSELFTRIG_EN = '0' or SELF_TRIG_CLR = '1' 
		or RESET_TRIG_FROM_SOFTWARE = '1' then		
		SELF_TRIG_LATCHED_2 <= '0';	
	elsif rising_edge(xSELFTRIG(2)) and xSELFTRIG_MASK = 3 then
		SELF_TRIG_LATCHED_2 <= '1';
	end if;
end process;

process(xCLR_ALL, xDONE, xSELFTRIG(3), xSELFTRIG_MASK)
begin
	if xCLR_ALL = '1'  or xDONE = '1' or xSELFTRIG_EN = '0' or SELF_TRIG_CLR = '1' 
		or RESET_TRIG_FROM_SOFTWARE = '1' then		
		SELF_TRIG_LATCHED_3 <= '0';	
	elsif rising_edge(xSELFTRIG(3)) and xSELFTRIG_MASK = 4 then
		SELF_TRIG_LATCHED_3 <= '1';
	end if;
end process;

process(xCLR_ALL, xDONE, xSELFTRIG(4), xSELFTRIG_MASK)
begin
	if xCLR_ALL = '1'  or xDONE = '1' or xSELFTRIG_EN = '0' or SELF_TRIG_CLR = '1' 
		or RESET_TRIG_FROM_SOFTWARE = '1' then		
		SELF_TRIG_LATCHED_4 <= '0';	
	elsif rising_edge(xSELFTRIG(4)) and xSELFTRIG_MASK = 5 then
		SELF_TRIG_LATCHED_4 <= '1';
	end if;
end process;

process(xCLR_ALL, xDONE, xSELFTRIG(5), xSELFTRIG_MASK)
begin
	if xCLR_ALL = '1'  or xDONE = '1' or xSELFTRIG_EN = '0' or SELF_TRIG_CLR = '1' 
		or RESET_TRIG_FROM_SOFTWARE = '1' then		
		SELF_TRIG_LATCHED_5 <= '0';	
	elsif rising_edge(xSELFTRIG(5)) and xSELFTRIG_MASK = 6 then
		SELF_TRIG_LATCHED_5 <= '1';
	end if;
end process;

process(	xTRIG_CLK, xSELFTRIG, xSELFTRIG_MASK, 
			xSELFTRIG_EN, xCLR_ALL, xDONE, SELF_TRIG_CLR)
begin
	if xCLR_ALL = '1'  or xDONE = '1' or xSELFTRIG_EN = '0' or SELF_TRIG_CLR = '1' 
		or RESET_TRIG_FROM_SOFTWARE = '1' then
		--
		SELF_TRIG_EXT <= '0';
		--
	--elsif falling_edge(xTRIG_CLK) and
	elsif (SELF_TRIG_LATCHED_0 = '1' or SELF_TRIG_LATCHED_1 = '1' or SELF_TRIG_LATCHED_2 = '1' or
		SELF_TRIG_LATCHED_3 = '1' or SELF_TRIG_LATCHED_4 = '1' or SELF_TRIG_LATCHED_5 = '1') then
		--						
		SELF_TRIG_EXT <= 	'1';
		--						
	end if;
end process;

--clearing trigger
process(xCLR_ALL, xDONE, SELF_TRIG_EXT )

begin
	if xCLR_ALL = '1'  or xDONE = '1' or xSELFTRIG_EN = '0' then
		SELF_TRIG_CLR <= '1';
	elsif xCLR_ALL = '0'  and xDONE = '0' and xSELFTRIG_EN = '1' then
		SELF_TRIG_CLR <= '0';		
	end if;
end process;


--software trigger reset
process(xTRIG_CLK, xRESET_TRIG_FLAG)
		begin
			if xCLR_ALL = '1' then
				RESET_TRIG_FROM_SOFTWARE <= '0';
			elsif rising_edge(xTRIG_CLK) and (RESET_TRIG_COUNT = '0') then
				RESET_TRIG_FROM_SOFTWARE <= '0';
			elsif rising_edge(xTRIG_CLK) and xRESET_TRIG_FLAG = '1' and xCLR_ALL = '0' then
				RESET_TRIG_FROM_SOFTWARE <= '1';
			end if;
	end process;
	
	process(xMCLK, RESET_TRIG_FROM_SOFTWARE)
	variable i : integer range 10000004 downto -1 := 0;
		begin
			if falling_edge(xMCLK) and RESET_TRIG_FROM_SOFTWARE = '0' then
				i := 0;
				RESET_TRIG_STATE <= RESETT;
				RESET_TRIG_COUNT <= '1';
			elsif falling_edge(xMCLK) and RESET_TRIG_FROM_SOFTWARE  = '1' then
				case RESET_TRIG_STATE is
					when RESETT =>
						i:=i+1;
						if i > 10 then
							i := 0;
							RESET_TRIG_STATE <= RELAXT;
						end if;
						
					when RELAXT =>
						RESET_TRIG_COUNT <= '0';

				end case;
			end if;
	end process;

end Behavioral;
		
	



	






	
	
	


			

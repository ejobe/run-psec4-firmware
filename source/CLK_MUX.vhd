-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- e oberla                                                                  --
-- DATE: Mar. 2010                                                           --
-- PROJECT: psec3 tester firmware                                          --
-- NAME: CLK_MUX                                                                --
-- Description:                                                              --
--      sampling speed select                                                 --
--    -- 																	 --
--    --                                                                     --
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity CLK_MUX is
	port(
		xCLR_ALL		: in	std_logic;
		xCONTROL		: in	std_logic_vector(1 downto 0);
		xCLK40M		: in	std_logic;
		xCLKFAST		: in	std_logic;
		xRESET_FLAG	: in	std_logic;
		xRESET_TRIG_FLAG : in	std_logic;
		xSAMPLE_CLK	: out	std_logic;
		xRESET_DLL	: out	std_logic;	--DLL reset signal (active low)
		xCLK40M_OUT	: out	std_logic;
		xSPEED_SEL	: out	std_logic;
		xTRIG_CLK	: out	std_logic;
		xRESET_TRIG	: out	std_logic);
	end CLK_MUX;

architecture Behavioral of CLK_MUX is 
---SIGNALS-----------------------------------
	type 	RESET_STATE_TYPE	is (RESET, RELAX);
	signal	RESET_STATE	:	RESET_STATE_TYPE;

	type 	RESET_TRIG_TYPE	is (RESETT, RELAXT);
	signal	RESET_TRIG_STATE:	RESET_TRIG_TYPE;
		
	signal 	CLK40M						:	std_logic;
	signal	CLK_SAMPLE					:	std_logic;
	--signal	CLK_TRIG						:	std_logic;
	signal	CLK_COUNTER					:	std_logic_vector(1 downto 0);
	--signal	CLK_COUNTER_FAST			:	std_logic_vector(1 downto 0);
	signal	RESET_DLL_FROM_POWERUP	:	std_logic;	
	signal	RESET_DLL_FROM_SOFTWARE	:	std_logic	:=	'1';
	signal	RESET_COUNT					:	std_logic	:= '1';
	signal	RESET_TRIG_FROM_POWERUP		:	std_logic;
	signal  RESET_TRIG_FROM_SOFTWARE 	:	std_logic := '0';
	signal  RESET_TRIG_COUNT			:	std_logic := '1';
	
	signal	SWITCH_CLK					:	std_logic;

	signal	SPEED_SELECT				:	std_logic 	:= '0';

	begin
	
	CLK40M		<=	xCLK40M;
	xCLK40M_OUT	<=	CLK40M;
	xSAMPLE_CLK	<= CLK_SAMPLE;
	xTRIG_CLK	<= xCLKFAST;
	
	xSPEED_SEL	<= SPEED_SELECT;
	
	xRESET_DLL	<=	(RESET_DLL_FROM_POWERUP and RESET_DLL_FROM_SOFTWARE);
	xRESET_TRIG <=  RESET_TRIG_FROM_SOFTWARE or RESET_TRIG_FROM_POWERUP;

	process(xCLR_ALL)
		begin	
			if xCLR_ALL = '1' then
				RESET_DLL_FROM_POWERUP <= '0';
			else
				RESET_DLL_FROM_POWERUP <= '1';		
			end if;
	end process;
	
	process(xCLR_ALL)
		begin	
			if xCLR_ALL = '1' then
				RESET_TRIG_FROM_POWERUP <= '1';
			else
				RESET_TRIG_FROM_POWERUP <= '0';		
			end if;
	end process;
	
	
	process(xCLKFAST, xRESET_FLAG)
		begin
			if xCLR_ALL = '1' then
				RESET_DLL_FROM_SOFTWARE <= '1';
			elsif rising_edge(xCLKFAST) and (RESET_COUNT = '0') then
				RESET_DLL_FROM_SOFTWARE <= '1';
			elsif rising_edge(xCLKFAST) and xRESET_FLAG = '1' then
				RESET_DLL_FROM_SOFTWARE <= '0';
			end if;
	end process;
	
	process(xCLK40M, RESET_DLL_FROM_SOFTWARE)
	variable i : integer range 1000000002 downto 0 := 0;
		begin
			if falling_edge(xCLK40M) and RESET_DLL_FROM_SOFTWARE = '1' then
				i := 0;
				RESET_STATE <= RESET;
				RESET_COUNT <= '1';
			elsif falling_edge(xCLK40M) and RESET_DLL_FROM_SOFTWARE  = '0' then
				case RESET_STATE is
					when RESET =>
						i:=i+1;
						if i > 300000000 then
							i := 0;
							RESET_STATE <= RELAX;
						end if;
						
					when RELAX =>
						RESET_COUNT <= '0';

				end case;
			end if;
	end process;

	process(xCLKFAST, xRESET_TRIG_FLAG)
		begin
			if xCLR_ALL = '1' then
				RESET_TRIG_FROM_SOFTWARE <= '0';
			elsif rising_edge(xCLKFAST) and (RESET_TRIG_COUNT = '0') then
				RESET_TRIG_FROM_SOFTWARE <= '0';
			elsif rising_edge(xCLKFAST) and xRESET_TRIG_FLAG = '1' then
				RESET_TRIG_FROM_SOFTWARE <= '1';
			end if;
	end process;
	
	process(xCLK40M, RESET_TRIG_FROM_SOFTWARE)
	variable i : integer range 1000002 downto 0 := 0;
		begin
			if falling_edge(xCLK40M) and RESET_TRIG_FROM_SOFTWARE = '0' then
				i := 0;
				RESET_TRIG_STATE <= RESETT;
				RESET_TRIG_COUNT <= '1';
			elsif falling_edge(xCLK40M) and RESET_TRIG_FROM_SOFTWARE  = '1' then
				case RESET_TRIG_STATE is
					when RESETT =>
						i:=i+1;
						if i > 1000000 then
							i := 0;
							RESET_TRIG_STATE <= RELAXT;
						end if;
						
					when RELAXT =>
						RESET_TRIG_COUNT <= '0';

				end case;
			end if;
	end process;
	
	process(xCLR_ALL, xCONTROL, xCLK40M)
	begin
		if xCLR_ALL = '1' then
			SPEED_SELECT <= '0';
		elsif falling_edge(xCLK40M) then
		case xCONTROL(0) is
			when '0' =>
				SPEED_SELECT <= '0';
			when '1' =>
				SPEED_SELECT <= '1';
			--when others =>
			--	SPEED_SELECT <= '0';
			end case;
		end if;
	end process;
	
	process(xCLK40M, SPEED_SELECT)
	begin
--		if rising_edge(xCLK40M) then
--			CLK_COUNTER <= CLK_COUNTER + 1;
--		end if;			
		if SPEED_SELECT = '0' or xCLR_ALL = '1' then
			CLK_COUNTER <= (others => '0');
			SWITCH_CLK	<= '0';
		elsif rising_edge(xCLK40M) and SPEED_SELECT = '1' then
			CLK_COUNTER <= CLK_COUNTER + 1;
			SWITCH_CLK	<= '1';
		end if;
	end process;

--	process(xCLKFAST, SPEED_SELECT)
--	begin
--		if SPEED_SELECT = '0' or xCLR_ALL = '1' then
--			CLK_COUNTER_FAST <= (others => '0');
--		elsif rising_edge(xCLKFAST) and SPEED_SELECT = '1' and SWITCH_CLK = '1' then
--			CLK_COUNTER_FAST <= CLK_COUNTER_FAST + 1;
--		end if;
--	end process;
	
	--keep ratio of clk_fast/clk_sample always 8 for simplicity
	process(xCLR_ALL, CLK40M, SWITCH_CLK, SPEED_SELECT)
	begin
		if xCLR_ALL = '1' then
			CLK_SAMPLE 	<= xCLK40M;
			--CLK_TRIG		<= xCLKFAST;
		elsif SPEED_SELECT = '0' then
			CLK_SAMPLE 	<= xCLK40M;
			--CLK_TRIG		<=	xCLKFAST;
		elsif SPEED_SELECT = '1' then
			CLK_SAMPLE  <= CLK_COUNTER(0);
			--CLK_TRIG		<=	CLK_COUNTER_FAST(0);
		end if;
	end process;				
	
end Behavioral; 						
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- e oberla                                                                  --
-- DATE: Mar. 2010                                                           --
-- PROJECT: psTDC_2 tester firmware                                          --
-- NAME: RAMP_psTDC                                                                --
-- Description:                                                              --
--      ramp/ADC module                                                      --
--    --  includes latch transparency pulse at end of digitization  		 --
--    --                                                                     --
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity RAMP_psTDC_3 is
	port(
			xCLK		: in	std_logic; 
			xCLR_ALL	: in	std_logic;
			xTRIGHIT	: in	std_logic;
			xDONE   	: in	std_logic;
			xRAMP		: out	std_logic;	
			xRAMPDONE	: out	std_logic;
		--	xRD			: out	std_logic;
			xCLEARADC	: out	std_logic;
			xRO_enable	: out	std_logic;
			xRO_freq	: out	std_logic;
			ADClatch_select:out	std_logic);
		--	ADClatch_value :out std_logic);
	end RAMP_psTDC_3;
	
architecture Behavioral of RAMP_psTDC_3 is
	type STATE_TYPE is (INIT,  RAMPING, EXTLATCH_rise, EXTLATCH_fall,  RAMPDONE);
-------------------------------------------------------------------------------
-- SIGNALS
-------------------------------------------------------------------------------	
		signal STATE	:	STATE_TYPE;
		signal RAMP_DONE:	std_logic;
		signal RAMP		:	std_logic;
		signal RAMP_CNT	:	std_logic_vector(7 downto 0);
		signal RAMP_WAIT	: std_logic_vector(31 downto 0);
		--signal RD		:	std_logic;
		signal CLEAR	: 	std_logic;
		signal ROen		: 	std_logic;
		signal ROfreq	:	std_logic := '0';   --0 for fast, 1 for slow
		signal ADClatch	:   std_logic;--:= '0';  --0= latch internal
		signal latch_value: std_logic;--:= '1';
--		signal TRIG		:	std_logic;
-------------------------------------------------------------------------------
begin  --Behavioral
-------------------------------------------------------------------------------
	xRO_freq <= ROfreq;
	--ADClatch_select <= ADClatch;
	--ADClatch_value	<= latch_value;
	
	process(xCLK, xCLR_ALL, xDONE, xTRIGHIT)
	variable i : integer range 100 downto 0 := 0; --variable i : integer range 50 downto 0; (default)
	begin
		if xDONE = '1' or xCLR_ALL = '1' then 
			RAMP <='0';
			RAMP_DONE <= '0';
			RAMP_CNT <= "00000000";
			RAMP_WAIT <= (others=>'0');
			STATE <= INIT;
			CLEAR <= '1';
			ADClatch <= '0'; --latch internal upon start
			--ADClatch <= '1'; --test ADC power
			latch_value <= '1';
			i := 0;
			--ROen <= '0';
			--ROen <= '1'; --test ADC power
		elsif falling_edge(xCLK) and xTRIGHIT = '1'  then 
			case STATE is
			-------------------------	
				when INIT =>
					ROen <= '1';
					--RD <= '1'; --close read switches 
					RAMP <= '1';
					--ADClatch <= '0';
					CLEAR <= '1';
					--if RAMP_WAIT = 10 then   --if RAMP_WAIT = 12 then (default)
					if RAMP_WAIT = 400000 then   --if RAMP_WAIT = 12 then (default)
						RAMP_WAIT <= (others=>'0');
						RAMP <= '0';
					--	ADClatch <= '0';
						--RAMP <= '0';
						STATE <= RAMPING;
					else	
						RAMP_WAIT <= RAMP_WAIT+1;   -- some setup time
					end if;
						
			--	when CLEARPULSE =>
			--		i := i+1;
			--		if i = 4 then
			--			CLEAR <= '0';
			--			i := 0;
			--			STATE <= RAMPING;
			--		end if;
			-------------------------	
				when RAMPING =>
					
					CLEAR <= '0';   -- ramp active low
					RAMP_CNT <= RAMP_CNT + 1;
					if RAMP_CNT = 160 then  --set ramp length w.r.t. clock
						--STATE <= RAMPDONE;
						RAMP_CNT <= "00000000";
						ROen <='0';
						STATE <= EXTLATCH_rise;
					end if;
			-------------------------

			    when EXTLATCH_rise =>   --latch tranparency pulse
				--	ADClatch <= '1';
					i := i+1;
					if i = 1 then
						i := 0;
						ADClatch <= '1';
						STATE <= EXTLATCH_fall;
					end if;
					
				when EXTLATCH_fall =>
					i := i+1;
					if i = 1  then	
						i:= 0;
						ADClatch <= '0';
						STATE <= RAMPDONE;
					end if;
			-------------------------
				when RAMPDONE =>
					RAMP_DONE <= '1';
					--CLEAR <= '1';
					--RAMP <= '0';
					--ROen <= '0';
					--ADClatch <= '1';
			-------------------------
				when others =>
					STATE <= INIT;
			end case;
		end if;
	end process;
	
	ADClatch_select <= ADClatch;
	xRO_enable <= ROen;
	xRAMP <= RAMP;
	xRAMPDONE <= RAMP_DONE;
	xCLEARADC <= CLEAR;
	
end Behavioral;
				
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- e oberla                                                                  --
-- DATE: Jan. 2011                                                           --
-- PROJECT: psTDC_3 tester firmware                                          --
-- NAME: READ_RAM                                                            --
-- Description:                                                              --
--      read -> memory                                                       --
--    -- fullchannel psec3																	 --
--    --                                                                     --
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity READ_RAM_4 is
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
			xCLK_EN		: out	std_logic;	
			xTOK_IN1	: out	std_logic;
			xTOK_IN2	: out	std_logic;
			xCHAN_SEL	: out	std_logic_vector(2 downto 0);
			xBLOCK_SEL	: out	std_logic_vector(2 downto 0);
			xSTART		: out	std_logic);		--USB start
--			xREADDONE	: out	std_logic);
	end READ_RAM_4;
	
architecture Behavioral of READ_RAM_4 is
	type STATE_TYPE is (IDLE, INSERT_TOK, WAIT_TOK, WRITE_RAM, DONE);
	signal STATE		:	STATE_TYPE;
-------------------------------------------------------------------------------
-- SIGNALS
-------------------------------------------------------------------------------
	signal W_EN			: 	std_logic;
	signal W_EN_temp	: 	std_logic;
	signal WADDR		:	std_logic_vector(10 downto 0);
	signal WADDR_temp	:	std_logic_vector(10 downto 0);
	signal CNT			: 	std_logic_vector(6 downto 0);
	signal START		:	std_logic;
	signal CHAN_SEL		:	std_logic_vector(2 downto 0);
	signal TOKIN1		: 	std_logic;
	signal TOKIN2		: 	std_logic;
	signal TOK_CNT		:	std_logic_vector(1 downto 0);
--	signal TOKOUT1		: 	std_logic
--	signal TOKOUT2		: 	std_logic
	signal BLKSEL		:  	std_logic_vector(2 downto 0);
	signal CLK_EN		:	std_logic;
-------------------------------------------------------------------------------
-- COMPONENTS
-------------------------------------------------------------------------------
	component RAM_12bit
	port( 	xW_EN		: in	std_logic;
			xR_EN		: in	std_logic;
			xWRAM_CLK	: in	std_logic;
			xRRAM_CLK	: in 	std_logic;
			xWR_ADDRESS	: in	std_logic_vector(10 downto 0);
			xRD_ADDRESS	: in	std_logic_vector(10 downto 0);
			xWRITE		: in	std_logic_vector(11 downto 0);
			dat_overflow: in	std_logic;
			xREAD		: out	std_logic_vector(12 downto 0));
	end component;
-------------------------------------------------------------------------------
begin   ---behavioral
-------------------------------------------------------------------------------	
	xSTART <= START;
	xTOK_IN1 <= TOKIN1;
	xTOK_IN2 <= TOKIN2;
	xCHAN_SEL <= CHAN_SEL;
	xBLOCK_SEL <= BLKSEL;
	xW_EN <= W_EN;
	xCLK_EN <= CLK_EN;
--	xREADDONE <= READDONE;
	
	process(TOK_CNT)   
	begin
		if TOK_CNT = 0 then
			TOKIN1 <= '0';
			TOKIN2 <= '0';
		elsif TOK_CNT = 1 then
			TOKIN1 <= '1';
			TOKIN2 <= '0';
		elsif TOK_CNT = 2 then
			TOKIN1 <= '0';
			TOKIN2 <= '1';
		else
			TOKIN1 <= '0';
			TOKIN2 <= '0';
		end if;
	end process;
-----------------------------------------------------------------------------	
	process(xRD_CLK)
	--variable d : integer range 0 to 10;
	begin
	
		if xDONE = '1' or xCLR_ALL = '1' then
			TOK_CNT <= "00";
			W_EN	<= '0';
			W_EN_temp <= '0';
			WADDR_temp	<= (others => '0');
			WADDR <= (others => '0');
			CHAN_SEL<= "000";
			CNT		<= "0000000";
			BLKSEL 	<= "101"; -- clear token
			START <= '0';
			CLK_EN <= '0';
			STATE	<= IDLE;
		
		elsif falling_edge(xRD_CLK) and xRAMPDONE = '1' then
		--elsif falling_edge(xRD_CLK) then --power test
			case STATE is
				when IDLE =>
					BLKSEL <= "001";
					CLK_EN <= '1';
					CHAN_SEL <= CHAN_SEL + 1;
					STATE <= INSERT_TOK;
					
				when INSERT_TOK =>
					if CHAN_SEL = "111" then
						STATE <= DONE;
					elsif BLKSEL = "101" then
						STATE <= IDLE;
					else
						if CHAN_SEL = "110" or CHAN_SEL = "100" or CHAN_SEL = "101" then
							TOK_CNT <=  "10";
							STATE <= WAIT_TOK;
						else
							TOK_CNT <= "01";
							STATE <= WAIT_TOK;
						end if;
					end if;
						
				when WAIT_TOK =>
					TOK_CNT <= "00";
					W_EN_temp <= '1';
					STATE <= WRITE_RAM;
					
				when WRITE_RAM=>	
					WADDR_temp <= WADDR_temp + 1;
					CNT <= CNT + 1;
					if CNT = 63 then    -- read out blocks of 64 at a time
						W_EN_temp <= '0';
						CNT <= (others=>'0');
						BLKSEL <= BLKSEL + 1;
						STATE <= INSERT_TOK;
					end if;				
					
				when DONE =>
					CLK_EN <= '0';
					START <= '1';
					
				when others =>
					STATE <= IDLE;
				
			end case;
		--end if;
	--end process;
	
--	process(xRD_CLK)
--	begin
		elsif rising_edge(xRD_CLK) and xRAMPDONE = '1' then
			WADDR <= WADDR_temp;
			W_EN <= W_EN_temp;
		end if;
	end process;
	
	xRAM_12bit : RAM_12bit
	port map(
			xW_EN		=> W_EN,
			xR_EN		=> xR_EN,
			xWRAM_CLK	=> not(xRD_CLK),
			xRRAM_CLK   => xRAM_CLK,
			xWR_ADDRESS => WADDR,
			xRD_ADDRESS	=> xRD_ADDRESS,
			xWRITE		=> xDATIN,
			dat_overflow=> dat_overflow,
			xREAD		=> xDATOUT);
			
end Behavioral;
					
					
					
		
	
	
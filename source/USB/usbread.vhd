 --------------------------------------------------------------------------------
--edited by: EJO																				--
--FEB 2010																							--
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity USBread is
   port ( xIFCLK     		: in    std_logic;
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
			xDLL_RESET		: out	std_logic;
	      xPED_SCAN			: out   std_logic_vector (11 downto 0);
	      xTRIG_RESET		: out	std_logic;
	      xTRIG_SIGN		: out	std_logic;
	      xTRIG_ENABLE		: out	std_logic;
			xTRIG_MASK			: out std_logic_vector(5 downto 0);
	      xSAMPLE_SPEED		: out	std_logic;
		  xDEBUG 		  	: out   std_logic_vector (15 downto 0);
          xTOGGLE   		: out   std_logic);
end USBread;

architecture BEHAVIORAL of USBread is
	type State_type is(st1_WAIT,
							st1_READ, st2_READ, st3_READ,st4_READ,
							st1_SAVE, st1_TARGET, ENDDELAY);
	signal state: State_type;
	signal dbuffer			: std_logic_vector (15 downto 0);
	signal Locmd			: std_logic_vector (15 downto 0);
	signal Hicmd			: std_logic_vector (15 downto 0);
	signal again			: std_logic_vector (1 downto 0);
	signal TOGGLE			: std_logic;
	signal SOFT_TRIG		: std_logic;
	signal DLL_RESET		:	std_logic;
	signal TRIG_RESET		:	std_logic;
	signal TRIG_SIGN		:	std_logic;
	signal SAMPLE_SPEED		:	std_logic;
	signal TRIG_ENABLE		:	std_logic;
	signal TRIG_MASK			: std_logic_vector(5 downto 0);
	signal DEBUG	    	: std_logic_vector (15 downto 0);
	signal PED_SCAN    		: std_logic_vector (11 downto 0);
	signal SYNC_USB			: std_logic;
	signal SLRD				: std_logic;
	signal SLOE				: std_logic;
	signal RBUSY			: std_logic;
	signal FIFOADR    		: std_logic_vector (1 downto 0);
	--signal TX_LENGTH     	: std_logic_vector (13 downto 0);
--------------------------------------------------------------------------------
begin
--------------------------------------------------------------------------------
	xTOGGLE 	<= TOGGLE;
	xSOFT_TRIG 	<= SOFT_TRIG;
	xDLL_RESET	<=	DLL_RESET;
	xTRIG_RESET	<=	TRIG_RESET;
	xTRIG_SIGN	<= 	TRIG_SIGN;
	xTRIG_ENABLE<=  TRIG_ENABLE;
	xTRIG_MASK <= TRIG_MASK;
	xSAMPLE_SPEED<=	SAMPLE_SPEED;
	xDEBUG 		<= DEBUG;
	xPED_SCAN 	<= PED_SCAN;
	xSYNC_USB 	<= SYNC_USB;
	xSLRD 		<= SLRD;
	xSLOE 		<= SLOE;
	xRBUSY 		<= RBUSY;
	xFIFOADR 	<= FIFOADR;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
	process(xIFCLK, xRESET)
	variable delay : integer range 0 to 10;
	begin
		if xRESET = '0' then
			SYNC_USB		<= '0';
			SOFT_TRIG	<= '0';
			DLL_RESET	<=	'0';
			TRIG_RESET 	<= '0'; --clear internal trig on startup
			TRIG_SIGN	<= '1'; --sign=1 => (-) pulse 
			DEBUG			<= (others=>'0');
			PED_SCAN		<= x"800"; --(others=>'0');
			SAMPLE_SPEED	<= '0';
			TRIG_ENABLE		<= '0';
			TRIG_MASK		<= "000000";
			SLRD 			<= '1';
			SLOE 			<= '1';
			FIFOADR 		<= "10";
			TOGGLE 		<= '0';
			again 		<= "00";
			RBUSY 		<= '1';
			delay 		:= 0;	
			state       <= st1_WAIT;
		elsif rising_edge(xIFCLK) then
			SLOE 			<= '1';
			SLRD 			<= '1';			
			FIFOADR 		<= "10";
			TOGGLE 		<= '0';
			SOFT_TRIG	<= '0';
			DLL_RESET	<=	'0';
			TRIG_RESET  <= '0';
			RBUSY 		<= '1';
--------------------------------------------------------------------------------				
			case	state is	
--------------------------------------------------------------------------------
				when st1_WAIT =>
					RBUSY <= '0';						 
					if xFLAGA = '1' then	
						RBUSY <= '1';
						if xWBUSY = '0' then		
							RBUSY <= '1';
							state <= st1_READ;
						end if;
					end if;		 
--------------------------------------------------------------------------------		
				when st1_READ =>
					FIFOADR <= "00";	
					TOGGLE <= '1';		
					if delay = 2 then
						delay := 0;
						state <= st2_READ;
					else
						delay := delay +1;
					end if;
--------------------------------------------------------------------------------					
				when st2_READ =>	
					FIFOADR <= "00";
					TOGGLE <= '1';
					SLOE <= '0';
					if delay = 2 then
						delay := 0;
						state <= st3_READ;
					else
						delay := delay +1;
					end if;				
--------------------------------------------------------------------------------						
				when st3_READ =>					
					FIFOADR <= "00";
					TOGGLE <= '1';
					SLOE <= '0';
					SLRD <= '0';
					dbuffer <= xUSB_DATA;
					if delay = 2 then
						delay := 0;
						state <= st4_READ;
					else
						delay := delay +1;
					end if;					
--------------------------------------------------------------------------------					   
				when st4_READ =>					
					FIFOADR <= "00";
					TOGGLE <= '1';
					SLOE <= '0';
					if delay = 2 then
						delay := 0;
						state <= st1_SAVE;
					else
						delay := delay +1;
					end if;				
--------------------------------------------------------------------------------	
				when st1_SAVE	=>
					FIFOADR <= "00";
					TOGGLE <= '1';	
--------------------------------------------------------------------------------						
					case again is 
						when "00" =>	
							again <="01";	
							Locmd <= dbuffer;
							state <= ENDDELAY;
--------------------------------------------------------------------------------	
						when "01" =>
							again <="00";	
							Hicmd <= dbuffer;	
							state <= st1_TARGET;
--------------------------------------------------------------------------------	
						when others =>				
							state <= st1_WAIT;
					end case;
--------------------------------------------------------------------------------	
				when st1_TARGET =>
					RBUSY <= '0';
					case Locmd(7 downto 0) is
--------------------------------------------------------------------------------
-----------       Software People only care about this part :-p    -------------
--------------------------------------------------------------------------------
						when x"01" =>	--USE SYNC signal
							SYNC_USB <= Hicmd(0); 
							state <= st1_WAIT;		--HICMD "XXXX-XXXX-XXXX-XXXD"
							
						when x"02" =>	--SOFT_TRIG
							SOFT_TRIG <= '1';	 		
							state <= st1_WAIT;		--HICMD =>"XXX-XXXX-XXXX-XXXX"
						
						when x"03" =>	--PED_SCAN
							PED_SCAN <=  Hicmd(11 downto 0);	
							state <= st1_WAIT;		--HICMD =>"XXX-DDDD-DDDD-DDDD"
												
						when x"04" =>	--DLL_RESET
							DLL_RESET <= '1';	 		
							state <= st1_WAIT;		--HICMD =>"XXX-XXXX-XXXX-XXXX"

						when x"05" =>	--DLL_RESET
							TRIG_RESET <= '1';	 		
							state <= st1_WAIT;		--HICMD =>"XXX-XXXX-XXXX-XXXX"

						when x"06" =>	--DLL_RESET
							TRIG_SIGN <= Hicmd(0);	 		
							state <= st1_WAIT;		--HICMD =>"XXX-XXXX-XXXX-XXXX"

						when x"07" =>	--DLL_RESET
							SAMPLE_SPEED <= Hicmd(0);	 		
							state <= st1_WAIT;		--HICMD =>"XXX-XXXX-XXXX-XXXX"
							
						when x"08" =>	--DLL_RESET
							TRIG_ENABLE <= Hicmd(0);	
							TRIG_MASK <= Hicmd(6 downto 1);
							state <= st1_WAIT;		--HICMD =>"XXX-XXXX-XXXX-XXXX"
							
						when x"FF" =>	--W_STRB
							DEBUG <= Hicmd(15 downto 0);
							state <= st1_WAIT;		--HICMD "DDDD-DDDD-DDDD-DDDD"
							
--------------------------------------------------------------------------------
-----------       Software People stop caring at this point  ^_^   -------------
--------------------------------------------------------------------------------
						when others =>
							state <= st1_WAIT;
					end case;
--------------------------------------------------------------------------------	
				when ENDDELAY =>	
					FIFOADR <= "00"; 
					if delay = 2 then
						if xFLAGA = '1' then
							delay := 0;
							state <= st1_READ;
						else
							delay := 0;
							state <= st1_WAIT;
						end if;
					else
						delay := delay +1;
					end if;
--------------------------------------------------------------------------------						
				when others =>
					state <= st1_WAIT;
			end case;	  
		end if;
	end process;
--------------------------------------------------------------------------------	
end Behavioral;

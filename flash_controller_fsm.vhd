----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:53:01 08/27/2014 
-- Design Name: 
-- Module Name:    write_new - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity fsm is
port(   A 					: out   std_logic_vector (18 downto 0);

	operation_counter			: out   std_logic_vector (39 downto 0);
			  
	LED,DQ 					: out 	std_logic_vector (7 downto 0);
			  
	dout, DfromF				: in 	std_logic_vector (7 downto 0); 
			  
	CE, OE, 
	WE, outen, 	
	tx_start_r, 
	send_time				: out   std_logic;	  
          
	clk, rst, 
	tx_done, 
	tx_done_tick_r,				
	rx_done_tick				: in 	std_logic
			  
			  );
end fsm;

architecture Behavioral of fsm is

	type state_type is  (	IDLE, COMMAND, OPERATION, DATA, 

				WRITE0, WRITE1, WRITE2, WRITE3,
								
				WRITE4, READY0, READY1,READY2,
								
				READY3, READY4, READY5,ADDINC, 
								
				READ0, READ1, READSETUP, READSETUP1,
								
				TRANSMIT0,TRANSMIT1,TRANSMIT2, SEND_TIMING
	
								);
													
	signal state, operation_state, previous_operation: state_type;
	

	type array_type is array(0 to 6) of std_logic_vector(18 downto 0);

	constant block_addr : array_type := (	"1111100000000000000",	-- Block addresses to erase
						"1111010000000000000",
						"1111000000000000000",
						"1100000000000000000",
						"1000000000000000000",
						"0100000000000000001",
						"0000000000000000000"
						);


	signal operation_counter_reg 	:  std_logic_vector(39 downto 0) := (others => '0'); 	-- Timing counter for program/erase operation
	
	signal count  			:  std_logic_vector(31 downto 0) := (others => '0'); 	-- counter for state machine
	
	signal Pre_A  			:  std_logic_vector(18 downto 0) := (others => '0'); 	-- Address register
	
	signal DQ_reg			:  std_logic_vector(7 downto 0)	 := (others => '0'); 	-- register for flash program/erase operation setup and data 
	
	signal setup 			:  std_logic_vector(7 downto 0)	 := (others => '0'); 	-- setup register for erase operation
	
	signal dtow 			:  std_logic_vector(7 downto 0)  := (others => '0'); 	-- data register for program operation
	
	signal cmd			:  std_logic_vector(7 downto 0)	 := (others => '0'); 	-- cmd register to store the command coming from serial port
	
	signal LED_reg			:  std_logic_vector(7 downto 0)	 := (others => '0'); 	-- LED register to store state of the operation 
												-- and data coming from Flash to display 
												-- and send to serial interface 
	signal DfromF_reg	 	:  std_logic_vector(7 downto 0)  := (others => '0'); 	-- Register for the data coming from Flash memory 
	
	signal block_cnt 		:  std_logic_vector(3 downto 0)  := (others => '0'); 	-- counter for indexing the block_addr array 
	
	signal address_select 		:  std_logic := '0';					-- register for selecting the address between write,read and erase



	
	begin
		
		process (clk, rst)
			begin
				
				if(rst = '1') then
						state <= IDLE;
						
				elsif (rising_edge(clk)) then
					case state is
						when IDLE => 	
											CE <= '1';
											OE <= '1';
											WE <= '1';
											outen <= '0';
											state <= COMMAND;
											send_time<= '0';
											tx_start_r <= '0';
											address_select <= '0';
											operation_state  <= READ0;
											previous_operation <= IDLE;		
											DQ_reg <= (others => '0');	
											DfromF_reg<= (others => '0');
											count <= (others => '0');
											Pre_A  <= (others => '0');
											block_cnt <= (others => '0');
											operation_counter_reg<= (others => '0');
											LED_reg<= (others => '0');
						
	-------------------------------------------------------------------------------------------------------				
	-------------------------------------------------------------------------------------------------------
	---------------------------------------- Wait For Command ---------------------------------------------
	-------------------------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------------------------
						when COMMAND => -- Recieve the command from serial port										
											if(previous_operation = IDLE) then LED_reg<= X"00";
											elsif(previous_operation = READ0) then LED_reg<= X"01";
											else LED_reg<= DfromF_reg; end if;
											
											if(rx_done_tick = '1') then cmd <= dout; state <= DATA;
											else  state <= COMMAND; end if;
						
						when DATA => -- Recieve the data for write or erase verify command for erase operation
											if(rx_done_tick = '1') then
												dtow <= dout;
												state <= OPERATION;
											else 
												state <= DATA;
												
											end if;					
										
						when OPERATION => -- Select the operation depending on the command recieved in the COMMAND state
											if(cmd = "01000101") then  
												state <= WRITE0;
												operation_state <= WRITE0;
												setup <= X"20";
												address_select <= '1';
												Pre_A  <= block_addr(CONV_INTEGER(block_cnt));
												
											elsif(cmd = "01010111") then  
												state <= WRITE0;
												operation_state <= WRITE0;
												setup <= X"40";
												address_select <= '0';
												Pre_A <= "0000000000000000000";
												
											elsif(cmd = "01010010") then
												if(previous_operation = WRITE0) then state <= READSETUP;
												else state <= READ0; end if;
												
												operation_state <= READ0;
												address_select <= '0';
												Pre_A <= "0000000000000000000";
												
											else 
												state <= OPERATION;
												
											end if;
											
	-------------------------------------------------------------------------------------------------------										
	-------------------------------------------------------------------------------------------------------
	----------------------------------- Write and Erase States --------------------------------------------
	-------------------------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------------------------								
						when WRITE0 => 
											CE <= '1';
											OE <= '1';
											WE <= '1';
											outen <= '0';
											send_time <= '0';
											operation_state <= operation_state;
											address_select <= address_select;
											if(count = 5) then 
												state <= WRITE1; count <= (others => '0');
											else 
												if(address_select = '1') then
													Pre_A  <= block_addr(CONV_INTEGER(block_cnt));
												else 
													Pre_A <= Pre_A;
												end if;
												state <= WRITE0; count <= count + 1;
												
											end if;
											
						
						when WRITE1 =>
											CE <= '0';
											OE <= '1';
											WE <= '0';
											outen <= '1';
											DQ_reg<= setup;
											Pre_A  <= Pre_A;
											address_select <= address_select;
											operation_state <= operation_state;
											if(count = 5) then 
												state <= WRITE2; count <= (others => '0');
											else 
												state <= WRITE1; count <= count + 1;
											end if;
											
						when WRITE2 =>
											CE <= '1';
											OE <= '1';
											WE <= '1';
											outen <= '1';
											DQ_reg<= setup;
											Pre_A  <= Pre_A;
											address_select <= address_select;
											operation_state <= operation_state;
											if(count = 5) then 
												state <= WRITE3; count <= (others => '0');
											else 
												state <= WRITE2; count <= count + 1;
											end if;
						
						when WRITE3 =>
											CE <= '0';
											OE <= '1';
											WE <= '0';
											outen <= '1';
											DQ_reg<= dtow;
											Pre_A  <= Pre_A;
											address_select <= address_select;
											operation_state <= operation_state;
											if(count = 5) then 
												state <= WRITE4; count <= (others => '0');
											else 
												state <= WRITE3; count <= count + 1;
											end if;						
						when WRITE4 =>
											CE <= '1';
											OE <= '1';
											WE <= '1';
											DQ_reg<= dtow;
											outen <= '1';										
											Pre_A  <= Pre_A;
											address_select <= address_select;
											operation_state <= operation_state;
											if(count = 5) then 
												state <= READY0; count <= (others => '0');
											else 
												state <= WRITE4; count <= count + 1;
											end if;	
											
						
						when READY0 =>
											operation_counter_reg <= operation_counter_reg+ '1';
											CE <= '0';
											OE <= '0';
											WE <= '1';
											outen <= '0';
											Pre_A  <= Pre_A;
											state <= READY1;
											address_select <= address_select;
											operation_state <= operation_state;
											
						when READY1 =>
											operation_counter_reg <= operation_counter_reg+ '1';
											CE <= '0';
											OE <= '0';
											WE <= '1';
											outen <= '0';
											Pre_A  <= Pre_A;
											state <= READY2;
											address_select <= address_select;
											operation_state <= operation_state;
						
						when READY2 =>
											operation_counter_reg <= operation_counter_reg+ '1';
											CE <= '0';
											OE <= '0';
											WE <= '1';
											outen <= '0';
											DfromF_reg <= DfromF;
											LED_reg <= DfromF;
											Pre_A  <= Pre_A;
											state <= READY3;
											address_select <= address_select;
											operation_state <= operation_state;
											
						when READY3 =>
											operation_counter_reg <= operation_counter_reg+ '1';
											CE <= '0';
											OE <= '0';
											WE <= '1';
											outen <= '0';
											DfromF_reg <= DfromF;
											LED_reg <= DfromF;
											Pre_A  <= Pre_A;
											state <= READY4;
											address_select <= address_select;
											operation_state <= operation_state;
						
						when READY4 =>
											operation_counter_reg <= operation_counter_reg+ '1';
											CE <= '0';
											OE <= '0';
											WE <= '1';
											outen <= '0';
											DfromF_reg <= DfromF;
											LED_reg <= DfromF;
											Pre_A  <= Pre_A;
											state <= READY5;
											address_select <= address_select;
											operation_state <= operation_state;
											if(count = 1) then
												state <= READY5; count <= (others => '0');
											else 
												state <= READY4; count <= count + 1;
											end if;
						
						when READY5 =>
											operation_counter_reg <= operation_counter_reg+ '1';
											CE <= '1';
											OE <= '1';
											WE <= '1';
											outen <= '0';
											Pre_A  <= Pre_A;
											DfromF_reg <= DfromF_reg;
											LED_reg<= LED_reg;
											address_select <= address_select;
											operation_state <= operation_state;
											if(DfromF(7) = '1') then 
												state <= ADDINC;
											else
												state <= READY0;
											end if;
											
	-------------------------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------------------------
	----------------------------------- Read Operation States ---------------------------------------------
	-------------------------------------------------------------------------------------------------------				
	-------------------------------------------------------------------------------------------------------				
						when READ0 => 		
												CE <= '1';
												OE <= '1';
												WE <= '1';
												outen <= '0';											
												tx_start_r <= '0'; 
												Pre_A  <= Pre_A;
												address_select <= address_select;
												operation_state <= operation_state;
											if(count = 100000000) then 
												state <= READ1;
												count <= (others => '0'); 
											else 
												state <= READ0; 
												count <= count + 1;
											end if;
						
						when READSETUP =>  -- if read after erase or write happens, place  read setup command FF						
												CE <= '0';
												OE <= '1';
												WE <= '0';
												DQ_reg <= X"FF";
												Pre_A  <= Pre_A;
												address_select <= address_select;
												operation_state <= operation_state;
												if(count = 5) then 
													state <= READSETUP1; count <= (others => '0');
												else 
													state <= READSETUP; count <= count + 1;
												end if;
						
						when READSETUP1 =>
												CE <= '1';
												OE <= '1';
												WE <= '1';
												outen <= '0';											
												tx_start_r <= '0'; 
												Pre_A  <= Pre_A;
												address_select <= address_select;
												operation_state <= operation_state; 
												state <= READ1;
											
						when READ1 => 
												CE <= '0';
												OE <= '0';
												WE <= '1';
												tx_start_r <= '0';
												outen <= '0';											
												LED_reg <= DfromF;
												Pre_A  <= Pre_A;	
												state <= TRANSMIT0; 
												address_select <= address_select;
												operation_state <= operation_state;
												if(count = 7) then 
													state <= TRANSMIT0; 
													count <= (others => '0'); 
												else 
													state <= READ1; 
													count <= count + 1;
												end if;
					
						when TRANSMIT0 =>
												CE <= '1';
												OE <= '1';
												WE <= '1';
												tx_start_r <= '0'; 
												outen <= '0';											
												LED_reg <= LED_reg;											
												Pre_A  <= Pre_A;
												state <= TRANSMIT1;
												address_select <= address_select;
												operation_state <= operation_state;
						
						when TRANSMIT1 =>
												CE <= '1';
												OE <= '1';
												WE <= '1';
												tx_start_r <= '1';
												outen <= '0';											
												LED_reg <= LED_reg;
												Pre_A  <= Pre_A;
												state <= TRANSMIT2;
												address_select <= address_select; 
												operation_state <= operation_state;
											
						when TRANSMIT2 =>
											if(tx_done_tick_r = '1') then 
												state <= ADDINC;
											else 
												state <= TRANSMIT2;
												CE <= '1';
												OE <= '1';
												WE <= '1';
												outen <= '0';											
												LED_reg<= LED_reg;
												tx_start_r <= '0';
												Pre_A  <= Pre_A;
												address_select <= address_select;
												operation_state <= operation_state;
											end if;
											
	-------------------------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------------------------
	------------------------- Increase the address for Read, Write and Erase ------------------------------
	-------------------------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------------------------
						when ADDINC =>								
											CE <= '1';
											OE <= '1';
											WE <= '1';
											outen <= '0';											
											operation_counter_reg <= operation_counter_reg;
											previous_operation <= operation_state;
											if (address_select = '1') then
												if(block_cnt = "0111") then
													state <= SEND_TIMING;
													block_cnt <= (others => '0');
												else
													state <= WRITE0;
													block_cnt <= block_cnt + 1;
												end if;
											else
												if(Pre_A = "1111111111111111111") then
												
													if(operation_state = WRITE0) then state <= SEND_TIMING; Pre_A <= (others => '0');
													else state <= COMMAND; Pre_A <= (others => '0'); end if;
												
												else
									
													if(operation_state = READ0) then Pre_A  <= Pre_A + 1; state <= READ1;
													else Pre_A  <= Pre_A + 1; state <= WRITE0; end if;
													
												end if;
											end if;
						
						
						when SEND_TIMING =>
											if(tx_done = '1') then
												CE <= '1';
												OE <= '1';
												WE <= '1';
												state <= COMMAND;
												send_time <= '0';
												operation_counter_reg <= (others => '0');
																				
											else 
												outen <= '1';
												send_time <= '1';
												state <= SEND_TIMING;											
												LED_reg <= DfromF_reg;
												operation_counter_reg <= operation_counter_reg;
											end if;					

						
						when others => 
											CE <= '1';
											OE <= '1';
											WE <= '1';
											outen <= '0';
											state <= IDLE;
											send_time<= '0';
											tx_start_r <= '0';
											address_select <= '0';
											operation_state  <= READ0;
											previous_operation <= IDLE;		
											DQ_reg <= (others => '0');	
											DfromF_reg<= (others => '0');
											count <= (others => '0');
											Pre_A  <= (others => '0');
											block_cnt <= (others => '0');
											operation_counter_reg<= (others => '0');
											LED_reg<= (others => '0');
											
											
					end case;
				end if;
		end process;
		

		

		A <= Pre_A;
		DQ <= DQ_reg;
		LED <= LED_reg;
		operation_counter <= operation_counter_reg;
		
end Behavioral;


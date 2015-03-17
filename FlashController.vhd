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

entity FlashController is
port(      A 			: out   	std_logic_vector (18 downto 0);
			  DQ 			: inout 	std_logic_vector (7 downto 0);
			  LED		 	: out   	std_logic_vector (7 downto 0);
			  CE 			: out   	std_logic;
           OE 			: out   	std_logic;
           WE 			: out   	std_logic;           
           RP 			: out   	std_logic;
			  WP 			: out   	std_logic;
			  BYTE		: out   	std_logic;
			  TxD			: out 	std_logic;
			  RxD			: in 		std_logic;
			  clk 		: in 	  	std_logic;
			  rst 		: in    	std_logic);
end FlashController;

architecture Behavioral of FlashController is

signal counter  			:  std_logic_vector(39 downto 0)	:= (others => '0');
signal dout 				:  std_logic_vector(7 downto 0)	:= (others => '0');
signal DfromF	  			:  std_logic_vector(7 downto 0)  := (others => '0');
signal din		 			:  std_logic_vector(7 downto 0)	:= (others => '0');
signal D_TX	  				:  std_logic_vector(7 downto 0)  := (others => '0');
signal DQtemp				:  std_logic_vector(7 downto 0)	:= (others => '0');
signal LED_reg				:  std_logic_vector(7 downto 0)	:= (others => '0');
signal outen				:	std_logic;
signal tx_start 			:  std_logic;
signal tx_start_r 		:  std_logic;
signal tx_start_t 		:  std_logic;
signal start_send			:  std_logic;
signal tx_done				:  std_logic;
signal s_tick 	 			:  std_logic;
signal tx_done_tick		:  std_logic;
signal tick 	 			:  std_logic; 
signal rx_done_tick		:  std_logic;
signal tx_done_tick_r	:	std_logic;
signal tx_done_tick_t	:	std_logic;
signal address_select 	:  std_logic;




	COMPONENT fsm
	port(   A 					: out   	std_logic_vector (18 downto 0);
			  counter			: out    std_logic_vector (39 downto 0);
			  DQ					: out 	std_logic_vector (7 downto 0);
			  dout				: in 		std_logic_vector (7 downto 0);
			  DfromF				: in 		std_logic_vector (7 downto 0);
			  LED					: out 	std_logic_vector (7 downto 0);
			  CE 					: out   	std_logic;
           OE 					: out   	std_logic;
           WE 					: out   	std_logic;           
			  tx_start_r		: out   	std_logic;
			  start_send		: out   	std_logic;
			  rx_done_tick		: in 		std_logic;
			  tx_done_tick_r	: in 		std_logic;
			  tx_done			: in 		std_logic;		  			  
			  outen				: out   	std_logic;
			  clk 				: in 	  	std_logic;
			  rst 				: in    	std_logic);
	end component;		

	COMPONENT uart_tx
	PORT (
			clk 			: in std_logic;
			reset			: in std_logic;
			tx_start    : in std_logic;
			s_tick		: in std_logic;
			din			: in std_logic_vector(7 downto 0);
			tx				: out std_logic;
			tx_done_tick: out std_logic
			);
	end component;
	
	COMPONENT uart_rx
	PORT (
			clk 			: in std_logic;
			reset			: in std_logic;
			s_tick		: in std_logic;
			dout			: out std_logic_vector(7 downto 0);
			rx				: in std_logic;
			rx_done_tick: out std_logic
			);
	end component;

	
	COMPONENT mod_m_counter 
	PORT (
			clk 		: in std_logic;
			reset 	: in std_logic;
			tick 		: out std_logic);
	end component;
	
	COMPONENT Conv5x8 
	PORT (
			clk			: in std_logic;
			control 		: in std_logic;
			tx_done_tick: in std_logic;
			reset			: in std_logic;
			roout			: in std_logic_vector(39 downto 0);
			adout			: out std_logic_vector(7 downto 0);
			tx_start		: out std_logic;
			tx_done		: out std_logic);
	end COMPONENT;
	
begin
	

	
	rx: uart_rx PORT MAP(
			clk => clk,
			reset => rst,
			dout => dout,
			rx => RxD,
			rx_done_tick => rx_done_tick,
			s_tick => tick
			);

	
	tx: uart_tx PORT MAP(
			clk => clk,
			reset => rst,
			tx_start => tx_start,
			din	=> D_TX,
			tx => TxD,
			tx_done_tick => tx_done_tick,
			s_tick => tick
			);
	
	baud: mod_m_counter PORT MAP(
			clk => clk,
			reset => rst,
			tick => tick
			);
			
	conv: Conv5x8	PORT MAP(
			clk => clk,
			reset => rst,
			tx_done_tick => tx_done_tick_t,
			control => start_send,
			roout => counter,
			adout => din,
			tx_start => tx_start_t,
			tx_done => tx_done
			);
	
	state_machine: fsm PORT MAP(
			clk 				=> clk,
			rst  				=> rst,
			CE   				=> CE,
			OE   				=> OE,
			WE   				=> WE,
			A 					=> A,
			DfromF 			=> DfromF,
			dout 				=> dout,
			DQ 				=> DQtemp,
			outen 			=> outen,
			counter 			=> counter,
			status 			=> status_reg,		
			tx_start_r 		=> tx_start_r,
			start_send 		=> start_send,
			tx_done 			=> tx_done,
			rx_done_tick 	=> rx_done_tick,
			tx_done_tick_r => tx_done_tick_r
			);
			

	PROCESS (outen, DQtemp, tx_start_r, tx_start_t, tx_done_tick, din, LED_reg) -- Behavioral representation of tri-states.
        BEGIN                    	   
        IF( outen = '0') THEN
		  
				DQ 				<= (others => 'Z');
				DfromF   		<= DQ;
				D_TX 				<= LED_reg;							
				tx_start 		<= tx_start_r;
				tx_done_tick_r <= tx_done_tick;
			
		  ELSE 
		  
				D_TX 				<= din;
				DQ 				<= DQtemp;
				tx_start 		<= tx_start_t;
				tx_done_tick_t <= tx_done_tick;

        END IF;
    END PROCESS;

	BYTE 	 <= '0';
	WP  	 <= '1';
	RP		 <= '1';
	LED 	 <= LED_reg;	
	
end Behavioral;


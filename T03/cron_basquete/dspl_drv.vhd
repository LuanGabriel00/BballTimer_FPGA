-------------------------------------------------------------------------------
--  File: dspl_drv\SRC\dspl_drv.vhd
--
--  Created by Ney Calazans in 05/03/2008 15:30:00
--	Last modified in 23/08/2025
--
-- 	This module implements the interface hardware needed to drive some 
--		FPGA Boards 4-digit, 7-segment display. The display is 
--		multiplexed (see the specific board Reference Manual for details), 
--		requiring that just one digit be displayed at any instant.
--		Examples boards that employ this display are D2SB/DIO4, 
--		the Spartan3 Starter Kit and The Digilent Nexys and Nexys 2 boards.
--	Observation:
--		An 8-digit version of this driver is also available, as required 
--		for boards such as the Digilent Nexys A7 or similar boards.
-- 
--	The inputs of the module are:
--		clock - the 50MHz system board clock
--		reset - the active-high system reset signal
--		4 di vectors - vectors, each with 6 bits, where:
--			di(0) is the decimal point (active-low)
--			di(4 downto 1) is the binary value of the digit
--			di(5) is the (active-high) enable signal of the digit
--      The index i in the di varies from 0 to 3. If the chosen pin constraints
--			are kept standard (in the .ucf or corresponding file),
--			0 corresponds to the rightmost digit of the display and
--			3 corresponds to the leftmost digit. 
-- 
--	The outputs of the module are:
--		an (3 downto 0) - the 4-wire, active-low, anode control vector.
--			For this circuit, exactly one of these 4 wires is at logic 0
--			at any moment. The wire at '0' switches on the corresponding 
--			7-segment digit and switchs off the other three digits.
--		dec_ddp (7 downto 0) - is the decoded value of the digit to show
--			at the current instant. dec_ddp(7 downto 1)  corresponds
--			respectively to the segments a b c d e f g, and dec_ddp(0) is
--			the decimal point. 
--
-- Functional description: The (assumed) 50MHz clock is divided to obtain the
--		1KHz display refresh clock (process Ck1KHz_gen). Upon reset, all
--		digits are turned off. The 1KHz clock feeds a process (Digit_choice).
--		This process creates a 2-bit Johnson counter (dig_selection), 
--		to cycle through all digits (Order is 00, 01, 11, 10). The counter
--		is employed to generate a signal to select one of the four di vectors
--		to light up the corresponding digit in the display, based on the
--		immediate value of the anode vector. The selected di vector enables
--		which digit to show or not (through bit di(5)), while bits 
--		di (4 downto 1) furnish the digit value for the single, multiplexed,
--		7-segment decoder (Muxed_4toHex_decod). 
--		Output an is registered using the 1KHz clock.
-------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
--use work.cron_dec.all;
--use work.rom.all; --dividir vetor rom em 2 vet de 4

entity dspl_drv is
	port (
		dsp_clock: in STD_LOGIC;
		dsp_reset: in STD_LOGIC;
		dsp_d3: in STD_LOGIC_VECTOR (5 downto 0);
		dsp_d2: in STD_LOGIC_VECTOR (5 downto 0);
		dsp_d1: in STD_LOGIC_VECTOR (5 downto 0);
		dsp_d0: in STD_LOGIC_VECTOR (5 downto 0);
		dsp_an: out STD_LOGIC_VECTOR (3 downto 0);
		dsp_dec_ddp: out STD_LOGIC_VECTOR (7 downto 0)
		
	);
end dspl_drv;

--}} End of automatically maintained section

architecture dspl_drv of dspl_drv is
signal ck_1KHz: std_logic;
signal dig_selection: std_logic_vector (1 downto 0);
signal selected_dig: std_logic_vector (4 downto 0);

begin
	-- 1KHz clock generation
	Ck1KHz_gen:
		process (dsp_reset, dsp_clock)
		variable count_25K: integer range 0 to 25000;
		begin
			if dsp_reset='1' then
				count_25K := 0;
				ck_1KHz <= '0';
			elsif (dsp_clock'event and dsp_clock='1') then
				count_25K := count_25K + 1;
				if (count_25K = 24999) then
					count_25K := 0;
					ck_1KHz <= not ck_1KHz;
				end if;
			end if;
		end process;

Digit_choice : process (dsp_reset, ck_1KHz)
	begin
		if dsp_reset='1' then
			dig_selection <= (others => '0'); 
			dsp_an <= (others => '1'); 					-- Disable all displays
		elsif (ck_1KHz'event and ck_1KHz='1') then
			-- a 2-bit Johnson counter		
			dig_selection <= dig_selection(0)  & not dig_selection (1);
			
			if dig_selection="00" then
			    selected_dig <= dsp_d0(4 downto 0);
			    dsp_an <= "111"  & (not dsp_d0(5));
			elsif dig_selection="01" then
			    selected_dig <= dsp_d1(4 downto 0);
			    dsp_an <= "11" & (not dsp_d1(5)) & "1";
			elsif dig_selection="10" then
			    selected_dig <= dsp_d2(4 downto 0);
			    dsp_an <= "1"  & (not dsp_d2(5)) & "11";
			else
			    selected_dig <= dsp_d3(4 downto 0);
			    dsp_an <= (not dsp_d3(5)) & "111";
			end if;
		end if; 
	end process;
	
	-- Driver state machine: Produces the counter dig_selection used to
	--	choose the digit to show at any moment (just one at a time)
--ShowDisplay:
--process (reset, ck_1KHz)
--
--	
--end process;
--	
-- The 4bit-to-Hexadecimal decoder
Muxed_4toHex_decod:
	with selected_dig (4 downto 1) select
	dsp_dec_ddp(7 downto 1) <=
		"0000001" when "0000", -- draws a 0 digit
		"1001111" when "0001", -- draws a 1 digit
		"0010010" when "0010", -- draws a 2 digit
		"0000110" when "0011", -- draws a 3 digit
		"1001100" when "0100", -- draws a 4 digit
		"0100100" when "0101", -- draws a 5 digit
		"0100000" when "0110", -- draws a 6 digit
		"0001111" when "0111", -- draws a 7 digit
		"0000000" when "1000", -- draws a 8 digit
		"0000100" when "1001", -- draws a 9 digit
		"0001000" when "1010", -- draws a A digit
		"1100000" when "1011", -- draws a B digit
		"0110001" when "1100", -- draws a C digit
		"1000010" when "1101", -- draws a D digit
		"0110000" when "1110", -- draws a E digit
		"0111000" when others; -- draws a F digit

	-- and the decimal point
	dsp_dec_ddp(0) <= selected_dig(0);

end dspl_drv;
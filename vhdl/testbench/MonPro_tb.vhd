--Test bench for monpro

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;

entity MonPro_tb is
	end MonPro_tb;

architecture bahavioral of MonPro_tb is

	--Helper function that waits n amount of falling edges
	procedure wait_until_n_falling_edges(
											signal clk_signal : in std_logic;
											n : in positive) is
	begin
		for i in 1 to n loop
			wait until falling_edge(clk_signal);
		end loop;
	end procedure;

	--Helper function that waits n amount of falling edges
	procedure wait_until_n_rising_edges(
										   signal clk_signal : in std_logic;
										   n : in positive) is
	begin
		for i in 1 to n loop
			wait until rising_edge(clk_signal);
		end loop;
	end procedure;

	--Clock parameters
	constant CLK_PERIOD : time := 10ns;

	constant k : integer := 128;

	signal clk         : std_logic := '0';
	signal resetn      : std_logic := '0';
	signal start       : std_logic;
	signal a           : std_logic_vector(k -1 downto 0);
	signal b           : std_logic_vector(k -1 downto 0);
	signal n           : std_logic_vector(k -1 downto 0);
	signal done        : std_logic;
	signal u           : std_logic_vector(k -1 downto 0);

	--File for test data
	constant testdata_filename : string := "../../../../../testbench/monpro_testdata.txt";
	file testdata_file : TEXT;


	-- Function for converting string of hex to std_logic_vector
	function str_to_stdvec(inp: string) return std_logic_vector is
	variable temp: std_logic_vector(4*inp'length-1 downto 0) := (others => 'X');
	variable temp1 : std_logic_vector(3 downto 0);

	begin 
		for i in  inp'range loop
			case inp(i) is 
				when '0' => 
					temp1 := x"0";
				when '1' => 
					temp1 := x"1";         
				when '2' => 
					temp1 := x"2";         
				when '3' => 
					temp1 := x"3";         
				when '4' => 
					temp1 := x"4";                    
				when '5' => 
					temp1 := x"5";         
				when '6' => 
					temp1 := x"6";         
				when '7' => 
					temp1 := x"7";         
				when '8' => 
					temp1 := x"8";         
				when '9' => 
					temp1 := x"9";         
				when 'A' => 
					temp1 := x"A";         
				when 'B' => 
					temp1 := x"B";         
				when 'C' => 
					temp1 := x"C";         
				when 'D' => 
					temp1 := x"D";         
				when 'E' => 
					temp1 := x"E";         
				when 'F' => 
					temp1 := x"F";         
				when others =>
					temp1 := "XXXX";                  
			end case;
			temp(4*(i-1)+3 downto 4*(i-1)) := temp1;                                         
		end loop;
		return temp;
	end function str_to_stdvec;   
begin
	-- Connect dut
	dut : entity work.MonPro
	port map (
				 clk         => clk,          
				 resetn      => resetn,       
				 start       => start,        
				 a           => a,            
				 b           => b,            
				 n           => n,            
				 done        => done,         
				 u           => u            
			 );

	-- Clock generation
	clk <= not clk after CLK_PERIOD/2;


	-- Stimuli
	stimuli_proc: process
		-- Variables for file input
		variable a_file, b_file, n_file, result_file : std_logic_vector(k-1 downto 0);
		variable l : LINE;
		variable s32: string(k/4 downto 1);          
		variable char_dump : character;
        variable error_counter : integer := 0;
        variable test_counter : integer := 0;
	begin
		-- Test with different clk periods between start and done
        for i in 0 to 2 loop
             --report "Running tests with " & integer'image(i) & " clocks delay"  severity error;
            file_open(testdata_file, testdata_filename,  read_mode);
            -- reset the system
            resetn <= '0';

            wait_until_n_falling_edges(clk, 2);
            resetn <= '1';
            while not ENDFILE(testdata_file) loop


                --Set data on input
                readline(testdata_file, l);
                read(l, s32);
                a <= str_to_stdvec(s32);
                --Read space
                read(l, char_dump);
                read(l, s32);
                b <= str_to_stdvec(s32);
                read(l, char_dump);
                read(l, s32);
                n <= str_to_stdvec(s32);
                read(l, char_dump);
                read(l, s32);
                result_file := str_to_stdvec(s32);


                wait_until_n_rising_edges(clk, i);

                start <= '1';
                wait_until_n_rising_edges(clk, 1);
                start <= '0';

                wait until done = '1';

                -- Check output
                if (u /= result_file) then
                    error_counter := error_counter + 1;
                    report "Result not correct, with " & integer'image(i) & " clocks delay"  severity error;
                end if;

				test_counter := test_counter + 1;


            end loop;
			-- Closes the file so it can be read again
            file_close(testdata_file);
        end loop;

		--End simulation 
        if (error_counter = 0) then
		    assert false report "Test successful all results correct" severity failure;
        else
		    assert false report "Test failed with " & integer'image(error_counter) & " wrong results" severity failure;
        end if;
	end process;



end;

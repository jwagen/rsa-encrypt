--Test bench for monpro

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

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
    constant RESET_TIME : time := 10ns;

    constant k : integer := 128;

    signal clk         : std_logic := '0';
    signal resetn      : std_logic := '0';
    signal start       : std_logic;
    signal a           : std_logic_vector(k -1 downto 0);
    signal b           : std_logic_vector(k -1 downto 0);
    signal n           : std_logic_vector(k -1 downto 0);
    signal done        : std_logic;
    signal u           : std_logic_vector(k -1 downto 0);

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

    -- Reset
    reset_proc: process
    begin
        wait for RESET_TIME;
        resetn <= '1';
        wait;
    end process;

    -- Stimuli
    stimuli_proc: process
    begin
        a <= x"0000_0000_0000_0000_0000_0000_0000_0003";
        b <= x"0000_0000_0000_0000_0000_0000_0000_0003";
        n <= x"0000_0000_0000_0000_0000_0000_0000_0007";
        
        wait until resetn = '1';

        wait_until_n_falling_edges(clk, 2);

        start <= '1';
        wait_until_n_falling_edges(clk, 1);
        start <= '0';

        wait until done = '1';

        wait_until_n_falling_edges(clk, 5);
        


        --End simulation 
		assert false report "Test complete" severity failure;
    end process;



end;

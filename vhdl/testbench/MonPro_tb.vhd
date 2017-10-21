--Test bench for monpro

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MonPro_tb is
end MonPro_tb;

architecture bahav of MonPro_tb is
    --Clock parameters
    constant CLK_PERIOD : time := 10ns;
    constant RESET_TIME : time := 10ns;

    signal clk         : in std_logic := '0';
    signal resetn      : in std_logic := '0';
    signal start       : in std_logic;
    signal a           : in std_logic_vector(k downto 0);
    signal b           : in std_logic_vector(k downto 0);
    signal n           : in std_logic_vector(k downto 0);
    signal done        : out std_logic;
    signal u           : out std_logic_vector(k downto 0);

begin
    -- Connect dut
    dut : entity work.Monpro
        port map (
            clk         => clk,          
            resetn      => resetn,       
            start       => start,        
            a,          => a,            
            b,          => b,            
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
    stimuli_proc: precess
    begin
        wait for RESET_TIME;

        wait for CLK_PERIOD;

        start <= '1';
        wait for CLK_PERIOD;
        start <= '0';
        wait for 127*CLK_PERIOD;

        assert done = '1'report "Done not 1 after full count" severity failure;
        


        --End simulation 
		assert false report "Test complete" severity failure;
    end process;



end architecture;

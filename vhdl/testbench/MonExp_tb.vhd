--Test bench for monexp

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MonExp_tb is
end MonExp_tb;

architecture bahavioral of MonExp_tb is
    --Clock parameters
    constant CLK_PERIOD : time := 10ns;
    constant RESET_TIME : time := 10ns;

    constant k : integer := 128;

    signal clk         : std_logic := '0';
    signal resetn      : std_logic := '0';
    signal start       : std_logic;
    signal M           : std_logic_vector(k -1 downto 0);
    signal e           : std_logic_vector(k -1 downto 0);
    signal n           : std_logic_vector(k -1 downto 0);
    signal r           : std_logic_vector(k -1 downto 0);
    signal r_2         : std_logic_vector(k -1 downto 0);
    signal done        : std_logic;
    signal output      : std_logic_vector(k -1 downto 0);

begin
    -- Connect dut
    dut : entity work.MonExp
        port map (
            clk         => clk,          
            resetn      => resetn,       
            start       => start,        
            M           => M,     
            e           => e,     
            n           => n,     
            r           => r,     
            r_2         => r_2,   
            done        => done,  
            output      => output   
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
        wait for 1*RESET_TIME;
        M <= x"0000_0000_0000_0000_0000_0000_0000_0003";
        e <= x"0000_0000_0000_0000_0000_0000_0000_0003";
        n <= x"0000_0000_0000_0000_0000_0000_0000_000b";
        r <= x"0000_0000_0000_0000_0000_0000_0000_0003";
        r_2 <= x"0000_0000_0000_0000_0000_0000_0000_0003";
        wait for 1*CLK_PERIOD;

        start <= '1';
        wait for 1*CLK_PERIOD;
        start <= '0';
        --wait for 130*CLK_PERIOD;

        assert done = '1'report "Done not 1 after full count" severity failure;
        


        --End simulation 
		assert false report "Test complete" severity failure;
    end process;

end;

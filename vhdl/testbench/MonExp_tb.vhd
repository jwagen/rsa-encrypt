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
        start <= '0';
        wait for 1*RESET_TIME;
       
        
        M <=   x"0AAA AAAA AAAA AAAA AAAA AAAA AAAA AAAA";
        e <=   x"0000 0000 0000 0000 0000 0000 0001 0001";
        n <=   x"819D C6B2 574E 12C3 C8BC 49CD D795 55FD";
        r <=   x"4F4F 353B 16D9 B17C D307 F02F 3937 34D9";
        r_2 <= x"7E62 394D A8B1 ED3C 3743 B632 286A AA03";
        wait for 1*CLK_PERIOD;

        start <= '1';
        wait for 1*CLK_PERIOD;
        start <= '0';
        
        wait until done = '1';
        --End simulation 
		assert false report "Test complete" severity failure;
    end process;

end;

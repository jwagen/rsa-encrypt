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
        M <=   x"0ddddddddddddddddddddddddddddddd";
        e <=   x"00000000000000000000000000010001";
        n <=   x"819DC6B2574E12C3C8BC49CDD79555FD";
        r <=   x"7E62394DA8B1ED3C3743B632286AAA03";
        r_2 <= x"4F4F353B16D9B17CD307F02F393734D9";
        
        wait for 1*CLK_PERIOD;

        start <= '1';
        wait for 1*CLK_PERIOD;
        start <= '0';
        
        wait until done = '1';
        --End simulation 
		assert false report "Test complete" severity failure;
    end process;

end;

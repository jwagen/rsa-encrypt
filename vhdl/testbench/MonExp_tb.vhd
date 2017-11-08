--Test bench for monexp

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.RSAParameters.all;
use work.CompDecl.all;

library std;
use std.textio.all;

entity MonExp_tb is
    end MonExp_tb;

architecture bahavioral of MonExp_tb is
    --Clock parameters
    constant CLK_PERIOD : time := 10ns;
    constant RESET_TIME : time := 10ns;

    constant msg_length_bits : integer := 128;

    signal clk         : std_logic := '0';
    signal resetn      : std_logic := '0';
    signal start       : std_logic;
    signal M           : std_logic_vector(msg_length_bits -1 downto 0);
    signal e           : std_logic_vector(msg_length_bits -1 downto 0);
    signal n           : std_logic_vector(msg_length_bits -1 downto 0);
    signal r           : std_logic_vector(msg_length_bits -1 downto 0);
    signal r_2         : std_logic_vector(msg_length_bits -1 downto 0);
    signal done        : std_logic;
    signal output      : std_logic_vector(msg_length_bits -1 downto 0);


    -- File input
    type   ComFileType  is array(natural range <>) of std_logic_vector(15 downto 0);
    constant ComFileName : string :="ComFile.txt";  
    file ComFile: TEXT open read_mode is ComFileName;


    function str_to_stdvec(inp: string) return std_logic_vector is
    variable temp: std_logic_vector(4*inp'length-1 downto 0) := (others => 'X');
    variable temp1 : std_logic_vector(3 downto 0);
    begin 
        for i in inp'range loop
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
        variable l: line;
        variable s1: string(1 downto 1);  
        variable s32: string(W_BLOCK/4 downto 1);      
        variable s64: string(2*W_BLOCK/4 downto 1);          
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

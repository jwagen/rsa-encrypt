-- Top level disign of rsa crpyto core


library ieee;
use ieee.std_logic_1164.all;


entity RSACore is
    generic(
    W_DATA           : Positive := 32 --TODO: Is this supposed to be gotten from somewhere else?
);
  port (    
  Clk              :  in std_logic;
  Resetn           :  in std_logic;
  InitRsa          :  in std_logic;
  StartRsa         :  in std_logic;
  DataIn           :  in std_logic_vector(W_DATA-1 downto 0);
  DataOut          :  out std_logic_vector(W_DATA-1 downto 0);
  CoreFinished     :  out std_logic        
);
end RSACore;
architecture circuit of RSACore is
    constant k : integer := 128;
    signal me_start       : std_logic;
    signal me_M           : std_logic_vector(k -1 downto 0);
    signal me_e           : std_logic_vector(k -1 downto 0);
    signal me_n           : std_logic_vector(k -1 downto 0);
    signal me_r           : std_logic_vector(k -1 downto 0);
    signal me_r_2         : std_logic_vector(k -1 downto 0);
    signal me_done        : std_logic;
    signal me_output      : std_logic_vector(k -1 downto 0);
begin
    me : entity work.MonExp
    port map (
        clk         => clk,          
        resetn      => resetn,       
        start       => me_start,        
        M           => me_M,     
        e           => me_e,     
        n           => me_n,     
        r           => me_r,     
        r_2         => me_r_2,   
        done        => me_done,  
        output      => me_output   
             );
end architecture;
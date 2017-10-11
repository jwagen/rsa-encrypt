
library ieee;
use ieee.std_logic_1164.all;
library work;
use work.RSAParameters.all;


package CompDecl is  
component RSACore is
  port (    
    Clk              :  in std_logic;
    Resetn           :  in std_logic;
    InitRsa          :  in std_logic;
    StartRsa         :  in std_logic;
    DataIn           :  in std_logic_vector(W_DATA-1 downto 0);
    DataOut          : out std_logic_vector(W_DATA-1 downto 0);
    CoreFinished     : out std_logic        
  );
end component RSACore;
component RSACoreTestBench is
end component RSACoreTestBench;
end CompDecl;

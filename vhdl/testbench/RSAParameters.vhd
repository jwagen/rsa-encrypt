library ieee;
use ieee.std_logic_1164.all;

package RSAParameters is

  constant W_BYTE: integer := 8;
  constant W_DATA : integer := 32; 
  constant W_BLOCK: integer := 4*W_DATA;
  constant W_BLOCK_LOG: integer:= 7;
  constant W_CTR_MAX: std_logic_vector(W_BLOCK_LOG-1 downto 0):= (others => '1');
  
  -- Commands 
  constant UC_PUSH_KEY        : std_logic_vector(W_BYTE-1 downto 0) := x"31";
  constant UC_PUSH_MESSAGE    : std_logic_vector(W_BYTE-1 downto 0) := x"32";
  constant UC_INIT            : std_logic_vector(W_BYTE-1 downto 0) := x"33";
  constant UC_ENCRYPT         : std_logic_vector(W_BYTE-1 downto 0) := x"34";
  constant UC_POP_RESULT      : std_logic_vector(W_BYTE-1 downto 0) := x"35";

end RSAParameters;





  

             
      
    
    

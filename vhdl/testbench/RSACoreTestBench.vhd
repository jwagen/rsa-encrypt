-- *****************************************************************************
-- Name:     RSACoreTestBench.vhd   
-- Project:  RSACore
-- Created:  03.10.04
-- Author:   Øystein Gjermundnes
-- Purpose:  A small testbench for the RSACore.
-- *****************************************************************************
library ieee;
use ieee.std_logic_1164.all;

library work;
use work.RSAParameters.all;
use work.CompDecl.all;

library std;
use std.textio.all;

entity RSACoreTestBench is
end RSACoreTestBench;

architecture struct of RSACoreTestBench is
  -- Change this constant to true if you are using the Montgomery method!
  constant C_MONTGOMERY : boolean := true;

  -- ---------------------------------------------------------------------------
  -- Signal declarations
  -- ---------------------------------------------------------------------------
  signal  Clk              :  std_logic;
  signal  Resetn           :  std_logic;
  signal  InitRsa          :  std_logic;
  signal  StartRsa         :  std_logic;
  signal  DataIn           :  std_logic_vector(W_DATA-1 downto 0);
  signal  DataOut          :  std_logic_vector(W_DATA-1 downto 0);
  signal  CoreFinished     :  std_logic;  
  
  type   ComFileType  is array(natural range <>) of std_logic_vector(15 downto 0);
  constant ComFileName : string :="ComFile.txt";  
  file ComFile: TEXT open read_mode is ComFileName;
  
  type CryptoStateType is (e_IDLE, e_READ_DATA, e_EXECUTE, e_INIT, e_ENCRYPT,
                           e_WAIT_INIT_FINISHED, e_WAIT_ENCR_FINISHED, 
                           e_STORE_CIPHERTEXT, e_VERIFY_RESULT, e_TEST_FINISHED);
                           
  signal CryptoState : CryptoStateType;
  
  constant MAXSHIFT : integer := 15;  
  signal ShiftCtr : integer range 0 to MAXSHIFT;
 
  signal R2RNE       : std_logic_vector(4*W_BLOCK-1 downto 0);
  signal PlainText   : std_logic_vector(W_BLOCK-1 downto 0);
  signal CipherText  : std_logic_vector(W_BLOCK-1 downto 0);
  signal Result      : std_logic_vector(W_BLOCK-1 downto 0);
  signal Command     : std_logic;
   
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

  -- Generates a 50MHz Clk
  CLKGEN: process is
  begin
    Clk <= '1';
    wait for 10 ns;
    Clk <= '0';
    wait for 10 ns;
  end process;
  
  -- Resetn generator
  RSTGEN: process is
  begin
    Resetn <= '0';
    wait for 20 ns;
    Resetn <= '1';
    wait;
  end process;
  
  -- CryptoCtrl
  -- Sends jobs to the encryption algorithm
  CryptoCtrl: process(Clk, Resetn)
    variable l: line;
    variable s1: string(1 downto 1);  
    variable s32: string(W_BLOCK/4 downto 1);      
    variable s64: string(2*W_BLOCK/4 downto 1);          
  begin  
    if (Resetn = '0') then
    
      -- RSACore signals
      InitRsa          <= '0';
      StartRsa         <= '0';
      DataIn           <= (others => '0');
    
      -- TB signals    
      CryptoState  <= e_IDLE;
      R2RNE        <= (others => '0');
      PlainText    <= (others => '0');
      CipherText   <= (others => '0');
      Result       <= (others => '0');
      Command      <= '0';
      ShiftCtr     <= 0;
   
    elsif (Clk'event and Clk='1') then
    
      -- Pulsed signals
      InitRsa  <= '0';
      StartRsa <= '0';      
      
      
      case CryptoState is
  
        -- Start the state machine
        when e_IDLE=>
          CryptoState <= e_READ_DATA;
          ShiftCtr <= 0;
        
        -- Read Configuration data
        when e_READ_DATA =>                    
          -- Read comment          
          readline(ComFile, l);
          
          -- Data to be encrypted/decrypted (128 bit)
          readline(ComFile, l);
          read(l, s32);                    
          PlainText      <= str_to_stdvec(s32);

          -- Encrypted/decrypted data (128 bit)
          readline(ComFile, l);
          read(l, s32);                                   
          CipherText     <= str_to_stdvec(s32);          
          
          -- N and E (128 bit + 128 bit)
          readline(ComFile, l);
          read(l, s64);                              
          R2RNE(2*W_BLOCK-1 downto 0) <= str_to_stdvec(s64);
		  
		  readline(ComFile, l);
		  if (C_MONTGOMERY) then
			-- R and R^2 (128 bit + 128 bit)
			read(l, s64); 
			R2RNE(4*W_BLOCK-1 downto 2*W_BLOCK) <= str_to_stdvec(s64);
          else
			R2RNE(4*W_BLOCK-1 downto 2*W_BLOCK) <= (others => '0');
		  end if;
		  
          -- Command (Init/Encrypt)
          -- 0: Init
          -- 1: Encrypt
          readline(ComFile, l);
          read(l, s1);                              
          Command        <= str_to_stdvec(s1)(0);
                  
          -- Read comment          
          readline(ComFile, l);

          -- Execute command
          CryptoState <= e_EXECUTE;                                      
                    
        -- Wait one cycle
        when e_EXECUTE =>
          if (Command = '0') then
            CryptoState <= e_INIT;                                      
            InitRsa <= '1';
            R2RNE <= R2RNE(W_DATA-1 downto 0) & R2RNE(4*W_BLOCK-1 downto W_DATA);
            DataIn <= R2RNE(W_DATA-1 downto 0);
            ShiftCtr <= ShiftCtr + 1;
          else
            CryptoState <= e_ENCRYPT;                         
            StartRsa <= '1';            
            PlainText <= PlainText(W_DATA-1 downto 0) & PlainText(W_BLOCK-1 downto W_DATA);
            DataIn <= PlainText(W_DATA-1 downto 0);
            ShiftCtr <= ShiftCtr + 1;            
          end if;
          
        -- Initialize 
        when e_INIT => 
          R2RNE <= R2RNE(W_DATA-1 downto 0) & R2RNE(4*W_BLOCK-1 downto W_DATA);
          DataIn <= R2RNE(W_DATA-1 downto 0);
          ShiftCtr <= ShiftCtr + 1;          
          if ((not C_MONTGOMERY and ShiftCtr = 7) or (C_MONTGOMERY and ShiftCtr = 15)) then
            CryptoState <= e_WAIT_INIT_FINISHED;                                   
            ShiftCtr <= 0;            
          end if;  
                            
        -- Send command
        when e_ENCRYPT =>                
          PlainText <= PlainText(W_DATA-1 downto 0) & PlainText(W_BLOCK-1 downto W_DATA);
          DataIn <= PlainText(W_DATA-1 downto 0);
          ShiftCtr <= ShiftCtr + 1;          
          if (ShiftCtr = 7) then
            CryptoState <= e_WAIT_ENCR_FINISHED; 
            ShiftCtr <= 0;
          end if;  
                    
        -- Wait for the initialization to finish
        when e_WAIT_INIT_FINISHED => 
          if (CoreFinished = '1') then
            CryptoState <= e_TEST_FINISHED;
          end if;  
          
        -- Wait for the initialization to finish
        when e_WAIT_ENCR_FINISHED => 
          if (CoreFinished = '1') then
            CryptoState <= e_STORE_CIPHERTEXT;
            Result <= DataOut & Result(W_BLOCK-1 downto W_DATA);
            ShiftCtr <= ShiftCtr + 1;                      
          end if;            
                           
        -- Send command
        when e_STORE_CIPHERTEXT =>   
          Result <= DataOut & Result(W_BLOCK-1 downto W_DATA);
          ShiftCtr <= ShiftCtr + 1;        
          if (ShiftCtr = 3) then
            CryptoState <= e_VERIFY_RESULT; 
            ShiftCtr <= 0;
          end if;  
                            
        -- Verify result
        when e_VERIFY_RESULT => 
          assert Result = CipherText
            report "Result differs from expected result"
            severity Error;
          CryptoState <= e_TEST_FINISHED;             
                       
        -- End testbench
        when others => -- e_TEST_FINISHED;
          if (endfile(ComFile)) then              
            assert true;
              report "Finished"
              severity Failure;                 
          else
            CryptoState <= e_IDLE;                                            
          end if;          
                                              
      end case;
    end if;  
  
  end process;
  
  
  R: RSACore
  port map(      
    Clk              => Clk, 
    Resetn           => Resetn,
    InitRsa          => InitRsa, 
    StartRsa         => StartRsa, 
    DataIn           => DataIn, 
    DataOut          => DataOut, 
    CoreFinished     => CoreFinished
  );  
  
 
    
end struct;  
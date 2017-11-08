-- Top level disign of rsa crpyto core

library ieee;
use ieee.std_logic_1164.all;

entity RSACore is
    generic(
    W_DATA           : Positive := 32; -- Size in bits of DataIn and DataOut, name keept the same as from handout testbench
    msg_length_bits  : integer := 128;
    nr_of_datapackets: integer := 4
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
    -- Setup constants
    constant msg_parts : integer := msg_length_bits/W_DATA;
    constant nr_of_msg_parts_in_datapackets : integer    := nr_of_datapackets*msg_parts;
    -- MonExp signals
    signal me_start       : std_logic;
    signal me_done        : std_logic;
    signal me_output      : std_logic_vector(msg_length_bits -1 downto 0);
    -- Control data
    type state is (INIT, LOADCONF, WAITFORMSG, LOADINGMSG, CALC, UNLOADANS);
    signal current_state  : state;
    signal next_state     : state;
    signal loop_counter   : natural range 0 to nr_of_msg_parts_in_datapackets-1;
    signal count          : std_logic;
    -- Config registers
    signal config_reg_en   : std_logic;
    signal e_r     : std_logic_vector(msg_length_bits-1 downto 0);
    signal n_r     : std_logic_vector(msg_length_bits-1 downto 0);
    signal r_r     : std_logic_vector(msg_length_bits-1 downto 0);
    signal r_2_r   : std_logic_vector(msg_length_bits-1 downto 0);
    -- Message register
    signal M_reg_en : std_logic;
    signal M_r      : std_logic_vector(msg_length_bits-1 downto 0);
    -- Output register
    signal result_r        : std_logic_vector(msg_length_bits-1 downto 0);
    Signal output_reg_en   : std_logic;
    Signal output_reg_load : std_logic;
begin
  -- ***************************************************************************
  -- Registers for configuration: e_r, n_r, r_r and r_2_r
  -- ***************************************************************************
  process (clk, resetn) begin
    if(resetn = '0') then
      e_r <= (others => '0');
      n_r <= (others => '0'); 
      r_r <= (others => '0');
      r_2_r <= (others => '0');     
    elsif rising_edge(clk) then
      if(config_reg_en = '1') then
        r_2_r <= DataIn & r_2_r(msg_length_bits-1 downto W_DATA);
        r_r <= r_2_r(W_DATA-1 downto 0) & r_r(msg_length_bits-1 downto W_DATA);
        n_r <= r_r(W_DATA-1 downto 0) & n_r(msg_length_bits-1 downto W_DATA);
        e_r <= n_r(W_DATA-1 downto 0) & e_r(msg_length_bits-1 downto W_DATA);      
      end if;
    end if;
  end process;
  -- ***************************************************************************
  -- Register for message: M_r
  -- ***************************************************************************
  process (clk, resetn) begin
    if(resetn = '0') then
      M_r <= (others => '0');    
    elsif rising_edge(clk) then
      if(M_reg_en ='1') then
        M_r <= DataIn & M_r(msg_length_bits-1 downto W_DATA);   
      end if;
    end if;
  end process;
  -- ***************************************************************************
  -- Register for output: result_r
  -- Logic for shifting the content of result_r to data_out
  -- ***************************************************************************
    process (clk, resetn) begin
      if(resetn = '0') then
        result_r <= (others => '0');     
      elsif rising_edge(clk) then
        if(output_reg_en ='1') then
            if(output_reg_load = '1') then
                result_r <= me_output;
            else
                result_r <= (W_DATA-1 downto 0 => '0') & result_r(msg_length_bits-1 downto W_DATA);
            end if;       
        end if;
      end if;
    end process;
    
    DataOut <= result_r(W_DATA-1 downto 0);
  -- ***************************************************************************
  -- Attaching the montgomery exponential calculating circuit
  -- ***************************************************************************
    me : entity work.MonExp
    port map (
        clk         => clk,          
        resetn      => resetn,       
        start       => me_start,        
        M           => M_r,     
        e           => e_r,     
        n           => n_r,     
        r           => r_r,     
        r_2         => r_2_r,   
        done        => me_done,  
        output      => me_output   
             );
  -- ***************************************************************************
  -- Counter circuit for controlling shifting in and out
  -- ***************************************************************************
     CounterProc : process (resetn, clk)
      begin
          if (resetn = '0') then
              loop_counter <= 0;
          elsif rising_edge(clk) then
              if count = '1' then 
                 loop_counter <= loop_counter + 1;
              else
                 loop_counter <= 0;
              end if;
          end if;
    end process CounterProc;
  -- ***************************************************************************
  -- FSM for controlling the whole circuit
  -- ***************************************************************************
     fsm_SynchProc : process (resetn, clk)
         begin
             if (resetn = '0') then
                 current_state <= INIT;
             elsif rising_edge(clk) then
                 current_state <= next_state;
             end if;
     end process fsm_SynchProc;
    fsm_CombProc : process (current_state, me_done, InitRsa, StartRsa, loop_counter)
         begin
             config_reg_en <= '0';
             output_reg_en <= '0';
             output_reg_load <= '0';
             me_start <= '0';
             M_reg_en <= '0';
             count <= '0';
             CoreFinished <= '1'; -- Only goes low when the circuit is working.
             next_state <= current_state;
             case (current_state) is
                 when INIT       =>     
                    
                    if InitRsa = '1' then
                        config_reg_en <= '1';
                        count <= '1';
                        next_state <= LOADCONF;
                    else
                        next_state <= INIT;
                    end if;
                 when LOADCONF   =>
                    CoreFinished <= '0';
                    config_reg_en <= '1';
                    count <= '1';
                    if loop_counter = nr_of_msg_parts_in_datapackets - 1 then
                        count <= '0';
                        next_state <= WAITFORMSG;
                    else
                        next_state <= LOADCONF;
                    end if;
                 when WAITFORMSG =>
                     if StartRsa = '1' then
                         M_reg_en <= '1';
                         next_state <= LOADINGMSG;
                     elsif InitRsa = '1' then
                         config_reg_en <= '1';
                         count <= '1';
                         next_state <= LOADCONF;
                     else
                         next_state <= WAITFORMSG;
                     end if;
                 when LOADINGMSG =>
                    CoreFinished <= '0';
                    M_reg_en <= '1';
                    count <= '1';
                    if loop_counter = msg_parts - 1 then
                        count <= '0';
                        M_reg_en <= '0';
                        me_start <= '1'; 
                        next_state <= CALC;
                    else
                        next_state <= LOADINGMSG;
                    end if;
                 when CALC       =>
                    CoreFinished <= '0';
                    if me_done = '1' then
                        next_state <= UNLOADANS;
                        output_reg_en <= '1';
                        output_reg_load <= '1';
                    else
                        next_state <= CALC;
                    end if;
                 when UNLOADANS  =>
                    output_reg_en <= '1';
                    count <= '1';
                    if loop_counter = msg_parts - 1 then
                        next_state <= WAITFORMSG;
                        output_reg_en <= '0';
                        count <= '0';
                    else
                        next_state <= UNLOADANS;
                    end if;
                 when others     =>
                    next_state <= INIT;
             end case;
    end process fsm_CombProc;
end architecture;
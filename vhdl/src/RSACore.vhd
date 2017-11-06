-- Top level disign of rsa crpyto core

--TODO:
-- * Should enter LOADCONF one cycle earlier
-- * Perhaps outputs should be changed/set when changing states, not in the states? Would fix both the one above and counters going one too far.
-- * Use rising_edge on InitRsa and StartRsa?
-- * Need to find out how to send the two extra parameters in simulation
-- * All states should be able to return to init(add if InitRsa to each statement)
-- * Trouble when reconfiguring?
-- * Change every clocked process to use rising_edge()


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
    --TODO: IN TESTBENCH ONLY 8 SENT, should change 2 to 4
    constant params : integer := 16; --TODO 4*k/W_DATA;  -- 4 params of 128bit, 4*128/32=16
    constant msg_parts : integer := k/W_DATA;
    -- MonExp signals
    signal me_start       : std_logic;
    signal me_done        : std_logic;
    signal me_output      : std_logic_vector(k -1 downto 0);
    -- Control data
    type state is (INIT, LOADCONF, WAITFORMSG, LOADINGMSG, STARTCALC, CALC, UNLOADANS);
    signal current_state  : state;
    signal next_state     : state;
    signal loop_counter   : natural range 0 to params-1 := 0;
    signal count          : std_logic;
    -- Config registers
    signal config_reg_en   : std_logic;
    signal e_r, e_nxt     : std_logic_vector(k-1 downto 0);
    signal n_r, n_nxt     : std_logic_vector(k-1 downto 0);
    signal r_r, r_nxt     : std_logic_vector(k-1 downto 0);
    signal r_2_r, r_2_nxt     : std_logic_vector(k-1 downto 0);
    -- Message registers
    signal M_reg_en   : std_logic;
    signal M_r, M_nxt     : std_logic_vector(k-1 downto 0);
    -- Output registers
    signal result_r, result_nxt: std_logic_vector(127 downto 0);
    Signal output_reg_en   : std_logic;
    Signal output_reg_load : std_logic;
begin

  -- Register e_r, n_r, r_r and r_2_r
  -- ***************************************************************************
  process (clk, resetn) begin
    if(resetn = '0') then
      e_r <= (others => '0');
      n_r <= (others => '0'); 
      r_r <= (others => '0');
      r_2_r <= (others => '0');     
    elsif rising_edge(clk) then
      if(config_reg_en ='1') then
        r_2_r <= DataIn & r_2_r(127 downto 32);
        r_r <= r_2_r(31 downto 0) & r_r(127 downto 32);
        n_r <= r_r(31 downto 0) & n_r(127 downto 32);
        e_r <= n_r(31 downto 0) & e_r(127 downto 32);      
      end if;
    end if;
  end process;
  -- ***************************************************************************
  -- Register M_r
  -- ***************************************************************************
  process (clk, resetn) begin
    if(resetn = '0') then
      M_r <= (others => '0');    
    elsif rising_edge(clk) then
      if(M_reg_en ='1') then
        M_r <= DataIn & M_r(127 downto 32);   
      end if;
    end if;
  end process;
-- ***************************************************************************
    -- Register result_r for outputing data
    -- Logic for shifting out the content of result_r to data_out
    -- ***************************************************************************
    process (clk, resetn) begin
      if(resetn = '0') then
        result_r <= (others => '0');     
      elsif rising_edge(clk) then
        if(output_reg_en ='1') then
            if(output_reg_load = '1') then
                result_r <= me_output;
            else
                result_r <= x"00000000" & result_r(127 downto 32);
            end if;       
        end if;
      end if;
    end process;
    
    process (result_r, me_output, output_reg_load) begin

    end process;
    DataOut <= result_r(31 downto 0);
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
         
     fsm_SynchProc : process (resetn, clk)
         begin
             if (resetn = '0') then
                 current_state <= INIT;
             elsif rising_edge(clk) then
                 current_state <= next_state;
                 if count = '1' then 
                    loop_counter <= loop_counter + 1;
                 else
                    loop_counter <= 0;
                 end if;
             end if;
    end process fsm_SynchProc;
    fsm_CombProc : process (current_state, me_done, InitRsa, StartRsa, loop_counter)-- TODO: Update this list
         begin
             case (current_state) is
                 when INIT       =>
                    output_reg_en <= '0';
                    output_reg_load <= '0';
                    config_reg_en <= '0';
                    CoreFinished <= '1';
                    count <= '0';
                    me_start <= '0';
                    M_reg_en <= '0';
                    if InitRsa = '1' then
                        config_reg_en <= '1';
                        count <= '1';
                        next_state <= LOADCONF;
                    else
                        next_state <= INIT;
                    end if;
                 when LOADCONF   =>
                    output_reg_en <= '0';
                    output_reg_load <= '0';
                    config_reg_en <= '1';
                    M_reg_en <= '0';
                    CoreFinished <= '0';
                    count <= '1';
                    me_start <= '0';
                    if loop_counter = params - 1 then
                        count <= '0';
                        next_state <= WAITFORMSG;
                    else
                        next_state <= LOADCONF;
                    end if;
                 when WAITFORMSG =>
                    output_reg_en <= '0';
                    output_reg_load <= '0';
                    config_reg_en <= '0';
                    CoreFinished <= '1';
                    count <= '0';
                    me_start <= '0';
                    M_reg_en <= '0';
                     if StartRsa = '1' then
                         M_reg_en <= '1';
                         next_state <= LOADINGMSG;
                     elsif InitRsa = '1' then -- TODO: Check this
                         config_reg_en <= '1';
                         count <= '1';
                         next_state <= LOADCONF;
                     else
                         next_state <= WAITFORMSG;
                     end if;
                 when LOADINGMSG =>
                    output_reg_en <= '0';
                    output_reg_load <= '0';
                    config_reg_en <= '0';
                    M_reg_en <= '1';
                    CoreFinished <= '0';
                    count <= '1';
                    me_start <= '0';
                    if loop_counter = msg_parts - 1 then
                        count <= '0';
                        M_reg_en <= '0';
                        next_state <= STARTCALC;
                    else
                        next_state <= LOADINGMSG;
                    end if;
                 when STARTCALC       =>
                    output_reg_en <= '0';
                    output_reg_load <= '0';
                    M_reg_en <= '0';
                    config_reg_en <= '0';
                    CoreFinished <= '0';
                    count <= '0';
                    me_start <= '1';
                    next_state <= CALC;
                 when CALC       =>
                    output_reg_en <= '0';
                    output_reg_load <= '0';
                    config_reg_en <= '0';
                    M_reg_en <= '0';
                    CoreFinished <= '0';
                    count <= '0';
                    me_start <= '0';
                    if me_done = '1' then
                        next_state <= UNLOADANS;
                        output_reg_en <= '1';
                        output_reg_load <= '1';
                    else
                        next_state <= CALC;
                    end if;
                 when UNLOADANS  =>
                    CoreFinished <= '1';
                    output_reg_en <= '1';
                    M_reg_en <= '0';
                    config_reg_en <= '0';
                    output_reg_load <= '0';
                    count <= '1';
                    me_start <= '0';
                    if loop_counter = msg_parts - 1 then
                        next_state <= WAITFORMSG;
                        output_reg_en <= '0';
                        count <= '0';
                    else
                        next_state <= UNLOADANS;
                    end if;
                 when others     => --Should NOT happen
                    next_state <= INIT;
                    output_reg_en <= '0';
                    output_reg_load <= '0';
                    M_reg_en <= '0';
                    config_reg_en <= '0';
                    count <= '0';
                    me_start <= '0';
                    CoreFinished <= '1';
             end case;
    end process fsm_CombProc;
    
end architecture;
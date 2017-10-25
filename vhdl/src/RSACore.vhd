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
    --TODO: IN TESTBENCH ONLY 8 SENT, should change 2 to 4
    constant params : integer := 16; --TODO 4*k/W_DATA;  -- 4 params of 128bit, 4*128/32=16
    constant msg_parts : integer := k/W_DATA;
    -- MonExp signals
    signal me_start       : std_logic;
    signal me_M           : std_logic_vector(k -1 downto 0);
    signal me_e           : std_logic_vector(k -1 downto 0);
    signal me_n           : std_logic_vector(k -1 downto 0);
    signal me_r           : std_logic_vector(k -1 downto 0);
    signal me_r_2         : std_logic_vector(k -1 downto 0);
    signal me_done        : std_logic;
    signal me_output      : std_logic_vector(k -1 downto 0);
    -- Control data
    type state is (INIT, LOADCONF, WAITFORMSG, LOADINGMSG, CALC, UNLOADANS);
    signal current_state: state;
    signal next_state: state;
    signal loop_counter : natural range 0 to params-1 := 0;
    signal count          : std_logic;
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
                    CoreFinished <= '1';
                    count <= '0';
                    if InitRsa = '1' then
                        next_state <= LOADCONF;
                    else
                        next_state <= INIT;
                    end if;
                 when LOADCONF   =>
                    CoreFinished <= '0';
                    count <= '1';
                    if loop_counter = params - 1 then
                        next_state <= WAITFORMSG;
                    else
                        next_state <= LOADCONF;
                    end if;
                 when WAITFORMSG =>
                    CoreFinished <= '1';
                    count <= '0';
                     if StartRsa = '1' then
                         next_state <= LOADINGMSG;
                     else
                         next_state <= WAITFORMSG;
                     end if;
                 when LOADINGMSG =>
                    CoreFinished <= '0';
                    count <= '1';
                    if loop_counter = msg_parts - 1 then
                        next_state <= CALC;
                    else
                        next_state <= LOADINGMSG;
                    end if;
                 when CALC       =>
                    CoreFinished <= '0';
                    count <= '0';
                    if me_done = '1' then
                        next_state <= UNLOADANS;
                    else
                        next_state <= CALC;
                    end if;
                 when UNLOADANS  =>
                    CoreFinished <= '1';
                    count <= '1';
                    if loop_counter = msg_parts - 1 then
                        next_state <= WAITFORMSG;
                    else
                        next_state <= UNLOADANS;
                    end if;
                 when others     => --Should NOT happen
                    next_state <= INIT;
             end case;
    end process fsm_CombProc;
end architecture;
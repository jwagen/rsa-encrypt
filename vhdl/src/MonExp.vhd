--Montgomery exponential calculation

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.numeric_std_unsigned.all;

entity MonExp is
    generic(
        k           : Positive := 128
    );
    port (
        clk         : in std_logic;
        resetn      : in std_logic;
        start       : in std_logic;
        M           : in std_logic_vector(k -1 downto 0);
        e           : in std_logic_vector(k -1 downto 0);
        n           : in std_logic_vector(k -1 downto 0);
        r           : in std_logic_vector(k -1 downto 0);
        r_2         : in std_logic_vector(k -1 downto 0);
        done        : out std_logic;
        output      : out std_logic_vector(k -1 downto 0)
    );
end MonExp; 

architecture circuit of MonExp is
    signal loop_counter : natural range 0 to k-1 := 0;
    type state is (IDLE, PREPARE, MONPROLOOP, POSTX, FINISHED); --TODO
    signal current_state: state;
    signal next_state: state;
    -- Connections to MonPro
    signal mp_start       : std_logic;
    signal mp_a           : std_logic_vector(k -1 downto 0);
    signal mp_b           : std_logic_vector(k -1 downto 0);
    signal mp_n           : std_logic_vector(k -1 downto 0);
    signal mp_done        : std_logic;
    signal mp_u           : std_logic_vector(k -1 downto 0);
    signal x_mon          : std_logic_vector(k -1 downto 0);
    signal M_mon          : std_logic_vector(k -1 downto 0);
    -- Counter signals
    signal reset_counter  : std_logic;
    signal increment_counter  : std_logic;
begin
    mp : entity work.MonPro
    port map (
        clk         => clk,          
        resetn      => resetn,       
        start       => mp_start,        
        a           => mp_a,            
        b           => mp_b,            
        n           => mp_n,            
        done        => mp_done,         
        u           => mp_u            
             );
    counterProc : process (clk, resetn, increment_counter, reset_counter) is
         begin
             if rising_edge(clk) then
                if resetn = '0' then
                    loop_counter <= 0;
                else
                    if reset_counter = '1' then
                        loop_counter <= 0;
                    else
                        if increment_counter = '1' then
                            loop_counter <= loop_counter + 1;
                        end if;
                    end if;
                end if;
             end if;
         end process counterProc;
    fsm_SynchProc : process (resetn, clk)
    begin
        if (resetn = '0') then
            current_state <= IDLE;
            --next_state <= IDLE;
            --output <= (others => '0');
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process fsm_SynchProc;
    
    fsm_CombProc : process (current_state, start, mp_done, M, n, e, r, r_2, loop_counter, M_mon, x_mon, mp_u)
    variable loop_double_monpro : std_logic;
    begin
        case (current_state) is
        when IDLE       =>
            loop_double_monpro := '0';
            reset_counter <= '1';
            increment_counter <= '0';
            output <= (others => '0');
            x_mon <= (others => '0');
            M_mon <= (others => '0');
            mp_a <= (others => '0');
            mp_b <= (others => '0');
            mp_n <= (others => '0');
            mp_start <= '0';
            done <= '0';
            if start = '1' then
                x_mon <= r;
                mp_a <= M;
                mp_b <= r_2;
                mp_n <= n;
                mp_start <= '1';
                next_state <= PREPARE;
            else
                next_state <= IDLE;
            end if;
        when PREPARE      =>
            loop_double_monpro := '0';
            reset_counter <= '0';
            increment_counter <= '0';
            output <= (others => '0');
            x_mon <= (others => '0'); --TODO, change to the ones above
            M_mon <= (others => '0'); --TODO, make M_mon and x_mon registers
            mp_a <= (others => '0');
            mp_b <= (others => '0');
            mp_n <= (others => '0');
            mp_start <= '0';
            done <= '0';
            if mp_done = '1' then
                M_mon <= mp_u; -- Maybe this should be moved
                mp_a <= x_mon;
                mp_b <= x_mon;
                mp_n <= n;
                mp_start <= '1';
                next_state <= MONPROLOOP;
            else
                next_state <= PREPARE;
            end if;
        when MONPROLOOP =>
            loop_double_monpro := '0';
            reset_counter <= '0';
            done <= '0';
            output <= (others => '0');
            x_mon <= (others => '0');
            M_mon <= (others => '0');
            mp_a <= (others => '0');
            mp_b <= (others => '0');
            mp_n <= (others => '0');
            mp_start <= '0';  -- TODO: Remove the ones with no effect from this
            if mp_done = '1' then
                x_mon <= mp_u;
                if (e(loop_counter) = '1') and (loop_double_monpro = '0')  then 
                    mp_a <= M_mon;
                    mp_b <= x_mon;
                    mp_n <= n;
                    mp_start <= '1';
                    loop_double_monpro := '1';  -- TODO: DELETE THIS WAITING, just for testing
                else
                    mp_a <= x_mon;
                    mp_b <= x_mon;
                    mp_n <= n;
                    mp_start <= '1';
                    loop_double_monpro := '0';
                end if;
                if loop_double_monpro = '1' then
                    increment_counter <= '0';
                else
                    increment_counter <= '1'; 
                end if;
            else
                mp_start <= '0'; -- Unnedeed
                increment_counter <= '1'; -- TODO: For testing, set this to 1, when monpro fixed, set to 0
            end if;
            if loop_counter = k-1 then 
                mp_a <= x_mon;
                mp_b <= (others => '0');
                mp_b(0) <= '1';
                mp_n <= n;
                mp_start <= '1';
                next_state <= POSTX;
                increment_counter <= '0';
            else
                next_state <= MONPROLOOP;
                
            end if;
        when POSTX      =>
            loop_double_monpro := '0';
            reset_counter <= '0';
            increment_counter <= '0';
            output <= (others => '0'); -- TODO: Change these to the ones above
            x_mon <= (others => '0');
            M_mon <= (others => '0');
            mp_a <= (others => '0');
            mp_b <= (others => '0');
            mp_n <= (others => '0');
            mp_start <= '0';
            done <= '0';
            if mp_done = '1' then
                done <= '1';
                output <= mp_u;
                next_state <= FINISHED;
            else
                next_state <= POSTX;
        end if;
        when FINISHED   =>
            loop_double_monpro := '0';
            reset_counter <= '0';
            increment_counter <= '0';
            output <= (others => '0');
            x_mon <= (others => '0');
            M_mon <= (others => '0');
            mp_a <= (others => '0');
            mp_b <= (others => '0');
            mp_n <= (others => '0');
            mp_start <= '0';
            done <= '1';
            next_state <= IDLE;
        when others     => --Should NOT happen
            loop_double_monpro := '0';
            reset_counter <= '0';
            increment_counter <= '0';
            output <= (others => '0');
            x_mon <= (others => '0');
            M_mon <= (others => '0');
            mp_a <= (others => '0');
            mp_b <= (others => '0');
            mp_n <= (others => '0');
            mp_start <= '0';
            done <= '0';
            next_state <= IDLE;
        end case;
    end process fsm_CombProc;
end architecture;

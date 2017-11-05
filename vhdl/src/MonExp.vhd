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
        clk             : in std_logic;
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
    type state is (IDLE, PREPARE, MONPROLOOP_FIRST, MONPROLOOP_SECOND, POSTX, FINISHED); --TODO
    signal current_state: state;
    signal next_state: state;
    -- Connections to MonPro
    signal mp_start           : std_logic;
    signal mp_a               : std_logic_vector(k -1 downto 0);
    signal mp_b               : std_logic_vector(k -1 downto 0);
    signal mp_n               : std_logic_vector(k -1 downto 0);
    signal mp_done            : std_logic;
    signal mp_u               : std_logic_vector(k -1 downto 0);
    -- x_ and M_ registers    
    signal x_q                : std_logic_vector(k -1 downto 0);  -- Corresponds to x_ in python script
    signal M_q                : std_logic_vector(k -1 downto 0);  -- Corresponds to M_ in python script
    signal x_d                : std_logic_vector(k -1 downto 0);
    signal M_d                : std_logic_vector(k -1 downto 0); 
    signal M_en               : std_logic;
    signal x_en               : std_logic;
    -- Counter signals
    signal reset_counter      : std_logic;
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
    regProc: process(clk, resetn)
     begin
         if resetn = '1' then
             x_q <= (others => '0');
             M_q <= (others => '0');
         elsif rising_edge(clk) then
             if x_en = '1' then
                 x_q <= x_d;
             end if;
             if M_en = '1' then
                 M_q <= M_d;
             end if;
         end if;
     end process regProc;
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
    
    fsm_CombProc : process (current_state, start, mp_done, M, n, e, r, r_2, loop_counter, M_q, x_q, mp_u)
    begin
        case (current_state) is
        when IDLE       =>
            reset_counter <= '1';
            increment_counter <= '0';
            output <= (others => '0');
            x_d <= (others => '0');
            M_d <= (others => '0');
            x_en <= '1';
            M_en <= '1';
            mp_a <= (others => '0');
            mp_b <= (others => '0');
            mp_n <= (others => '0');
            mp_start <= '0';
            done <= '0';
            if start = '1' then
                x_en <= '1';
                x_d <= r;
                mp_a <= M;
                mp_b <= r_2;
                mp_n <= n;
                mp_start <= '1';
                next_state <= PREPARE;
            else
                next_state <= IDLE;
            end if;
        when PREPARE      =>
            reset_counter <= '0';
            increment_counter <= '0';
            output <= (others => '0');
            M_d <= (others => '0');
            x_en <= '0';
            M_en <= '0';
            x_d <= r;
            mp_a <= M;
            mp_b <= r_2;
            mp_n <= n;
            mp_start <= '0';
            done <= '0';
            if mp_done = '1' then
                M_en <= '1';
                M_d <= mp_u; -- Maybe this should be moved
                mp_a <= x_q;
                mp_b <= x_q;
                mp_n <= n;
                mp_start <= '1';
                next_state <= MONPROLOOP_FIRST;
            else
                next_state <= PREPARE;
            end if;
        when MONPROLOOP_FIRST =>
            reset_counter <= '0';
            done <= '0';
            output <= (others => '0');
            x_en <= '0';
            M_en <= '0';
            x_d <= (others => '0');
            M_d <= (others => '0');
            mp_a <= (others => '0');
            mp_b <= (others => '0');
            mp_n <= (others => '0');
            mp_start <= '0';  -- TODO: Remove the ones with no effect from this
            if loop_counter = k-1 then 
                mp_a <= x_q;
                mp_b <= (others => '0');
                mp_b(0) <= '1';
                mp_n <= n;
                mp_start <= '1';
                next_state <= POSTX;
                increment_counter <= '0';
            --else
            --    next_state <= MONPROLOOP_FIRST;
            --end if;
            elsif mp_done = '1' then
                x_en <= '1';
                x_d <= mp_u;
                if (e(loop_counter) = '1') then 
                    mp_a <= M_q;
                    mp_b <= x_q;
                    mp_n <= n;
                    mp_start <= '1';
                    increment_counter <= '0';
                    next_state <= MONPROLOOP_SECOND;
                else
                    mp_a <= x_q;
                    mp_b <= x_q;
                    mp_n <= n;
                    mp_start <= '1';
                    increment_counter <= '1';
                end if;
            else
                next_state <= MONPROLOOP_FIRST;
                increment_counter <= '0'; -- TODO: For testing, set this to 1, when monpro fixed, set to 0
            end if;
        when MONPROLOOP_SECOND =>
            reset_counter <= '0';
            done <= '0';
            output <= (others => '0');
            x_en <= '0';
            M_en <= '0';
            x_d <= (others => '0');
            M_d <= (others => '0');
            mp_a <= (others => '0');
            mp_b <= (others => '0');
            mp_n <= (others => '0');
            mp_start <= '0';  -- TODO: Remove the ones with no effect from this
            if mp_done = '1' then
                x_en <= '1';
                x_d <= mp_u;
                mp_a <= x_q;
                mp_b <= x_q;
                mp_n <= n;
                mp_start <= '1';
                increment_counter <= '1';
                next_state <= MONPROLOOP_FIRST;
            else
                mp_start <= '0'; -- Unnedeed
                increment_counter <= '0'; -- TODO: For testing, set this to 1, when monpro fixed, set to 0
                next_state <= MONPROLOOP_SECOND;
            end if;
        when POSTX      =>
            reset_counter <= '0';
            increment_counter <= '0';
            output <= (others => '0');
            x_en <= '0';
            M_en <= '0';
            x_d <= (others => '0');
            M_d <= (others => '0');
            mp_a <= x_q;
            mp_b <= (others => '0');
            mp_b(0) <= '1';
            mp_n <= n;
            mp_start <= '0';
            done <= '0';
            if mp_done = '1' then
                x_en <= '1';
                x_d <= mp_u; -- TODO: May make this faster by returning mp_u on output?
                --done <= '1';
                output <= mp_u;
                next_state <= FINISHED;
            else
                next_state <= POSTX;
        end if;
        when FINISHED   =>
            reset_counter <= '0';
            increment_counter <= '0';
            x_en <= '0';
            M_en <= '0';
            output <= x_q;
            x_d <= (others => '0');
            M_d <= (others => '0');
            mp_a <= (others => '0');
            mp_b <= (others => '0');
            mp_n <= (others => '0');
            mp_start <= '0';
            done <= '1';
            next_state <= IDLE;
        when others     => --Should NOT happen
            reset_counter <= '0';
            increment_counter <= '0';
            output <= (others => '0');
            x_en <= '0';
            M_en <= '0';
            x_d <= (others => '0');
            M_d <= (others => '0');
            mp_a <= (others => '0');
            mp_b <= (others => '0');
            mp_n <= (others => '0');
            mp_start <= '0';
            done <= '0';
            next_state <= IDLE;
        end case;
    end process fsm_CombProc;
end architecture;

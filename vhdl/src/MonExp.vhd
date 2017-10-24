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
    fsm_SynchProc : process (resetn, clk)
    begin
        if (resetn = '1') then
            current_state <= IDLE;
            --next_state <= IDLE;
            loop_counter <= 0;
            output <= (others => '0');
            done <= '0';
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process fsm_SynchProc;
    
    fsm_CombProc : process (current_state)
    begin
        case (current_state) is
        when IDLE       =>
            if start = '1' then
                next_state <= PREPARE;
            else
                next_state <= IDLE;
            end if;
        when PREPARE      =>
            x_mon <= r;
            mp_a <= M;
            mp_b <= r_2;
            mp_n <= n;
            mp_start <= '1';
            if mp_done = '1' then
                M_mon <= mp_u; -- Maybe this should be moved
                next_state <= MONPROLOOP;
            else
                next_state <= PREPARE;
            end if;
        when MONPROLOOP =>
            done <= '1';
            next_state <= MONPROLOOP;
        when POSTX      =>
        when FINISHED   =>
        when others     => --Should NOT happen
            done <= '0';
            next_state <= IDLE;
        end case;
    end process fsm_CombProc;
end architecture;

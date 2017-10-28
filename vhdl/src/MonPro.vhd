--Montgomery product multiplier

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.numeric_std_unsigned.all;

-- Math operators
use IEEE.math_real."ceil";
use IEEE.math_real."log2";

entity MonPro is
    generic(
        k           : Positive := 128
    );
    port (
        clk         : in std_logic;
        resetn      : in std_logic;
        start       : in std_logic;
        a           : in std_logic_vector(k -1 downto 0);
        b           : in std_logic_vector(k -1 downto 0);
        n           : in std_logic_vector(k -1 downto 0);
        done        : out std_logic;
        u           : out std_logic_vector(k -1 downto 0)
    );
end MonPro;

architecture circuit of MonPro is
    type state_type is (LOOPING, SUBTRACTING, FINISHED, IDLE);
    signal current_state, next_state: state_type;
    

    signal u_next : std_logic_vector(k -1 downto 0);
    signal u_reg : std_logic_vector(k -1 downto 0);
    signal u_reg_next : std_logic_vector(k -1 downto 0);
    constant bits_in_k : integer := integer(ceil(log2(real(k))));
    signal loop_counter : natural range 0 to k-1 := 0;
    signal loop_counter_next : natural range 0 to k-1 := 0;
begin
    sync_proc: process (clk)
    begin
        if rising_edge(clk) then
            if resetn = '0' then
                current_state <= IDLE;
                loop_counter <= 0;

                u <= (others => '0');
                u_reg <= (others => '0');
            else
                current_state <= next_state;
                loop_counter <= loop_counter_next;

                u <= u_next;
                u_reg <= u_reg_next;

            end if;
        end if;
    end process;

    comb_proc: process (all)
    begin
        case (current_state) is
            when IDLE =>
                done <= '0';
                loop_counter_next <= 0;

                if start = '1' then
                    next_state <= LOOPING;
                else
                    next_state <= IDLE;
                end if;

            when LOOPING =>
                done <= '0';
                loop_counter_next <= loop_counter + 1;
                
                if loop_counter = k-2 then
                    next_state <= SUBTRACTING;
                else
                    next_state <= LOOPING;
                end if;

            when SUBTRACTING =>
                done <= '0';
                loop_counter_next <= 0;

                next_state <= FINISHED;

            when FINISHED =>
                done <= '1';
                loop_counter_next <= 0;

                next_state <= IDLE;

            when others =>
                next_state <= IDLE;
        end case;
    end process;

--    process(clk)
--    begin
--        -- Loop counter
--        if rising_edge(clk) then
--            if resetn = '0' then
--                -- Reset loop counter
--                loop_counter <= 0;
--                u <= (others => '0');
--            else
--                -- Initialize the system
--                if start = '1' then 
--                    loop_counter_done = '0';
--                    loop_counter_started <= '1';
--                end if;
--
--                -- Counter
--                if loop_counter_started = '1' then
--                    loop_counter <= loop_counter + 1;
--                end if;
--
--                -- Counter at max value
--                if loop_counter = k - 1 then
--                    loop_counter <= 0;
--                    loop_counter_started <= '0';
--                    loop_counter_done <= '1';
--                end if;
--                
--                -- TODO: Done should be delayed one clk cycle
--                if loop_counter_done = '1' then
--                    done <= '1';
--                    if u_reg >= n then
--                        u <= std_logic_vector(unsigned(u_reg) - unsigned(n));
--                    else
--                        u <= u_reg;
--                    end if;
--                else
--                    done <= '0';
--
--                end if;
--
--                u_reg <= u_reg_next;
--            end if;
--        end if;
--    end process;
--
--
-- Set done output
    process(all)
        variable u_temp1 : std_logic_vector(k -1 downto 0);
        variable u_temp2 : std_logic_vector(k -1 downto 0);
        variable u_temp3 : std_logic_vector(k -1 downto 0);
    begin
        if a(loop_counter) = '1' then
            u_temp1 := std_logic_vector(unsigned(u) + unsigned(b));
        else
            u_temp1 := u;
        end if;

        if u_temp1(0) = '1' then
            u_temp2 := std_logic_vector(unsigned(u_temp1) + unsigned(n));
        else
            u_temp2 := u_temp1;
        end if;


        u_reg_next <= '0' & u_temp2(k -1 downto 1);

        if current_state = SUBTRACTING then
            if u_reg >= n then
                u_next <= std_logic_vector(unsigned(u_reg) - unsigned(n));
            else
                u_next <= u_reg;
            end if;

        else
            u_next <= (others => '0');
        end if;




    end process;

end architecture;
        


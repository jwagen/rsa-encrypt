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
    signal u_reg : std_logic_vector(k -1 downto 0);
    signal u_out : std_logic_vector(k -1 downto 0);
    signal u_reg_next : std_logic_vector(k -1 downto 0);
    constant bits_in_k : integer := integer(ceil(log2(real(k))));
    signal loop_counter : natural range 0 to k-1 := 0;

    signal loop_counter_started : std_logic;
begin
    process(clk)
    begin
        -- Loop counter
        if rising_edge(clk) then
            if resetn = '0' then
                -- Reset loop counter
                loop_counter <= 0;
            else
                if start = '1' then 
                    loop_counter_started <= '1';
                    u <= (others => '0');
                end if;

                if loop_counter_started = '1' then
                    loop_counter <= loop_counter + 1;
                end if;

                if loop_counter = k - to_unsigned(1, bits_in_k) then
                    loop_counter <= 0;
                    loop_counter_started <= '0';
                    done <= '1';
                else
                    done <= '0';
                end if;
                
                -- TODO: Done should be delayed one clk cycle
                if loop_counter = 0 and done = '1' then
                    if u_reg >= n then
                        u <= std_logic_vector(unsigned(u_reg) - unsigned(n));
                    else
                        u <= u_reg;
                    end if;

                end if;

                u_reg <= u_reg_next;
            end if;
        end if;
    end process;


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

        

    end process;

end architecture;
        


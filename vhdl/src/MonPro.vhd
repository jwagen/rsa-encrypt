--Montgomery product multiplier

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

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
        a           : in std_logic_vector(k downto 0);
        b           : in std_logic_vector(k downto 0);
        n           : in std_logic_vector(k downto 0);
        done        : out std_logic;
        u           : out std_logic_vector(k downto 0)
    );
end MonPro;

architecture circuit of MonPro is
    signal u_reg : std_logic_vector(k downto 0);
    constant bits_in_k : integer := integer(ceil(log2(real(k))));
    signal loop_counter : unsigned(bits_in_k - 1  downto 0);

    signal loop_counter_started : std_logic;
begin
    process(clk)
    begin
        -- Loop counter
        if rising_edge(clk) then
            if resetn = '0' then
                -- Reset loop counter
                loop_counter <= (others => '0');
            else
                if start = '1' then 
                    loop_counter_started <= '1';
                end if;

                if loop_counter_started = '1' then
                    loop_counter <= loop_counter + '1';
                end if;

                if loop_counter = k - to_unsigned(1, bits_in_k) then
                    loop_counter <= (others => '0');
                    loop_counter_started <= '0';
                    done <= '1';
                else
                    done <= '0';
                end if;

            end if;
        end if;
    end process;


-- Set done output
    process(all)
    begin
    end process;

end architecture;
        


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
    type state_type is (IDLE, LOOPING, SUBTRACTING, FINISHED);
    signal current_state, next_state: state_type;
    
    signal u_next : std_logic_vector(k -1 downto 0);

	-- Use k+1 bits for the intermediate registers
	-- The upper bound of the intermediate result before downshift is:
	-- (N-1)*3 = 3N - 3. This requires two extra bits to contain
    signal u_intermediate : std_logic_vector(k+1 downto 0);
    signal u_intermediate_next : std_logic_vector(k+1 downto 0);

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
                u_intermediate <= (others => '0');
            else
                current_state <= next_state;
                loop_counter <= loop_counter_next;

                u <= u_next;
                u_intermediate <= u_intermediate_next;

            end if;
        end if;
    end process;

    comb_proc: process (all)
        variable u_temp1 : std_logic_vector(k+1  downto 0);
        variable u_temp2 : std_logic_vector(k+1  downto 0);
        variable u_next_temp : std_logic_vector(k+1 downto 0);
    begin
		-- Intermediate calculation
		-- Stage 2a
        if a(loop_counter) = '1' then
            u_temp1 := std_logic_vector(unsigned(u_intermediate) + unsigned("00" & b));
        else
            u_temp1 := u_intermediate;
        end if;

		-- Stage 2a
        if u_temp1(0) = '1' then
            u_temp2 := std_logic_vector(unsigned(u_temp1) + unsigned("00" & n));
        else
            u_temp2 := u_temp1;
        end if;


        -- State machine
        case (current_state) is
            when IDLE =>
                done <= '0';
                u_next <= (others => '0');


				-- Do start first loop imediatly on start signal
                if start = '1' then
                    next_state <= LOOPING;
                    loop_counter_next <= 1;
					u_intermediate_next <= '0' & u_temp2(k+1 downto 1);
                else
                    next_state <= IDLE;
                    loop_counter_next <= 0;
					u_intermediate_next <= (others => '0');
                end if;

            when LOOPING =>
                done <= '0';
                u_next <= (others => '0');

				--Shift intermediate
				u_intermediate_next <= '0' & u_temp2(k+1 downto 1);
                
                if loop_counter = k-1 then
                    next_state <= SUBTRACTING;
                    loop_counter_next <= 0;
                else
                    next_state <= LOOPING;
                    loop_counter_next <= loop_counter + 1;
                end if;

            when SUBTRACTING =>
                loop_counter_next <= 0;
                done <= '0';
				u_intermediate_next <= (others => '0');

				-- Subtraction has to be don with the k+1 bits to be correct
                if u_intermediate >= ("00" & n) then
                    u_next_temp := std_logic_vector(unsigned(u_intermediate) - unsigned("00" & n));
                    u_next <= u_next_temp(k-1 downto 0);
                else
                    u_next <= u_intermediate(k-1 downto 0);
                end if;

                next_state <= FINISHED;

            when FINISHED =>
                done <= '1';
                u_next <= (others => '0');
                
                -- Jump to looping if the start signal already is pressent
				-- Do start first loop imediatly on start signal
                if start = '1' then
                    next_state <= LOOPING;
                    loop_counter_next <= 1;
					u_intermediate_next <= '0' & u_temp2(k+1 downto 1);
                else
                    next_state <= IDLE;
                    loop_counter_next <= 0;
					u_intermediate_next <= (others => '0');
                end if;

            when others =>
                next_state <= IDLE;
        end case;
    end process;

end architecture;
        


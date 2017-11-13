--Montgomery product multiplier

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.numeric_std_unsigned.all;



entity MonPro is
  generic(
    k : positive := 128
    );
  port (
    clk    : in  std_logic;
    resetn : in  std_logic;
    start  : in  std_logic;
    a      : in  std_logic_vector(k -1 downto 0);
    b      : in  std_logic_vector(k -1 downto 0);
    n      : in  std_logic_vector(k -1 downto 0);
    done   : out std_logic;
    u      : out std_logic_vector(k -1 downto 0)
    );
end MonPro;

architecture circuit of MonPro is
  type state_type is (IDLE, LOOPING, SUBTRACTING, FINISHED);
  signal state : state_type;

  type stage_type is (FIRST, SECOND);
  signal stage : stage_type;


  -- Use k+1 bits for the intermediate registers
  -- The upper bound of the intermediate result before downshift is:
  -- (N-1)*3 = 3N - 3. This requires two extra bits to contain
  -- u_intermediate could be only k bits long, as long it only holds the
  -- result of the shift opperation. It is kept at k+1 bits for ease of use.
  signal u_intermediate      : std_logic_vector(k+1 downto 0);
  signal u_intermadiates1_s2 : std_logic_vector(k+1 downto 0);
  --signal c_out_lower : std_logic;

  signal loop_counter : natural range 0 to k-1 := 0;

begin
  sync_proc : process (clk)
    variable u_temp1     : std_logic_vector(k+1 downto 0);
    variable u_temp2     : std_logic_vector(k+1 downto 0);
    variable u_next_temp : std_logic_vector(k+1 downto 0);
  begin
    if rising_edge(clk) then
      if resetn = '0' then
        state        <= IDLE;
        stage        <= FIRST;
        loop_counter <= 0;

        u              <= (others => '0');
        u_intermediate <= (others => '0');
      else
        -- Intermediate calculation
        -- Stage 2a
        if a(loop_counter) = '1' then
          u_temp1 := std_logic_vector(unsigned(u_intermediate) + unsigned("00" & b));
        else
          u_temp1 := u_intermediate;
        end if;

        -- Stage 2a
        if u_intermadiates1_s2(0) = '1' then
          u_temp2 := std_logic_vector(unsigned(u_intermadiates1_s2) + unsigned("00" & n));
        else
          u_temp2 := u_intermadiates1_s2;
        end if;

        --Default values
        state        <= IDLE;
        stage        <= FIRST;
        loop_counter <= 0;

        u              <= (others => '0');
        u_intermediate <= (others => '0');

        -- State machine
        case (state) is
          when IDLE =>
            u <= (others => '0');


                                        -- Do start first loop imediatly on start signal
            if start = '1' then
              state <= LOOPING;
            --loop_counter   <= 1;
            --u_intermediate <= '0' & u_temp2(k+1 downto 1);
            else
              state          <= IDLE;
              loop_counter   <= 0;
              u_intermediate <= (others => '0');
            end if;

          when LOOPING =>
            u <= (others => '0');
            if(stage = FIRST) then
              u_intermadiates1_s2 <= u_temp1;
              stage               <= SECOND;
            else
              u_intermediate <= '0' & u_temp2(k+1 downto 1);
              stage          <= FIRST;

            end if;

            if loop_counter = k-1 and stage = SECOND then
              state        <= SUBTRACTING;
              loop_counter <= 0;
            else
              state <= LOOPING;
              if(stage = SECOND) then
                loop_counter <= loop_counter + 1;
              else
                loop_counter <= loop_counter;
              end if;
            end if;

          when SUBTRACTING =>
            loop_counter   <= 0;
            u_intermediate <= (others => '0');

                                        -- Subtraction has to be don with the k+1 bits to be correct
            if u_intermediate >= ("00" & n) then
              u_next_temp := std_logic_vector(unsigned(u_intermediate) - unsigned("00" & n));
              u           <= u_next_temp(k-1 downto 0);
            else
              u <= u_intermediate(k-1 downto 0);
            end if;

            state <= FINISHED;

          when FINISHED =>
            u <= (others => '0');

                                        -- Jump to looping if the start signal already is pressent
                                        -- Do start first loop imediatly on start signal
            if start = '1' then
              state <= LOOPING;
            --loop_counter   <= 1;
            --u_intermediate <= '0' & u_temp2(k+1 downto 1);
            else
              state          <= IDLE;
              loop_counter   <= 0;
              u_intermediate <= (others => '0');
            end if;

          when others =>
            state <= IDLE;
        end case;

      end if;
    end if;
  end process;

  process (state)
  begin
    if state = FINISHED then
      done <= '1';
    else
      done <= '0';
    end if;

  end process;


end architecture;



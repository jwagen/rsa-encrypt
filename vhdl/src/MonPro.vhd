--Montgomery product multiplier

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--Should use this package, but cant because has to compile with VHDL 93
--use ieee.numeric_std_unsigned.all;

-- Use synopsis non standard libraries, as VHDL 2008 is not supported by the syntesis tool.
-- These libraries are not recomended to use, but greatly reduses the amount of type conversion.
-- All math in the block is of type unsigned.
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;



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


  -- Use k+1 bits for the intermediate registers
  -- The upper bound of the intermediate result before downshift is:
  -- (N-1)*3 = 3N - 3. This requires two extra bits to contain
  -- This is followed by a shift opperation that devides by two.
  -- Which leads to that one carry bit is enough for the intermediate value as a whole.

  --The adders are split in two, a lower section and an upper, and pipelinded verticaly
  --signal u_intermediate : std_logic_vector(k+1 downto 0);

  -- The msb of the lower needs to come from the lsb of the upper, this is done combinatrialy.
  -- Therefore u_intermediate is k-1 bits large.
  signal u_intermediate_lower : std_logic_vector(k/2-2 downto 0);

  -- The upper signal can be upto k/2 bits. This allows for one carry out bit from the opperation.
  signal u_intermediate_upper     : std_logic_vector(k/2 downto 0);
  signal c_out_lower              : std_logic_vector(1 downto 0);
  signal u_intermediate_s1_is_odd : std_logic;

  -- Holds the value u before subtraction
  signal u_intermediate_whole : std_logic_vector(k downto 0);

  signal loop_counter : natural range 0 to k := 0;

begin
  sync_proc : process (clk)
    variable u_intermediate_upper_stage1 : std_logic_vector(k/2+1 downto 0);
    variable u_intermediate_upper_stage2 : std_logic_vector(k/2+2 downto 0);
    variable u_intermediate_lower_stage1 : std_logic_vector(k/2 downto 0);
    variable u_intermediate_lower_stage2 : std_logic_vector(k/2+1 downto 0);
    variable u_intermediate_subtracted   : std_logic_vector(k downto 0);
    variable u_intermediate_s1_msb       : std_logic;
  begin

    if rising_edge(clk) then
      if resetn = '0' then
        state        <= IDLE;
        loop_counter <= 0;

        u                        <= (others => '0');
        u_intermediate_upper     <= (others => '0');
        u_intermediate_lower     <= (others => '0');
        c_out_lower              <= (others => '0');
        u_intermediate_whole     <= (others => '0');
        u_intermediate_s1_is_odd <= '0';
      else

        --Upper
        --Stage one
        --Delayed one clock, second stage in pipeline
        if(loop_counter /= 0) then
          if a(loop_counter-1) = '1' then
            u_intermediate_upper_stage1 := ('0' & u_intermediate_upper) + ("00" & b(k-1 downto k/2));
          else
            u_intermediate_upper_stage1 := ('0' & u_intermediate_upper);
          end if;
        else
          u_intermediate_upper_stage1 := (others => '0');
        end if;

        -- Stage two
        if u_intermediate_s1_is_odd = '1' then
          u_intermediate_upper_stage2 := ('0' & u_intermediate_upper_stage1) + ("00" & n(k-1 downto k/2)) + c_out_lower;
        else
          u_intermediate_upper_stage2 := ('0' & u_intermediate_upper_stage1);
        end if;

        --LSB from upper is MSB in lower after shift
        --It is zero on first loop
        if(loop_counter /= 0) then
          u_intermediate_s1_msb := u_intermediate_upper_stage2(0);
        else
          u_intermediate_s1_msb := '0';
        end if;

        --Lower
        --Stage one
        --Last bit of u_intermediate_lower_stage1 is the carry out bit from the first stage
        if(loop_counter /= k) then
          if a(loop_counter) = '1' then
            u_intermediate_lower_stage1 := (u_intermediate_s1_msb & u_intermediate_lower) + ('0' & b(k/2 -1 downto 0));
          else
            u_intermediate_lower_stage1 := '0' & u_intermediate_s1_msb & u_intermediate_lower;
          end if;
        else
          u_intermediate_lower_stage1 := (others => '0');
        end if;


        -- Stage 2a
        --Last bit of u_intermediate_lower_stage2 is the carry out bit from the first stage
        if u_intermediate_lower_stage1(0) = '1' then
          u_intermediate_lower_stage2 := '0' & u_intermediate_lower_stage1 + ("00" & n((k/2)-1 downto 0));
        else
          u_intermediate_lower_stage2 := '0' & u_intermediate_lower_stage1;
        end if;

        --Default values for the intermediate registers
        u_intermediate_lower     <= (others => '0');
        u_intermediate_upper     <= (others => '0');
        u_intermediate_whole     <= (others => '0');
        c_out_lower              <= (others => '0');
        u_intermediate_s1_is_odd <= '0';

        -- State machine
        case (state) is
          when IDLE =>
            u <= (others => '0');

            -- Disabled temperaraly
            -- Do start first loop imediatly on start signal
            if start = '1' then
              state <= LOOPING;
            --loop_counter   <= 1;
            --u_intermediate_lower <= u_intermediate_lower_stage2;
            --u_intermediate_upper <= (others => '0');
            else
              state                <= IDLE;
              loop_counter         <= 0;
              u_intermediate_lower <= (others => '0');
              u_intermediate_upper <= (others => '0');
            end if;

          when LOOPING =>
            u                        <= (others => '0');
            --Store lsb of stage 1 for next clock for use in upper
            u_intermediate_s1_is_odd <= u_intermediate_lower_stage1(0);

            --Shift intermediate
            if(loop_counter /= k) then
              u_intermediate_lower <= u_intermediate_lower_stage2(k/2-1 downto 1);
            else
              u_intermediate_lower <= u_intermediate_lower;
            end if;
            c_out_lower          <= u_intermediate_lower_stage2(k/2+1 downto k/2);
            u_intermediate_upper <= u_intermediate_upper_stage2(k/2+1 downto 1);
            --u_intermediate <= '0' & u_temp2(k+1 downto 1);

--Use variable for upper so it is available emediatly
            --This does the shifting operation as well
            u_intermediate_whole <= u_intermediate_upper_stage2(k/2+1 downto 0)& u_intermediate_lower;
            if loop_counter = k then
              state        <= SUBTRACTING;
              loop_counter <= 0;
            else
              state        <= LOOPING;
              loop_counter <= loop_counter + 1;
            end if;

          when SUBTRACTING =>
            loop_counter <= 0;
            --u_intermediate <= (others => '0');

            -- Subtraction has to be don with the k+1 bits to be correct
            if (u_intermediate_whole >= ("00" & n)) then
              u_intermediate_subtracted := u_intermediate_whole - ('0' & n);
              u                         <= u_intermediate_subtracted(k-1 downto 0);
            else
              u <= u_intermediate_whole(k-1 downto 0);
            end if;

            state <= FINISHED;

          when FINISHED =>
            u <= (others => '0');
            loop_counter <= 0;

                                        -- Jump to looping if the start signal already is pressent
                                        -- Do start first loop imediatly on start signal
            if start = '1' then
              state        <= LOOPING;
            --  loop_counter <= 1;
            --u_intermediate <= '0' & u_temp2(k+1 downto 1);
            else
              state        <= IDLE;
              loop_counter <= 0;
            --u_intermediate <= (others => '0');
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



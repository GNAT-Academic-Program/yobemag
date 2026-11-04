-- ================================================================================ --
-- 16-bit 8080 LCD write bridge, XBUS slave                                        --
-- -------------------------------------------------------------------------------- --
-- Turns one 32-bit bus write into one 8080 write cycle on the LCD connector. The   --
-- CPU writes a word, the bridge holds the bus until the cycle is done, then acks.  --
-- Reads of the LCD (RD) are not implemented: lcd_rd_n stays high.                  --
--                                                                                  --
-- Register map, word offsets from BASE (default 0x90000000):                       --
--   0x0  CTRL    read/write  bit 0: LCD reset, 1 = held in reset (lcd_rst_n low)   --
--                            bit 1: LCD chip select, 1 = selected (lcd_cs_n low)   --
--                            reset value: 0 (not in reset, not selected)           --
--   0x4  CMD     write only  one command write: DC = 0, data(15 downto 0) on DB    --
--   0x8  DATA    write only  one data write:    DC = 1, data(15 downto 0) on DB    --
--   0xC  ID      read only   0x594F4245 ("YOBE"), so software can tell this        --
--                            bitstream from the plain one                          --
--                                                                                  --
-- A write cycle, in clock cycles of clk_i: DB and DC are set, WR goes low for      --
-- WR_LOW cycles, then high for WR_HIGH cycles, then the bus is acked. DB and DC    --
-- keep their value until the next write, so hold time is never an issue.          --
-- The defaults (2 and 2 at 50 MHz: 40 ns low, 40 ns high) are well above the      --
-- ST7796 minimums and leave room for the module's level shifters.                  --
-- -------------------------------------------------------------------------------- --
-- SPDX-License-Identifier: MIT                                                     --
-- ================================================================================ --

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lcd_8080_xbus is
  generic (
    BASE    : std_ulogic_vector(31 downto 0) := x"90000000"; -- 16-byte window, aligned
    WR_LOW  : natural range 1 to 15 := 2;  -- clock cycles WR is held low
    WR_HIGH : natural range 1 to 15 := 2   -- clock cycles WR is held high before the ack
  );
  port (
    clk_i      : in  std_ulogic;
    rstn_i     : in  std_ulogic;
    -- XBUS, from neorv32_mercury2_soc
    xbus_adr_i : in  std_ulogic_vector(31 downto 0);
    xbus_dat_i : in  std_ulogic_vector(31 downto 0);
    xbus_we_i  : in  std_ulogic;
    xbus_stb_i : in  std_ulogic;
    xbus_cyc_i : in  std_ulogic;
    xbus_dat_o : out std_ulogic_vector(31 downto 0);
    xbus_ack_o : out std_ulogic;
    xbus_err_o : out std_ulogic;
    -- LCD connector, 8080 16-bit
    lcd_db_o   : out std_ulogic_vector(15 downto 0);
    lcd_wr_n_o : out std_ulogic;
    lcd_rd_n_o : out std_ulogic;
    lcd_dc_o   : out std_ulogic;  -- 0 = command, 1 = data
    lcd_cs_n_o : out std_ulogic;
    lcd_rst_n_o: out std_ulogic
  );
end entity;

architecture rtl of lcd_8080_xbus is

  constant ID_c : std_ulogic_vector(31 downto 0) := x"594F4245"; -- "YOBE"

  signal selected : std_ulogic;                    -- address is in our window
  signal word     : std_ulogic_vector(1 downto 0); -- which of the four registers

  signal ctrl     : std_ulogic_vector(1 downto 0) := (others => '0');
  signal db       : std_ulogic_vector(15 downto 0) := (others => '0');
  signal dc       : std_ulogic := '0';
  signal wr_n     : std_ulogic := '1';

  type state_t is (s_idle, s_wr_low, s_wr_high);
  signal state    : state_t := s_idle;
  signal count    : natural range 0 to 15 := 0;

  signal ack      : std_ulogic := '0';

begin

  selected <= '1' when (xbus_adr_i(31 downto 4) = BASE(31 downto 4)) else '0';
  word     <= xbus_adr_i(3 downto 2);

  bus_and_cycle: process(clk_i)
  begin
    if rising_edge(clk_i) then
      ack <= '0';
      if rstn_i = '0' then
        ctrl  <= (others => '0');
        state <= s_idle;
        wr_n  <= '1';
      else
        case state is

          when s_idle =>
            if xbus_cyc_i = '1' and xbus_stb_i = '1' and selected = '1' then
              if xbus_we_i = '0' then
                ack <= '1';                                 -- reads: one cycle
              else
                case word is
                  when "00" =>                              -- CTRL
                    ctrl <= xbus_dat_i(1 downto 0);
                    ack  <= '1';
                  when "01" | "10" =>                       -- CMD, DATA
                    db    <= xbus_dat_i(15 downto 0);
                    dc    <= word(1);                       -- "10" is DATA
                    wr_n  <= '0';
                    count <= WR_LOW - 1;
                    state <= s_wr_low;
                  when others =>                            -- ID: writes do nothing
                    ack <= '1';
                end case;
              end if;
            end if;

          when s_wr_low =>
            if count = 0 then
              wr_n  <= '1';
              count <= WR_HIGH - 1;
              state <= s_wr_high;
            else
              count <= count - 1;
            end if;

          when s_wr_high =>
            if count = 0 then
              ack   <= '1';
              state <= s_idle;
            else
              count <= count - 1;
            end if;

        end case;
      end if;
    end if;
  end process;

  -- Read data. Only CTRL and ID carry a value; CMD and DATA read as zero.
  xbus_dat_o <= (31 downto 2 => '0') & ctrl when word = "00" else
                ID_c                        when word = "11" else
                (others => '0');
  xbus_ack_o <= ack;
  xbus_err_o <= '0';

  lcd_db_o    <= db;
  lcd_dc_o    <= dc;
  lcd_wr_n_o  <= wr_n;
  lcd_rd_n_o  <= '1';
  lcd_rst_n_o <= not ctrl(0);
  lcd_cs_n_o  <= not ctrl(1);

end architecture;

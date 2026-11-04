-- Unit test of lcd_8080_xbus: a small XBUS master writes CTRL, CMD and DATA,
-- reads ID and CTRL back, and checks the 8080 waveform on the LCD side.
-- Runs in well under a second.
-- SPDX-License-Identifier: MIT

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_lcd is
end entity;

architecture sim of tb_lcd is

  signal clk  : std_ulogic := '0';
  signal rstn : std_ulogic := '0';

  signal adr, wdat, rdat : std_ulogic_vector(31 downto 0) := (others => '0');
  signal we, stb, cyc, ack, err : std_ulogic := '0';

  signal db   : std_ulogic_vector(15 downto 0);
  signal wr_n, rd_n, dc, cs_n, rst_n : std_ulogic;

  signal done : boolean := false;

  -- Count WR falling edges, to prove each CMD or DATA write made exactly one.
  signal wr_pulses : natural := 0;

begin

  clk <= not clk after 10 ns when not done;

  dut: entity work.lcd_8080_xbus
  generic map (WR_LOW => 2, WR_HIGH => 2)
  port map (
    clk_i       => clk,
    rstn_i      => rstn,
    xbus_adr_i  => adr,
    xbus_dat_i  => wdat,
    xbus_we_i   => we,
    xbus_stb_i  => stb,
    xbus_cyc_i  => cyc,
    xbus_dat_o  => rdat,
    xbus_ack_o  => ack,
    xbus_err_o  => err,
    lcd_db_o    => db,
    lcd_wr_n_o  => wr_n,
    lcd_rd_n_o  => rd_n,
    lcd_dc_o    => dc,
    lcd_cs_n_o  => cs_n,
    lcd_rst_n_o => rst_n
  );

  count_wr: process(wr_n)
  begin
    if falling_edge(wr_n) then
      wr_pulses <= wr_pulses + 1;
    end if;
  end process;

  master: process
    -- One pipelined-Wishbone transfer the way NEORV32 issues it: strobe for one
    -- cycle, keep cyc until the ack. Returns the number of cycles waited.
    procedure xfer (a : std_ulogic_vector(31 downto 0); d : std_ulogic_vector(31 downto 0);
                    write : std_ulogic; waited : out natural) is
      variable n : natural := 0;
    begin
      wait until rising_edge(clk);
      adr <= a; wdat <= d; we <= write; stb <= '1'; cyc <= '1';
      wait until rising_edge(clk);
      stb <= '0';
      while ack = '0' loop
        wait until rising_edge(clk);
        n := n + 1;
        assert n < 100 report "no ack" severity failure;
      end loop;
      cyc <= '0'; we <= '0';
      waited := n;
    end procedure;

    variable waited : natural;
  begin
    wait for 50 ns;
    rstn <= '1';
    wait for 50 ns;

    assert rst_n = '1' and cs_n = '1' report "reset state: LCD must be out of reset and deselected" severity failure;
    assert rd_n = '1' report "RD must stay high" severity failure;

    -- ID
    xfer(x"9000000C", x"00000000", '0', waited);
    assert rdat = x"594F4245" report "ID read wrong" severity failure;

    -- CTRL: reset the LCD, then release and select it
    xfer(x"90000000", x"00000001", '1', waited);
    assert rst_n = '0' report "CTRL bit 0 must assert LCD reset" severity failure;
    xfer(x"90000000", x"00000002", '1', waited);
    assert rst_n = '1' and cs_n = '0' report "CTRL bit 1 must select the LCD" severity failure;
    xfer(x"90000000", x"00000000", '0', waited);
    assert rdat = x"00000002" report "CTRL read back wrong" severity failure;

    -- CMD 0x2C (memory write): DC = 0, one WR pulse
    xfer(x"90000004", x"0000002C", '1', waited);
    assert db = x"002C" and dc = '0' report "CMD: bus or DC wrong" severity failure;
    assert wr_pulses = 1 report "CMD: expected exactly one WR pulse" severity failure;
    assert waited >= 3 report "CMD: ack came before the WR cycle could have finished" severity failure;

    -- DATA 0xF800 (red): DC = 1, one more WR pulse, data held after the ack
    xfer(x"90000008", x"0000F800", '1', waited);
    assert db = x"F800" and dc = '1' report "DATA: bus or DC wrong" severity failure;
    assert wr_pulses = 2 report "DATA: expected a second WR pulse" severity failure;
    assert wr_n = '1' report "WR must be high after the ack" severity failure;

    -- Outside the window: no ack at all (the SoC's XBUS timeout turns that into a bus error)
    wait until rising_edge(clk);
    adr <= x"90000010"; we <= '1'; stb <= '1'; cyc <= '1';
    wait until rising_edge(clk);
    stb <= '0';
    for i in 1 to 20 loop
      wait until rising_edge(clk);
      assert ack = '0' report "an address outside the window must not be acked" severity failure;
    end loop;
    cyc <= '0'; we <= '0';

    report "PASS: lcd_8080_xbus";
    done <= true;
    wait;
  end process;

end architecture;

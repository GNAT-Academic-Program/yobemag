-- Smoke test: boot the yobemag top and print what the bootloader sends on UART0.
-- The same test as the board repo's, on the composed top. Takes about three minutes.
-- SPDX-License-Identifier: MIT

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;

entity tb_top is
end entity;

architecture sim of tb_top is

  constant bit_time_c : time := 1 sec / 19200; -- bootloader baud rate

  signal clk    : std_ulogic := '0';
  signal txd    : std_ulogic;
  signal leds   : std_ulogic_vector(2 downto 0);
  signal clk_en : std_ulogic;

  signal lcd_db : std_ulogic_vector(15 downto 0);
  signal lcd_wr_n, lcd_rd_n, lcd_dc, lcd_cs_n, lcd_rst_n, lcd_bl, spk : std_ulogic;

begin

  clk <= not clk after 10 ns; -- 50 MHz

  dut: entity work.top_mercury2
  port map (
    clk_i       => clk,
    rstn_i      => '1',
    gpio_o      => leds,
    uart0_txd_o => txd,
    uart0_rxd_i => '1',
    clk_en_o    => clk_en,
    lcd_db_o    => lcd_db,
    lcd_wr_n_o  => lcd_wr_n,
    lcd_rd_n_o  => lcd_rd_n,
    lcd_dc_o    => lcd_dc,
    lcd_cs_n_o  => lcd_cs_n,
    lcd_rst_n_o => lcd_rst_n,
    lcd_bl_o    => lcd_bl,
    btn_n_i     => (others => '1'),
    spk_o       => spk
  );

  -- UART receiver: one output line per received text line, prefixed with "UART: ".
  uart_rx: process
    variable l : line;
    variable c : std_ulogic_vector(7 downto 0);
  begin
    wait until falling_edge(txd);
    wait for bit_time_c * 1.5;
    for i in 0 to 7 loop
      c(i) := txd;
      wait for bit_time_c;
    end loop;
    if c = x"0A" then
      if l = null then
        write(l, string'(""));
      end if;
      write(output, "UART: " & l.all & LF);
      deallocate(l);
    elsif c /= x"0D" then
      write(l, character'val(to_integer(unsigned(c))));
    end if;
  end process;

end architecture;

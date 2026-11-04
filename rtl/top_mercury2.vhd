-- ================================================================================ --
-- yobemag on the Mercury 2: the board SoC plus the carrier's logic                 --
-- -------------------------------------------------------------------------------- --
-- This is the composition. neorv32_mercury2_soc comes from boards/neorv32_mercury2 --
-- (a git submodule); everything else here is yobemag's.                            --
--                                                                                  --
-- What the carrier adds, and how the SoC sees it:                                  --
--   LCD (ST7796, 16-bit 8080)  lcd_8080_xbus on XBUS at 0x90000000                 --
--   8 buttons                  gpio_i(10 downto 3), 1 while pressed                 --
--   speaker                    pwm_o(0)                                             --
--   LCD backlight              pwm_o(1)                                             --
--   the module's 3 LEDs        gpio_o(2 downto 0), unchanged                        --
-- -------------------------------------------------------------------------------- --
-- SPDX-License-Identifier: MIT                                                     --
-- ================================================================================ --

library ieee;
use ieee.std_logic_1164.all;

entity top_mercury2 is
  port (
    -- Mercury 2 module (names fixed by boards/neorv32_mercury2/vivado/mercury2/mercury2.xdc)
    clk_i       : in  std_ulogic;
    rstn_i      : in  std_ulogic;
    gpio_o      : out std_ulogic_vector(2 downto 0);
    uart0_txd_o : out std_ulogic;
    uart0_rxd_i : in  std_ulogic;
    clk_en_o    : out std_ulogic;
    -- Carrier (vivado/mercury2/carrier.xdc)
    lcd_db_o    : out std_ulogic_vector(15 downto 0);
    lcd_wr_n_o  : out std_ulogic;
    lcd_rd_n_o  : out std_ulogic;
    lcd_dc_o    : out std_ulogic;
    lcd_cs_n_o  : out std_ulogic;
    lcd_rst_n_o : out std_ulogic;
    lcd_bl_o    : out std_ulogic;                     -- backlight, PWM
    btn_n_i     : in  std_ulogic_vector(7 downto 0);  -- active low, pulled up in the XDC
    spk_o       : out std_ulogic                      -- speaker, PWM
  );
end entity;

architecture rtl of top_mercury2 is

  signal rstn     : std_ulogic;
  signal gpio_out : std_ulogic_vector(31 downto 0);
  signal gpio_in  : std_ulogic_vector(31 downto 0);
  signal pwm      : std_ulogic_vector(31 downto 0);

  signal xbus_adr, xbus_wdat, xbus_rdat : std_ulogic_vector(31 downto 0);
  signal xbus_sel : std_ulogic_vector(3 downto 0);
  signal xbus_we, xbus_stb, xbus_cyc, xbus_ack, xbus_err : std_ulogic;

begin

  soc: entity work.neorv32_mercury2_soc
  generic map (
    GPIO_NUM => 11,     -- 3 LEDs + 8 buttons
    PWM_NUM  => 2,      -- speaker, backlight
    XBUS_EN  => true
  )
  port map (
    clk_i       => clk_i,
    rstn_i      => rstn_i,
    gpio_o      => gpio_out,
    gpio_i      => gpio_in,
    pwm_o       => pwm,
    uart0_txd_o => uart0_txd_o,
    uart0_rxd_i => uart0_rxd_i,
    clk_en_o    => clk_en_o,
    rstn_o      => rstn,
    xbus_adr_o  => xbus_adr,
    xbus_dat_o  => xbus_wdat,
    xbus_we_o   => xbus_we,
    xbus_sel_o  => xbus_sel,
    xbus_stb_o  => xbus_stb,
    xbus_cyc_o  => xbus_cyc,
    xbus_dat_i  => xbus_rdat,
    xbus_ack_i  => xbus_ack,
    xbus_err_i  => xbus_err
  );

  lcd: entity work.lcd_8080_xbus
  port map (
    clk_i       => clk_i,
    rstn_i      => rstn,
    xbus_adr_i  => xbus_adr,
    xbus_dat_i  => xbus_wdat,
    xbus_we_i   => xbus_we,
    xbus_stb_i  => xbus_stb,
    xbus_cyc_i  => xbus_cyc,
    xbus_dat_o  => xbus_rdat,
    xbus_ack_o  => xbus_ack,
    xbus_err_o  => xbus_err,
    lcd_db_o    => lcd_db_o,
    lcd_wr_n_o  => lcd_wr_n_o,
    lcd_rd_n_o  => lcd_rd_n_o,
    lcd_dc_o    => lcd_dc_o,
    lcd_cs_n_o  => lcd_cs_n_o,
    lcd_rst_n_o => lcd_rst_n_o
  );

  -- LEDs
  gpio_o <= gpio_out(2 downto 0);

  -- Buttons: pulled up, pressed = low on the pin, 1 in the register.
  gpio_in <= (31 downto 11 => '0') & (not btn_n_i) & "000";

  -- PWM
  spk_o    <= pwm(0);
  lcd_bl_o <= pwm(1);

end architecture;

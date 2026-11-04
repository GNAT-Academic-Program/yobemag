## yobemag carrier on the Mercury 2 DIP. Only the carrier's pins; the module's own
## pins (clock, LEDs, UART, reset) come from the submodule's mercury2.xdc.
##
## All carrier signals are on the module's 40 "IO" pins, the 5 V tolerant ones that
## go through the module's level shifters. The 10 FPGA-direct "DIO" pins are left
## free (DIO 0 is the reset). IO numbering below follows the LiteX platform file
## (micronova_mercury2.py); check each number against the Mercury 2 reference
## manual's DIP pinout before the carrier layout is sent to fab.
##
## Buttons use the FPGA's internal pull-ups. Do not add strong external pull-ups
## on the carrier: the module's level shifters cannot drive against them.

## LCD, 16-bit 8080 data bus: IO 0 .. IO 15
set_property -dict { PACKAGE_PIN G1   IOSTANDARD LVCMOS33 } [get_ports { lcd_db_o[0]  }]; # IO 0
set_property -dict { PACKAGE_PIN G2   IOSTANDARD LVCMOS33 } [get_ports { lcd_db_o[1]  }]; # IO 1
set_property -dict { PACKAGE_PIN F2   IOSTANDARD LVCMOS33 } [get_ports { lcd_db_o[2]  }]; # IO 2
set_property -dict { PACKAGE_PIN E1   IOSTANDARD LVCMOS33 } [get_ports { lcd_db_o[3]  }]; # IO 3
set_property -dict { PACKAGE_PIN E2   IOSTANDARD LVCMOS33 } [get_ports { lcd_db_o[4]  }]; # IO 4
set_property -dict { PACKAGE_PIN C2   IOSTANDARD LVCMOS33 } [get_ports { lcd_db_o[5]  }]; # IO 5
set_property -dict { PACKAGE_PIN B2   IOSTANDARD LVCMOS33 } [get_ports { lcd_db_o[6]  }]; # IO 6
set_property -dict { PACKAGE_PIN B1   IOSTANDARD LVCMOS33 } [get_ports { lcd_db_o[7]  }]; # IO 7
set_property -dict { PACKAGE_PIN A2   IOSTANDARD LVCMOS33 } [get_ports { lcd_db_o[8]  }]; # IO 8
set_property -dict { PACKAGE_PIN H2   IOSTANDARD LVCMOS33 } [get_ports { lcd_db_o[9]  }]; # IO 9
set_property -dict { PACKAGE_PIN B10  IOSTANDARD LVCMOS33 } [get_ports { lcd_db_o[10] }]; # IO 10
set_property -dict { PACKAGE_PIN C8   IOSTANDARD LVCMOS33 } [get_ports { lcd_db_o[11] }]; # IO 11
set_property -dict { PACKAGE_PIN C9   IOSTANDARD LVCMOS33 } [get_ports { lcd_db_o[12] }]; # IO 12
set_property -dict { PACKAGE_PIN T13  IOSTANDARD LVCMOS33 } [get_ports { lcd_db_o[13] }]; # IO 13
set_property -dict { PACKAGE_PIN R12  IOSTANDARD LVCMOS33 } [get_ports { lcd_db_o[14] }]; # IO 14
set_property -dict { PACKAGE_PIN P11  IOSTANDARD LVCMOS33 } [get_ports { lcd_db_o[15] }]; # IO 15

## LCD control: IO 16 .. IO 21
set_property -dict { PACKAGE_PIN T2   IOSTANDARD LVCMOS33 } [get_ports { lcd_wr_n_o  }]; # IO 16
set_property -dict { PACKAGE_PIN T4   IOSTANDARD LVCMOS33 } [get_ports { lcd_rd_n_o  }]; # IO 17
set_property -dict { PACKAGE_PIN T5   IOSTANDARD LVCMOS33 } [get_ports { lcd_dc_o    }]; # IO 18, RS on some modules
set_property -dict { PACKAGE_PIN T7   IOSTANDARD LVCMOS33 } [get_ports { lcd_cs_n_o  }]; # IO 19
set_property -dict { PACKAGE_PIN K5   IOSTANDARD LVCMOS33 } [get_ports { lcd_rst_n_o }]; # IO 20
set_property -dict { PACKAGE_PIN A3   IOSTANDARD LVCMOS33 } [get_ports { lcd_bl_o    }]; # IO 21, backlight PWM, through a transistor on the carrier

## Buttons: IO 22 .. IO 29, to GND when pressed
set_property -dict { PACKAGE_PIN C6   IOSTANDARD LVCMOS33  PULLUP true } [get_ports { btn_n_i[0] }]; # IO 22, Up
set_property -dict { PACKAGE_PIN D4   IOSTANDARD LVCMOS33  PULLUP true } [get_ports { btn_n_i[1] }]; # IO 23, Down
set_property -dict { PACKAGE_PIN F5   IOSTANDARD LVCMOS33  PULLUP true } [get_ports { btn_n_i[2] }]; # IO 24, Left
set_property -dict { PACKAGE_PIN D8   IOSTANDARD LVCMOS33  PULLUP true } [get_ports { btn_n_i[3] }]; # IO 25, Right
set_property -dict { PACKAGE_PIN P1   IOSTANDARD LVCMOS33  PULLUP true } [get_ports { btn_n_i[4] }]; # IO 26, A
set_property -dict { PACKAGE_PIN C7   IOSTANDARD LVCMOS33  PULLUP true } [get_ports { btn_n_i[5] }]; # IO 27, B
set_property -dict { PACKAGE_PIN M2   IOSTANDARD LVCMOS33  PULLUP true } [get_ports { btn_n_i[6] }]; # IO 28, Start
set_property -dict { PACKAGE_PIN N1   IOSTANDARD LVCMOS33  PULLUP true } [get_ports { btn_n_i[7] }]; # IO 29, Select

## Speaker: IO 30, PWM, through a transistor or a small amplifier on the carrier
set_property -dict { PACKAGE_PIN C1   IOSTANDARD LVCMOS33 } [get_ports { spk_o }]; # IO 30

## Free for the team: IO 31 .. IO 39 (D1 L2 G5 H5 H1 K1 K2 J1 J3) and DIO 1 .. DIO 9.

--  Yobemag_GPIO: the carrier's lines on the SoC, as the yobemag bitstream
--  wires them (rtl/top_mercury2.vhd). The module's own three LEDs stay in
--  the mercury2 crate (Board_GPIO).
--
--  Buttons are SoC GPIO inputs 3 .. 10. The gateware inverts them: the
--  register reads 1 while the button is held down. The FPGA pin and the
--  module IO number are quoted from vivado/mercury2/carrier.xdc.

with Gpio;
with NEORV32_GPIO;

package Yobemag_GPIO is

   Btn_Up     : constant Gpio.Pin := NEORV32_GPIO.Make_Pin (3);   --  C6, IO 22
   Btn_Down   : constant Gpio.Pin := NEORV32_GPIO.Make_Pin (4);   --  D4, IO 23
   Btn_Left   : constant Gpio.Pin := NEORV32_GPIO.Make_Pin (5);   --  F5, IO 24
   Btn_Right  : constant Gpio.Pin := NEORV32_GPIO.Make_Pin (6);   --  D8, IO 25
   Btn_A      : constant Gpio.Pin := NEORV32_GPIO.Make_Pin (7);   --  P1, IO 26
   Btn_B      : constant Gpio.Pin := NEORV32_GPIO.Make_Pin (8);   --  C7, IO 27
   Btn_Start  : constant Gpio.Pin := NEORV32_GPIO.Make_Pin (9);   --  M2, IO 28
   Btn_Select : constant Gpio.Pin := NEORV32_GPIO.Make_Pin (10);  --  N1, IO 29

   --  PWM channels of the SoC's PWM peripheral.
   Speaker_Channel   : constant := 0;   --  C1, IO 30
   Backlight_Channel : constant := 1;   --  A3, IO 21

end Yobemag_GPIO;

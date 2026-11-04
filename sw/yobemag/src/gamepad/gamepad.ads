--  Gamepad: the eight buttons on the carrier.
--
--  Reading is a plain GPIO read, no debouncing: a mechanical button bounces
--  for a few milliseconds, so a game loop that polls every frame is fine,
--  a loop that counts edges is not. Debouncing, edge detection ("just
--  pressed") and interrupts are the team's to add.

package Gamepad is

   type Button is (Up, Down, Left, Right, A, B, Start, Sel);

   type Button_State is array (Button) of Boolean;

   procedure Initialize;
   --  Configures the eight GPIO lines as inputs.

   function Pressed (Btn : Button) return Boolean;
   --  True while the button is held down.

   function State return Button_State;
   --  All eight at once, from one register read.

end Gamepad;

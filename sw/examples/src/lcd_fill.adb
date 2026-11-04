--  First light: fills the screen with red, green, blue, white in turn.
--  If the panel stays dark or shows the wrong colors, see the checklist
--  at the top of st7796.ads.

with Board;
with Yobemag;
with Gpio;
with Debug;

procedure LCD_Fill is
   use Yobemag;
   Colors : constant array (1 .. 4) of LCD.Color :=
     (LCD.Red, LCD.Green, LCD.Blue, LCD.White);
begin
   Yobemag.Initialize;
   Debug.Put_Line ("lcd_fill: red, green, blue, white, one second each");

   loop
      for C of Colors loop
         LCD.Fill_Screen (C);
         Gpio.Toggle (Board.Led);
         delay 1.0;
      end loop;
   end loop;
end LCD_Fill;

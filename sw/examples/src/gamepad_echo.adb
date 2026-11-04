--  Prints the name of each button while it is held, and lights a 40x40
--  square in a corner of the screen for A and B. Polls 50 times a second.

with Yobemag;
with Debug;

procedure Gamepad_Echo is
   use Yobemag;
   Previous : Pad.Button_State := (others => False);
   Current  : Pad.Button_State;
begin
   Yobemag.Initialize;
   Debug.Put_Line ("gamepad_echo: press buttons");

   loop
      Current := Pad.State;
      for Btn in Pad.Button loop
         if Current (Btn) and then not Previous (Btn) then
            Debug.Put_Line (Pad.Button'Image (Btn) & " down");
         elsif Previous (Btn) and then not Current (Btn) then
            Debug.Put_Line (Pad.Button'Image (Btn) & " up");
         end if;
      end loop;

      LCD.Fill_Rect (0, 0, 39, 39,
                     (if Current (Pad.A) then LCD.Red else LCD.Black));
      LCD.Fill_Rect (LCD.Width - 40, 0, LCD.Width - 1, 39,
                     (if Current (Pad.B) then LCD.Blue else LCD.Black));

      Previous := Current;
      delay 0.02;
   end loop;
end Gamepad_Echo;

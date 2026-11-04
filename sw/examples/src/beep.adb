--  Plays a short scale on the speaker, then a note for each button pressed.

with Yobemag;
with Debug;

procedure Beep is
   use Yobemag;
   Scale : constant array (1 .. 8) of Positive :=
     (262, 294, 330, 349, 392, 440, 494, 523);   --  C4 to C5
   Note_Of : constant array (Pad.Button) of Positive :=
     (Pad.Up => 523, Pad.Down => 262, Pad.Left => 330, Pad.Right => 392,
      Pad.A => 440, Pad.B => 494, Pad.Start => 349, Pad.Sel => 294);
   Playing : Boolean := False;
begin
   Yobemag.Initialize;
   Debug.Put_Line ("beep: scale, then one note per button");

   for Hz of Scale loop
      Yobemag.Beep (Hz, 0.15);
      delay 0.05;
   end loop;

   loop
      Playing := False;
      for Btn in Pad.Button loop
         if Pad.Pressed (Btn) then
            Tone_On (Note_Of (Btn));
            Playing := True;
            exit;
         end if;
      end loop;
      if not Playing then
         Tone_Off;
      end if;
      delay 0.02;
   end loop;
end Beep;

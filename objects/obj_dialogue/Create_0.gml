// Dialogue box. Created by start_dialogue(lines). One line at a time, typed out;
// Space finishes the line, then Space again goes to the next. Play stays frozen until the last line.
lines = [];
idx = 0;
shown = 0;              // characters revealed so far
type_speed = 1.5;       // characters per frame

///|
let board_cols : Int = 10

///|
let board_rows : Int = 20

///|
let board_cell : Int = 30

///|
let board_x : Int = 42

///|
let board_y : Int = 24

///|
let side_panel_x : Int = board_x + board_cols * board_cell + 24

///|
let screen_width : Int = 560

///|
let screen_height : Int = 700

///|
let bag_size : Int = 7

///|
let score_single : Int = 100

///|
let score_double : Int = 300

///|
let score_triple : Int = 500

///|
let score_tetris : Int = 800

///|
fn inside_rect(px : Float, py : Float, rx : Int, ry : Int, rw : Int, rh : Int) -> Bool {
  px >= Float::from_int(rx) && px <= Float::from_int(rx + rw) &&
  py >= Float::from_int(ry) && py <= Float::from_int(ry + rh)
}

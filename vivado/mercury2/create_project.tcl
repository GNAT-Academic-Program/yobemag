# Build the yobemag bitstream for the Mercury 2.
#
# Do not call this directly. Use build.sh (Linux) or build.bat (Windows) at the
# root of the repo: they find Vivado and pass the variant (100t or 35t).
#
# Output: yobemag_mercury2_<variant>.bit next to this script.
#
# The board (part, NEORV32 core, SoC, module pins) comes from the submodule's
# board.tcl. This file adds what is yobemag's: the bridge, the top, the carrier pins.

set variant "100t"
if { $argc > 0 } { set variant [string tolower [lindex $argv 0]] }

set here  [file dirname [file normalize [info script]]]
set root  [file normalize $here/../..]
set board $root/boards/neorv32_mercury2

if { ![file exists $board/vivado/mercury2/board.tcl] } {
  error "boards/neorv32_mercury2 is empty. From the root of the repo, run: git submodule update --init --recursive"
}
source $board/vivado/mercury2/board.tcl

board_project $variant $here/work
add_files $root/rtl/lcd_8080_xbus.vhd
add_files $root/rtl/top_mercury2.vhd
add_files -fileset constrs_1 $here/carrier.xdc
board_build top_mercury2 $here yobemag_mercury2_$variant

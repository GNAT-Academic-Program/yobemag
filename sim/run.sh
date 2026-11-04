#!/usr/bin/env bash
# GHDL tests.
#   ./sim/run.sh         the bridge unit test (seconds) and the boot smoke test (about 3 minutes)
#   ./sim/run.sh quick   the bridge unit test only
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/.." && pwd)
board=$root/boards/neorv32_mercury2
build=$here/build

if [ ! -f "$board/rtl/neorv32_mercury2_soc.vhd" ]; then
  echo "boards/neorv32_mercury2 is empty. From the root of the repo, run:"
  echo "  git submodule update --init --recursive"
  exit 1
fi
export NEORV32_HOME=$board/neorv32

mkdir -p "$build"
cd "$build"
flags="--std=08 --workdir=$build -P$build"

# The bridge alone
ghdl -a $flags "$root/rtl/lcd_8080_xbus.vhd" "$here/tb_lcd.vhd"
ghdl -e $flags tb_lcd
ghdl -r $flags tb_lcd --ieee-asserts=disable

if [ "${1:-}" = "quick" ]; then
  exit 0
fi

# The composed top boots the bootloader
core_files=$(sed "s|\$NEORV32_HOME|$NEORV32_HOME|" "$NEORV32_HOME/rtl/file_list_core.f")
ghdl -a $flags --work=neorv32 $core_files
ghdl -a $flags "$board/rtl/neorv32_mercury2_soc.vhd" "$root/rtl/top_mercury2.vhd" "$here/tb_top.vhd"
ghdl -e $flags tb_top
ghdl -r $flags tb_top --stop-time="${STOP_TIME:-40ms}" --ieee-asserts=disable | tee sim.log

if grep -q "UART: .*NEORV32" sim.log; then
  echo "PASS: bootloader banner seen on UART0 through top_mercury2"
else
  echo "FAIL: no bootloader banner on UART0"
  exit 1
fi

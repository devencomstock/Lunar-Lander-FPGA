// DESCRIPTION: Verilator: Verilog example module
//
// This file ONLY is placed under the Creative Commons Public Domain, for
// any use, without warranty, 2017 by Wilson Snyder.
// SPDX-License-Identifier: CC0-1.0
//======================================================================
// For std::unique_ptr
#include <memory>

// Include common routines
#include <verilated.h>
#include "verilated_fst_c.h"

// Verilator using new C++?  Need to include these now
#include <iostream>

const std::unique_ptr<VerilatedContext> contextp{new VerilatedContext};
VerilatedFstC* tfp = new VerilatedFstC;

// Current simulation time (64-bit unsigned)
vluint64_t main_time = 0;
// Called by $time in Verilog
double sc_time_stamp()
{
  return main_time; // Note does conversion to real, to match SystemC
}

int concat(int w, int a, int b)
{
  return (a << w) | b;
}

int pin(int a, int b) {
  return (a >> b) & 1;
}

int pinsel(int x, int a, int b) {
    assert(a < b);
    int y = 0;
    for (int i = a; i <= b; i++) {
        y |= pin(x, i);
    }
    return y;
}

int intssenc (int x) {
    switch (x) {
        case -2: return 64; // dash
        case -1: return 0;  // blank
        case 0 : return 63;
        case 1 : return 6;
        case 2 : return 91;
        case 3 : return 79;
        case 4 : return 102;
        case 5 : return 109;
        case 6 : return 125;
        case 7 : return 7;
        case 8 : return 127;
        case 9 : return 103;
        case 10: return 119;
        case 11: return 124;
        case 12: return 57;
        case 13: return 94;
        case 14: return 121;
        case 15: return 113;
    }
    // uhhh this should not happen
    assert(false);
    return -255;
}

int intssdec (int x) {
    switch (x) {
        case 64: return -2; // dash
        case 0: return -1;  // blank
        case 63 : return 0;
        case 6 : return 1;
        case 91 : return 2;
        case 79 : return 3;
        case 102 : return 4;
        case 109 : return 5;
        case 125 : return 6;
        case 7 : return 7;
        case 127 : return 8;
        case 103 : return 9;
        case 119: return 10;
        case 124: return 11;
        case 57: return 12;
        case 94: return 13;
        case 121: return 14;
        case 113: return 15;
        default: return -2;
    }
    // uhhh this should not happen
    assert(false);
    return -255;
}

std::string bin(uint64_t b)
{
  std::string ans;
  while (b != 0)
  {
    ans += b % 2 == 0 ? "0" : "1";
    b /= 2;
  }
  std::reverse(ans.begin(), ans.end());
  return ans;
}

std::string padbin(uint64_t b, int n)
{
  std::string ans;
  while (b != 0)
  {
    ans += b % 2 == 0 ? "0" : "1";
    b /= 2;
    n--;
  }
  while (n-- != 0) {
    ans += "0";
  }
  std::reverse(ans.begin(), ans.end());
  return ans;
}

uint16_t bcdcomp9 (uint16_t a) {
  // invert number in 9's complement
  uint16_t ans = 0;
  for (int i = 0; i < 4; i++) {
    uint16_t a_digit = (a >> (4*i)) & 0xF;
    uint16_t ans_digit = 9 - a_digit;
    ans |= (ans_digit << (4*i));
  }
  return ans;
}

uint16_t bcdaddsub4 (uint16_t a, uint16_t b, bool op) {
  // equivalent to verilog function where a and b are BCD decimal format, eg.
  // a = 0x1234, b = 0x5678, op = 0, therefore return value = 0x6912
  // op = 0 -> add, op = 1 -> subtract
  uint16_t ans = 0;
  uint16_t carry = 0;
  // std::cout << "a = " << std::hex << a << ", b = " << std::hex << b << ", op = " << std::hex << op << "\n";
  if (op == 1)
    b = bcdaddsub4(bcdcomp9(b), 0x1, 0);
  // std::cout << "a = " << std::hex << a << ", b = " << std::hex << b << ", op = " << std::hex << op << "\n";
  for (int i = 0; i < 4; i++) {
    uint16_t a_digit = (a >> (4*i)) & 0xF;
    uint16_t b_digit = (b >> (4*i)) & 0xF;
    uint16_t ans_digit = 0;
    ans_digit = a_digit + b_digit + carry;
    if (ans_digit >= 10) {
      ans_digit -= 10;
      carry = 1;
    } else {
      carry = 0;
    }
    ans |= (ans_digit << (4*i));
  }
  // std::cout << "ans = " << std::hex << ans << "\n";
  return ans;
}

// Include model header, generated from Verilating the Verilog module.
#if defined(LL_DISPLAY)
    #include "Vll_display.h"
    static uint16_t exp_ss7 = 0; static uint16_t exp_ss6 = 0; static uint16_t exp_ss5 = 0; 
    static uint16_t exp_ss3 = 0; static uint16_t exp_ss2 = 0; static uint16_t exp_ss1 = 0; static uint16_t exp_ss0 = 0;
    static uint16_t exp_red = 0;
    static uint16_t exp_green = 0;
    void eval(Vll_display *ll_display) {
      contextp->timeInc(1);
      ll_display->eval();
      tfp->dump(contextp->time());
    }
    void cycle_clock(Vll_display *ll_display) {
      ll_display->clk = 1; eval(ll_display);
      ll_display->clk = 0; eval(ll_display);
    }
    void check_outputs(Vll_display *ll_display, int* pt, int* tt) {
      // print current time first
      std::cout << "Time: " << std::to_string(contextp->time()) << "\n";
      
      (*tt) += 9;
      if ((ll_display->ss7 & 0x7F) != exp_ss7)
        std::cout << "ERROR: ss7 expected " << std::hex << exp_ss7 << " but got " << std::hex << (ll_display->ss7 & 0x7F) << "\n";
      else
        (*pt)++;
      if ((ll_display->ss6 & 0x7F) != exp_ss6)
        std::cout << "ERROR: ss6 expected " << std::hex << exp_ss6 << " but got " << std::hex << (ll_display->ss6 & 0x7F) << "\n";
      else
        (*pt)++;
      if ((ll_display->ss5 & 0x7F) != exp_ss5)
        std::cout << "ERROR: ss5 expected " << std::hex << exp_ss5 << " but got " << std::hex << (ll_display->ss5 & 0x7F) << "\n";
      else
        (*pt)++;
      if ((ll_display->ss3 & 0x7F) != exp_ss3)
        std::cout << "ERROR: ss3 expected " << std::to_string(intssdec(exp_ss3)) << " but got " << std::to_string(intssdec(ll_display->ss3 & 0x7F)) << "\n";
      else
        (*pt)++;
      if ((ll_display->ss2 & 0x7F) != exp_ss2)
        std::cout << "ERROR: ss2 expected " << std::to_string(intssdec(exp_ss2)) << " but got " << std::to_string(intssdec(ll_display->ss2 & 0x7F)) << "\n";
      else
        (*pt)++;
      if ((ll_display->ss1 & 0x7F) != exp_ss1)
        std::cout << "ERROR: ss1 expected " << std::to_string(intssdec(exp_ss1)) << " but got " << std::to_string(intssdec(ll_display->ss1 & 0x7F)) << "\n";
      else
        (*pt)++;
      if ((ll_display->ss0 & 0x7F) != exp_ss0)
        std::cout << "ERROR: ss0 expected " << std::to_string(intssdec(exp_ss0)) << " but got " << std::to_string(intssdec(ll_display->ss0 & 0x7F)) << "\n";
      else
        (*pt)++;
      if (ll_display->red != exp_red)
        std::cout << "ERROR: red expected " << std::hex << (exp_red) << " but got " << std::hex << (ll_display->red & 0x1) << "\n";
      else
        (*pt)++;
      if (ll_display->green != exp_green)
        std::cout << "ERROR: green expected " << std::hex << (exp_green) << " but got " << std::hex << (ll_display->green & 0x1) << "\n";
      else
        (*pt)++;
    }
#else
    #error "No module specified"
#endif

static int passed_test_count = 0; // every time we perform a test, and the test passes, increment this by one.
static int total_test_count = 0;  // every time we perform a test, increment this by one.

void update_tests(int passed, int total, std::string test) {
  // add tests to global test variables
  passed_test_count += passed;
  total_test_count += total;
  // perform sanity check on global test variables
  assert(passed_test_count <= total_test_count);
  // let TA know if this set of tests failed
  std::cout << "Part " << test << ": " << std::to_string(passed) << " out of " << std::to_string(total) << " tests passed.\n";
}

int main(int argc, char **argv)
{
  // This is a more complicated example, please also see the simpler examples/make_hello_c.

  // Prevent unused variable warnings
  if (0 && argc && argv) {}

  int passed_subtests = 0; // if we have multiple subtests, we need to know how many passed for each
  int total_subtests = 0;
  
  // Set debug level, 0 is off, 9 is highest presently used
  // May be overridden by commandArgs argument parsing
  contextp->debug(0);

  // Randomization reset policy
  // May be overridden by commandArgs argument parsing
  contextp->randReset(2);

  // Verilator must compute traced signals
  contextp->traceEverOn(true);

  // Pass arguments so Verilated code can see them, e.g. $value$plusargs
  // This needs to be called before you create any model
  contextp->commandArgs(argc, argv);

  #if defined(LL_DISPLAY)
    std::cout << "\nTesting ll_display...\n";
    // Construct the Verilated model, from each module after Verilating each module file
    const std::unique_ptr<Vll_display> ll_display {new Vll_display {contextp.get(), "LL_DISPLAY"} };
    ll_display->trace(tfp, 99);
    tfp->open("ll_display.fst");
    // inputs are clk, rst, land, crash, disp_ctrl, alt, vel, fuel, thrust
    // outputs are ss7,ss6,ss5, ss3-ss0, red, green
    // clk rst are for clocked register that shows alt, vel, fuel or thrust messages and values on ss7-ss0
    // expected behavior:
    //   if clk goes high and disp_ctrl=8, show "alt" and "XXXX" on ss7-ss0 where XXXX is alt
    //   if clk goes high and disp_ctrl=4, show "vel" and "XXXX" on ss7-ss0 where XXXX is vel
    //   if clk goes high and disp_ctrl=2, show "fuel" and "XXXX" on ss7-ss0 where XXXX is fuel
    //   if clk goes high and disp_ctrl=1, show "thrust" and "XXXX" on ss7-ss0 where XXXX is thrust
    //   otherwise only show the message "XXXX" on ss7-ss0 where XXXX is alt, vel, fuel or thrust
    //   if land=1, green=1
    //   if crash=1, red=1
    //   else green and red should be low
    // display messages on ss7-ss5:
    /*
      24'b01110111_00111000_01111000  // ALT
      24'b00111110_01111001_00111000  // VEL
      24'b01101111_01110111_01101101  // fuel (says GAS)
      24'b01111000_01110110_01010000  // thrust (says THR)
    */
    
    // test power-on reset
    std::cout << "ssX value reference: -2 means dash/minus sign, -1 means blank.\n";
    std::cout << "Errors for a test case will appear after the test case is specified.\n\n";
    ll_display->clk = 0;
    ll_display->rst = 0;
    eval(ll_display.get());
    ll_display->rst = 1;
    ll_display->land = 0;
    ll_display->crash = 0;
    ll_display->disp_ctrl = 0;
    ll_display->alt = 0x4500;
    ll_display->vel = 0x0;
    ll_display->fuel = 0x800; 
    ll_display->thrust = 5;
    eval(ll_display.get());
    exp_ss7 = 0b01110111; exp_ss6 = 0b00111000; exp_ss5 = 0b01111000;
    exp_ss3 = intssenc(4); exp_ss2 = intssenc(5); exp_ss1 = intssenc(0); exp_ss0 = intssenc(0);
    exp_red = 0; exp_green = 0;
    std::cout << "Test case: Power-on reset.\n";
    check_outputs(ll_display.get(), &passed_subtests, &total_subtests);

    // check alt by "pressing Z" (disp_ctrl = 8)
    ll_display->rst = 0;
    eval(ll_display.get());
    ll_display->disp_ctrl = 8;
    eval(ll_display.get());
    cycle_clock(ll_display.get());
    std::cout << "Test case: Display alt by pressing Z.\n";
    check_outputs(ll_display.get(), &passed_subtests, &total_subtests);

    // check vel by "pressing Y" (disp_ctrl = 4)
    ll_display->disp_ctrl = 4;
    eval(ll_display.get());
    std::cout << "Test case: Display vel by pressing Y but before rising edge of clk (display should not change).\n";
    check_outputs(ll_display.get(), &passed_subtests, &total_subtests);
    cycle_clock(ll_display.get());
    exp_ss7 = 0b00111110; exp_ss6 = 0b01111001; exp_ss5 = 0b00111000;
    exp_ss3 = intssenc(-1); exp_ss2 = intssenc(-1); exp_ss1 = intssenc(-1); exp_ss0 = intssenc(0);
    std::cout << "Test case: Display vel by pressing Y after rising edge of clk.\n";
    check_outputs(ll_display.get(), &passed_subtests, &total_subtests);

    // check fuel by "pressing X" (disp_ctrl = 2)
    ll_display->disp_ctrl = 2;
    eval(ll_display.get());
    cycle_clock(ll_display.get());
    exp_ss7 = 0b01101111; exp_ss6 = 0b01110111; exp_ss5 = 0b01101101;
    exp_ss3 = intssenc(-1); exp_ss2 = intssenc(8); exp_ss1 = intssenc(0); exp_ss0 = intssenc(0);
    std::cout << "Test case: Display fuel by pressing X.\n";
    check_outputs(ll_display.get(), &passed_subtests, &total_subtests);

    // check thrust by "pressing W" (disp_ctrl = 1)
    ll_display->disp_ctrl = 1;
    eval(ll_display.get());
    cycle_clock(ll_display.get());
    exp_ss7 = 0b01111000; exp_ss6 = 0b01110110; exp_ss5 = 0b01010000;
    exp_ss3 = intssenc(-1); exp_ss2 = intssenc(-1); exp_ss1 = intssenc(-1); exp_ss0 = intssenc(5);
    std::cout << "Test case: Display thrust by pressing W.\n";
    check_outputs(ll_display.get(), &passed_subtests, &total_subtests);

    // change values and display again
    ll_display->alt = 0x1234;
    ll_display->vel = 0x9970;
    ll_display->fuel = 0x1000;
    ll_display->thrust = 0x9;

    // check alt by "pressing Z" (disp_ctrl = 8)
    ll_display->disp_ctrl = 8;
    eval(ll_display.get());
    cycle_clock(ll_display.get());
    exp_ss7 = 0b01110111; exp_ss6 = 0b00111000; exp_ss5 = 0b01111000;
    exp_ss3 = intssenc(1); exp_ss2 = intssenc(2); exp_ss1 = intssenc(3); exp_ss0 = intssenc(4);
    std::cout << "Test case: Display alt=0x1234 by pressing Z.\n";
    check_outputs(ll_display.get(), &passed_subtests, &total_subtests);

    // check vel by "pressing Y" (disp_ctrl = 4)
    ll_display->disp_ctrl = 4;
    eval(ll_display.get());
    cycle_clock(ll_display.get());
    exp_ss7 = 0b00111110; exp_ss6 = 0b01111001; exp_ss5 = 0b00111000;
    exp_ss3 = intssenc(-2); exp_ss2 = intssenc(-1); exp_ss1 = intssenc(3); exp_ss0 = intssenc(0);
    std::cout << "Test case: Display vel=0x9970 (should show -30 not 9970) by pressing Y.\n";
    check_outputs(ll_display.get(), &passed_subtests, &total_subtests);

    // check fuel by "pressing X" (disp_ctrl = 2)
    ll_display->disp_ctrl = 2;
    eval(ll_display.get());
    cycle_clock(ll_display.get());
    exp_ss7 = 0b01101111; exp_ss6 = 0b01110111; exp_ss5 = 0b01101101;
    exp_ss3 = intssenc(1); exp_ss2 = intssenc(0); exp_ss1 = intssenc(0); exp_ss0 = intssenc(0);
    std::cout << "Test case: Display fuel=0x1000 by pressing X.\n";
    check_outputs(ll_display.get(), &passed_subtests, &total_subtests);

    // check thrust by "pressing W" (disp_ctrl = 1)
    ll_display->disp_ctrl = 1;
    eval(ll_display.get());
    cycle_clock(ll_display.get());
    exp_ss7 = 0b01111000; exp_ss6 = 0b01110110; exp_ss5 = 0b01010000;
    exp_ss3 = intssenc(-1); exp_ss2 = intssenc(-1); exp_ss1 = intssenc(-1); exp_ss0 = intssenc(9);
    std::cout << "Test case: Display thrust=9 by pressing W.\n";
    check_outputs(ll_display.get(), &passed_subtests, &total_subtests);

    // check land
    ll_display->land = 1;
    eval(ll_display.get());
    exp_green = 1;
    std::cout << "Test case: Display land=1.\n";
    check_outputs(ll_display.get(), &passed_subtests, &total_subtests);

    // check crash
    ll_display->crash = 1;
    eval(ll_display.get());
    exp_red = 1;
    std::cout << "Test case: Display crash=1.\n";
    check_outputs(ll_display.get(), &passed_subtests, &total_subtests);

    // turn both off and check again
    ll_display->land = 0;
    ll_display->crash = 0;
    eval(ll_display.get());
    exp_green = exp_red = 0;
    std::cout << "Test case: Display land=0 and crash=0.\n";
    check_outputs(ll_display.get(), &passed_subtests, &total_subtests);
  #endif

  tfp->close();
  tfp = nullptr;
  
  update_tests(passed_subtests, total_subtests, "1");
  /***********************************/

  passed_subtests = 0;
  total_subtests = 0;

  /***********************************/
  // END TESTS
  /*************************************************************************/

  // good to have to detect bugs
  assert(passed_test_count <= total_test_count);

  if (passed_test_count == total_test_count)
  {
    std::cout << "ALL " << std::to_string(total_test_count) << " TESTS PASSED"
              << "\n";
  }
  else
  {
    std::cout << "ERROR: " << std::to_string(passed_test_count) << "/" << std::to_string(total_test_count) << " tests passed.\n";
  }

  // Fin
  return 0;
}

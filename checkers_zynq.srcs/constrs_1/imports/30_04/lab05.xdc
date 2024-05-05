set_property PACKAGE_PIN Y21  [get_ports {blue[0]}]; # "VGA-B0" 
set_property PACKAGE_PIN Y20  [get_ports {blue[1]}];  # "VGA-B1" 
set_property PACKAGE_PIN AB20 [get_ports {blue[2]}];  # "VGA-B2" 
set_property PACKAGE_PIN AB19 [get_ports {blue[3]}];  # "VGA-B3" 
set_property PACKAGE_PIN AB22 [get_ports {green[0]}];  # "VGA-G0" 
set_property PACKAGE_PIN AA22 [get_ports {green[1]}];  # "VGA-G1" 
set_property PACKAGE_PIN AB21 [get_ports {green[2]}];  # "VGA-G2" 
set_property PACKAGE_PIN AA21 [get_ports {green[3]}];  # "VGA-G3" 
set_property PACKAGE_PIN R18 [get_ports {BTNR}];  #BTNR
set_property PACKAGE_PIN T18 [get_ports {BTNU}];  #BTNU
set_property PACKAGE_PIN R16 [get_ports {BTND}];  #BTND
set_property PACKAGE_PIN N15 [get_ports {BTNL}];  #BTNL

set_property PACKAGE_PIN V20  [get_ports {red[0]}];  # "VGA-R0" 
set_property PACKAGE_PIN U20  [get_ports {red[1]}];  # "VGA-R1" 
set_property PACKAGE_PIN V19  [get_ports {red[2]}];  # "VGA-R2" 
set_property PACKAGE_PIN V18  [get_ports {red[3]}];  # "VGA-R3" 
set_property PACKAGE_PIN AA19 [get_ports {hsync}];  # "VGA-HS" 
set_property PACKAGE_PIN Y19  [get_ports {vsync}];  # "VGA-VS" 
set_property IOSTANDARD LVCMOS25 [get_ports BTNR]; # "BTNR"
set_property IOSTANDARD LVCMOS25 [get_ports BTNU]; # "BTNU"
set_property IOSTANDARD LVCMOS25 [get_ports BTND]; # "BTND"
set_property IOSTANDARD LVCMOS25 [get_ports BTNL]; # "BTNL"

# All VGA pins are connected by bank 33, so specified 3.3V together. 
set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 33]]; 

set_property PACKAGE_PIN Y9 [get_ports {clk}];  # "clk" 
set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 13]];


set_property PACKAGE_PIN Y11  [get_ports {ssd[6]}];  # "JA1"
set_property PACKAGE_PIN AA11 [get_ports {ssd[5]}];  # "JA2"
set_property PACKAGE_PIN Y10  [get_ports {ssd[4]}];  # "JA3"
set_property PACKAGE_PIN AA9  [get_ports {ssd[3]}];  # "JA4"


# ----------------------------------------------------------------------------
# JB Pmod - Bank 13
# ---------------------------------------------------------------------------- 
set_property PACKAGE_PIN W12 [get_ports {ssd[2]}];  # "JB1"
set_property PACKAGE_PIN W11 [get_ports {ssd[1]}];  # "JB2"
set_property PACKAGE_PIN V10 [get_ports {ssd[0]}];  # "JB3"
set_property PACKAGE_PIN W8 [get_ports {sel}];  # "JB4"

# ----------------------------------------------------------------------------
# JC Pmod - Bank 13
# ---------------------------------------------------------------------------- 
set_property PACKAGE_PIN AB6 [get_ports {mosi}];  # "JC1_N"
set_property PACKAGE_PIN AB7 [get_ports {cs_n}];  # "JC1_P"
set_property PACKAGE_PIN AA4 [get_ports {sclk}];  # "JC2_N"
set_property PACKAGE_PIN Y4  [get_ports {miso}];  # "JC2_P"
set_property IOSTANDARD LVCMOS33 [get_ports ssd];
set_property IOSTANDARD LVCMOS33 [get_ports sel];
set_property IOSTANDARD LVCMOS33 [get_ports cs_n];
set_property IOSTANDARD LVCMOS33 [get_ports miso];
set_property IOSTANDARD LVCMOS33 [get_ports mosi];
set_property IOSTANDARD LVCMOS33 [get_ports sclk];

set_property PACKAGE_PIN Y9 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 10 [get_ports clk]


set_property PACKAGE_PIN T22 [get_ports {Q[0]}]; # "LED0"
set_property PACKAGE_PIN T21 [get_ports {Q[1]}]; # "LED1"
set_property PACKAGE_PIN U22 [get_ports {Q[2]}]; # "LED2"
set_property PACKAGE_PIN U21 [get_ports {Q[3]}]; # "LED3"
set_property PACKAGE_PIN V22 [get_ports {Q[4]}]; # "LED4"
set_property PACKAGE_PIN W22 [get_ports {Q[5]}]; # "LED5"
set_property PACKAGE_PIN U19 [get_ports {Q[6]}]; # "LED6"
set_property PACKAGE_PIN U14 [get_ports {Q[7]}]; # "LED7"

set_property IOSTANDARD LVCMOS33 [get_ports Q];

#set_property IOSTANDARD LVCMOS18 [get_ports -of_objects [get_iobanks 34]];

#set_property IOSTANDARD LVCMOS18 [get_ports -of_objects [get_iobanks 35]];


#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets BTND_IBUF]
#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets BTNU_IBUF]

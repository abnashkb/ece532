# ECE532 - Running Simplex on an FPGA

This repository contains the Verilog code for our ECE532 project which involved porting the simplex linear programming algorithm to a Xilinx FPGA.

Repository Design Tree Structure is organized into the following folders:

* docs: PDF of this final report and presentation slides
* ignore: stash of files used during development but not required for understanding the current state of the project, such as deprecated modules
* lp\_modules: Verilog files for our LP modules alongside the .xci files of the Vivado IP used for the LP modules and testbenches used for development.
* project\_tcl\_scripts: tcl scripts generated from our Vivado project, which can be used to regenerate the project
* pyomo\_fpga\_bridge: links to a separate repository where we host code used convert a real energy model into a streamable presolved standard form tableau. The repository also contains code to test this generated tableau against Gurobi.
* sdk\_code contains C code run on the Microblaze, including for data transfer over Ethernet
* sw\_benchmark has C and Python code used in our software implementations of Simplex; these were used to learn the Simplex algorithm and test our results from hardware
* verilog\_module: any Verilog files not directly related to the LP modules

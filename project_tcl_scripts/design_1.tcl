
################################################################
# This is a generated script based on design: design_1
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2018.3
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   catch {common::send_msg_id "BD_TCL-109" "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source design_1_script.tcl


# The design that will be created by this Tcl script contains the following 
# module references:
# choose_pivot_row, fifo_dma, fifo_dma, fifo_read_interface, fifo_read_interface, fifo_read_interface, fifo_read_interface, fifo_redirect, fifo_write_interface, fifo_write_interface, fifo_write_interface, find_pivot_col, lp_control_unit, lp_timer, mblaze_lp_bridge_v1_0, update_pivot_row, update_tableau

# Please add the sources of those modules before sourcing this Tcl script.

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xc7a200tsbg484-1
   set_property BOARD_PART digilentinc.com:nexys_video:part0:1.1 [current_project]
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name design_1

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_msg_id "BD_TCL-001" "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_msg_id "BD_TCL-002" "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_msg_id "BD_TCL-003" "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_msg_id "BD_TCL-004" "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_msg_id "BD_TCL-005" "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_msg_id "BD_TCL-114" "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
xilinx.com:ip:axi_bram_ctrl:4.1\
xilinx.com:ip:axi_dma:7.1\
xilinx.com:ip:axi_ethernet:7.1\
xilinx.com:ip:axi_timer:2.0\
xilinx.com:ip:axi_uartlite:2.0\
xilinx.com:ip:blk_mem_gen:8.4\
xilinx.com:ip:xlconstant:1.1\
xilinx.com:ip:clk_wiz:6.0\
xilinx.com:ip:fifo_generator:13.2\
xilinx.com:ip:ila:6.2\
xilinx.com:ip:mdm:3.2\
xilinx.com:ip:microblaze:11.0\
xilinx.com:ip:axi_intc:4.1\
xilinx.com:ip:xlconcat:2.1\
xilinx.com:ip:mig_7series:4.2\
xilinx.com:ip:proc_sys_reset:5.0\
xilinx.com:ip:lmb_bram_if_cntlr:4.0\
xilinx.com:ip:lmb_v10:3.0\
"

   set list_ips_missing ""
   common::send_msg_id "BD_TCL-006" "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_msg_id "BD_TCL-115" "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

##################################################################
# CHECK Modules
##################################################################
set bCheckModules 1
if { $bCheckModules == 1 } {
   set list_check_mods "\ 
choose_pivot_row\
fifo_dma\
fifo_dma\
fifo_read_interface\
fifo_read_interface\
fifo_read_interface\
fifo_read_interface\
fifo_redirect\
fifo_write_interface\
fifo_write_interface\
fifo_write_interface\
find_pivot_col\
lp_control_unit\
lp_timer\
mblaze_lp_bridge_v1_0\
update_pivot_row\
update_tableau\
"

   set list_mods_missing ""
   common::send_msg_id "BD_TCL-006" "INFO" "Checking if the following modules exist in the project's sources: $list_check_mods ."

   foreach mod_vlnv $list_check_mods {
      if { [can_resolve_reference $mod_vlnv] == 0 } {
         lappend list_mods_missing $mod_vlnv
      }
   }

   if { $list_mods_missing ne "" } {
      catch {common::send_msg_id "BD_TCL-115" "ERROR" "The following module(s) are not found in the project: $list_mods_missing" }
      common::send_msg_id "BD_TCL-008" "INFO" "Please add source files for the missing module(s) above."
      set bCheckIPsPassed 0
   }
}

if { $bCheckIPsPassed != 1 } {
  common::send_msg_id "BD_TCL-1003" "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################


# Hierarchical cell: microblaze_0_local_memory
proc create_hier_cell_microblaze_0_local_memory { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_microblaze_0_local_memory() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode MirroredMaster -vlnv xilinx.com:interface:lmb_rtl:1.0 DLMB
  create_bd_intf_pin -mode MirroredMaster -vlnv xilinx.com:interface:lmb_rtl:1.0 ILMB

  # Create pins
  create_bd_pin -dir I -type clk LMB_Clk
  create_bd_pin -dir I -type rst SYS_Rst

  # Create instance: dlmb_bram_if_cntlr, and set properties
  set dlmb_bram_if_cntlr [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr:4.0 dlmb_bram_if_cntlr ]
  set_property -dict [ list \
   CONFIG.C_ECC {0} \
 ] $dlmb_bram_if_cntlr

  # Create instance: dlmb_v10, and set properties
  set dlmb_v10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10:3.0 dlmb_v10 ]

  # Create instance: ilmb_bram_if_cntlr, and set properties
  set ilmb_bram_if_cntlr [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr:4.0 ilmb_bram_if_cntlr ]
  set_property -dict [ list \
   CONFIG.C_ECC {0} \
 ] $ilmb_bram_if_cntlr

  # Create instance: ilmb_v10, and set properties
  set ilmb_v10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10:3.0 ilmb_v10 ]

  # Create instance: lmb_bram, and set properties
  set lmb_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 lmb_bram ]
  set_property -dict [ list \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
   CONFIG.use_bram_block {BRAM_Controller} \
 ] $lmb_bram

  # Create interface connections
  connect_bd_intf_net -intf_net microblaze_0_dlmb [get_bd_intf_pins DLMB] [get_bd_intf_pins dlmb_v10/LMB_M]
  connect_bd_intf_net -intf_net microblaze_0_dlmb_bus [get_bd_intf_pins dlmb_bram_if_cntlr/SLMB] [get_bd_intf_pins dlmb_v10/LMB_Sl_0]
  connect_bd_intf_net -intf_net microblaze_0_dlmb_cntlr [get_bd_intf_pins dlmb_bram_if_cntlr/BRAM_PORT] [get_bd_intf_pins lmb_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net microblaze_0_ilmb [get_bd_intf_pins ILMB] [get_bd_intf_pins ilmb_v10/LMB_M]
  connect_bd_intf_net -intf_net microblaze_0_ilmb_bus [get_bd_intf_pins ilmb_bram_if_cntlr/SLMB] [get_bd_intf_pins ilmb_v10/LMB_Sl_0]
  connect_bd_intf_net -intf_net microblaze_0_ilmb_cntlr [get_bd_intf_pins ilmb_bram_if_cntlr/BRAM_PORT] [get_bd_intf_pins lmb_bram/BRAM_PORTB]

  # Create port connections
  connect_bd_net -net SYS_Rst_1 [get_bd_pins SYS_Rst] [get_bd_pins dlmb_bram_if_cntlr/LMB_Rst] [get_bd_pins dlmb_v10/SYS_Rst] [get_bd_pins ilmb_bram_if_cntlr/LMB_Rst] [get_bd_pins ilmb_v10/SYS_Rst]
  connect_bd_net -net microblaze_0_Clk [get_bd_pins LMB_Clk] [get_bd_pins dlmb_bram_if_cntlr/LMB_Clk] [get_bd_pins dlmb_v10/LMB_Clk] [get_bd_pins ilmb_bram_if_cntlr/LMB_Clk] [get_bd_pins ilmb_v10/LMB_Clk]

  # Restore current instance
  current_bd_instance $oldCurInst
}


# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set DDR3_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddrx_rtl:1.0 DDR3_0 ]
  set eth_mdio_mdc [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:mdio_rtl:1.0 eth_mdio_mdc ]
  set eth_rgmii [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:rgmii_rtl:1.0 eth_rgmii ]
  set usb_uart [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 usb_uart ]

  # Create ports
  set phy_reset_out [ create_bd_port -dir O -from 0 -to 0 -type rst phy_reset_out ]
  set reset [ create_bd_port -dir I -type rst reset ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_LOW} \
 ] $reset
  set sys_clock [ create_bd_port -dir I -type clk sys_clock ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {100000000} \
   CONFIG.PHASE {0.000} \
 ] $sys_clock

  # Create instance: axi_bram_ctrl_obj_row, and set properties
  set axi_bram_ctrl_obj_row [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_obj_row ]
  set_property -dict [ list \
   CONFIG.SINGLE_PORT_BRAM {1} \
 ] $axi_bram_ctrl_obj_row

  # Create instance: axi_bram_ctrl_rhs_col, and set properties
  set axi_bram_ctrl_rhs_col [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_rhs_col ]
  set_property -dict [ list \
   CONFIG.SINGLE_PORT_BRAM {1} \
 ] $axi_bram_ctrl_rhs_col

  # Create instance: axi_dma_0, and set properties
  set axi_dma_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 axi_dma_0 ]
  set_property -dict [ list \
   CONFIG.c_include_mm2s_dre {1} \
   CONFIG.c_include_s2mm_dre {1} \
   CONFIG.c_sg_length_width {16} \
   CONFIG.c_sg_use_stsapp_length {1} \
 ] $axi_dma_0

  # Create instance: axi_ethernet_0, and set properties
  set axi_ethernet_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_ethernet:7.1 axi_ethernet_0 ]
  set_property -dict [ list \
   CONFIG.ETHERNET_BOARD_INTERFACE {eth_rgmii} \
   CONFIG.MDIO_BOARD_INTERFACE {eth_mdio_mdc} \
   CONFIG.PHYRST_BOARD_INTERFACE {phy_reset_out} \
   CONFIG.PHY_TYPE {RGMII} \
 ] $axi_ethernet_0

  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_LOW} \
 ] [get_bd_pins /axi_ethernet_0/axi_rxd_arstn]

  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_LOW} \
 ] [get_bd_pins /axi_ethernet_0/axi_rxs_arstn]

  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_LOW} \
 ] [get_bd_pins /axi_ethernet_0/axi_txc_arstn]

  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_LOW} \
 ] [get_bd_pins /axi_ethernet_0/axi_txd_arstn]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {m_axis_rxd:m_axis_rxs:s_axis_txc:s_axis_txd} \
   CONFIG.ASSOCIATED_RESET {axi_rxd_arstn:axi_rxs_arstn:axi_txc_arstn:axi_txd_arstn} \
 ] [get_bd_pins /axi_ethernet_0/axis_clk]

  set_property -dict [ list \
   CONFIG.FREQ_HZ {125000000} \
 ] [get_bd_pins /axi_ethernet_0/gtx_clk]

  set_property -dict [ list \
   CONFIG.SENSITIVITY {LEVEL_HIGH} \
 ] [get_bd_pins /axi_ethernet_0/interrupt]

  set_property -dict [ list \
   CONFIG.SENSITIVITY {EDGE_RISING} \
 ] [get_bd_pins /axi_ethernet_0/mac_irq]

  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_LOW} \
 ] [get_bd_pins /axi_ethernet_0/phy_rst_n]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {s_axi} \
   CONFIG.ASSOCIATED_RESET {s_axi_lite_resetn} \
 ] [get_bd_pins /axi_ethernet_0/s_axi_lite_clk]

  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_LOW} \
 ] [get_bd_pins /axi_ethernet_0/s_axi_lite_resetn]

  # Create instance: axi_interconnect_1, and set properties
  set axi_interconnect_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_1 ]
  set_property -dict [ list \
   CONFIG.NUM_MI {3} \
   CONFIG.NUM_SI {16} \
 ] $axi_interconnect_1

  # Create instance: axi_timer_0, and set properties
  set axi_timer_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_timer:2.0 axi_timer_0 ]

  # Create instance: axi_uartlite_0, and set properties
  set axi_uartlite_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uartlite:2.0 axi_uartlite_0 ]
  set_property -dict [ list \
   CONFIG.UARTLITE_BOARD_INTERFACE {usb_uart} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $axi_uartlite_0

  # Create instance: blk_mem_gen_obj_row, and set properties
  set blk_mem_gen_obj_row [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen_obj_row ]

  # Create instance: blk_mem_gen_rhs_col, and set properties
  set blk_mem_gen_rhs_col [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen_rhs_col ]

  # Create instance: bram_all_wbits, and set properties
  set bram_all_wbits [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 bram_all_wbits ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0xF} \
   CONFIG.CONST_WIDTH {4} \
 ] $bram_all_wbits

  # Create instance: bram_obj_row_base, and set properties
  set bram_obj_row_base [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 bram_obj_row_base ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0xC0000000} \
   CONFIG.CONST_WIDTH {32} \
 ] $bram_obj_row_base

  # Create instance: bram_rhs_col_base, and set properties
  set bram_rhs_col_base [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 bram_rhs_col_base ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0xC2000000} \
   CONFIG.CONST_WIDTH {32} \
 ] $bram_rhs_col_base

  # Create instance: bram_rhs_col_second_elem, and set properties
  set bram_rhs_col_second_elem [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 bram_rhs_col_second_elem ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0xC2000004} \
   CONFIG.CONST_WIDTH {32} \
 ] $bram_rhs_col_second_elem

  # Create instance: choose_pivot_row_0, and set properties
  set block_name choose_pivot_row
  set block_cell_name choose_pivot_row_0
  if { [catch {set choose_pivot_row_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $choose_pivot_row_0 eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: clk_wiz_1, and set properties
  set clk_wiz_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_1 ]
  set_property -dict [ list \
   CONFIG.CLKOUT2_JITTER {114.829} \
   CONFIG.CLKOUT2_PHASE_ERROR {98.575} \
   CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {200.000} \
   CONFIG.CLKOUT2_USED {true} \
   CONFIG.CLKOUT3_JITTER {125.247} \
   CONFIG.CLKOUT3_PHASE_ERROR {98.575} \
   CONFIG.CLKOUT3_REQUESTED_OUT_FREQ {125.000} \
   CONFIG.CLKOUT3_USED {true} \
   CONFIG.CLK_IN1_BOARD_INTERFACE {sys_clock} \
   CONFIG.MMCM_CLKOUT1_DIVIDE {5} \
   CONFIG.MMCM_CLKOUT2_DIVIDE {8} \
   CONFIG.MMCM_DIVCLK_DIVIDE {1} \
   CONFIG.NUM_OUT_CLKS {3} \
   CONFIG.PRIM_SOURCE {Single_ended_clock_capable_pin} \
   CONFIG.RESET_BOARD_INTERFACE {reset} \
   CONFIG.RESET_PORT {resetn} \
   CONFIG.RESET_TYPE {ACTIVE_LOW} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $clk_wiz_1

  # Create instance: fifo_dma_full_pivot_col, and set properties
  set block_name fifo_dma
  set block_cell_name fifo_dma_full_pivot_col
  if { [catch {set fifo_dma_full_pivot_col [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $fifo_dma_full_pivot_col eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: fifo_dma_skip_OR_pivot_col, and set properties
  set block_name fifo_dma
  set block_cell_name fifo_dma_skip_OR_pivot_col
  if { [catch {set fifo_dma_skip_OR_pivot_col [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $fifo_dma_skip_OR_pivot_col eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: fifo_entire_tableau, and set properties
  set fifo_entire_tableau [ create_bd_cell -type ip -vlnv xilinx.com:ip:fifo_generator:13.2 fifo_entire_tableau ]
  set_property -dict [ list \
   CONFIG.Empty_Threshold_Assert_Value_axis {4} \
   CONFIG.Empty_Threshold_Assert_Value_rach {14} \
   CONFIG.Empty_Threshold_Assert_Value_wach {14} \
   CONFIG.Empty_Threshold_Assert_Value_wrch {14} \
   CONFIG.Enable_Safety_Circuit {true} \
   CONFIG.FIFO_Implementation_rach {Common_Clock_Distributed_RAM} \
   CONFIG.FIFO_Implementation_wach {Common_Clock_Distributed_RAM} \
   CONFIG.FIFO_Implementation_wrch {Common_Clock_Distributed_RAM} \
   CONFIG.Full_Flags_Reset_Value {1} \
   CONFIG.Full_Threshold_Assert_Value_rach {15} \
   CONFIG.Full_Threshold_Assert_Value_wach {15} \
   CONFIG.Full_Threshold_Assert_Value_wrch {15} \
   CONFIG.INTERFACE_TYPE {AXI_STREAM} \
   CONFIG.Programmable_Empty_Type_axis {Single_Programmable_Empty_Threshold_Constant} \
   CONFIG.Programmable_Full_Type_axis {Single_Programmable_Full_Threshold_Constant} \
   CONFIG.Reset_Type {Asynchronous_Reset} \
   CONFIG.TDATA_NUM_BYTES {4} \
   CONFIG.TKEEP_WIDTH {4} \
   CONFIG.TSTRB_WIDTH {4} \
   CONFIG.TUSER_WIDTH {0} \
 ] $fifo_entire_tableau

  # Create instance: fifo_generator_1, and set properties
  set fifo_generator_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:fifo_generator:13.2 fifo_generator_1 ]
  set_property -dict [ list \
   CONFIG.Empty_Threshold_Assert_Value_axis {4} \
   CONFIG.Empty_Threshold_Assert_Value_rach {14} \
   CONFIG.Empty_Threshold_Assert_Value_wach {14} \
   CONFIG.Empty_Threshold_Assert_Value_wrch {14} \
   CONFIG.Enable_Safety_Circuit {true} \
   CONFIG.FIFO_Implementation_rach {Common_Clock_Distributed_RAM} \
   CONFIG.FIFO_Implementation_wach {Common_Clock_Distributed_RAM} \
   CONFIG.FIFO_Implementation_wrch {Common_Clock_Distributed_RAM} \
   CONFIG.Full_Flags_Reset_Value {1} \
   CONFIG.Full_Threshold_Assert_Value_rach {15} \
   CONFIG.Full_Threshold_Assert_Value_wach {15} \
   CONFIG.Full_Threshold_Assert_Value_wrch {15} \
   CONFIG.INTERFACE_TYPE {AXI_STREAM} \
   CONFIG.Programmable_Empty_Type_axis {Single_Programmable_Empty_Threshold_Constant} \
   CONFIG.Programmable_Full_Type_axis {Single_Programmable_Full_Threshold_Constant} \
   CONFIG.Reset_Type {Asynchronous_Reset} \
   CONFIG.TDATA_NUM_BYTES {4} \
   CONFIG.TKEEP_WIDTH {4} \
   CONFIG.TSTRB_WIDTH {4} \
   CONFIG.TUSER_WIDTH {0} \
 ] $fifo_generator_1

  # Create instance: fifo_generator_2, and set properties
  set fifo_generator_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:fifo_generator:13.2 fifo_generator_2 ]
  set_property -dict [ list \
   CONFIG.Empty_Threshold_Assert_Value_axis {4} \
   CONFIG.Empty_Threshold_Assert_Value_rach {14} \
   CONFIG.Empty_Threshold_Assert_Value_wach {14} \
   CONFIG.Empty_Threshold_Assert_Value_wrch {14} \
   CONFIG.Enable_Safety_Circuit {true} \
   CONFIG.FIFO_Implementation_rach {Common_Clock_Distributed_RAM} \
   CONFIG.FIFO_Implementation_wach {Common_Clock_Distributed_RAM} \
   CONFIG.FIFO_Implementation_wrch {Common_Clock_Distributed_RAM} \
   CONFIG.Full_Flags_Reset_Value {1} \
   CONFIG.Full_Threshold_Assert_Value_rach {15} \
   CONFIG.Full_Threshold_Assert_Value_wach {15} \
   CONFIG.Full_Threshold_Assert_Value_wrch {15} \
   CONFIG.INTERFACE_TYPE {AXI_STREAM} \
   CONFIG.Programmable_Empty_Type_axis {Single_Programmable_Empty_Threshold_Constant} \
   CONFIG.Programmable_Full_Type_axis {Single_Programmable_Full_Threshold_Constant} \
   CONFIG.Reset_Type {Asynchronous_Reset} \
   CONFIG.TDATA_NUM_BYTES {4} \
   CONFIG.TKEEP_WIDTH {4} \
   CONFIG.TSTRB_WIDTH {4} \
   CONFIG.TUSER_WIDTH {0} \
 ] $fifo_generator_2

  # Create instance: fifo_generator_3, and set properties
  set fifo_generator_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:fifo_generator:13.2 fifo_generator_3 ]
  set_property -dict [ list \
   CONFIG.Empty_Threshold_Assert_Value_axis {4} \
   CONFIG.Empty_Threshold_Assert_Value_rach {14} \
   CONFIG.Empty_Threshold_Assert_Value_wach {14} \
   CONFIG.Empty_Threshold_Assert_Value_wrch {14} \
   CONFIG.Enable_Safety_Circuit {true} \
   CONFIG.FIFO_Implementation_rach {Common_Clock_Distributed_RAM} \
   CONFIG.FIFO_Implementation_wach {Common_Clock_Distributed_RAM} \
   CONFIG.FIFO_Implementation_wrch {Common_Clock_Distributed_RAM} \
   CONFIG.Full_Flags_Reset_Value {1} \
   CONFIG.Full_Threshold_Assert_Value_rach {15} \
   CONFIG.Full_Threshold_Assert_Value_wach {15} \
   CONFIG.Full_Threshold_Assert_Value_wrch {15} \
   CONFIG.INTERFACE_TYPE {AXI_STREAM} \
   CONFIG.Programmable_Empty_Type_axis {Single_Programmable_Empty_Threshold_Constant} \
   CONFIG.Programmable_Full_Type_axis {Single_Programmable_Full_Threshold_Constant} \
   CONFIG.Reset_Type {Asynchronous_Reset} \
   CONFIG.TDATA_NUM_BYTES {4} \
   CONFIG.TKEEP_WIDTH {4} \
   CONFIG.TSTRB_WIDTH {4} \
   CONFIG.TUSER_WIDTH {0} \
 ] $fifo_generator_3

  # Create instance: fifo_obj_row, and set properties
  set fifo_obj_row [ create_bd_cell -type ip -vlnv xilinx.com:ip:fifo_generator:13.2 fifo_obj_row ]
  set_property -dict [ list \
   CONFIG.Empty_Threshold_Assert_Value_axis {4} \
   CONFIG.Empty_Threshold_Assert_Value_rach {14} \
   CONFIG.Empty_Threshold_Assert_Value_wach {14} \
   CONFIG.Empty_Threshold_Assert_Value_wrch {14} \
   CONFIG.Enable_Safety_Circuit {true} \
   CONFIG.FIFO_Implementation_rach {Common_Clock_Distributed_RAM} \
   CONFIG.FIFO_Implementation_wach {Common_Clock_Distributed_RAM} \
   CONFIG.FIFO_Implementation_wrch {Common_Clock_Distributed_RAM} \
   CONFIG.Full_Flags_Reset_Value {1} \
   CONFIG.Full_Threshold_Assert_Value_rach {15} \
   CONFIG.Full_Threshold_Assert_Value_wach {15} \
   CONFIG.Full_Threshold_Assert_Value_wrch {15} \
   CONFIG.INTERFACE_TYPE {AXI_STREAM} \
   CONFIG.Programmable_Empty_Type_axis {Single_Programmable_Empty_Threshold_Constant} \
   CONFIG.Programmable_Full_Type_axis {Single_Programmable_Full_Threshold_Constant} \
   CONFIG.Reset_Type {Asynchronous_Reset} \
   CONFIG.TDATA_NUM_BYTES {4} \
   CONFIG.TKEEP_WIDTH {4} \
   CONFIG.TSTRB_WIDTH {4} \
   CONFIG.TUSER_WIDTH {0} \
 ] $fifo_obj_row

  # Create instance: fifo_pivot_row, and set properties
  set fifo_pivot_row [ create_bd_cell -type ip -vlnv xilinx.com:ip:fifo_generator:13.2 fifo_pivot_row ]
  set_property -dict [ list \
   CONFIG.Empty_Threshold_Assert_Value_axis {4} \
   CONFIG.Empty_Threshold_Assert_Value_rach {14} \
   CONFIG.Empty_Threshold_Assert_Value_wach {14} \
   CONFIG.Empty_Threshold_Assert_Value_wrch {14} \
   CONFIG.Enable_Safety_Circuit {true} \
   CONFIG.FIFO_Implementation_rach {Common_Clock_Distributed_RAM} \
   CONFIG.FIFO_Implementation_wach {Common_Clock_Distributed_RAM} \
   CONFIG.FIFO_Implementation_wrch {Common_Clock_Distributed_RAM} \
   CONFIG.Full_Flags_Reset_Value {1} \
   CONFIG.Full_Threshold_Assert_Value_rach {15} \
   CONFIG.Full_Threshold_Assert_Value_wach {15} \
   CONFIG.Full_Threshold_Assert_Value_wrch {15} \
   CONFIG.INTERFACE_TYPE {AXI_STREAM} \
   CONFIG.Programmable_Empty_Type_axis {Single_Programmable_Empty_Threshold_Constant} \
   CONFIG.Programmable_Full_Type_axis {Single_Programmable_Full_Threshold_Constant} \
   CONFIG.Reset_Type {Asynchronous_Reset} \
   CONFIG.TDATA_NUM_BYTES {4} \
   CONFIG.TKEEP_WIDTH {4} \
   CONFIG.TSTRB_WIDTH {4} \
   CONFIG.TUSER_WIDTH {0} \
 ] $fifo_pivot_row

  # Create instance: fifo_read_entire_tableau, and set properties
  set block_name fifo_read_interface
  set block_cell_name fifo_read_entire_tableau
  if { [catch {set fifo_read_entire_tableau [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $fifo_read_entire_tableau eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.NUM_ELEMENTS_WIDTH {32} \
 ] $fifo_read_entire_tableau

  # Create instance: fifo_read_obj_row, and set properties
  set block_name fifo_read_interface
  set block_cell_name fifo_read_obj_row
  if { [catch {set fifo_read_obj_row [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $fifo_read_obj_row eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: fifo_read_pivot_row, and set properties
  set block_name fifo_read_interface
  set block_cell_name fifo_read_pivot_row
  if { [catch {set fifo_read_pivot_row [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $fifo_read_pivot_row eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: fifo_read_skip_OR_rhs_col, and set properties
  set block_name fifo_read_interface
  set block_cell_name fifo_read_skip_OR_rhs_col
  if { [catch {set fifo_read_skip_OR_rhs_col [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $fifo_read_skip_OR_rhs_col eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: fifo_redirect_1, and set properties
  set block_name fifo_redirect
  set block_cell_name fifo_redirect_1
  if { [catch {set fifo_redirect_1 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $fifo_redirect_1 eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: fifo_write_interface_0, and set properties
  set block_name fifo_write_interface
  set block_cell_name fifo_write_interface_0
  if { [catch {set fifo_write_interface_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $fifo_write_interface_0 eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: fifo_write_interface_1, and set properties
  set block_name fifo_write_interface
  set block_cell_name fifo_write_interface_1
  if { [catch {set fifo_write_interface_1 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $fifo_write_interface_1 eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: fifo_write_interface_2, and set properties
  set block_name fifo_write_interface
  set block_cell_name fifo_write_interface_2
  if { [catch {set fifo_write_interface_2 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $fifo_write_interface_2 eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.NUM_ELEMENTS_WIDTH {32} \
 ] $fifo_write_interface_2

  # Create instance: find_pivot_col_0, and set properties
  set block_name find_pivot_col
  set block_cell_name find_pivot_col_0
  if { [catch {set find_pivot_col_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $find_pivot_col_0 eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: full_pivot_column, and set properties
  set full_pivot_column [ create_bd_cell -type ip -vlnv xilinx.com:ip:fifo_generator:13.2 full_pivot_column ]
  set_property -dict [ list \
   CONFIG.Empty_Threshold_Assert_Value_axis {4} \
   CONFIG.Empty_Threshold_Assert_Value_rach {14} \
   CONFIG.Empty_Threshold_Assert_Value_wach {14} \
   CONFIG.Empty_Threshold_Assert_Value_wrch {14} \
   CONFIG.Enable_Safety_Circuit {true} \
   CONFIG.FIFO_Implementation_rach {Common_Clock_Distributed_RAM} \
   CONFIG.FIFO_Implementation_wach {Common_Clock_Distributed_RAM} \
   CONFIG.FIFO_Implementation_wrch {Common_Clock_Distributed_RAM} \
   CONFIG.Full_Flags_Reset_Value {1} \
   CONFIG.Full_Threshold_Assert_Value_rach {15} \
   CONFIG.Full_Threshold_Assert_Value_wach {15} \
   CONFIG.Full_Threshold_Assert_Value_wrch {15} \
   CONFIG.INTERFACE_TYPE {AXI_STREAM} \
   CONFIG.Programmable_Empty_Type_axis {Single_Programmable_Empty_Threshold_Constant} \
   CONFIG.Programmable_Full_Type_axis {Single_Programmable_Full_Threshold_Constant} \
   CONFIG.Reset_Type {Asynchronous_Reset} \
   CONFIG.TDATA_NUM_BYTES {4} \
   CONFIG.TKEEP_WIDTH {4} \
   CONFIG.TSTRB_WIDTH {4} \
   CONFIG.TUSER_WIDTH {0} \
 ] $full_pivot_column

  # Create instance: ila_0, and set properties
  set ila_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 ila_0 ]
  set_property -dict [ list \
   CONFIG.C_DATA_DEPTH {4096} \
 ] $ila_0

  # Create instance: ila_choose_pivot_row, and set properties
  set ila_choose_pivot_row [ create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 ila_choose_pivot_row ]
  set_property -dict [ list \
   CONFIG.C_DATA_DEPTH {4096} \
   CONFIG.C_ENABLE_ILA_AXI_MON {false} \
   CONFIG.C_MONITOR_TYPE {Native} \
   CONFIG.C_NUM_OF_PROBES {6} \
   CONFIG.C_PROBE0_WIDTH {32} \
   CONFIG.C_PROBE1_WIDTH {16} \
   CONFIG.C_PROBE5_WIDTH {16} \
 ] $ila_choose_pivot_row

  # Create instance: ila_find_pivot_col, and set properties
  set ila_find_pivot_col [ create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 ila_find_pivot_col ]
  set_property -dict [ list \
   CONFIG.C_DATA_DEPTH {4096} \
   CONFIG.C_ENABLE_ILA_AXI_MON {false} \
   CONFIG.C_MONITOR_TYPE {Native} \
   CONFIG.C_NUM_OF_PROBES {4} \
   CONFIG.C_PROBE0_WIDTH {1} \
   CONFIG.C_PROBE1_WIDTH {1} \
   CONFIG.C_PROBE2_WIDTH {16} \
   CONFIG.C_PROBE3_WIDTH {16} \
 ] $ila_find_pivot_col

  # Create instance: ila_lp_control, and set properties
  set ila_lp_control [ create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 ila_lp_control ]
  set_property -dict [ list \
   CONFIG.C_DATA_DEPTH {4096} \
   CONFIG.C_ENABLE_ILA_AXI_MON {false} \
   CONFIG.C_MONITOR_TYPE {Native} \
   CONFIG.C_NUM_OF_PROBES {29} \
   CONFIG.C_PROBE10_WIDTH {32} \
   CONFIG.C_PROBE11_WIDTH {16} \
   CONFIG.C_PROBE12_WIDTH {16} \
   CONFIG.C_PROBE17_WIDTH {32} \
   CONFIG.C_PROBE18_WIDTH {32} \
   CONFIG.C_PROBE21_WIDTH {32} \
   CONFIG.C_PROBE22_WIDTH {16} \
   CONFIG.C_PROBE28_WIDTH {16} \
   CONFIG.C_PROBE9_WIDTH {16} \
 ] $ila_lp_control

  # Create instance: ila_mblaze_bridge, and set properties
  set ila_mblaze_bridge [ create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 ila_mblaze_bridge ]
  set_property -dict [ list \
   CONFIG.C_DATA_DEPTH {4096} \
   CONFIG.C_ENABLE_ILA_AXI_MON {false} \
   CONFIG.C_MONITOR_TYPE {Native} \
   CONFIG.C_NUM_OF_PROBES {6} \
   CONFIG.C_PROBE12_WIDTH {1} \
   CONFIG.C_PROBE1_WIDTH {16} \
   CONFIG.C_PROBE2_WIDTH {16} \
   CONFIG.C_PROBE3_WIDTH {32} \
   CONFIG.C_PROBE4_WIDTH {16} \
   CONFIG.C_PROBE5_WIDTH {16} \
   CONFIG.C_PROBE6_WIDTH {1} \
   CONFIG.C_PROBE7_WIDTH {1} \
   CONFIG.C_PROBE9_WIDTH {1} \
 ] $ila_mblaze_bridge

  # Create instance: ila_pivot_col_IN_AXIS, and set properties
  set ila_pivot_col_IN_AXIS [ create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 ila_pivot_col_IN_AXIS ]
  set_property -dict [ list \
   CONFIG.C_DATA_DEPTH {4096} \
   CONFIG.C_ENABLE_ILA_AXI_MON {true} \
   CONFIG.C_MONITOR_TYPE {AXI} \
   CONFIG.C_NUM_OF_PROBES {4} \
   CONFIG.C_PROBE0_WIDTH {1} \
   CONFIG.C_SLOT_0_AXI_PROTOCOL {AXI4S} \
 ] $ila_pivot_col_IN_AXIS

  # Create instance: ila_pivot_col_PR, and set properties
  set ila_pivot_col_PR [ create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 ila_pivot_col_PR ]
  set_property -dict [ list \
   CONFIG.C_NUM_OF_PROBES {9} \
   CONFIG.C_SLOT_0_AXI_PROTOCOL {AXI4S} \
 ] $ila_pivot_col_PR

  # Create instance: ila_rhs_PR, and set properties
  set ila_rhs_PR [ create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 ila_rhs_PR ]
  set_property -dict [ list \
   CONFIG.C_NUM_OF_PROBES {9} \
   CONFIG.C_SLOT_0_AXI_PROTOCOL {AXI4S} \
 ] $ila_rhs_PR

  # Create instance: ila_tableau_IN_AXIS, and set properties
  set ila_tableau_IN_AXIS [ create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 ila_tableau_IN_AXIS ]
  set_property -dict [ list \
   CONFIG.C_DATA_DEPTH {4096} \
   CONFIG.C_NUM_OF_PROBES {9} \
   CONFIG.C_SLOT_0_AXI_PROTOCOL {AXI4S} \
 ] $ila_tableau_IN_AXIS

  # Create instance: ila_update_pivot_row, and set properties
  set ila_update_pivot_row [ create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 ila_update_pivot_row ]
  set_property -dict [ list \
   CONFIG.C_DATA_DEPTH {4096} \
   CONFIG.C_ENABLE_ILA_AXI_MON {false} \
   CONFIG.C_MONITOR_TYPE {Native} \
   CONFIG.C_NUM_OF_PROBES {7} \
   CONFIG.C_PROBE10_WIDTH {1} \
   CONFIG.C_PROBE2_WIDTH {1} \
   CONFIG.C_PROBE3_WIDTH {1} \
   CONFIG.C_PROBE4_WIDTH {32} \
   CONFIG.C_PROBE5_WIDTH {32} \
   CONFIG.C_PROBE6_WIDTH {16} \
   CONFIG.C_PROBE7_WIDTH {1} \
 ] $ila_update_pivot_row

  # Create instance: ila_update_tableau, and set properties
  set ila_update_tableau [ create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 ila_update_tableau ]
  set_property -dict [ list \
   CONFIG.C_DATA_DEPTH {4096} \
   CONFIG.C_ENABLE_ILA_AXI_MON {false} \
   CONFIG.C_MONITOR_TYPE {Native} \
   CONFIG.C_NUM_OF_PROBES {25} \
   CONFIG.C_PROBE11_WIDTH {16} \
   CONFIG.C_PROBE12_WIDTH {16} \
   CONFIG.C_PROBE16_WIDTH {3} \
   CONFIG.C_PROBE18_WIDTH {32} \
   CONFIG.C_PROBE19_WIDTH {32} \
   CONFIG.C_PROBE20_WIDTH {32} \
   CONFIG.C_PROBE24_WIDTH {16} \
   CONFIG.C_PROBE3_WIDTH {16} \
   CONFIG.C_PROBE4_WIDTH {16} \
   CONFIG.C_PROBE5_WIDTH {32} \
   CONFIG.C_PROBE6_WIDTH {32} \
   CONFIG.C_PROBE7_WIDTH {3} \
 ] $ila_update_tableau

  # Create instance: ila_update_tableau_out_AXIS, and set properties
  set ila_update_tableau_out_AXIS [ create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 ila_update_tableau_out_AXIS ]
  set_property -dict [ list \
   CONFIG.C_DATA_DEPTH {4096} \
   CONFIG.C_NUM_OF_PROBES {9} \
   CONFIG.C_SLOT_0_AXI_PROTOCOL {AXI4S} \
 ] $ila_update_tableau_out_AXIS

  # Create instance: ila_writeback, and set properties
  set ila_writeback [ create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 ila_writeback ]
  set_property -dict [ list \
   CONFIG.C_DATA_DEPTH {4096} \
   CONFIG.C_ENABLE_ILA_AXI_MON {false} \
   CONFIG.C_MONITOR_TYPE {Native} \
   CONFIG.C_NUM_OF_PROBES {18} \
   CONFIG.C_PROBE0_WIDTH {32} \
   CONFIG.C_PROBE13_WIDTH {1} \
   CONFIG.C_PROBE14_WIDTH {1} \
   CONFIG.C_PROBE15_WIDTH {32} \
   CONFIG.C_PROBE16_WIDTH {32} \
   CONFIG.C_PROBE17_WIDTH {32} \
   CONFIG.C_PROBE18_WIDTH {1} \
   CONFIG.C_PROBE19_WIDTH {1} \
   CONFIG.C_PROBE1_WIDTH {16} \
   CONFIG.C_PROBE26_WIDTH {1} \
   CONFIG.C_PROBE27_WIDTH {1} \
   CONFIG.C_PROBE28_WIDTH {1} \
   CONFIG.C_PROBE29_WIDTH {1} \
   CONFIG.C_PROBE2_WIDTH {32} \
   CONFIG.C_PROBE30_WIDTH {1} \
   CONFIG.C_SLOT_0_AXI_PROTOCOL {AXI4S} \
 ] $ila_writeback

  # Create instance: lp_control_unit_0, and set properties
  set block_name lp_control_unit
  set block_cell_name lp_control_unit_0
  if { [catch {set lp_control_unit_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $lp_control_unit_0 eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: lp_timer_0, and set properties
  set block_name lp_timer
  set block_cell_name lp_timer_0
  if { [catch {set lp_timer_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $lp_timer_0 eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: mblaze_lp_bridge_v1_0_1, and set properties
  set block_name mblaze_lp_bridge_v1_0
  set block_cell_name mblaze_lp_bridge_v1_0_1
  if { [catch {set mblaze_lp_bridge_v1_0_1 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $mblaze_lp_bridge_v1_0_1 eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: mdm_1, and set properties
  set mdm_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:mdm:3.2 mdm_1 ]

  # Create instance: microblaze_0, and set properties
  set microblaze_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze:11.0 microblaze_0 ]
  set_property -dict [ list \
   CONFIG.C_ADDR_TAG_BITS {16} \
   CONFIG.C_CACHE_BYTE_SIZE {32768} \
   CONFIG.C_DCACHE_ADDR_TAG {16} \
   CONFIG.C_DCACHE_BYTE_SIZE {32768} \
   CONFIG.C_DEBUG_ENABLED {1} \
   CONFIG.C_D_AXI {1} \
   CONFIG.C_D_LMB {1} \
   CONFIG.C_I_AXI {1} \
   CONFIG.C_I_LMB {1} \
   CONFIG.C_USE_DCACHE {1} \
   CONFIG.C_USE_FPU {1} \
   CONFIG.C_USE_ICACHE {1} \
 ] $microblaze_0

  # Create instance: microblaze_0_axi_intc, and set properties
  set microblaze_0_axi_intc [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc:4.1 microblaze_0_axi_intc ]
  set_property -dict [ list \
   CONFIG.C_HAS_FAST {1} \
 ] $microblaze_0_axi_intc

  # Create instance: microblaze_0_axi_periph, and set properties
  set microblaze_0_axi_periph [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 microblaze_0_axi_periph ]
  set_property -dict [ list \
   CONFIG.NUM_MI {8} \
 ] $microblaze_0_axi_periph

  # Create instance: microblaze_0_local_memory
  create_hier_cell_microblaze_0_local_memory [current_bd_instance .] microblaze_0_local_memory

  # Create instance: microblaze_0_xlconcat, and set properties
  set microblaze_0_xlconcat [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 microblaze_0_xlconcat ]
  set_property -dict [ list \
   CONFIG.NUM_PORTS {6} \
 ] $microblaze_0_xlconcat

  # Create instance: mig_7series_0, and set properties
  set mig_7series_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:mig_7series:4.2 mig_7series_0 ]
  set_property -dict [ list \
   CONFIG.RESET_BOARD_INTERFACE {reset} \
 ] $mig_7series_0

  # Create instance: pivot_row, and set properties
  set pivot_row [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 pivot_row ]
  set_property -dict [ list \
   CONFIG.Assume_Synchronous_Clk {true} \
   CONFIG.Byte_Size {8} \
   CONFIG.EN_SAFETY_CKT {false} \
   CONFIG.Enable_32bit_Address {true} \
   CONFIG.Enable_A {Use_ENA_Pin} \
   CONFIG.Enable_B {Always_Enabled} \
   CONFIG.Memory_Type {Simple_Dual_Port_RAM} \
   CONFIG.Operating_Mode_A {NO_CHANGE} \
   CONFIG.Operating_Mode_B {READ_FIRST} \
   CONFIG.Port_B_Clock {100} \
   CONFIG.Port_B_Enable_Rate {100} \
   CONFIG.Port_B_Write_Rate {0} \
   CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
   CONFIG.Register_PortB_Output_of_Memory_Primitives {true} \
   CONFIG.Use_Byte_Write_Enable {true} \
   CONFIG.Use_RSTA_Pin {false} \
   CONFIG.Use_RSTB_Pin {false} \
   CONFIG.Write_Depth_A {65536} \
   CONFIG.use_bram_block {Stand_Alone} \
 ] $pivot_row

  # Create instance: rst_clk_wiz_1_100M, and set properties
  set rst_clk_wiz_1_100M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_clk_wiz_1_100M ]
  set_property -dict [ list \
   CONFIG.RESET_BOARD_INTERFACE {reset} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $rst_clk_wiz_1_100M

  # Create instance: rst_mig_7series_0_100M, and set properties
  set rst_mig_7series_0_100M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_mig_7series_0_100M ]

  # Create instance: skip_OR_pivot_col, and set properties
  set skip_OR_pivot_col [ create_bd_cell -type ip -vlnv xilinx.com:ip:fifo_generator:13.2 skip_OR_pivot_col ]
  set_property -dict [ list \
   CONFIG.Empty_Threshold_Assert_Value_axis {4} \
   CONFIG.Empty_Threshold_Assert_Value_rach {14} \
   CONFIG.Empty_Threshold_Assert_Value_wach {14} \
   CONFIG.Empty_Threshold_Assert_Value_wrch {14} \
   CONFIG.Enable_Safety_Circuit {true} \
   CONFIG.FIFO_Implementation_rach {Common_Clock_Distributed_RAM} \
   CONFIG.FIFO_Implementation_wach {Common_Clock_Distributed_RAM} \
   CONFIG.FIFO_Implementation_wrch {Common_Clock_Distributed_RAM} \
   CONFIG.Full_Flags_Reset_Value {1} \
   CONFIG.Full_Threshold_Assert_Value_rach {15} \
   CONFIG.Full_Threshold_Assert_Value_wach {15} \
   CONFIG.Full_Threshold_Assert_Value_wrch {15} \
   CONFIG.INTERFACE_TYPE {AXI_STREAM} \
   CONFIG.Programmable_Empty_Type_axis {Single_Programmable_Empty_Threshold_Constant} \
   CONFIG.Programmable_Full_Type_axis {Single_Programmable_Full_Threshold_Constant} \
   CONFIG.Reset_Type {Asynchronous_Reset} \
   CONFIG.TDATA_NUM_BYTES {4} \
   CONFIG.TKEEP_WIDTH {4} \
   CONFIG.TSTRB_WIDTH {4} \
   CONFIG.TUSER_WIDTH {0} \
 ] $skip_OR_pivot_col

  # Create instance: skip_OR_rhs_col, and set properties
  set skip_OR_rhs_col [ create_bd_cell -type ip -vlnv xilinx.com:ip:fifo_generator:13.2 skip_OR_rhs_col ]
  set_property -dict [ list \
   CONFIG.Empty_Threshold_Assert_Value_axis {4} \
   CONFIG.Empty_Threshold_Assert_Value_rach {14} \
   CONFIG.Empty_Threshold_Assert_Value_wach {14} \
   CONFIG.Empty_Threshold_Assert_Value_wrch {14} \
   CONFIG.Enable_Safety_Circuit {true} \
   CONFIG.FIFO_Implementation_rach {Common_Clock_Distributed_RAM} \
   CONFIG.FIFO_Implementation_wach {Common_Clock_Distributed_RAM} \
   CONFIG.FIFO_Implementation_wrch {Common_Clock_Distributed_RAM} \
   CONFIG.Full_Flags_Reset_Value {1} \
   CONFIG.Full_Threshold_Assert_Value_rach {15} \
   CONFIG.Full_Threshold_Assert_Value_wach {15} \
   CONFIG.Full_Threshold_Assert_Value_wrch {15} \
   CONFIG.INTERFACE_TYPE {AXI_STREAM} \
   CONFIG.Programmable_Empty_Type_axis {Single_Programmable_Empty_Threshold_Constant} \
   CONFIG.Programmable_Full_Type_axis {Single_Programmable_Full_Threshold_Constant} \
   CONFIG.Reset_Type {Asynchronous_Reset} \
   CONFIG.TDATA_NUM_BYTES {4} \
   CONFIG.TKEEP_WIDTH {4} \
   CONFIG.TSTRB_WIDTH {4} \
   CONFIG.TUSER_WIDTH {0} \
 ] $skip_OR_rhs_col

  # Create instance: update_pivot_row_0, and set properties
  set block_name update_pivot_row
  set block_cell_name update_pivot_row_0
  if { [catch {set update_pivot_row_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $update_pivot_row_0 eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: update_tableau_0, and set properties
  set block_name update_tableau
  set block_cell_name update_tableau_0
  if { [catch {set update_tableau_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $update_tableau_0 eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create interface connections
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_rhs_col/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen_rhs_col/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_obj_row_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_obj_row/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen_obj_row/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_dma_0_M_AXIS_CNTRL [get_bd_intf_pins axi_dma_0/M_AXIS_CNTRL] [get_bd_intf_pins axi_ethernet_0/s_axis_txc]
  connect_bd_intf_net -intf_net axi_dma_0_M_AXIS_MM2S [get_bd_intf_pins axi_dma_0/M_AXIS_MM2S] [get_bd_intf_pins axi_ethernet_0/s_axis_txd]
  connect_bd_intf_net -intf_net axi_dma_0_M_AXI_MM2S [get_bd_intf_pins axi_dma_0/M_AXI_MM2S] [get_bd_intf_pins axi_interconnect_1/S14_AXI]
  connect_bd_intf_net -intf_net axi_dma_0_M_AXI_S2MM [get_bd_intf_pins axi_dma_0/M_AXI_S2MM] [get_bd_intf_pins axi_interconnect_1/S15_AXI]
  connect_bd_intf_net -intf_net axi_dma_0_M_AXI_SG [get_bd_intf_pins axi_dma_0/M_AXI_SG] [get_bd_intf_pins axi_interconnect_1/S13_AXI]
  connect_bd_intf_net -intf_net axi_ethernet_0_m_axis_rxd [get_bd_intf_pins axi_dma_0/S_AXIS_S2MM] [get_bd_intf_pins axi_ethernet_0/m_axis_rxd]
  connect_bd_intf_net -intf_net axi_ethernet_0_m_axis_rxs [get_bd_intf_pins axi_dma_0/S_AXIS_STS] [get_bd_intf_pins axi_ethernet_0/m_axis_rxs]
  connect_bd_intf_net -intf_net axi_ethernet_0_mdio [get_bd_intf_ports eth_mdio_mdc] [get_bd_intf_pins axi_ethernet_0/mdio]
  connect_bd_intf_net -intf_net axi_ethernet_0_rgmii [get_bd_intf_ports eth_rgmii] [get_bd_intf_pins axi_ethernet_0/rgmii]
  connect_bd_intf_net -intf_net axi_interconnect_1_M00_AXI [get_bd_intf_pins axi_bram_ctrl_rhs_col/S_AXI] [get_bd_intf_pins axi_interconnect_1/M00_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_1_M01_AXI [get_bd_intf_pins axi_bram_ctrl_obj_row/S_AXI] [get_bd_intf_pins axi_interconnect_1/M01_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_1_M02_AXI [get_bd_intf_pins axi_interconnect_1/M02_AXI] [get_bd_intf_pins mig_7series_0/S_AXI]
  connect_bd_intf_net -intf_net axi_uartlite_0_UART [get_bd_intf_ports usb_uart] [get_bd_intf_pins axi_uartlite_0/UART]
  connect_bd_intf_net -intf_net fifo_dma_0_M_AXI [get_bd_intf_pins axi_interconnect_1/S05_AXI] [get_bd_intf_pins fifo_dma_skip_OR_pivot_col/M_AXI]
  connect_bd_intf_net -intf_net fifo_dma_0_M_AXIS [get_bd_intf_pins fifo_dma_skip_OR_pivot_col/M_AXIS] [get_bd_intf_pins skip_OR_pivot_col/S_AXIS]
  connect_bd_intf_net -intf_net fifo_dma_1_M_AXI [get_bd_intf_pins axi_interconnect_1/S08_AXI] [get_bd_intf_pins fifo_dma_full_pivot_col/M_AXI]
  connect_bd_intf_net -intf_net fifo_dma_1_M_AXIS [get_bd_intf_pins fifo_dma_full_pivot_col/M_AXIS] [get_bd_intf_pins full_pivot_column/S_AXIS]
  connect_bd_intf_net -intf_net fifo_generator_0_M_AXIS [get_bd_intf_pins fifo_obj_row/M_AXIS] [get_bd_intf_pins find_pivot_col_0/S_AXIS]
  connect_bd_intf_net -intf_net fifo_generator_1_M_AXIS [get_bd_intf_pins fifo_generator_1/M_AXIS] [get_bd_intf_pins fifo_write_interface_2/S_AXIS]
  connect_bd_intf_net -intf_net fifo_generator_2_M_AXIS [get_bd_intf_pins fifo_generator_2/M_AXIS] [get_bd_intf_pins fifo_write_interface_0/S_AXIS]
  connect_bd_intf_net -intf_net fifo_generator_3_M_AXIS [get_bd_intf_pins fifo_generator_3/M_AXIS] [get_bd_intf_pins fifo_write_interface_1/S_AXIS]
  connect_bd_intf_net -intf_net fifo_generator_4_M_AXIS [get_bd_intf_pins choose_pivot_row_0/S_AXIS_PIVOT_COL] [get_bd_intf_pins skip_OR_pivot_col/M_AXIS]
connect_bd_intf_net -intf_net [get_bd_intf_nets fifo_generator_4_M_AXIS] [get_bd_intf_pins ila_pivot_col_PR/SLOT_0_AXIS] [get_bd_intf_pins skip_OR_pivot_col/M_AXIS]
  connect_bd_intf_net -intf_net fifo_generator_5_M_AXIS [get_bd_intf_pins choose_pivot_row_0/S_AXIS_RHS_COL] [get_bd_intf_pins skip_OR_rhs_col/M_AXIS]
connect_bd_intf_net -intf_net [get_bd_intf_nets fifo_generator_5_M_AXIS] [get_bd_intf_pins ila_rhs_PR/SLOT_0_AXIS] [get_bd_intf_pins skip_OR_rhs_col/M_AXIS]
  connect_bd_intf_net -intf_net fifo_generator_6_M_AXIS [get_bd_intf_pins fifo_pivot_row/M_AXIS] [get_bd_intf_pins update_pivot_row_0/S_AXIS_PIVOTROW]
  connect_bd_intf_net -intf_net fifo_generator_7_M_AXIS [get_bd_intf_pins fifo_entire_tableau/M_AXIS] [get_bd_intf_pins update_tableau_0/S_AXIS_TABLEAU]
connect_bd_intf_net -intf_net [get_bd_intf_nets fifo_generator_7_M_AXIS] [get_bd_intf_pins fifo_entire_tableau/M_AXIS] [get_bd_intf_pins ila_tableau_IN_AXIS/SLOT_0_AXIS]
  connect_bd_intf_net -intf_net fifo_mig_interface_0_M_AXI [get_bd_intf_pins axi_interconnect_1/S04_AXI] [get_bd_intf_pins fifo_read_obj_row/M_AXI]
connect_bd_intf_net -intf_net [get_bd_intf_nets fifo_mig_interface_0_M_AXI] [get_bd_intf_pins fifo_read_obj_row/M_AXI] [get_bd_intf_pins ila_0/SLOT_0_AXI]
  connect_bd_intf_net -intf_net fifo_read_interface_0_M_AXI [get_bd_intf_pins axi_interconnect_1/S06_AXI] [get_bd_intf_pins fifo_read_skip_OR_rhs_col/M_AXI]
  connect_bd_intf_net -intf_net fifo_read_interface_0_M_AXI1 [get_bd_intf_pins axi_interconnect_1/S07_AXI] [get_bd_intf_pins fifo_read_pivot_row/M_AXI]
  connect_bd_intf_net -intf_net fifo_read_interface_0_M_AXIS [get_bd_intf_pins fifo_obj_row/S_AXIS] [get_bd_intf_pins fifo_read_obj_row/M_AXIS]
  connect_bd_intf_net -intf_net fifo_read_interface_0_M_AXIS1 [get_bd_intf_pins fifo_read_skip_OR_rhs_col/M_AXIS] [get_bd_intf_pins skip_OR_rhs_col/S_AXIS]
  connect_bd_intf_net -intf_net fifo_read_interface_0_M_AXIS2 [get_bd_intf_pins fifo_pivot_row/S_AXIS] [get_bd_intf_pins fifo_read_pivot_row/M_AXIS]
  connect_bd_intf_net -intf_net fifo_read_interface_4_M_AXI [get_bd_intf_pins axi_interconnect_1/S09_AXI] [get_bd_intf_pins fifo_read_entire_tableau/M_AXI]
  connect_bd_intf_net -intf_net fifo_read_interface_4_M_AXIS [get_bd_intf_pins fifo_entire_tableau/S_AXIS] [get_bd_intf_pins fifo_read_entire_tableau/M_AXIS]
  connect_bd_intf_net -intf_net fifo_write_interface_0_M_AXI [get_bd_intf_pins axi_interconnect_1/S02_AXI] [get_bd_intf_pins fifo_write_interface_0/M_AXI]
  connect_bd_intf_net -intf_net fifo_write_interface_1_M_AXI [get_bd_intf_pins axi_interconnect_1/S03_AXI] [get_bd_intf_pins fifo_write_interface_1/M_AXI]
  connect_bd_intf_net -intf_net fifo_write_interface_2_M_AXI [get_bd_intf_pins axi_interconnect_1/S01_AXI] [get_bd_intf_pins fifo_write_interface_2/M_AXI]
  connect_bd_intf_net -intf_net microblaze_0_M_AXI_DC [get_bd_intf_pins axi_interconnect_1/S11_AXI] [get_bd_intf_pins microblaze_0/M_AXI_DC]
  connect_bd_intf_net -intf_net microblaze_0_M_AXI_IC [get_bd_intf_pins axi_interconnect_1/S12_AXI] [get_bd_intf_pins microblaze_0/M_AXI_IC]
  connect_bd_intf_net -intf_net microblaze_0_M_AXI_IP [get_bd_intf_pins axi_interconnect_1/S10_AXI] [get_bd_intf_pins microblaze_0/M_AXI_IP]
  connect_bd_intf_net -intf_net microblaze_0_axi_dp [get_bd_intf_pins microblaze_0/M_AXI_DP] [get_bd_intf_pins microblaze_0_axi_periph/S00_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M01_AXI [get_bd_intf_pins axi_uartlite_0/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M01_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M02_AXI [get_bd_intf_pins axi_interconnect_1/S00_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M02_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M03_AXI [get_bd_intf_pins mblaze_lp_bridge_v1_0_1/s00_axi] [get_bd_intf_pins microblaze_0_axi_periph/M03_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M04_AXI [get_bd_intf_pins axi_ethernet_0/s_axi] [get_bd_intf_pins microblaze_0_axi_periph/M04_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M05_AXI [get_bd_intf_pins axi_dma_0/S_AXI_LITE] [get_bd_intf_pins microblaze_0_axi_periph/M05_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M06_AXI [get_bd_intf_pins axi_timer_0/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M06_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M07_AXI [get_bd_intf_pins lp_timer_0/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M07_AXI]
  connect_bd_intf_net -intf_net microblaze_0_debug [get_bd_intf_pins mdm_1/MBDEBUG_0] [get_bd_intf_pins microblaze_0/DEBUG]
  connect_bd_intf_net -intf_net microblaze_0_dlmb_1 [get_bd_intf_pins microblaze_0/DLMB] [get_bd_intf_pins microblaze_0_local_memory/DLMB]
  connect_bd_intf_net -intf_net microblaze_0_ilmb_1 [get_bd_intf_pins microblaze_0/ILMB] [get_bd_intf_pins microblaze_0_local_memory/ILMB]
  connect_bd_intf_net -intf_net microblaze_0_intc_axi [get_bd_intf_pins microblaze_0_axi_intc/s_axi] [get_bd_intf_pins microblaze_0_axi_periph/M00_AXI]
  connect_bd_intf_net -intf_net microblaze_0_interrupt [get_bd_intf_pins microblaze_0/INTERRUPT] [get_bd_intf_pins microblaze_0_axi_intc/interrupt]
  connect_bd_intf_net -intf_net mig_7series_0_DDR3 [get_bd_intf_ports DDR3_0] [get_bd_intf_pins mig_7series_0/DDR3]
  connect_bd_intf_net -intf_net pivot_column_M_AXIS [get_bd_intf_pins full_pivot_column/M_AXIS] [get_bd_intf_pins update_tableau_0/S_AXIS_PIVOT_COL]
connect_bd_intf_net -intf_net [get_bd_intf_nets pivot_column_M_AXIS] [get_bd_intf_pins full_pivot_column/M_AXIS] [get_bd_intf_pins ila_pivot_col_IN_AXIS/SLOT_0_AXIS]
  connect_bd_intf_net -intf_net update_tableau_0_M_AXIS_RESULT [get_bd_intf_pins fifo_redirect_1/S_AXIS] [get_bd_intf_pins update_tableau_0/M_AXIS_RESULT]
connect_bd_intf_net -intf_net [get_bd_intf_nets update_tableau_0_M_AXIS_RESULT] [get_bd_intf_pins ila_update_tableau_out_AXIS/SLOT_0_AXIS] [get_bd_intf_pins update_tableau_0/M_AXIS_RESULT]

  # Create port connections
  connect_bd_net -net Net [get_bd_pins choose_pivot_row_0/num_rows] [get_bd_pins fifo_dma_skip_OR_pivot_col/num_elements] [get_bd_pins fifo_read_skip_OR_rhs_col/num_elements] [get_bd_pins ila_mblaze_bridge/probe4] [get_bd_pins mblaze_lp_bridge_v1_0_1/lp_num_rows_minus_one]
  connect_bd_net -net axi_dma_0_mm2s_cntrl_reset_out_n [get_bd_pins axi_dma_0/mm2s_cntrl_reset_out_n] [get_bd_pins axi_ethernet_0/axi_txc_arstn]
  connect_bd_net -net axi_dma_0_mm2s_introut [get_bd_pins axi_dma_0/mm2s_introut] [get_bd_pins microblaze_0_xlconcat/In1]
  connect_bd_net -net axi_dma_0_mm2s_prmry_reset_out_n [get_bd_pins axi_dma_0/mm2s_prmry_reset_out_n] [get_bd_pins axi_ethernet_0/axi_txd_arstn]
  connect_bd_net -net axi_dma_0_s2mm_introut [get_bd_pins axi_dma_0/s2mm_introut] [get_bd_pins microblaze_0_xlconcat/In2]
  connect_bd_net -net axi_dma_0_s2mm_prmry_reset_out_n [get_bd_pins axi_dma_0/s2mm_prmry_reset_out_n] [get_bd_pins axi_ethernet_0/axi_rxd_arstn]
  connect_bd_net -net axi_dma_0_s2mm_sts_reset_out_n [get_bd_pins axi_dma_0/s2mm_sts_reset_out_n] [get_bd_pins axi_ethernet_0/axi_rxs_arstn]
  connect_bd_net -net axi_ethernet_0_interrupt [get_bd_pins axi_ethernet_0/interrupt] [get_bd_pins microblaze_0_xlconcat/In4]
  connect_bd_net -net axi_ethernet_0_mac_irq [get_bd_pins axi_ethernet_0/mac_irq] [get_bd_pins microblaze_0_xlconcat/In3]
  connect_bd_net -net axi_ethernet_0_phy_rst_n [get_bd_ports phy_reset_out] [get_bd_pins axi_ethernet_0/phy_rst_n]
  connect_bd_net -net axi_timer_0_interrupt [get_bd_pins axi_timer_0/interrupt] [get_bd_pins microblaze_0_xlconcat/In0]
  connect_bd_net -net bram_all_wbits_dout [get_bd_pins bram_all_wbits/dout] [get_bd_pins pivot_row/wea]
  connect_bd_net -net bram_obj_row_base_dout [get_bd_pins bram_obj_row_base/dout] [get_bd_pins fifo_read_obj_row/addr_offset] [get_bd_pins fifo_write_interface_0/addr_offset] [get_bd_pins ila_writeback/probe16]
  connect_bd_net -net bram_rhs_col_base_dout [get_bd_pins bram_rhs_col_base/dout] [get_bd_pins fifo_write_interface_1/addr_offset] [get_bd_pins ila_writeback/probe17]
  connect_bd_net -net bram_rhs_col_second_elem_dout [get_bd_pins bram_rhs_col_second_elem/dout] [get_bd_pins fifo_read_skip_OR_rhs_col/addr_offset]
  connect_bd_net -net choose_pivot_row_0_cont [get_bd_pins choose_pivot_row_0/cont] [get_bd_pins ila_choose_pivot_row/probe3] [get_bd_pins ila_lp_control/probe5] [get_bd_pins lp_control_unit_0/pivot_row_continue]
  connect_bd_net -net choose_pivot_row_0_pivot_col_pivot_row_data [get_bd_pins choose_pivot_row_0/pivot_col_pivot_row_data] [get_bd_pins ila_choose_pivot_row/probe0] [get_bd_pins update_pivot_row_0/factor_in]
  connect_bd_net -net choose_pivot_row_0_pivot_row_index [get_bd_pins choose_pivot_row_0/pivot_row_index] [get_bd_pins ila_choose_pivot_row/probe1] [get_bd_pins ila_lp_control/probe12] [get_bd_pins lp_control_unit_0/pivot_row_idx]
  connect_bd_net -net choose_pivot_row_0_terminate [get_bd_pins choose_pivot_row_0/terminate] [get_bd_pins ila_choose_pivot_row/probe2] [get_bd_pins ila_lp_control/probe1] [get_bd_pins lp_control_unit_0/pivot_row_terminate]
  connect_bd_net -net clk_wiz_1_clk_out2 [get_bd_pins axi_ethernet_0/ref_clk] [get_bd_pins clk_wiz_1/clk_out2] [get_bd_pins mig_7series_0/sys_clk_i]
  connect_bd_net -net clk_wiz_1_clk_out3 [get_bd_pins axi_ethernet_0/gtx_clk] [get_bd_pins clk_wiz_1/clk_out3]
  connect_bd_net -net clk_wiz_1_locked [get_bd_pins clk_wiz_1/locked] [get_bd_pins rst_clk_wiz_1_100M/dcm_locked]
  connect_bd_net -net fifo_generator_0_axis_prog_full [get_bd_pins fifo_obj_row/axis_prog_full] [get_bd_pins fifo_read_obj_row/fifo_full]
  connect_bd_net -net fifo_generator_0_wr_rst_busy [get_bd_pins fifo_obj_row/wr_rst_busy] [get_bd_pins fifo_read_obj_row/rst_busy]
  connect_bd_net -net fifo_generator_1_axis_prog_empty [get_bd_pins fifo_generator_1/axis_prog_empty] [get_bd_pins fifo_write_interface_2/fifo_empty]
  connect_bd_net -net fifo_generator_1_rd_rst_busy [get_bd_pins fifo_generator_1/rd_rst_busy] [get_bd_pins fifo_write_interface_2/rst_busy]
  connect_bd_net -net fifo_generator_1_s_axis_tready [get_bd_pins fifo_generator_1/s_axis_tready] [get_bd_pins fifo_redirect_1/M_AXIS_TREADY_DDR] [get_bd_pins ila_writeback/probe7]
  connect_bd_net -net fifo_generator_1_wr_rst_busy [get_bd_pins fifo_generator_1/wr_rst_busy] [get_bd_pins fifo_redirect_1/rst_busy_ddr] [get_bd_pins ila_writeback/probe3]
  connect_bd_net -net fifo_generator_2_axis_prog_empty [get_bd_pins fifo_generator_2/axis_prog_empty] [get_bd_pins fifo_write_interface_0/fifo_empty]
  connect_bd_net -net fifo_generator_2_rd_rst_busy [get_bd_pins fifo_generator_2/rd_rst_busy] [get_bd_pins fifo_write_interface_0/rst_busy]
  connect_bd_net -net fifo_generator_2_s_axis_tready [get_bd_pins fifo_generator_2/s_axis_tready] [get_bd_pins fifo_redirect_1/M_AXIS_TREADY_OBJ_ROW] [get_bd_pins ila_writeback/probe9]
  connect_bd_net -net fifo_generator_2_wr_rst_busy [get_bd_pins fifo_generator_2/wr_rst_busy] [get_bd_pins fifo_redirect_1/rst_busy_obj_row] [get_bd_pins ila_writeback/probe4]
  connect_bd_net -net fifo_generator_3_axis_prog_empty [get_bd_pins fifo_generator_3/axis_prog_empty] [get_bd_pins fifo_write_interface_1/fifo_empty]
  connect_bd_net -net fifo_generator_3_rd_rst_busy [get_bd_pins fifo_generator_3/rd_rst_busy] [get_bd_pins fifo_write_interface_1/rst_busy]
  connect_bd_net -net fifo_generator_3_s_axis_tready [get_bd_pins fifo_generator_3/s_axis_tready] [get_bd_pins fifo_redirect_1/M_AXIS_TREADY_RHS_COL] [get_bd_pins ila_writeback/probe11]
  connect_bd_net -net fifo_generator_3_wr_rst_busy [get_bd_pins fifo_generator_3/wr_rst_busy] [get_bd_pins fifo_redirect_1/rst_busy_rhs_col] [get_bd_pins ila_writeback/probe5]
  connect_bd_net -net fifo_generator_4_axis_prog_full [get_bd_pins fifo_dma_skip_OR_pivot_col/fifo_full] [get_bd_pins skip_OR_pivot_col/axis_prog_full]
  connect_bd_net -net fifo_generator_4_wr_rst_busy [get_bd_pins fifo_dma_skip_OR_pivot_col/rst_busy] [get_bd_pins skip_OR_pivot_col/wr_rst_busy]
  connect_bd_net -net fifo_generator_5_axis_prog_full [get_bd_pins fifo_read_skip_OR_rhs_col/fifo_full] [get_bd_pins skip_OR_rhs_col/axis_prog_full]
  connect_bd_net -net fifo_generator_5_wr_rst_busy [get_bd_pins fifo_read_skip_OR_rhs_col/rst_busy] [get_bd_pins skip_OR_rhs_col/wr_rst_busy]
  connect_bd_net -net fifo_generator_6_axis_prog_full [get_bd_pins fifo_pivot_row/axis_prog_full] [get_bd_pins fifo_read_pivot_row/fifo_full]
  connect_bd_net -net fifo_generator_6_wr_rst_busy [get_bd_pins fifo_pivot_row/wr_rst_busy] [get_bd_pins fifo_read_pivot_row/rst_busy]
  connect_bd_net -net fifo_generator_7_axis_prog_full [get_bd_pins fifo_entire_tableau/axis_prog_full] [get_bd_pins fifo_read_entire_tableau/fifo_full]
  connect_bd_net -net fifo_generator_7_wr_rst_busy [get_bd_pins fifo_entire_tableau/wr_rst_busy] [get_bd_pins fifo_read_entire_tableau/rst_busy]
  connect_bd_net -net fifo_redirect_0_M_AXIS_TDATA [get_bd_pins fifo_generator_1/s_axis_tdata] [get_bd_pins fifo_generator_2/s_axis_tdata] [get_bd_pins fifo_generator_3/s_axis_tdata] [get_bd_pins fifo_redirect_1/M_AXIS_TDATA] [get_bd_pins ila_writeback/probe0]
  connect_bd_net -net fifo_redirect_0_M_AXIS_TVALID_DDR [get_bd_pins fifo_generator_1/s_axis_tvalid] [get_bd_pins fifo_redirect_1/M_AXIS_TVALID_DDR] [get_bd_pins ila_writeback/probe6]
  connect_bd_net -net fifo_redirect_0_M_AXIS_TVALID_OBJ_ROW [get_bd_pins fifo_generator_2/s_axis_tvalid] [get_bd_pins fifo_redirect_1/M_AXIS_TVALID_OBJ_ROW] [get_bd_pins ila_writeback/probe8]
  connect_bd_net -net fifo_redirect_0_M_AXIS_TVALID_RHS_COL [get_bd_pins fifo_generator_3/s_axis_tvalid] [get_bd_pins fifo_redirect_1/M_AXIS_TVALID_RHS_COL] [get_bd_pins ila_writeback/probe10]
  connect_bd_net -net fifo_redirect_0_start [get_bd_pins fifo_redirect_1/start] [get_bd_pins fifo_write_interface_0/start] [get_bd_pins fifo_write_interface_1/start] [get_bd_pins fifo_write_interface_2/start] [get_bd_pins ila_writeback/probe14]
  connect_bd_net -net fifo_redirect_1_busy [get_bd_pins fifo_redirect_1/busy] [get_bd_pins ila_writeback/probe12]
  connect_bd_net -net fifo_redirect_1_done [get_bd_pins fifo_redirect_1/done] [get_bd_pins ila_writeback/probe13]
  connect_bd_net -net fifo_write_interface_2_done [get_bd_pins fifo_write_interface_2/done] [get_bd_pins ila_lp_control/probe13] [get_bd_pins lp_control_unit_0/ddr_writeback_done]
  connect_bd_net -net find_pivot_col_0_cont [get_bd_pins find_pivot_col_0/cont] [get_bd_pins ila_find_pivot_col/probe1] [get_bd_pins ila_lp_control/probe4] [get_bd_pins lp_control_unit_0/pivot_col_continue]
  connect_bd_net -net find_pivot_col_0_pivot_col [get_bd_pins find_pivot_col_0/pivot_col] [get_bd_pins ila_find_pivot_col/probe2] [get_bd_pins ila_lp_control/probe11] [get_bd_pins lp_control_unit_0/pivot_col_idx]
  connect_bd_net -net find_pivot_col_0_terminate [get_bd_pins find_pivot_col_0/terminate] [get_bd_pins ila_find_pivot_col/probe0] [get_bd_pins ila_lp_control/probe0] [get_bd_pins lp_control_unit_0/pivot_col_terminate]
  connect_bd_net -net lp_control_unit_0_curr_iteration [get_bd_pins choose_pivot_row_0/curr_iteration] [get_bd_pins find_pivot_col_0/curr_iteration] [get_bd_pins ila_choose_pivot_row/probe5] [get_bd_pins ila_find_pivot_col/probe3] [get_bd_pins ila_lp_control/probe28] [get_bd_pins ila_update_pivot_row/probe6] [get_bd_pins ila_update_tableau/probe24] [get_bd_pins lp_control_unit_0/curr_iteration] [get_bd_pins update_pivot_row_0/curr_iteration] [get_bd_pins update_tableau_0/curr_iteration]
  connect_bd_net -net lp_control_unit_0_mblaze_done [get_bd_pins ila_lp_control/probe14] [get_bd_pins lp_control_unit_0/mblaze_done] [get_bd_pins lp_timer_0/lp_end] [get_bd_pins microblaze_0_xlconcat/In5]
  connect_bd_net -net lp_control_unit_0_pivot_col_addr [get_bd_pins fifo_dma_full_pivot_col/addr_offset] [get_bd_pins ila_lp_control/probe18] [get_bd_pins lp_control_unit_0/pivot_col_addr]
  connect_bd_net -net lp_control_unit_0_pivot_col_addr_skip_OR [get_bd_pins fifo_dma_skip_OR_pivot_col/addr_offset] [get_bd_pins ila_lp_control/probe17] [get_bd_pins lp_control_unit_0/pivot_col_addr_skip_OR]
  connect_bd_net -net lp_control_unit_0_pivot_col_fifo_start [get_bd_pins fifo_read_obj_row/start] [get_bd_pins ila_lp_control/probe16] [get_bd_pins lp_control_unit_0/pivot_col_fifo_start]
  connect_bd_net -net lp_control_unit_0_pivot_col_start [get_bd_pins find_pivot_col_0/resetn] [get_bd_pins ila_lp_control/probe15] [get_bd_pins lp_control_unit_0/pivot_col_start]
  connect_bd_net -net lp_control_unit_0_pivot_row_addr [get_bd_pins fifo_read_pivot_row/addr_offset] [get_bd_pins ila_lp_control/probe21] [get_bd_pins lp_control_unit_0/pivot_row_addr]
  connect_bd_net -net lp_control_unit_0_pivot_row_fifo_start [get_bd_pins fifo_dma_full_pivot_col/start] [get_bd_pins fifo_dma_skip_OR_pivot_col/start] [get_bd_pins fifo_read_skip_OR_rhs_col/start] [get_bd_pins ila_lp_control/probe20] [get_bd_pins lp_control_unit_0/pivot_row_fifo_start]
  connect_bd_net -net lp_control_unit_0_pivot_row_start [get_bd_pins choose_pivot_row_0/resetn] [get_bd_pins ila_choose_pivot_row/probe4] [get_bd_pins ila_lp_control/probe19] [get_bd_pins lp_control_unit_0/pivot_row_start]
  connect_bd_net -net lp_control_unit_0_update_pivot_row_fifo_start [get_bd_pins fifo_read_pivot_row/start] [get_bd_pins ila_lp_control/probe24] [get_bd_pins lp_control_unit_0/update_pivot_row_fifo_start]
  connect_bd_net -net lp_control_unit_0_update_pivot_row_start [get_bd_pins ila_lp_control/probe23] [get_bd_pins ila_update_pivot_row/probe2] [get_bd_pins lp_control_unit_0/update_pivot_row_start] [get_bd_pins update_pivot_row_0/resetn]
  connect_bd_net -net lp_control_unit_0_update_tableau_fifo_start [get_bd_pins fifo_read_entire_tableau/start] [get_bd_pins ila_lp_control/probe27] [get_bd_pins lp_control_unit_0/update_tableau_fifo_start]
  connect_bd_net -net lp_control_unit_0_update_tableau_persistent_start [get_bd_pins ila_lp_control/probe26] [get_bd_pins lp_control_unit_0/update_tableau_persistent_start] [get_bd_pins update_tableau_0/start]
  connect_bd_net -net lp_control_unit_0_update_tableau_pivot_row_index [get_bd_pins ila_lp_control/probe22] [get_bd_pins ila_update_tableau/probe22] [get_bd_pins lp_control_unit_0/update_tableau_pivot_row_index] [get_bd_pins update_tableau_0/pivot_row_index]
  connect_bd_net -net lp_control_unit_0_update_tableau_start [get_bd_pins ila_lp_control/probe25] [get_bd_pins ila_pivot_col_IN_AXIS/probe8] [get_bd_pins ila_update_tableau/probe2] [get_bd_pins lp_control_unit_0/update_tableau_start] [get_bd_pins update_tableau_0/resetn]
  connect_bd_net -net mblaze_lp_bridge_v1_0_0_lp_DDR_start_address [get_bd_pins fifo_read_entire_tableau/addr_offset] [get_bd_pins fifo_write_interface_2/addr_offset] [get_bd_pins ila_lp_control/probe10] [get_bd_pins ila_mblaze_bridge/probe3] [get_bd_pins ila_writeback/probe15] [get_bd_pins lp_control_unit_0/ddr_start_addr] [get_bd_pins mblaze_lp_bridge_v1_0_1/lp_DDR_start_address]
  connect_bd_net -net mblaze_lp_bridge_v1_0_0_lp_num_cols [get_bd_pins fifo_dma_full_pivot_col/stride] [get_bd_pins fifo_dma_skip_OR_pivot_col/stride] [get_bd_pins fifo_read_obj_row/num_elements] [get_bd_pins fifo_read_pivot_row/num_elements] [get_bd_pins fifo_redirect_1/tableau_num_cols] [get_bd_pins fifo_write_interface_0/num_elements] [get_bd_pins find_pivot_col_0/num_cols] [get_bd_pins ila_lp_control/probe9] [get_bd_pins ila_mblaze_bridge/probe2] [get_bd_pins ila_update_tableau/probe3] [get_bd_pins ila_writeback/probe1] [get_bd_pins lp_control_unit_0/num_cols] [get_bd_pins mblaze_lp_bridge_v1_0_1/lp_num_cols] [get_bd_pins update_pivot_row_0/num_cols] [get_bd_pins update_tableau_0/num_cols]
  connect_bd_net -net mblaze_lp_bridge_v1_0_0_lp_num_rows [get_bd_pins fifo_dma_full_pivot_col/num_elements] [get_bd_pins fifo_write_interface_1/num_elements] [get_bd_pins ila_mblaze_bridge/probe1] [get_bd_pins ila_update_tableau/probe4] [get_bd_pins mblaze_lp_bridge_v1_0_1/lp_num_rows] [get_bd_pins update_tableau_0/num_rows_current_iteration]
  connect_bd_net -net mblaze_lp_bridge_v1_0_0_lp_start [get_bd_pins ila_lp_control/probe8] [get_bd_pins ila_mblaze_bridge/probe0] [get_bd_pins lp_control_unit_0/bridge_start] [get_bd_pins lp_timer_0/lp_start] [get_bd_pins mblaze_lp_bridge_v1_0_1/lp_start]
  connect_bd_net -net mblaze_lp_bridge_v1_0_0_lp_tableau_size [get_bd_pins fifo_read_entire_tableau/num_elements] [get_bd_pins fifo_redirect_1/tableau_total_size] [get_bd_pins fifo_write_interface_2/num_elements] [get_bd_pins ila_writeback/probe2] [get_bd_pins mblaze_lp_bridge_v1_0_1/lp_tableau_size]
  connect_bd_net -net mblaze_lp_bridge_v1_0_1_lp_num_cols_minus_one [get_bd_pins ila_mblaze_bridge/probe5] [get_bd_pins mblaze_lp_bridge_v1_0_1/lp_num_cols_minus_one]
  connect_bd_net -net mdm_1_debug_sys_rst [get_bd_pins mdm_1/Debug_SYS_Rst] [get_bd_pins rst_clk_wiz_1_100M/mb_debug_sys_rst]
  connect_bd_net -net microblaze_0_Clk [get_bd_pins axi_bram_ctrl_obj_row/s_axi_aclk] [get_bd_pins axi_bram_ctrl_rhs_col/s_axi_aclk] [get_bd_pins axi_dma_0/m_axi_mm2s_aclk] [get_bd_pins axi_dma_0/m_axi_s2mm_aclk] [get_bd_pins axi_dma_0/m_axi_sg_aclk] [get_bd_pins axi_dma_0/s_axi_lite_aclk] [get_bd_pins axi_ethernet_0/axis_clk] [get_bd_pins axi_ethernet_0/s_axi_lite_clk] [get_bd_pins axi_interconnect_1/ACLK] [get_bd_pins axi_interconnect_1/M00_ACLK] [get_bd_pins axi_interconnect_1/M01_ACLK] [get_bd_pins axi_interconnect_1/S00_ACLK] [get_bd_pins axi_interconnect_1/S01_ACLK] [get_bd_pins axi_interconnect_1/S02_ACLK] [get_bd_pins axi_interconnect_1/S03_ACLK] [get_bd_pins axi_interconnect_1/S04_ACLK] [get_bd_pins axi_interconnect_1/S05_ACLK] [get_bd_pins axi_interconnect_1/S06_ACLK] [get_bd_pins axi_interconnect_1/S07_ACLK] [get_bd_pins axi_interconnect_1/S08_ACLK] [get_bd_pins axi_interconnect_1/S09_ACLK] [get_bd_pins axi_interconnect_1/S10_ACLK] [get_bd_pins axi_interconnect_1/S11_ACLK] [get_bd_pins axi_interconnect_1/S12_ACLK] [get_bd_pins axi_interconnect_1/S13_ACLK] [get_bd_pins axi_interconnect_1/S14_ACLK] [get_bd_pins axi_interconnect_1/S15_ACLK] [get_bd_pins axi_timer_0/s_axi_aclk] [get_bd_pins axi_uartlite_0/s_axi_aclk] [get_bd_pins choose_pivot_row_0/clk] [get_bd_pins clk_wiz_1/clk_out1] [get_bd_pins fifo_dma_full_pivot_col/aclk] [get_bd_pins fifo_dma_skip_OR_pivot_col/aclk] [get_bd_pins fifo_entire_tableau/s_aclk] [get_bd_pins fifo_generator_1/s_aclk] [get_bd_pins fifo_generator_2/s_aclk] [get_bd_pins fifo_generator_3/s_aclk] [get_bd_pins fifo_obj_row/s_aclk] [get_bd_pins fifo_pivot_row/s_aclk] [get_bd_pins fifo_read_entire_tableau/aclk] [get_bd_pins fifo_read_obj_row/aclk] [get_bd_pins fifo_read_pivot_row/aclk] [get_bd_pins fifo_read_skip_OR_rhs_col/aclk] [get_bd_pins fifo_redirect_1/aclk] [get_bd_pins fifo_write_interface_0/aclk] [get_bd_pins fifo_write_interface_1/aclk] [get_bd_pins fifo_write_interface_2/aclk] [get_bd_pins find_pivot_col_0/clk] [get_bd_pins full_pivot_column/s_aclk] [get_bd_pins ila_0/clk] [get_bd_pins ila_choose_pivot_row/clk] [get_bd_pins ila_find_pivot_col/clk] [get_bd_pins ila_lp_control/clk] [get_bd_pins ila_mblaze_bridge/clk] [get_bd_pins ila_pivot_col_IN_AXIS/clk] [get_bd_pins ila_pivot_col_PR/clk] [get_bd_pins ila_rhs_PR/clk] [get_bd_pins ila_tableau_IN_AXIS/clk] [get_bd_pins ila_update_pivot_row/clk] [get_bd_pins ila_update_tableau/clk] [get_bd_pins ila_update_tableau_out_AXIS/clk] [get_bd_pins ila_writeback/clk] [get_bd_pins lp_control_unit_0/aclk] [get_bd_pins lp_timer_0/clk] [get_bd_pins mblaze_lp_bridge_v1_0_1/s00_axi_aclk] [get_bd_pins microblaze_0/Clk] [get_bd_pins microblaze_0_axi_intc/processor_clk] [get_bd_pins microblaze_0_axi_intc/s_axi_aclk] [get_bd_pins microblaze_0_axi_periph/ACLK] [get_bd_pins microblaze_0_axi_periph/M00_ACLK] [get_bd_pins microblaze_0_axi_periph/M01_ACLK] [get_bd_pins microblaze_0_axi_periph/M02_ACLK] [get_bd_pins microblaze_0_axi_periph/M03_ACLK] [get_bd_pins microblaze_0_axi_periph/M04_ACLK] [get_bd_pins microblaze_0_axi_periph/M05_ACLK] [get_bd_pins microblaze_0_axi_periph/M06_ACLK] [get_bd_pins microblaze_0_axi_periph/M07_ACLK] [get_bd_pins microblaze_0_axi_periph/S00_ACLK] [get_bd_pins microblaze_0_local_memory/LMB_Clk] [get_bd_pins pivot_row/clka] [get_bd_pins pivot_row/clkb] [get_bd_pins rst_clk_wiz_1_100M/slowest_sync_clk] [get_bd_pins skip_OR_pivot_col/s_aclk] [get_bd_pins skip_OR_rhs_col/s_aclk] [get_bd_pins update_pivot_row_0/clk] [get_bd_pins update_tableau_0/clk]
  connect_bd_net -net microblaze_0_intr [get_bd_pins microblaze_0_axi_intc/intr] [get_bd_pins microblaze_0_xlconcat/dout]
  connect_bd_net -net mig_7series_0_mmcm_locked [get_bd_pins mig_7series_0/mmcm_locked] [get_bd_pins rst_mig_7series_0_100M/dcm_locked]
  connect_bd_net -net mig_7series_0_ui_clk [get_bd_pins axi_interconnect_1/M02_ACLK] [get_bd_pins mig_7series_0/ui_clk] [get_bd_pins rst_mig_7series_0_100M/slowest_sync_clk]
  connect_bd_net -net mig_7series_0_ui_clk_sync_rst [get_bd_pins mig_7series_0/ui_clk_sync_rst] [get_bd_pins rst_mig_7series_0_100M/ext_reset_in]
  connect_bd_net -net pivot_column_axis_prog_full [get_bd_pins fifo_dma_full_pivot_col/fifo_full] [get_bd_pins full_pivot_column/axis_prog_full]
  connect_bd_net -net pivot_column_wr_rst_busy [get_bd_pins fifo_dma_full_pivot_col/rst_busy] [get_bd_pins full_pivot_column/wr_rst_busy]
  connect_bd_net -net pivot_row_doutb [get_bd_pins ila_update_tableau/probe6] [get_bd_pins pivot_row/doutb] [get_bd_pins update_tableau_0/pivot_row_BRAM_data]
  connect_bd_net -net reset_1 [get_bd_ports reset] [get_bd_pins clk_wiz_1/resetn] [get_bd_pins mig_7series_0/sys_rst] [get_bd_pins rst_clk_wiz_1_100M/ext_reset_in]
  connect_bd_net -net rst_clk_wiz_1_100M_bus_struct_reset [get_bd_pins microblaze_0_local_memory/SYS_Rst] [get_bd_pins rst_clk_wiz_1_100M/bus_struct_reset]
  connect_bd_net -net rst_clk_wiz_1_100M_mb_reset [get_bd_pins microblaze_0/Reset] [get_bd_pins microblaze_0_axi_intc/processor_rst] [get_bd_pins rst_clk_wiz_1_100M/mb_reset]
  connect_bd_net -net rst_clk_wiz_1_100M_peripheral_aresetn [get_bd_pins axi_bram_ctrl_obj_row/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_rhs_col/s_axi_aresetn] [get_bd_pins axi_dma_0/axi_resetn] [get_bd_pins axi_ethernet_0/s_axi_lite_resetn] [get_bd_pins axi_interconnect_1/ARESETN] [get_bd_pins axi_interconnect_1/M00_ARESETN] [get_bd_pins axi_interconnect_1/M01_ARESETN] [get_bd_pins axi_interconnect_1/S00_ARESETN] [get_bd_pins axi_interconnect_1/S01_ARESETN] [get_bd_pins axi_interconnect_1/S02_ARESETN] [get_bd_pins axi_interconnect_1/S03_ARESETN] [get_bd_pins axi_interconnect_1/S04_ARESETN] [get_bd_pins axi_interconnect_1/S05_ARESETN] [get_bd_pins axi_interconnect_1/S06_ARESETN] [get_bd_pins axi_interconnect_1/S07_ARESETN] [get_bd_pins axi_interconnect_1/S08_ARESETN] [get_bd_pins axi_interconnect_1/S09_ARESETN] [get_bd_pins axi_interconnect_1/S10_ARESETN] [get_bd_pins axi_interconnect_1/S11_ARESETN] [get_bd_pins axi_interconnect_1/S12_ARESETN] [get_bd_pins axi_interconnect_1/S13_ARESETN] [get_bd_pins axi_interconnect_1/S14_ARESETN] [get_bd_pins axi_interconnect_1/S15_ARESETN] [get_bd_pins axi_timer_0/s_axi_aresetn] [get_bd_pins axi_uartlite_0/s_axi_aresetn] [get_bd_pins fifo_dma_full_pivot_col/aresetn] [get_bd_pins fifo_dma_skip_OR_pivot_col/aresetn] [get_bd_pins fifo_entire_tableau/s_aresetn] [get_bd_pins fifo_generator_1/s_aresetn] [get_bd_pins fifo_generator_2/s_aresetn] [get_bd_pins fifo_generator_3/s_aresetn] [get_bd_pins fifo_obj_row/s_aresetn] [get_bd_pins fifo_pivot_row/s_aresetn] [get_bd_pins fifo_read_entire_tableau/aresetn] [get_bd_pins fifo_read_obj_row/aresetn] [get_bd_pins fifo_read_pivot_row/aresetn] [get_bd_pins fifo_read_skip_OR_rhs_col/aresetn] [get_bd_pins fifo_redirect_1/aresetn] [get_bd_pins fifo_write_interface_0/aresetn] [get_bd_pins fifo_write_interface_1/aresetn] [get_bd_pins fifo_write_interface_2/aresetn] [get_bd_pins full_pivot_column/s_aresetn] [get_bd_pins lp_control_unit_0/aresetn] [get_bd_pins lp_timer_0/resetn] [get_bd_pins mblaze_lp_bridge_v1_0_1/s00_axi_aresetn] [get_bd_pins microblaze_0_axi_intc/s_axi_aresetn] [get_bd_pins microblaze_0_axi_periph/ARESETN] [get_bd_pins microblaze_0_axi_periph/M00_ARESETN] [get_bd_pins microblaze_0_axi_periph/M01_ARESETN] [get_bd_pins microblaze_0_axi_periph/M02_ARESETN] [get_bd_pins microblaze_0_axi_periph/M03_ARESETN] [get_bd_pins microblaze_0_axi_periph/M04_ARESETN] [get_bd_pins microblaze_0_axi_periph/M05_ARESETN] [get_bd_pins microblaze_0_axi_periph/M06_ARESETN] [get_bd_pins microblaze_0_axi_periph/M07_ARESETN] [get_bd_pins microblaze_0_axi_periph/S00_ARESETN] [get_bd_pins rst_clk_wiz_1_100M/peripheral_aresetn] [get_bd_pins skip_OR_pivot_col/s_aresetn] [get_bd_pins skip_OR_rhs_col/s_aresetn]
  connect_bd_net -net rst_mig_7series_0_100M_peripheral_aresetn [get_bd_pins axi_interconnect_1/M02_ARESETN] [get_bd_pins mig_7series_0/aresetn] [get_bd_pins rst_mig_7series_0_100M/peripheral_aresetn]
  connect_bd_net -net sys_clock_1 [get_bd_ports sys_clock] [get_bd_pins clk_wiz_1/clk_in1]
  connect_bd_net -net update_pivot_row_0_cont [get_bd_pins ila_lp_control/probe6] [get_bd_pins ila_update_pivot_row/probe1] [get_bd_pins ila_update_tableau/probe17] [get_bd_pins lp_control_unit_0/update_pivot_row_continue] [get_bd_pins update_pivot_row_0/cont]
  connect_bd_net -net update_pivot_row_0_terminate [get_bd_pins ila_lp_control/probe2] [get_bd_pins ila_update_pivot_row/probe0] [get_bd_pins lp_control_unit_0/update_pivot_row_terminate] [get_bd_pins update_pivot_row_0/terminate]
  connect_bd_net -net update_pivot_row_0_waddr [get_bd_pins ila_update_pivot_row/probe5] [get_bd_pins pivot_row/addra] [get_bd_pins update_pivot_row_0/waddr]
  connect_bd_net -net update_pivot_row_0_wdata [get_bd_pins ila_update_pivot_row/probe4] [get_bd_pins pivot_row/dina] [get_bd_pins update_pivot_row_0/wdata]
  connect_bd_net -net update_pivot_row_0_wen [get_bd_pins ila_update_pivot_row/probe3] [get_bd_pins pivot_row/ena] [get_bd_pins update_pivot_row_0/wen]
  connect_bd_net -net update_tableau_0_M_AXIS_RESULT_TFLAGS [get_bd_pins ila_update_tableau/probe16] [get_bd_pins update_tableau_0/M_AXIS_RESULT_TFLAGS]
  connect_bd_net -net update_tableau_0_col_index [get_bd_pins ila_update_tableau/probe12] [get_bd_pins update_tableau_0/col_index]
  connect_bd_net -net update_tableau_0_cont [get_bd_pins ila_lp_control/probe7] [get_bd_pins ila_update_tableau/probe0] [get_bd_pins lp_control_unit_0/update_tableau_continue] [get_bd_pins update_tableau_0/cont]
  connect_bd_net -net update_tableau_0_fp_unit_valid_in [get_bd_pins ila_update_tableau/probe21] [get_bd_pins update_tableau_0/fp_unit_valid_in]
  connect_bd_net -net update_tableau_0_pc_data [get_bd_pins ila_update_tableau/probe19] [get_bd_pins update_tableau_0/pc_data]
  connect_bd_net -net update_tableau_0_pc_s_axis_tready [get_bd_pins ila_update_tableau/probe9] [get_bd_pins update_tableau_0/pc_s_axis_tready]
  connect_bd_net -net update_tableau_0_pc_state [get_bd_pins ila_update_tableau/probe7] [get_bd_pins update_tableau_0/pc_state]
  connect_bd_net -net update_tableau_0_pc_valid [get_bd_pins ila_update_tableau/probe8] [get_bd_pins update_tableau_0/pc_valid]
  connect_bd_net -net update_tableau_0_pivot_row_BRAM_address [get_bd_pins ila_update_tableau/probe5] [get_bd_pins pivot_row/addrb] [get_bd_pins update_tableau_0/pivot_row_BRAM_address]
  connect_bd_net -net update_tableau_0_pivot_row_BRAM_valid [get_bd_pins ila_update_tableau/probe10] [get_bd_pins update_tableau_0/pivot_row_BRAM_valid]
  connect_bd_net -net update_tableau_0_pr_data [get_bd_pins ila_update_tableau/probe18] [get_bd_pins update_tableau_0/pr_data]
  connect_bd_net -net update_tableau_0_row_index [get_bd_pins ila_update_tableau/probe11] [get_bd_pins update_tableau_0/row_index]
  connect_bd_net -net update_tableau_0_s_axis_a_ready [get_bd_pins ila_update_tableau/probe13] [get_bd_pins update_tableau_0/s_axis_a_ready]
  connect_bd_net -net update_tableau_0_s_axis_b_ready [get_bd_pins ila_update_tableau/probe14] [get_bd_pins update_tableau_0/s_axis_b_ready]
  connect_bd_net -net update_tableau_0_s_axis_c_ready [get_bd_pins ila_update_tableau/probe15] [get_bd_pins update_tableau_0/s_axis_c_ready]
  connect_bd_net -net update_tableau_0_skip_row [get_bd_pins ila_update_tableau/probe23] [get_bd_pins update_tableau_0/skip_row]
  connect_bd_net -net update_tableau_0_tableau_data [get_bd_pins ila_update_tableau/probe20] [get_bd_pins update_tableau_0/tableau_data]
  connect_bd_net -net update_tableau_0_terminate [get_bd_pins ila_lp_control/probe3] [get_bd_pins ila_update_tableau/probe1] [get_bd_pins lp_control_unit_0/update_tableau_terminate] [get_bd_pins update_tableau_0/terminate]

  # Create address segments
  create_bd_addr_seg -range 0x00010000 -offset 0xC0000000 [get_bd_addr_spaces axi_dma_0/Data_SG] [get_bd_addr_segs axi_bram_ctrl_obj_row/S_AXI/Mem0] SEG_axi_bram_ctrl_obj_row_Mem0
  create_bd_addr_seg -range 0x00010000 -offset 0xC0000000 [get_bd_addr_spaces axi_dma_0/Data_MM2S] [get_bd_addr_segs axi_bram_ctrl_obj_row/S_AXI/Mem0] SEG_axi_bram_ctrl_obj_row_Mem0
  create_bd_addr_seg -range 0x00010000 -offset 0xC0000000 [get_bd_addr_spaces axi_dma_0/Data_S2MM] [get_bd_addr_segs axi_bram_ctrl_obj_row/S_AXI/Mem0] SEG_axi_bram_ctrl_obj_row_Mem0
  create_bd_addr_seg -range 0x00010000 -offset 0xC2000000 [get_bd_addr_spaces axi_dma_0/Data_SG] [get_bd_addr_segs axi_bram_ctrl_rhs_col/S_AXI/Mem0] SEG_axi_bram_ctrl_rhs_col_Mem0
  create_bd_addr_seg -range 0x00010000 -offset 0xC2000000 [get_bd_addr_spaces axi_dma_0/Data_MM2S] [get_bd_addr_segs axi_bram_ctrl_rhs_col/S_AXI/Mem0] SEG_axi_bram_ctrl_rhs_col_Mem0
  create_bd_addr_seg -range 0x00010000 -offset 0xC2000000 [get_bd_addr_spaces axi_dma_0/Data_S2MM] [get_bd_addr_segs axi_bram_ctrl_rhs_col/S_AXI/Mem0] SEG_axi_bram_ctrl_rhs_col_Mem0
  create_bd_addr_seg -range 0x20000000 -offset 0x80000000 [get_bd_addr_spaces axi_dma_0/Data_SG] [get_bd_addr_segs mig_7series_0/memmap/memaddr] SEG_mig_7series_0_memaddr
  create_bd_addr_seg -range 0x20000000 -offset 0x80000000 [get_bd_addr_spaces axi_dma_0/Data_MM2S] [get_bd_addr_segs mig_7series_0/memmap/memaddr] SEG_mig_7series_0_memaddr
  create_bd_addr_seg -range 0x20000000 -offset 0x80000000 [get_bd_addr_spaces axi_dma_0/Data_S2MM] [get_bd_addr_segs mig_7series_0/memmap/memaddr] SEG_mig_7series_0_memaddr
  create_bd_addr_seg -range 0x00010000 -offset 0xC0000000 [get_bd_addr_spaces fifo_dma_full_pivot_col/M_AXI] [get_bd_addr_segs axi_bram_ctrl_obj_row/S_AXI/Mem0] SEG_axi_bram_ctrl_obj_row_Mem0
  create_bd_addr_seg -range 0x00010000 -offset 0xC2000000 [get_bd_addr_spaces fifo_dma_full_pivot_col/M_AXI] [get_bd_addr_segs axi_bram_ctrl_rhs_col/S_AXI/Mem0] SEG_axi_bram_ctrl_rhs_col_Mem0
  create_bd_addr_seg -range 0x20000000 -offset 0x80000000 [get_bd_addr_spaces fifo_dma_full_pivot_col/M_AXI] [get_bd_addr_segs mig_7series_0/memmap/memaddr] SEG_mig_7series_0_memaddr
  create_bd_addr_seg -range 0x00010000 -offset 0xC0000000 [get_bd_addr_spaces fifo_dma_skip_OR_pivot_col/M_AXI] [get_bd_addr_segs axi_bram_ctrl_obj_row/S_AXI/Mem0] SEG_axi_bram_ctrl_obj_row_Mem0
  create_bd_addr_seg -range 0x00010000 -offset 0xC2000000 [get_bd_addr_spaces fifo_dma_skip_OR_pivot_col/M_AXI] [get_bd_addr_segs axi_bram_ctrl_rhs_col/S_AXI/Mem0] SEG_axi_bram_ctrl_rhs_col_Mem0
  create_bd_addr_seg -range 0x20000000 -offset 0x80000000 [get_bd_addr_spaces fifo_dma_skip_OR_pivot_col/M_AXI] [get_bd_addr_segs mig_7series_0/memmap/memaddr] SEG_mig_7series_0_memaddr
  create_bd_addr_seg -range 0x00010000 -offset 0xC0000000 [get_bd_addr_spaces fifo_read_entire_tableau/M_AXI] [get_bd_addr_segs axi_bram_ctrl_obj_row/S_AXI/Mem0] SEG_axi_bram_ctrl_obj_row_Mem0
  create_bd_addr_seg -range 0x00010000 -offset 0xC2000000 [get_bd_addr_spaces fifo_read_entire_tableau/M_AXI] [get_bd_addr_segs axi_bram_ctrl_rhs_col/S_AXI/Mem0] SEG_axi_bram_ctrl_rhs_col_Mem0
  create_bd_addr_seg -range 0x20000000 -offset 0x80000000 [get_bd_addr_spaces fifo_read_entire_tableau/M_AXI] [get_bd_addr_segs mig_7series_0/memmap/memaddr] SEG_mig_7series_0_memaddr
  create_bd_addr_seg -range 0x00010000 -offset 0xC0000000 [get_bd_addr_spaces fifo_read_obj_row/M_AXI] [get_bd_addr_segs axi_bram_ctrl_obj_row/S_AXI/Mem0] SEG_axi_bram_ctrl_obj_row_Mem0
  create_bd_addr_seg -range 0x00010000 -offset 0xC2000000 [get_bd_addr_spaces fifo_read_obj_row/M_AXI] [get_bd_addr_segs axi_bram_ctrl_rhs_col/S_AXI/Mem0] SEG_axi_bram_ctrl_rhs_col_Mem0
  create_bd_addr_seg -range 0x20000000 -offset 0x80000000 [get_bd_addr_spaces fifo_read_obj_row/M_AXI] [get_bd_addr_segs mig_7series_0/memmap/memaddr] SEG_mig_7series_0_memaddr
  create_bd_addr_seg -range 0x00010000 -offset 0xC0000000 [get_bd_addr_spaces fifo_read_pivot_row/M_AXI] [get_bd_addr_segs axi_bram_ctrl_obj_row/S_AXI/Mem0] SEG_axi_bram_ctrl_obj_row_Mem0
  create_bd_addr_seg -range 0x00010000 -offset 0xC2000000 [get_bd_addr_spaces fifo_read_pivot_row/M_AXI] [get_bd_addr_segs axi_bram_ctrl_rhs_col/S_AXI/Mem0] SEG_axi_bram_ctrl_rhs_col_Mem0
  create_bd_addr_seg -range 0x20000000 -offset 0x80000000 [get_bd_addr_spaces fifo_read_pivot_row/M_AXI] [get_bd_addr_segs mig_7series_0/memmap/memaddr] SEG_mig_7series_0_memaddr
  create_bd_addr_seg -range 0x00010000 -offset 0xC0000000 [get_bd_addr_spaces fifo_read_skip_OR_rhs_col/M_AXI] [get_bd_addr_segs axi_bram_ctrl_obj_row/S_AXI/Mem0] SEG_axi_bram_ctrl_obj_row_Mem0
  create_bd_addr_seg -range 0x00010000 -offset 0xC2000000 [get_bd_addr_spaces fifo_read_skip_OR_rhs_col/M_AXI] [get_bd_addr_segs axi_bram_ctrl_rhs_col/S_AXI/Mem0] SEG_axi_bram_ctrl_rhs_col_Mem0
  create_bd_addr_seg -range 0x20000000 -offset 0x80000000 [get_bd_addr_spaces fifo_read_skip_OR_rhs_col/M_AXI] [get_bd_addr_segs mig_7series_0/memmap/memaddr] SEG_mig_7series_0_memaddr
  create_bd_addr_seg -range 0x00010000 -offset 0xC0000000 [get_bd_addr_spaces fifo_write_interface_0/M_AXI] [get_bd_addr_segs axi_bram_ctrl_obj_row/S_AXI/Mem0] SEG_axi_bram_ctrl_obj_row_Mem0
  create_bd_addr_seg -range 0x00010000 -offset 0xC2000000 [get_bd_addr_spaces fifo_write_interface_0/M_AXI] [get_bd_addr_segs axi_bram_ctrl_rhs_col/S_AXI/Mem0] SEG_axi_bram_ctrl_rhs_col_Mem0
  create_bd_addr_seg -range 0x20000000 -offset 0x80000000 [get_bd_addr_spaces fifo_write_interface_0/M_AXI] [get_bd_addr_segs mig_7series_0/memmap/memaddr] SEG_mig_7series_0_memaddr
  create_bd_addr_seg -range 0x00010000 -offset 0xC0000000 [get_bd_addr_spaces fifo_write_interface_1/M_AXI] [get_bd_addr_segs axi_bram_ctrl_obj_row/S_AXI/Mem0] SEG_axi_bram_ctrl_obj_row_Mem0
  create_bd_addr_seg -range 0x00010000 -offset 0xC2000000 [get_bd_addr_spaces fifo_write_interface_1/M_AXI] [get_bd_addr_segs axi_bram_ctrl_rhs_col/S_AXI/Mem0] SEG_axi_bram_ctrl_rhs_col_Mem0
  create_bd_addr_seg -range 0x20000000 -offset 0x80000000 [get_bd_addr_spaces fifo_write_interface_1/M_AXI] [get_bd_addr_segs mig_7series_0/memmap/memaddr] SEG_mig_7series_0_memaddr
  create_bd_addr_seg -range 0x00010000 -offset 0xC0000000 [get_bd_addr_spaces fifo_write_interface_2/M_AXI] [get_bd_addr_segs axi_bram_ctrl_obj_row/S_AXI/Mem0] SEG_axi_bram_ctrl_obj_row_Mem0
  create_bd_addr_seg -range 0x00010000 -offset 0xC2000000 [get_bd_addr_spaces fifo_write_interface_2/M_AXI] [get_bd_addr_segs axi_bram_ctrl_rhs_col/S_AXI/Mem0] SEG_axi_bram_ctrl_rhs_col_Mem0
  create_bd_addr_seg -range 0x20000000 -offset 0x80000000 [get_bd_addr_spaces fifo_write_interface_2/M_AXI] [get_bd_addr_segs mig_7series_0/memmap/memaddr] SEG_mig_7series_0_memaddr
  create_bd_addr_seg -range 0x00010000 -offset 0xC0000000 [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs axi_bram_ctrl_obj_row/S_AXI/Mem0] SEG_axi_bram_ctrl_obj_row_Mem0
  create_bd_addr_seg -range 0x00010000 -offset 0xC0000000 [get_bd_addr_spaces microblaze_0/Instruction] [get_bd_addr_segs axi_bram_ctrl_obj_row/S_AXI/Mem0] SEG_axi_bram_ctrl_obj_row_Mem0
  create_bd_addr_seg -range 0x00010000 -offset 0xC2000000 [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs axi_bram_ctrl_rhs_col/S_AXI/Mem0] SEG_axi_bram_ctrl_rhs_col_Mem0
  create_bd_addr_seg -range 0x00010000 -offset 0xC2000000 [get_bd_addr_spaces microblaze_0/Instruction] [get_bd_addr_segs axi_bram_ctrl_rhs_col/S_AXI/Mem0] SEG_axi_bram_ctrl_rhs_col_Mem0
  create_bd_addr_seg -range 0x00010000 -offset 0x41E00000 [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs axi_dma_0/S_AXI_LITE/Reg] SEG_axi_dma_0_Reg
  create_bd_addr_seg -range 0x00040000 -offset 0x40C00000 [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs axi_ethernet_0/s_axi/Reg0] SEG_axi_ethernet_0_Reg0
  create_bd_addr_seg -range 0x00010000 -offset 0x41C00000 [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs axi_timer_0/S_AXI/Reg] SEG_axi_timer_0_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x40600000 [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs axi_uartlite_0/S_AXI/Reg] SEG_axi_uartlite_0_Reg
  create_bd_addr_seg -range 0x00008000 -offset 0x00000000 [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs microblaze_0_local_memory/dlmb_bram_if_cntlr/SLMB/Mem] SEG_dlmb_bram_if_cntlr_Mem
  create_bd_addr_seg -range 0x00008000 -offset 0x00000000 [get_bd_addr_spaces microblaze_0/Instruction] [get_bd_addr_segs microblaze_0_local_memory/ilmb_bram_if_cntlr/SLMB/Mem] SEG_ilmb_bram_if_cntlr_Mem
  create_bd_addr_seg -range 0x00010000 -offset 0x20000000 [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs lp_timer_0/S_AXI/reg0] SEG_lp_timer_0_reg0
  create_bd_addr_seg -range 0x00010000 -offset 0x44A00000 [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs mblaze_lp_bridge_v1_0_1/s00_axi/reg0] SEG_mblaze_lp_bridge_v1_0_1_reg0
  create_bd_addr_seg -range 0x00010000 -offset 0x41200000 [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs microblaze_0_axi_intc/S_AXI/Reg] SEG_microblaze_0_axi_intc_Reg
  create_bd_addr_seg -range 0x20000000 -offset 0x80000000 [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs mig_7series_0/memmap/memaddr] SEG_mig_7series_0_memaddr
  create_bd_addr_seg -range 0x20000000 -offset 0x80000000 [get_bd_addr_spaces microblaze_0/Instruction] [get_bd_addr_segs mig_7series_0/memmap/memaddr] SEG_mig_7series_0_memaddr


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""



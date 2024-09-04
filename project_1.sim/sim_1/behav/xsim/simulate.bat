@echo off
REM ****************************************************************************
REM Vivado (TM) v2020.2 (64-bit)
REM
REM Filename    : simulate.bat
REM Simulator   : Xilinx Vivado Simulator
REM Description : Script for simulating the design by launching the simulator
REM
REM Generated by Vivado on Wed Sep 04 10:42:27 +0700 2024
REM SW Build 3064766 on Wed Nov 18 09:12:45 MST 2020
REM
REM Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
REM
REM usage: simulate.bat
REM
REM ****************************************************************************
REM simulate design
echo "xsim tb_endec_new_behav -key {Behavioral:sim_1:Functional:tb_endec_new} -tclbatch tb_endec_new.tcl -view F:/Hieu/Onedrive/OneDrive - actvn.edu.vn/year4/datn/project/project_1/tb_endec_new_behav1.wcfg -log simulate.log"
call xsim  tb_endec_new_behav -key {Behavioral:sim_1:Functional:tb_endec_new} -tclbatch tb_endec_new.tcl -view F:/Hieu/Onedrive/OneDrive - actvn.edu.vn/year4/datn/project/project_1/tb_endec_new_behav1.wcfg -log simulate.log
if "%errorlevel%"=="0" goto SUCCESS
if "%errorlevel%"=="1" goto END
:END
exit 1
:SUCCESS
exit 0

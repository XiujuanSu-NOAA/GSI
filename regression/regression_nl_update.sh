# Standalone script used to pass namelist updates to the regression tests.

# First, generate new variable to hold the first 6 characters of the experiment.

#if [[ `expr substr $exp $((${#exp}-4)) ${#exp}` = "updat" ]]; then
if [[ `expr substr $exp 1 6` = "global" ]]; then
   if [[ `expr substr $exp 8 5` = "4dvar" ]]; then
      export SETUP_update=""
      export SETUP_enkf=""
   elif [[ `expr substr $exp 8 7` = "lanczos" ]]; then
      export SETUP_update=""
      export SETUP_enkf=""
   elif [[ `expr substr $exp 12 6` = "ozonly" ]]; then
      export SETUP_update="newpc4pred=.true.,adp_anglebc=.true.,angord=4,passive_bc=.true.,use_edges=.false.,diag_precon=.true.,step_start=1.0e-3,emiss_bc=.true.,"
      export SETUP_enkf="univaroz=.true.,adp_anglebc=.true.,angord=4,use_edges=.false.,emiss_bc=.true.,"
   else
      export SETUP_update="newpc4pred=.true.,adp_anglebc=.true.,angord=4,passive_bc=.true.,use_edges=.false.,diag_precon=.true.,step_start=1.0e-3,emiss_bc=.true.,cwoption=3,"
      export SETUP_enkf="univaroz=.true.,adp_anglebc=.true.,angord=4,use_edges=.false.,emiss_bc=.true.,"
   fi
fi
if [[ `expr substr $exp 1 4` = "rtma" ]]; then
   export OBSQC_update="pvis=0.2,pcldch=0.1,scale_cv=1.0,estvisoe=2.61,estcldchoe=2.3716,vis_thres=16000.,cldch_thres=16000.,"
else
   export OBSQC_update=""
fi
export GRIDOPTS_update=""
export BKGVERR_update=""
export ANBKGERR_update=""
export JCOPTS_update=""
if [[ `expr substr $exp 1 6` = "global" ]]; then
   export STRONGOPTS_update=""
   export OBSQC_update="vqc=.false.,nvqc=.true.,"
fi
export OBSINPUT_update=""
export SUPERRAD_update=""
export SINGLEOB_update=""


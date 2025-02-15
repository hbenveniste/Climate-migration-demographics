/*

Residualize the data for within-country migration analysis: 
- select all independent variables used across models
- save the residualized data to be used in cross-validation analyses
This script is applied only once before doing the first cross-validation analysis.
No need to re-run it before doing the robustness checks on the same data.

*/


****************************************************************
**# Residualize data to perform cross-validation ***
****************************************************************
* Gather all variables used as dependent or independent variables in one or several models
local allvar ln_outmigshare ///
                tmax_dp_uc sm_dp_uc tmax2_dp_uc sm2_dp_uc tmax3_dp_uc sm3_dp_uc ///
                tmax_dp_uc_clim1 tmax_dp_uc_clim2 tmax_dp_uc_clim3 tmax_dp_uc_clim4 tmax_dp_uc_clim5 tmax_dp_uc_clim6 ///
				sm_dp_uc_clim1 sm_dp_uc_clim2 sm_dp_uc_clim3 sm_dp_uc_clim4 sm_dp_uc_clim5 sm_dp_uc_clim6 ///
				tmax2_dp_uc_clim1 tmax2_dp_uc_clim2 tmax2_dp_uc_clim3 tmax2_dp_uc_clim4 tmax2_dp_uc_clim5 tmax2_dp_uc_clim6 ///
				sm2_dp_uc_clim1 sm2_dp_uc_clim2 sm2_dp_uc_clim3 sm2_dp_uc_clim4 sm2_dp_uc_clim5 sm2_dp_uc_clim6 ///
				tmax3_dp_uc_clim1 tmax3_dp_uc_clim2 tmax3_dp_uc_clim3 tmax3_dp_uc_clim4 tmax3_dp_uc_clim5 tmax3_dp_uc_clim6 ///
				sm3_dp_uc_clim1 sm3_dp_uc_clim2 sm3_dp_uc_clim3 sm3_dp_uc_clim4 sm3_dp_uc_clim5 sm3_dp_uc_clim6 //////
                tmax_dp_uc_clim1_age1 tmax_dp_uc_clim1_age2 tmax_dp_uc_clim1_age3 tmax_dp_uc_clim1_age4 sm_dp_uc_clim1_age1 sm_dp_uc_clim1_age2 sm_dp_uc_clim1_age3 sm_dp_uc_clim1_age4 ///
				tmax2_dp_uc_clim1_age1 tmax2_dp_uc_clim1_age2 tmax2_dp_uc_clim1_age3 tmax2_dp_uc_clim1_age4 sm2_dp_uc_clim1_age1 sm2_dp_uc_clim1_age2 sm2_dp_uc_clim1_age3 sm2_dp_uc_clim1_age4 ///
				tmax3_dp_uc_clim1_age1 tmax3_dp_uc_clim1_age2 tmax3_dp_uc_clim1_age3 tmax3_dp_uc_clim1_age4 sm3_dp_uc_clim1_age1 sm3_dp_uc_clim1_age2 sm3_dp_uc_clim1_age3 sm3_dp_uc_clim1_age4 ///
				tmax_dp_uc_clim2_age1 tmax_dp_uc_clim2_age2 tmax_dp_uc_clim2_age3 tmax_dp_uc_clim2_age4 sm_dp_uc_clim2_age1 sm_dp_uc_clim2_age2 sm_dp_uc_clim2_age3 sm_dp_uc_clim2_age4 ///
				tmax2_dp_uc_clim2_age1 tmax2_dp_uc_clim2_age2 tmax2_dp_uc_clim2_age3 tmax2_dp_uc_clim2_age4 sm2_dp_uc_clim2_age1 sm2_dp_uc_clim2_age2 sm2_dp_uc_clim2_age3 sm2_dp_uc_clim2_age4 ///
				tmax3_dp_uc_clim2_age1 tmax3_dp_uc_clim2_age2 tmax3_dp_uc_clim2_age3 tmax3_dp_uc_clim2_age4 sm3_dp_uc_clim2_age1 sm3_dp_uc_clim2_age2 sm3_dp_uc_clim2_age3 sm3_dp_uc_clim2_age4 ///
				tmax_dp_uc_clim3_age1 tmax_dp_uc_clim3_age2 tmax_dp_uc_clim3_age3 tmax_dp_uc_clim3_age4 sm_dp_uc_clim3_age1 sm_dp_uc_clim3_age2 sm_dp_uc_clim3_age3 sm_dp_uc_clim3_age4 ///
				tmax2_dp_uc_clim3_age1 tmax2_dp_uc_clim3_age2 tmax2_dp_uc_clim3_age3 tmax2_dp_uc_clim3_age4 sm2_dp_uc_clim3_age1 sm2_dp_uc_clim3_age2 sm2_dp_uc_clim3_age3 sm2_dp_uc_clim3_age4 ///
				tmax3_dp_uc_clim3_age1 tmax3_dp_uc_clim3_age2 tmax3_dp_uc_clim3_age3 tmax3_dp_uc_clim3_age4 sm3_dp_uc_clim3_age1 sm3_dp_uc_clim3_age2 sm3_dp_uc_clim3_age3 sm3_dp_uc_clim3_age4 //////
				tmax_dp_uc_clim4_age1 tmax_dp_uc_clim4_age2 tmax_dp_uc_clim4_age3 tmax_dp_uc_clim4_age4 sm_dp_uc_clim4_age1 sm_dp_uc_clim4_age2 sm_dp_uc_clim4_age3 sm_dp_uc_clim4_age4 ///
				tmax2_dp_uc_clim4_age1 tmax2_dp_uc_clim4_age2 tmax2_dp_uc_clim4_age3 tmax2_dp_uc_clim4_age4 sm2_dp_uc_clim4_age1 sm2_dp_uc_clim4_age2 sm2_dp_uc_clim4_age3 sm2_dp_uc_clim4_age4 ///
				tmax3_dp_uc_clim4_age1 tmax3_dp_uc_clim4_age2 tmax3_dp_uc_clim4_age3 tmax3_dp_uc_clim4_age4 sm3_dp_uc_clim4_age1 sm3_dp_uc_clim4_age2 sm3_dp_uc_clim4_age3 sm3_dp_uc_clim4_age4 ///
				tmax_dp_uc_clim5_age1 tmax_dp_uc_clim5_age2 tmax_dp_uc_clim5_age3 tmax_dp_uc_clim5_age4 sm_dp_uc_clim5_age1 sm_dp_uc_clim5_age2 sm_dp_uc_clim5_age3 sm_dp_uc_clim5_age4 ///
				tmax2_dp_uc_clim5_age1 tmax2_dp_uc_clim5_age2 tmax2_dp_uc_clim5_age3 tmax2_dp_uc_clim5_age4 sm2_dp_uc_clim5_age1 sm2_dp_uc_clim5_age2 sm2_dp_uc_clim5_age3 sm2_dp_uc_clim5_age4 ///
				tmax3_dp_uc_clim5_age1 tmax3_dp_uc_clim5_age2 tmax3_dp_uc_clim5_age3 tmax3_dp_uc_clim5_age4 sm3_dp_uc_clim5_age1 sm3_dp_uc_clim5_age2 sm3_dp_uc_clim5_age3 sm3_dp_uc_clim5_age4 ///
				tmax_dp_uc_clim6_age1 tmax_dp_uc_clim6_age2 tmax_dp_uc_clim6_age3 tmax_dp_uc_clim6_age4 sm_dp_uc_clim6_age1 sm_dp_uc_clim6_age2 sm_dp_uc_clim6_age3 sm_dp_uc_clim6_age4 ///
				tmax2_dp_uc_clim6_age1 tmax2_dp_uc_clim6_age2 tmax2_dp_uc_clim6_age3 tmax2_dp_uc_clim6_age4 sm2_dp_uc_clim6_age1 sm2_dp_uc_clim6_age2 sm2_dp_uc_clim6_age3 sm2_dp_uc_clim6_age4 ///
				tmax3_dp_uc_clim6_age1 tmax3_dp_uc_clim6_age2 tmax3_dp_uc_clim6_age3 tmax3_dp_uc_clim6_age4 sm3_dp_uc_clim6_age1 sm3_dp_uc_clim6_age2 sm3_dp_uc_clim6_age3 sm3_dp_uc_clim6_age4 ///
                tmax_dp_uc_clim1_edu1 tmax_dp_uc_clim1_edu2 tmax_dp_uc_clim1_edu3 tmax_dp_uc_clim1_edu4 sm_dp_uc_clim1_edu1 sm_dp_uc_clim1_edu2 sm_dp_uc_clim1_edu3 sm_dp_uc_clim1_edu4 ///
				tmax2_dp_uc_clim1_edu1 tmax2_dp_uc_clim1_edu2 tmax2_dp_uc_clim1_edu3 tmax2_dp_uc_clim1_edu4 sm2_dp_uc_clim1_edu1 sm2_dp_uc_clim1_edu2 sm2_dp_uc_clim1_edu3 sm2_dp_uc_clim1_edu4 ///
				tmax3_dp_uc_clim1_edu1 tmax3_dp_uc_clim1_edu2 tmax3_dp_uc_clim1_edu3 tmax3_dp_uc_clim1_edu4 sm3_dp_uc_clim1_edu1 sm3_dp_uc_clim1_edu2 sm3_dp_uc_clim1_edu3 sm3_dp_uc_clim1_edu4 ///
				tmax_dp_uc_clim2_edu1 tmax_dp_uc_clim2_edu2 tmax_dp_uc_clim2_edu3 tmax_dp_uc_clim2_edu4 sm_dp_uc_clim2_edu1 sm_dp_uc_clim2_edu2 sm_dp_uc_clim2_edu3 sm_dp_uc_clim2_edu4 ///
				tmax2_dp_uc_clim2_edu1 tmax2_dp_uc_clim2_edu2 tmax2_dp_uc_clim2_edu3 tmax2_dp_uc_clim2_edu4 sm2_dp_uc_clim2_edu1 sm2_dp_uc_clim2_edu2 sm2_dp_uc_clim2_edu3 sm2_dp_uc_clim2_edu4 ///
				tmax3_dp_uc_clim2_edu1 tmax3_dp_uc_clim2_edu2 tmax3_dp_uc_clim2_edu3 tmax3_dp_uc_clim2_edu4 sm3_dp_uc_clim2_edu1 sm3_dp_uc_clim2_edu2 sm3_dp_uc_clim2_edu3 sm3_dp_uc_clim2_edu4 ///
				tmax_dp_uc_clim3_edu1 tmax_dp_uc_clim3_edu2 tmax_dp_uc_clim3_edu3 tmax_dp_uc_clim3_edu4 sm_dp_uc_clim3_edu1 sm_dp_uc_clim3_edu2 sm_dp_uc_clim3_edu3 sm_dp_uc_clim3_edu4 ///
				tmax2_dp_uc_clim3_edu1 tmax2_dp_uc_clim3_edu2 tmax2_dp_uc_clim3_edu3 tmax2_dp_uc_clim3_edu4 sm2_dp_uc_clim3_edu1 sm2_dp_uc_clim3_edu2 sm2_dp_uc_clim3_edu3 sm2_dp_uc_clim3_edu4 ///
				tmax3_dp_uc_clim3_edu1 tmax3_dp_uc_clim3_edu2 tmax3_dp_uc_clim3_edu3 tmax3_dp_uc_clim3_edu4 sm3_dp_uc_clim3_edu1 sm3_dp_uc_clim3_edu2 sm3_dp_uc_clim3_edu3 sm3_dp_uc_clim3_edu4 ///
				tmax_dp_uc_clim4_edu1 tmax_dp_uc_clim4_edu2 tmax_dp_uc_clim4_edu3 tmax_dp_uc_clim4_edu4 sm_dp_uc_clim4_edu1 sm_dp_uc_clim4_edu2 sm_dp_uc_clim4_edu3 sm_dp_uc_clim4_edu4 ///
				tmax2_dp_uc_clim4_edu1 tmax2_dp_uc_clim4_edu2 tmax2_dp_uc_clim4_edu3 tmax2_dp_uc_clim4_edu4 sm2_dp_uc_clim4_edu1 sm2_dp_uc_clim4_edu2 sm2_dp_uc_clim4_edu3 sm2_dp_uc_clim4_edu4 ///
				tmax3_dp_uc_clim4_edu1 tmax3_dp_uc_clim4_edu2 tmax3_dp_uc_clim4_edu3 tmax3_dp_uc_clim4_edu4 sm3_dp_uc_clim4_edu1 sm3_dp_uc_clim4_edu2 sm3_dp_uc_clim4_edu3 sm3_dp_uc_clim4_edu4 ///
				tmax_dp_uc_clim5_edu1 tmax_dp_uc_clim5_edu2 tmax_dp_uc_clim5_edu3 tmax_dp_uc_clim5_edu4 sm_dp_uc_clim5_edu1 sm_dp_uc_clim5_edu2 sm_dp_uc_clim5_edu3 sm_dp_uc_clim5_edu4 ///
				tmax2_dp_uc_clim5_edu1 tmax2_dp_uc_clim5_edu2 tmax2_dp_uc_clim5_edu3 tmax2_dp_uc_clim5_edu4 sm2_dp_uc_clim5_edu1 sm2_dp_uc_clim5_edu2 sm2_dp_uc_clim5_edu3 sm2_dp_uc_clim5_edu4 ///
				tmax3_dp_uc_clim5_edu1 tmax3_dp_uc_clim5_edu2 tmax3_dp_uc_clim5_edu3 tmax3_dp_uc_clim5_edu4 sm3_dp_uc_clim5_edu1 sm3_dp_uc_clim5_edu2 sm3_dp_uc_clim5_edu3 sm3_dp_uc_clim5_edu4 ///
				tmax_dp_uc_clim6_edu1 tmax_dp_uc_clim6_edu2 tmax_dp_uc_clim6_edu3 tmax_dp_uc_clim6_edu4 sm_dp_uc_clim6_edu1 sm_dp_uc_clim6_edu2 sm_dp_uc_clim6_edu3 sm_dp_uc_clim6_edu4 ///
				tmax2_dp_uc_clim6_edu1 tmax2_dp_uc_clim6_edu2 tmax2_dp_uc_clim6_edu3 tmax2_dp_uc_clim6_edu4 sm2_dp_uc_clim6_edu1 sm2_dp_uc_clim6_edu2 sm2_dp_uc_clim6_edu3 sm2_dp_uc_clim6_edu4 ///
				tmax3_dp_uc_clim6_edu1 tmax3_dp_uc_clim6_edu2 tmax3_dp_uc_clim6_edu3 tmax3_dp_uc_clim6_edu4 sm3_dp_uc_clim6_edu1 sm3_dp_uc_clim6_edu2 sm3_dp_uc_clim6_edu3 sm3_dp_uc_clim6_edu4 ///
                tmax_dp_uc_clim1_sex1 tmax_dp_uc_clim1_sex2 tmax_dp_uc_clim2_sex1 tmax_dp_uc_clim2_sex2 tmax_dp_uc_clim3_sex1 tmax_dp_uc_clim3_sex2 ///
				tmax_dp_uc_clim4_sex1 tmax_dp_uc_clim4_sex2 tmax_dp_uc_clim5_sex1 tmax_dp_uc_clim5_sex2 tmax_dp_uc_clim6_sex1 tmax_dp_uc_clim6_sex2 ///
				sm_dp_uc_clim1_sex1 sm_dp_uc_clim1_sex2 sm_dp_uc_clim2_sex1 sm_dp_uc_clim2_sex2 sm_dp_uc_clim3_sex1 sm_dp_uc_clim3_sex2 ///
				sm_dp_uc_clim4_sex1 sm_dp_uc_clim4_sex2 sm_dp_uc_clim5_sex1 sm_dp_uc_clim5_sex2 sm_dp_uc_clim6_sex1 sm_dp_uc_clim6_sex2 ///
				tmax2_dp_uc_clim1_sex1 tmax2_dp_uc_clim1_sex2 tmax2_dp_uc_clim2_sex1 tmax2_dp_uc_clim2_sex2 tmax2_dp_uc_clim3_sex1 tmax2_dp_uc_clim3_sex2 ///
				tmax2_dp_uc_clim4_sex1 tmax2_dp_uc_clim4_sex2 tmax2_dp_uc_clim5_sex1 tmax2_dp_uc_clim5_sex2 tmax2_dp_uc_clim6_sex1 tmax2_dp_uc_clim6_sex2 ///
				sm2_dp_uc_clim1_sex1 sm2_dp_uc_clim1_sex2 sm2_dp_uc_clim2_sex1 sm2_dp_uc_clim2_sex2 sm2_dp_uc_clim3_sex1 sm2_dp_uc_clim3_sex2 ///
				sm2_dp_uc_clim4_sex1 sm2_dp_uc_clim4_sex2 sm2_dp_uc_clim5_sex1 sm2_dp_uc_clim5_sex2 sm2_dp_uc_clim6_sex1 sm2_dp_uc_clim6_sex2 ///
				tmax3_dp_uc_clim1_sex1 tmax3_dp_uc_clim1_sex2 tmax3_dp_uc_clim2_sex1 tmax3_dp_uc_clim2_sex2 tmax3_dp_uc_clim3_sex1 tmax3_dp_uc_clim3_sex2 ///
				tmax3_dp_uc_clim4_sex1 tmax3_dp_uc_clim4_sex2 tmax3_dp_uc_clim5_sex1 tmax3_dp_uc_clim5_sex2 tmax3_dp_uc_clim6_sex1 tmax3_dp_uc_clim6_sex2 ///
				sm3_dp_uc_clim1_sex1 sm3_dp_uc_clim1_sex2 sm3_dp_uc_clim2_sex1 sm3_dp_uc_clim2_sex2 sm3_dp_uc_clim3_sex1 sm3_dp_uc_clim3_sex2 ///
				sm3_dp_uc_clim4_sex1 sm3_dp_uc_clim4_sex2 sm3_dp_uc_clim5_sex1 sm3_dp_uc_clim5_sex2 sm3_dp_uc_clim6_sex1 sm3_dp_uc_clim6_sex2 ///
                tmax_dp_uc_rand_clim1_age1 tmax_dp_uc_rand_clim1_age2 tmax_dp_uc_rand_clim1_age3 tmax_dp_uc_rand_clim1_age4 sm_dp_uc_rand_clim1_age1 sm_dp_uc_rand_clim1_age2 sm_dp_uc_rand_clim1_age3 sm_dp_uc_rand_clim1_age4 ///
				tmax2_dp_uc_rand_clim1_age1 tmax2_dp_uc_rand_clim1_age2 tmax2_dp_uc_rand_clim1_age3 tmax2_dp_uc_rand_clim1_age4 sm2_dp_uc_rand_clim1_age1 sm2_dp_uc_rand_clim1_age2 sm2_dp_uc_rand_clim1_age3 sm2_dp_uc_rand_clim1_age4 ///
				tmax3_dp_uc_rand_clim1_age1 tmax3_dp_uc_rand_clim1_age2 tmax3_dp_uc_rand_clim1_age3 tmax3_dp_uc_rand_clim1_age4 sm3_dp_uc_rand_clim1_age1 sm3_dp_uc_rand_clim1_age2 sm3_dp_uc_rand_clim1_age3 sm3_dp_uc_rand_clim1_age4 ///
				tmax_dp_uc_rand_clim2_age1 tmax_dp_uc_rand_clim2_age2 tmax_dp_uc_rand_clim2_age3 tmax_dp_uc_rand_clim2_age4 sm_dp_uc_rand_clim2_age1 sm_dp_uc_rand_clim2_age2 sm_dp_uc_rand_clim2_age3 sm_dp_uc_rand_clim2_age4 ///
				tmax2_dp_uc_rand_clim2_age1 tmax2_dp_uc_rand_clim2_age2 tmax2_dp_uc_rand_clim2_age3 tmax2_dp_uc_rand_clim2_age4 sm2_dp_uc_rand_clim2_age1 sm2_dp_uc_rand_clim2_age2 sm2_dp_uc_rand_clim2_age3 sm2_dp_uc_rand_clim2_age4 ///
				tmax3_dp_uc_rand_clim2_age1 tmax3_dp_uc_rand_clim2_age2 tmax3_dp_uc_rand_clim2_age3 tmax3_dp_uc_rand_clim2_age4 sm3_dp_uc_rand_clim2_age1 sm3_dp_uc_rand_clim2_age2 sm3_dp_uc_rand_clim2_age3 sm3_dp_uc_rand_clim2_age4 ///
				tmax_dp_uc_rand_clim3_age1 tmax_dp_uc_rand_clim3_age2 tmax_dp_uc_rand_clim3_age3 tmax_dp_uc_rand_clim3_age4 sm_dp_uc_rand_clim3_age1 sm_dp_uc_rand_clim3_age2 sm_dp_uc_rand_clim3_age3 sm_dp_uc_rand_clim3_age4 ///
				tmax2_dp_uc_rand_clim3_age1 tmax2_dp_uc_rand_clim3_age2 tmax2_dp_uc_rand_clim3_age3 tmax2_dp_uc_rand_clim3_age4 sm2_dp_uc_rand_clim3_age1 sm2_dp_uc_rand_clim3_age2 sm2_dp_uc_rand_clim3_age3 sm2_dp_uc_rand_clim3_age4 ///
				tmax3_dp_uc_rand_clim3_age1 tmax3_dp_uc_rand_clim3_age2 tmax3_dp_uc_rand_clim3_age3 tmax3_dp_uc_rand_clim3_age4 sm3_dp_uc_rand_clim3_age1 sm3_dp_uc_rand_clim3_age2 sm3_dp_uc_rand_clim3_age3 sm3_dp_uc_rand_clim3_age4 ///
				tmax_dp_uc_rand_clim4_age1 tmax_dp_uc_rand_clim4_age2 tmax_dp_uc_rand_clim4_age3 tmax_dp_uc_rand_clim4_age4 sm_dp_uc_rand_clim4_age1 sm_dp_uc_rand_clim4_age2 sm_dp_uc_rand_clim4_age3 sm_dp_uc_rand_clim4_age4 ///
				tmax2_dp_uc_rand_clim4_age1 tmax2_dp_uc_rand_clim4_age2 tmax2_dp_uc_rand_clim4_age3 tmax2_dp_uc_rand_clim4_age4 sm2_dp_uc_rand_clim4_age1 sm2_dp_uc_rand_clim4_age2 sm2_dp_uc_rand_clim4_age3 sm2_dp_uc_rand_clim4_age4 ///
				tmax3_dp_uc_rand_clim4_age1 tmax3_dp_uc_rand_clim4_age2 tmax3_dp_uc_rand_clim4_age3 tmax3_dp_uc_rand_clim4_age4 sm3_dp_uc_rand_clim4_age1 sm3_dp_uc_rand_clim4_age2 sm3_dp_uc_rand_clim4_age3 sm3_dp_uc_rand_clim4_age4 ///
				tmax_dp_uc_rand_clim5_age1 tmax_dp_uc_rand_clim5_age2 tmax_dp_uc_rand_clim5_age3 tmax_dp_uc_rand_clim5_age4 sm_dp_uc_rand_clim5_age1 sm_dp_uc_rand_clim5_age2 sm_dp_uc_rand_clim5_age3 sm_dp_uc_rand_clim5_age4 ///
				tmax2_dp_uc_rand_clim5_age1 tmax2_dp_uc_rand_clim5_age2 tmax2_dp_uc_rand_clim5_age3 tmax2_dp_uc_rand_clim5_age4 sm2_dp_uc_rand_clim5_age1 sm2_dp_uc_rand_clim5_age2 sm2_dp_uc_rand_clim5_age3 sm2_dp_uc_rand_clim5_age4 ///
				tmax3_dp_uc_rand_clim5_age1 tmax3_dp_uc_rand_clim5_age2 tmax3_dp_uc_rand_clim5_age3 tmax3_dp_uc_rand_clim5_age4 sm3_dp_uc_rand_clim5_age1 sm3_dp_uc_rand_clim5_age2 sm3_dp_uc_rand_clim5_age3 sm3_dp_uc_rand_clim5_age4 ///
				tmax_dp_uc_rand_clim6_age1 tmax_dp_uc_rand_clim6_age2 tmax_dp_uc_rand_clim6_age3 tmax_dp_uc_rand_clim6_age4 sm_dp_uc_rand_clim6_age1 sm_dp_uc_rand_clim6_age2 sm_dp_uc_rand_clim6_age3 sm_dp_uc_rand_clim6_age4 ///
				tmax2_dp_uc_rand_clim6_age1 tmax2_dp_uc_rand_clim6_age2 tmax2_dp_uc_rand_clim6_age3 tmax2_dp_uc_rand_clim6_age4 sm2_dp_uc_rand_clim6_age1 sm2_dp_uc_rand_clim6_age2 sm2_dp_uc_rand_clim6_age3 sm2_dp_uc_rand_clim6_age4 ///
				tmax3_dp_uc_rand_clim6_age1 tmax3_dp_uc_rand_clim6_age2 tmax3_dp_uc_rand_clim6_age3 tmax3_dp_uc_rand_clim6_age4 sm3_dp_uc_rand_clim6_age1 sm3_dp_uc_rand_clim6_age2 sm3_dp_uc_rand_clim6_age3 sm3_dp_uc_rand_clim6_age4 ///
				tmax_dp_uc_rand_clim1_edu1 tmax_dp_uc_rand_clim1_edu2 tmax_dp_uc_rand_clim1_edu3 tmax_dp_uc_rand_clim1_edu4 sm_dp_uc_rand_clim1_edu1 sm_dp_uc_rand_clim1_edu2 sm_dp_uc_rand_clim1_edu3 sm_dp_uc_rand_clim1_edu4 ///
				tmax2_dp_uc_rand_clim1_edu1 tmax2_dp_uc_rand_clim1_edu2 tmax2_dp_uc_rand_clim1_edu3 tmax2_dp_uc_rand_clim1_edu4 sm2_dp_uc_rand_clim1_edu1 sm2_dp_uc_rand_clim1_edu2 sm2_dp_uc_rand_clim1_edu3 sm2_dp_uc_rand_clim1_edu4 ///
				tmax3_dp_uc_rand_clim1_edu1 tmax3_dp_uc_rand_clim1_edu2 tmax3_dp_uc_rand_clim1_edu3 tmax3_dp_uc_rand_clim1_edu4 sm3_dp_uc_rand_clim1_edu1 sm3_dp_uc_rand_clim1_edu2 sm3_dp_uc_rand_clim1_edu3 sm3_dp_uc_rand_clim1_edu4 ///
				tmax_dp_uc_rand_clim2_edu1 tmax_dp_uc_rand_clim2_edu2 tmax_dp_uc_rand_clim2_edu3 tmax_dp_uc_rand_clim2_edu4 sm_dp_uc_rand_clim2_edu1 sm_dp_uc_rand_clim2_edu2 sm_dp_uc_rand_clim2_edu3 sm_dp_uc_rand_clim2_edu4 ///
				tmax2_dp_uc_rand_clim2_edu1 tmax2_dp_uc_rand_clim2_edu2 tmax2_dp_uc_rand_clim2_edu3 tmax2_dp_uc_rand_clim2_edu4 sm2_dp_uc_rand_clim2_edu1 sm2_dp_uc_rand_clim2_edu2 sm2_dp_uc_rand_clim2_edu3 sm2_dp_uc_rand_clim2_edu4 ///
				tmax3_dp_uc_rand_clim2_edu1 tmax3_dp_uc_rand_clim2_edu2 tmax3_dp_uc_rand_clim2_edu3 tmax3_dp_uc_rand_clim2_edu4 sm3_dp_uc_rand_clim2_edu1 sm3_dp_uc_rand_clim2_edu2 sm3_dp_uc_rand_clim2_edu3 sm3_dp_uc_rand_clim2_edu4 ///
				tmax_dp_uc_rand_clim3_edu1 tmax_dp_uc_rand_clim3_edu2 tmax_dp_uc_rand_clim3_edu3 tmax_dp_uc_rand_clim3_edu4 sm_dp_uc_rand_clim3_edu1 sm_dp_uc_rand_clim3_edu2 sm_dp_uc_rand_clim3_edu3 sm_dp_uc_rand_clim3_edu4 ///
				tmax2_dp_uc_rand_clim3_edu1 tmax2_dp_uc_rand_clim3_edu2 tmax2_dp_uc_rand_clim3_edu3 tmax2_dp_uc_rand_clim3_edu4 sm2_dp_uc_rand_clim3_edu1 sm2_dp_uc_rand_clim3_edu2 sm2_dp_uc_rand_clim3_edu3 sm2_dp_uc_rand_clim3_edu4 ///
				tmax3_dp_uc_rand_clim3_edu1 tmax3_dp_uc_rand_clim3_edu2 tmax3_dp_uc_rand_clim3_edu3 tmax3_dp_uc_rand_clim3_edu4 sm3_dp_uc_rand_clim3_edu1 sm3_dp_uc_rand_clim3_edu2 sm3_dp_uc_rand_clim3_edu3 sm3_dp_uc_rand_clim3_edu4 ///
				tmax_dp_uc_rand_clim4_edu1 tmax_dp_uc_rand_clim4_edu2 tmax_dp_uc_rand_clim4_edu3 tmax_dp_uc_rand_clim4_edu4 sm_dp_uc_rand_clim4_edu1 sm_dp_uc_rand_clim4_edu2 sm_dp_uc_rand_clim4_edu3 sm_dp_uc_rand_clim4_edu4 ///
				tmax2_dp_uc_rand_clim4_edu1 tmax2_dp_uc_rand_clim4_edu2 tmax2_dp_uc_rand_clim4_edu3 tmax2_dp_uc_rand_clim4_edu4 sm2_dp_uc_rand_clim4_edu1 sm2_dp_uc_rand_clim4_edu2 sm2_dp_uc_rand_clim4_edu3 sm2_dp_uc_rand_clim4_edu4 ///
				tmax3_dp_uc_rand_clim4_edu1 tmax3_dp_uc_rand_clim4_edu2 tmax3_dp_uc_rand_clim4_edu3 tmax3_dp_uc_rand_clim4_edu4 sm3_dp_uc_rand_clim4_edu1 sm3_dp_uc_rand_clim4_edu2 sm3_dp_uc_rand_clim4_edu3 sm3_dp_uc_rand_clim4_edu4 ///
				tmax_dp_uc_rand_clim5_edu1 tmax_dp_uc_rand_clim5_edu2 tmax_dp_uc_rand_clim5_edu3 tmax_dp_uc_rand_clim5_edu4 sm_dp_uc_rand_clim5_edu1 sm_dp_uc_rand_clim5_edu2 sm_dp_uc_rand_clim5_edu3 sm_dp_uc_rand_clim5_edu4 ///
				tmax2_dp_uc_rand_clim5_edu1 tmax2_dp_uc_rand_clim5_edu2 tmax2_dp_uc_rand_clim5_edu3 tmax2_dp_uc_rand_clim5_edu4 sm2_dp_uc_rand_clim5_edu1 sm2_dp_uc_rand_clim5_edu2 sm2_dp_uc_rand_clim5_edu3 sm2_dp_uc_rand_clim5_edu4 ///
				tmax3_dp_uc_rand_clim5_edu1 tmax3_dp_uc_rand_clim5_edu2 tmax3_dp_uc_rand_clim5_edu3 tmax3_dp_uc_rand_clim5_edu4 sm3_dp_uc_rand_clim5_edu1 sm3_dp_uc_rand_clim5_edu2 sm3_dp_uc_rand_clim5_edu3 sm3_dp_uc_rand_clim5_edu4 ///
				tmax_dp_uc_rand_clim6_edu1 tmax_dp_uc_rand_clim6_edu2 tmax_dp_uc_rand_clim6_edu3 tmax_dp_uc_rand_clim6_edu4 sm_dp_uc_rand_clim6_edu1 sm_dp_uc_rand_clim6_edu2 sm_dp_uc_rand_clim6_edu3 sm_dp_uc_rand_clim6_edu4 ///
				tmax2_dp_uc_rand_clim6_edu1 tmax2_dp_uc_rand_clim6_edu2 tmax2_dp_uc_rand_clim6_edu3 tmax2_dp_uc_rand_clim6_edu4 sm2_dp_uc_rand_clim6_edu1 sm2_dp_uc_rand_clim6_edu2 sm2_dp_uc_rand_clim6_edu3 sm2_dp_uc_rand_clim6_edu4 ///
				tmax3_dp_uc_rand_clim6_edu1 tmax3_dp_uc_rand_clim6_edu2 tmax3_dp_uc_rand_clim6_edu3 tmax3_dp_uc_rand_clim6_edu4 sm3_dp_uc_rand_clim6_edu1 sm3_dp_uc_rand_clim6_edu2 sm3_dp_uc_rand_clim6_edu3 sm3_dp_uc_rand_clim6_edu4 ///


* Residualize all selected variables 
use "$input_dir/3_consolidate/withinmigweather_clean.dta"

preserve

keep `allvar' ctrycode yrmig geomig1 geolev1 demo agemigcat edattain sex climgroup

foreach var in `allvar' {
	quietly reghdfe `allvar', absorb(i.geomig1#i.geolev1#i.demo yrmig i.geomig1##c.yrmig) vce(cluster geomig1) residuals(res_`var')
}

rename res_* *

save "$input_dir/2_intermediate/_residualized_within.dta", replace

restore
/*

Calculate out-of-sample performance from 10-fold cross-validation for the cross-border migration analysis. 
This script is applied for each tested model, calling the script "crossval_function_crossmigration.do"

*/


****************************************************************
**# Residualize data to perform cross-validation ***
****************************************************************
#delimit ;
global allindepvar "tmax_dp sm_dp tmax2_dp sm2_dp tmax3_dp sm3_dp
				tmax_dp_clim1 tmax_dp_clim2 tmax_dp_clim3 tmax_dp_clim4 tmax_dp_clim5 tmax_dp_clim6 
				tmax2_dp_clim1 tmax2_dp_clim2 tmax2_dp_clim3 tmax2_dp_clim4 tmax2_dp_clim5 tmax2_dp_clim6
				tmax3_dp_clim1 tmax3_dp_clim2 tmax3_dp_clim3 tmax3_dp_clim4 tmax3_dp_clim5 tmax3_dp_clim6
				sm_dp_clim1 sm_dp_clim2 sm_dp_clim3 sm_dp_clim4 sm_dp_clim5 sm_dp_clim6
				sm2_dp_clim1 sm2_dp_clim2 sm2_dp_clim3 sm2_dp_clim4 sm2_dp_clim5 sm2_dp_clim6
				sm3_dp_clim1 sm3_dp_clim2 sm3_dp_clim3 sm3_dp_clim4 sm3_dp_clim5 sm3_dp_clim6
				tmax_dp_age1 tmax_dp_age2 tmax_dp_age3 tmax_dp_age4 tmax2_dp_age1 tmax2_dp_age2 tmax2_dp_age3 tmax2_dp_age4 tmax3_dp_age1 tmax3_dp_age2 tmax3_dp_age3 tmax3_dp_age4 
				sm_dp_age1 sm_dp_age2 sm_dp_age3 sm_dp_age4 sm2_dp_age1 sm2_dp_age2 sm2_dp_age3 sm2_dp_age4 sm3_dp_age1 sm3_dp_age2 sm3_dp_age3 sm3_dp_age4
				tmax_dp_edu1 tmax_dp_edu2 tmax_dp_edu3 tmax_dp_edu4 tmax2_dp_edu1 tmax2_dp_edu2 tmax2_dp_edu3 tmax2_dp_edu4 tmax3_dp_edu1 tmax3_dp_edu2 tmax3_dp_edu3 tmax3_dp_edu4 
				sm_dp_edu1 sm_dp_edu2 sm_dp_edu3 sm_dp_edu4 sm2_dp_edu1 sm2_dp_edu2 sm2_dp_edu3 sm2_dp_edu4 sm3_dp_edu1 sm3_dp_edu2 sm3_dp_edu3 sm3_dp_edu4
				tmax_dp_sex1 tmax_dp_sex2 tmax2_dp_sex1 tmax2_dp_sex2 tmax3_dp_sex1 tmax3_dp_sex2
				sm_dp_sex1 sm_dp_sex2 sm2_dp_sex1 sm2_dp_sex2 sm3_dp_sex1 sm3_dp_sex2
				tmax_dp_clim1_age1 tmax_dp_clim1_age2 tmax_dp_clim1_age3 tmax_dp_clim1_age4 tmax_dp_clim2_age1 tmax_dp_clim2_age2 tmax_dp_clim2_age3 tmax_dp_clim2_age4 
				tmax_dp_clim3_age1 tmax_dp_clim3_age2 tmax_dp_clim3_age3 tmax_dp_clim3_age4 tmax_dp_clim4_age1 tmax_dp_clim4_age2 tmax_dp_clim4_age3 tmax_dp_clim4_age4 
				tmax_dp_clim5_age1 tmax_dp_clim5_age2 tmax_dp_clim5_age3 tmax_dp_clim5_age4 tmax_dp_clim6_age1 tmax_dp_clim6_age2 tmax_dp_clim6_age3 tmax_dp_clim6_age4			
				tmax2_dp_clim1_age1 tmax2_dp_clim1_age2 tmax2_dp_clim1_age3 tmax2_dp_clim1_age4 tmax2_dp_clim2_age1 tmax2_dp_clim2_age2 tmax2_dp_clim2_age3 tmax2_dp_clim2_age4
				tmax2_dp_clim3_age1 tmax2_dp_clim3_age2 tmax2_dp_clim3_age3 tmax2_dp_clim3_age4 tmax2_dp_clim4_age1 tmax2_dp_clim4_age2 tmax2_dp_clim4_age3 tmax2_dp_clim4_age4
				tmax2_dp_clim5_age1 tmax2_dp_clim5_age2 tmax2_dp_clim5_age3 tmax2_dp_clim5_age4 tmax2_dp_clim6_age1 tmax2_dp_clim6_age2 tmax2_dp_clim6_age3 tmax2_dp_clim6_age4
				tmax3_dp_clim1_age1 tmax3_dp_clim1_age2 tmax3_dp_clim1_age3 tmax3_dp_clim1_age4 tmax3_dp_clim2_age1 tmax3_dp_clim2_age2 tmax3_dp_clim2_age3 tmax3_dp_clim2_age4
				tmax3_dp_clim3_age1 tmax3_dp_clim3_age2 tmax3_dp_clim3_age3 tmax3_dp_clim3_age4 tmax3_dp_clim4_age1 tmax3_dp_clim4_age2 tmax3_dp_clim4_age3 tmax3_dp_clim4_age4
				tmax3_dp_clim5_age1 tmax3_dp_clim5_age2 tmax3_dp_clim5_age3 tmax3_dp_clim5_age4 tmax3_dp_clim6_age1 tmax3_dp_clim6_age2 tmax3_dp_clim6_age3 tmax3_dp_clim6_age4
				sm_dp_clim1_age1 sm_dp_clim1_age2 sm_dp_clim1_age3 sm_dp_clim1_age4 sm_dp_clim2_age1 sm_dp_clim2_age2 sm_dp_clim2_age3 sm_dp_clim2_age4 
				sm_dp_clim3_age1 sm_dp_clim3_age2 sm_dp_clim3_age3 sm_dp_clim3_age4 sm_dp_clim4_age1 sm_dp_clim4_age2 sm_dp_clim4_age3 sm_dp_clim4_age4 
				sm_dp_clim5_age1 sm_dp_clim5_age2 sm_dp_clim5_age3 sm_dp_clim5_age4 sm_dp_clim6_age1 sm_dp_clim6_age2 sm_dp_clim6_age3 sm_dp_clim6_age4 
				sm2_dp_clim1_age1 sm2_dp_clim1_age2 sm2_dp_clim1_age3 sm2_dp_clim1_age4 sm2_dp_clim2_age1 sm2_dp_clim2_age2 sm2_dp_clim2_age3 sm2_dp_clim2_age4 
				sm2_dp_clim3_age1 sm2_dp_clim3_age2 sm2_dp_clim3_age3 sm2_dp_clim3_age4 sm2_dp_clim4_age1 sm2_dp_clim4_age2 sm2_dp_clim4_age3 sm2_dp_clim4_age4
				sm2_dp_clim5_age1 sm2_dp_clim5_age2 sm2_dp_clim5_age3 sm2_dp_clim5_age4 sm2_dp_clim6_age1 sm2_dp_clim6_age2 sm2_dp_clim6_age3 sm2_dp_clim6_age4
				sm3_dp_clim1_age1 sm3_dp_clim1_age2 sm3_dp_clim1_age3 sm3_dp_clim1_age4 sm3_dp_clim2_age1 sm3_dp_clim2_age2 sm3_dp_clim2_age3 sm3_dp_clim2_age4
				sm3_dp_clim3_age1 sm3_dp_clim3_age2 sm3_dp_clim3_age3 sm3_dp_clim3_age4 sm3_dp_clim4_age1 sm3_dp_clim4_age2 sm3_dp_clim4_age3 sm3_dp_clim4_age4
				sm3_dp_clim5_age1 sm3_dp_clim5_age2 sm3_dp_clim5_age3 sm3_dp_clim5_age4 sm3_dp_clim6_age1 sm3_dp_clim6_age2 sm3_dp_clim6_age3 sm3_dp_clim6_age4
				tmax_dp_clim1_edu1 tmax_dp_clim1_edu2 tmax_dp_clim1_edu3 tmax_dp_clim1_edu4 tmax_dp_clim2_edu1 tmax_dp_clim2_edu2 tmax_dp_clim2_edu3 tmax_dp_clim2_edu4
				tmax_dp_clim3_edu1 tmax_dp_clim3_edu2 tmax_dp_clim3_edu3 tmax_dp_clim3_edu4 tmax_dp_clim4_edu1 tmax_dp_clim4_edu2 tmax_dp_clim4_edu3 tmax_dp_clim4_edu4
				tmax_dp_clim5_edu1 tmax_dp_clim5_edu2 tmax_dp_clim5_edu3 tmax_dp_clim5_edu4 tmax_dp_clim6_edu1 tmax_dp_clim6_edu2 tmax_dp_clim6_edu3 tmax_dp_clim6_edu4
				tmax2_dp_clim1_edu1 tmax2_dp_clim1_edu2 tmax2_dp_clim1_edu3 tmax2_dp_clim1_edu4 tmax2_dp_clim2_edu1 tmax2_dp_clim2_edu2 tmax2_dp_clim2_edu3 tmax2_dp_clim2_edu4
				tmax2_dp_clim3_edu1 tmax2_dp_clim3_edu2 tmax2_dp_clim3_edu3 tmax2_dp_clim3_edu4 tmax2_dp_clim4_edu1 tmax2_dp_clim4_edu2 tmax2_dp_clim4_edu3 tmax2_dp_clim4_edu4
				tmax2_dp_clim5_edu1 tmax2_dp_clim5_edu2 tmax2_dp_clim5_edu3 tmax2_dp_clim5_edu4 tmax2_dp_clim6_edu1 tmax2_dp_clim6_edu2 tmax2_dp_clim6_edu3 tmax2_dp_clim6_edu4
				tmax3_dp_clim1_edu1 tmax3_dp_clim1_edu2 tmax3_dp_clim1_edu3 tmax3_dp_clim1_edu4 tmax3_dp_clim2_edu1 tmax3_dp_clim2_edu2 tmax3_dp_clim2_edu3 tmax3_dp_clim2_edu4
				tmax3_dp_clim3_edu1 tmax3_dp_clim3_edu2 tmax3_dp_clim3_edu3 tmax3_dp_clim3_edu4 tmax3_dp_clim4_edu1 tmax3_dp_clim4_edu2 tmax3_dp_clim4_edu3 tmax3_dp_clim4_edu4
				tmax3_dp_clim5_edu1 tmax3_dp_clim5_edu2 tmax3_dp_clim5_edu3 tmax3_dp_clim5_edu4 tmax3_dp_clim6_edu1 tmax3_dp_clim6_edu2 tmax3_dp_clim6_edu3 tmax3_dp_clim6_edu4
				sm_dp_clim1_edu1 sm_dp_clim1_edu2 sm_dp_clim1_edu3 sm_dp_clim1_edu4 sm_dp_clim2_edu1 sm_dp_clim2_edu2 sm_dp_clim2_edu3 sm_dp_clim2_edu4 
				sm_dp_clim3_edu1 sm_dp_clim3_edu2 sm_dp_clim3_edu3 sm_dp_clim3_edu4 sm_dp_clim4_edu1 sm_dp_clim4_edu2 sm_dp_clim4_edu3 sm_dp_clim4_edu4 
				sm_dp_clim5_edu1 sm_dp_clim5_edu2 sm_dp_clim5_edu3 sm_dp_clim5_edu4 sm_dp_clim6_edu1 sm_dp_clim6_edu2 sm_dp_clim6_edu3 sm_dp_clim6_edu4 
				sm2_dp_clim1_edu1 sm2_dp_clim1_edu2 sm2_dp_clim1_edu3 sm2_dp_clim1_edu4 sm2_dp_clim2_edu1 sm2_dp_clim2_edu2 sm2_dp_clim2_edu3 sm2_dp_clim2_edu4
				sm2_dp_clim3_edu1 sm2_dp_clim3_edu2 sm2_dp_clim3_edu3 sm2_dp_clim3_edu4 sm2_dp_clim4_edu1 sm2_dp_clim4_edu2 sm2_dp_clim4_edu3 sm2_dp_clim4_edu4
				sm2_dp_clim5_edu1 sm2_dp_clim5_edu2 sm2_dp_clim5_edu3 sm2_dp_clim5_edu4 sm2_dp_clim6_edu1 sm2_dp_clim6_edu2 sm2_dp_clim6_edu3 sm2_dp_clim6_edu4
				sm3_dp_clim1_edu1 sm3_dp_clim1_edu2 sm3_dp_clim1_edu3 sm3_dp_clim1_edu4 sm3_dp_clim2_edu1 sm3_dp_clim2_edu2 sm3_dp_clim2_edu3 sm3_dp_clim2_edu4
				sm3_dp_clim3_edu1 sm3_dp_clim3_edu2 sm3_dp_clim3_edu3 sm3_dp_clim3_edu4 sm3_dp_clim4_edu1 sm3_dp_clim4_edu2 sm3_dp_clim4_edu3 sm3_dp_clim4_edu4
				sm3_dp_clim5_edu1 sm3_dp_clim5_edu2 sm3_dp_clim5_edu3 sm3_dp_clim5_edu4 sm3_dp_clim6_edu1 sm3_dp_clim6_edu2 sm3_dp_clim6_edu3 sm3_dp_clim6_edu4
				tmax_dp_rand_clim1 tmax_dp_rand_clim2 tmax_dp_rand_clim3 tmax_dp_rand_clim4 tmax_dp_rand_clim5 tmax_dp_rand_clim6 
				tmax2_dp_rand_clim1 tmax2_dp_rand_clim2 tmax2_dp_rand_clim3 tmax2_dp_rand_clim4 tmax2_dp_rand_clim5 tmax2_dp_rand_clim6 
				tmax3_dp_rand_clim1 tmax3_dp_rand_clim2 tmax3_dp_rand_clim3 tmax3_dp_rand_clim4 tmax3_dp_rand_clim5 tmax3_dp_rand_clim6 
				sm_dp_rand_clim1 sm_dp_rand_clim2 sm_dp_rand_clim3 sm_dp_rand_clim4 sm_dp_rand_clim5 sm_dp_rand_clim6 
				sm2_dp_rand_clim1 sm2_dp_rand_clim2 sm2_dp_rand_clim3 sm2_dp_rand_clim4 sm2_dp_rand_clim5 sm2_dp_rand_clim6 
				sm3_dp_rand_clim1 sm3_dp_rand_clim2 sm3_dp_rand_clim3 sm3_dp_rand_clim4 sm3_dp_rand_clim5 sm3_dp_rand_clim6
				tmax_dp_rand_age1 tmax_dp_rand_age2 tmax_dp_rand_age3 tmax_dp_rand_age4 tmax2_dp_rand_age1 tmax2_dp_rand_age2 tmax2_dp_rand_age3 tmax2_dp_rand_age4 
				tmax3_dp_rand_age1 tmax3_dp_rand_age2 tmax3_dp_rand_age3 tmax3_dp_rand_age4 
				sm_dp_rand_age1 sm_dp_rand_age2 sm_dp_rand_age3 sm_dp_rand_age4 sm2_dp_rand_age1 sm2_dp_rand_age2 sm2_dp_rand_age3 sm2_dp_rand_age4 
				sm3_dp_rand_age1 sm3_dp_rand_age2 sm3_dp_rand_age3 sm3_dp_rand_age4
				tmax_dp_rand_edu1 tmax_dp_rand_edu2 tmax_dp_rand_edu3 tmax_dp_rand_edu4 tmax2_dp_rand_edu1 tmax2_dp_rand_edu2 tmax2_dp_rand_edu3 tmax2_dp_rand_edu4 
				tmax3_dp_rand_edu1 tmax3_dp_rand_edu2 tmax3_dp_rand_edu3 tmax3_dp_rand_edu4 
				sm_dp_rand_edu1 sm_dp_rand_edu2 sm_dp_rand_edu3 sm_dp_rand_edu4 sm2_dp_rand_edu1 sm2_dp_rand_edu2 sm2_dp_rand_edu3 sm2_dp_rand_edu4 sm3_dp_rand_edu1 
				sm3_dp_rand_edu2 sm3_dp_rand_edu3 sm3_dp_rand_edu4
				tmax_dp_a10 sm_dp_a10 tmax2_dp_a10 sm2_dp_a10 tmax3_dp_a10 sm3_dp_a10
				tmax_dp_a10_clim1 tmax_dp_a10_clim2 tmax_dp_a10_clim3 tmax_dp_a10_clim4 tmax_dp_a10_clim5 tmax_dp_a10_clim6 
				tmax2_dp_a10_clim1 tmax2_dp_a10_clim2 tmax2_dp_a10_clim3 tmax2_dp_a10_clim4 tmax2_dp_a10_clim5 tmax2_dp_a10_clim6
				tmax3_dp_a10_clim1 tmax3_dp_a10_clim2 tmax3_dp_a10_clim3 tmax3_dp_a10_clim4 tmax3_dp_a10_clim5 tmax3_dp_a10_clim6
				sm_dp_a10_clim1 sm_dp_a10_clim2 sm_dp_a10_clim3 sm_dp_a10_clim4 sm_dp_a10_clim5 sm_dp_a10_clim6
				sm2_dp_a10_clim1 sm2_dp_a10_clim2 sm2_dp_a10_clim3 sm2_dp_a10_clim4 sm2_dp_a10_clim5 sm2_dp_a10_clim6
				sm3_dp_a10_clim1 sm3_dp_a10_clim2 sm3_dp_a10_clim3 sm3_dp_a10_clim4 sm3_dp_a10_clim5 sm3_dp_a10_clim6
				tmax_dp_a10_age1 tmax_dp_a10_age2 tmax_dp_a10_age3 tmax_dp_a10_age4 sm_dp_a10_age1 sm_dp_a10_age2 sm_dp_a10_age3 sm_dp_a10_age4 
				tmax2_dp_a10_age1 tmax2_dp_a10_age2 tmax2_dp_a10_age3 tmax2_dp_a10_age4 sm2_dp_a10_age1 sm2_dp_a10_age2 sm2_dp_a10_age3 sm2_dp_a10_age4 
				tmax3_dp_a10_age1 tmax3_dp_a10_age2 tmax3_dp_a10_age3 tmax3_dp_a10_age4 sm3_dp_a10_age1 sm3_dp_a10_age2 sm3_dp_a10_age3 sm3_dp_a10_age4 
				tmax_dp_a10_edu1 tmax_dp_a10_edu2 tmax_dp_a10_edu3 tmax_dp_a10_edu4 sm_dp_a10_edu1 sm_dp_a10_edu2 sm_dp_a10_edu3 sm_dp_a10_edu4 
				tmax2_dp_a10_edu1 tmax2_dp_a10_edu2 tmax2_dp_a10_edu3 tmax2_dp_a10_edu4 sm2_dp_a10_edu1 sm2_dp_a10_edu2 sm2_dp_a10_edu3 sm2_dp_a10_edu4 
				tmax3_dp_a10_edu1 tmax3_dp_a10_edu2 tmax3_dp_a10_edu3 tmax3_dp_a10_edu4 sm3_dp_a10_edu1 sm3_dp_a10_edu2 sm3_dp_a10_edu3 sm3_dp_a10_edu4
				tmax_dp_a10_rand_clim1 tmax_dp_a10_rand_clim2 tmax_dp_a10_rand_clim3 tmax_dp_a10_rand_clim4 tmax_dp_a10_rand_clim5 tmax_dp_a10_rand_clim6 
				tmax2_dp_a10_rand_clim1 tmax2_dp_a10_rand_clim2 tmax2_dp_a10_rand_clim3 tmax2_dp_a10_rand_clim4 tmax2_dp_a10_rand_clim5 tmax2_dp_a10_rand_clim6 
				tmax3_dp_a10_rand_clim1 tmax3_dp_a10_rand_clim2 tmax3_dp_a10_rand_clim3 tmax3_dp_a10_rand_clim4 tmax3_dp_a10_rand_clim5 tmax3_dp_a10_rand_clim6 
				sm_dp_a10_rand_clim1 sm_dp_a10_rand_clim2 sm_dp_a10_rand_clim3 sm_dp_a10_rand_clim4 sm_dp_a10_rand_clim5 sm_dp_a10_rand_clim6 
				sm2_dp_a10_rand_clim1 sm2_dp_a10_rand_clim2 sm2_dp_a10_rand_clim3 sm2_dp_a10_rand_clim4 sm2_dp_a10_rand_clim5 sm2_dp_a10_rand_clim6 
				sm3_dp_a10_rand_clim1 sm3_dp_a10_rand_clim2 sm3_dp_a10_rand_clim3 sm3_dp_a10_rand_clim4 sm3_dp_a10_rand_clim5 sm3_dp_a10_rand_clim6
				tmax_dp_a10_rand_age1 tmax_dp_a10_rand_age2 tmax_dp_a10_rand_age3 tmax_dp_a10_rand_age4 tmax2_dp_a10_rand_age1 tmax2_dp_a10_rand_age2 tmax2_dp_a10_rand_age3 tmax2_dp_a10_rand_age4 
				tmax3_dp_a10_rand_age1 tmax3_dp_a10_rand_age2 tmax3_dp_a10_rand_age3 tmax3_dp_a10_rand_age4 
				sm_dp_a10_rand_age1 sm_dp_a10_rand_age2 sm_dp_a10_rand_age3 sm_dp_a10_rand_age4 sm2_dp_a10_rand_age1 sm2_dp_a10_rand_age2 sm2_dp_a10_rand_age3 sm2_dp_a10_rand_age4 
				sm3_dp_a10_rand_age1 sm3_dp_a10_rand_age2 sm3_dp_a10_rand_age3 sm3_dp_a10_rand_age4
				tmax_dp_a10_rand_edu1 tmax_dp_a10_rand_edu2 tmax_dp_a10_rand_edu3 tmax_dp_a10_rand_edu4 tmax2_dp_a10_rand_edu1 tmax2_dp_a10_rand_edu2 tmax2_dp_a10_rand_edu3 tmax2_dp_a10_rand_edu4 
				tmax3_dp_a10_rand_edu1 tmax3_dp_a10_rand_edu2 tmax3_dp_a10_rand_edu3 tmax3_dp_a10_rand_edu4 
				sm_dp_a10_rand_edu1 sm_dp_a10_rand_edu2 sm_dp_a10_rand_edu3 sm_dp_a10_rand_edu4 sm2_dp_a10_rand_edu1 sm2_dp_a10_rand_edu2 sm2_dp_a10_rand_edu3 sm2_dp_a10_rand_edu4 sm3_dp_a10_rand_edu1 
				sm3_dp_a10_rand_edu2 sm3_dp_a10_rand_edu3 sm3_dp_a10_rand_edu4
				tmax_dp_l1 sm_dp_l1 tmax2_dp_l1 sm2_dp_l1 tmax3_dp_l1 sm3_dp_l1
				tmax_dp_l1_clim1 tmax_dp_l1_clim2 tmax_dp_l1_clim3 tmax_dp_l1_clim4 tmax_dp_l1_clim5 tmax_dp_l1_clim6 
				tmax2_dp_l1_clim1 tmax2_dp_l1_clim2 tmax2_dp_l1_clim3 tmax2_dp_l1_clim4 tmax2_dp_l1_clim5 tmax2_dp_l1_clim6
				tmax3_dp_l1_clim1 tmax3_dp_l1_clim2 tmax3_dp_l1_clim3 tmax3_dp_l1_clim4 tmax3_dp_l1_clim5 tmax3_dp_l1_clim6
				sm_dp_l1_clim1 sm_dp_l1_clim2 sm_dp_l1_clim3 sm_dp_l1_clim4 sm_dp_l1_clim5 sm_dp_l1_clim6
				sm2_dp_l1_clim1 sm2_dp_l1_clim2 sm2_dp_l1_clim3 sm2_dp_l1_clim4 sm2_dp_l1_clim5 sm2_dp_l1_clim6
				sm3_dp_l1_clim1 sm3_dp_l1_clim2 sm3_dp_l1_clim3 sm3_dp_l1_clim4 sm3_dp_l1_clim5 sm3_dp_l1_clim6
				tmax_dp_l1_age1 tmax_dp_l1_age2 tmax_dp_l1_age3 tmax_dp_l1_age4 tmax2_dp_l1_age1 tmax2_dp_l1_age2 tmax2_dp_l1_age3 tmax2_dp_l1_age4 tmax3_dp_l1_age1 tmax3_dp_l1_age2 tmax3_dp_l1_age3 tmax3_dp_l1_age4 
				sm_dp_l1_age1 sm_dp_l1_age2 sm_dp_l1_age3 sm_dp_l1_age4 sm2_dp_l1_age1 sm2_dp_l1_age2 sm2_dp_l1_age3 sm2_dp_l1_age4 sm3_dp_l1_age1 sm3_dp_l1_age2 sm3_dp_l1_age3 sm3_dp_l1_age4
				tmax_dp_l1_edu1 tmax_dp_l1_edu2 tmax_dp_l1_edu3 tmax_dp_l1_edu4 tmax2_dp_l1_edu1 tmax2_dp_l1_edu2 tmax2_dp_l1_edu3 tmax2_dp_l1_edu4 tmax3_dp_l1_edu1 tmax3_dp_l1_edu2 tmax3_dp_l1_edu3 tmax3_dp_l1_edu4 
				sm_dp_l1_edu1 sm_dp_l1_edu2 sm_dp_l1_edu3 sm_dp_l1_edu4 sm2_dp_l1_edu1 sm2_dp_l1_edu2 sm2_dp_l1_edu3 sm2_dp_l1_edu4 sm3_dp_l1_edu1 sm3_dp_l1_edu2 sm3_dp_l1_edu3 sm3_dp_l1_edu4
				tmax_dp_des tmax2_dp_des tmax3_dp_des sm_dp_des sm2_dp_des sm3_dp_des
				tmax_dp_des_clim1 tmax_dp_des_clim2 tmax_dp_des_clim3 tmax_dp_des_clim4 tmax_dp_des_clim5 tmax_dp_des_clim6 
				tmax2_dp_des_clim1 tmax2_dp_des_clim2 tmax2_dp_des_clim3 tmax2_dp_des_clim4 tmax2_dp_des_clim5 tmax2_dp_des_clim6
				tmax3_dp_des_clim1 tmax3_dp_des_clim2 tmax3_dp_des_clim3 tmax3_dp_des_clim4 tmax3_dp_des_clim5 tmax3_dp_des_clim6
				sm_dp_des_clim1 sm_dp_des_clim2 sm_dp_des_clim3 sm_dp_des_clim4 sm_dp_des_clim5 sm_dp_des_clim6
				sm2_dp_des_clim1 sm2_dp_des_clim2 sm2_dp_des_clim3 sm2_dp_des_clim4 sm2_dp_des_clim5 sm2_dp_des_clim6
				sm3_dp_des_clim1 sm3_dp_des_clim2 sm3_dp_des_clim3 sm3_dp_des_clim4 sm3_dp_des_clim5 sm3_dp_des_clim6
				tmax_dp_des_age1 tmax_dp_des_age2 tmax_dp_des_age3 tmax_dp_des_age4 tmax2_dp_des_age1 tmax2_dp_des_age2 tmax2_dp_des_age3 tmax2_dp_des_age4 tmax3_dp_des_age1 tmax3_dp_des_age2 tmax3_dp_des_age3 tmax3_dp_des_age4 
				sm_dp_des_age1 sm_dp_des_age2 sm_dp_des_age3 sm_dp_des_age4 sm2_dp_des_age1 sm2_dp_des_age2 sm2_dp_des_age3 sm2_dp_des_age4 sm3_dp_des_age1 sm3_dp_des_age2 sm3_dp_des_age3 sm3_dp_des_age4
				tmax_dp_des_edu1 tmax_dp_des_edu2 tmax_dp_des_edu3 tmax_dp_des_edu4 tmax2_dp_des_edu1 tmax2_dp_des_edu2 tmax2_dp_des_edu3 tmax2_dp_des_edu4 tmax3_dp_des_edu1 tmax3_dp_des_edu2 tmax3_dp_des_edu3 tmax3_dp_des_edu4 
				sm_dp_des_edu1 sm_dp_des_edu2 sm_dp_des_edu3 sm_dp_des_edu4 sm2_dp_des_edu1 sm2_dp_des_edu2 sm2_dp_des_edu3 sm2_dp_des_edu4 sm3_dp_des_edu1 sm3_dp_des_edu2 sm3_dp_des_edu3 sm3_dp_des_edu4
				tmax_dp_rcs_k4_1 tmax_dp_rcs_k4_2 sm_dp_rcs_k4_1 sm_dp_rcs_k4_2
				prcp_dp prcp2_dp prcp3_dp
				prcp_dp_clim1 prcp_dp_clim2 prcp_dp_clim3 prcp_dp_clim4 prcp_dp_clim5 prcp_dp_clim6
				prcp2_dp_clim1 prcp2_dp_clim2 prcp2_dp_clim3 prcp2_dp_clim4 prcp2_dp_clim5 prcp2_dp_clim6
				prcp3_dp_clim1 prcp3_dp_clim2 prcp3_dp_clim3 prcp3_dp_clim4 prcp3_dp_clim5 prcp3_dp_clim6
				prcp_dp_age1 prcp_dp_age2 prcp_dp_age3 prcp_dp_age4 prcp2_dp_age1 prcp2_dp_age2 prcp2_dp_age3 prcp2_dp_age4 prcp3_dp_age1 prcp3_dp_age2 prcp3_dp_age3 prcp3_dp_age4
				prcp_dp_edu1 prcp_dp_edu2 prcp_dp_edu3 prcp_dp_edu4 prcp2_dp_edu1 prcp2_dp_edu2 prcp2_dp_edu3 prcp2_dp_edu4 prcp3_dp_edu1 prcp3_dp_edu2 prcp3_dp_edu3 prcp3_dp_edu4";
#delimit cr		


preserve

keep $depvar $allindepvar bpl bplcode country countrycode yrimm demo agemigcat edattain sex mainclimgroup

quietly reghdfe $depvar $allindepvar, absorb(i.bpl#i.country#i.demo yrimm i.bpl##c.yrimm) vce(cluster bpl) version(3) cache(save, keep(bplcode countrycode yrimm demo agemigcat edattain sex mainclimgroup))

save "$input_dir/2_intermediate/_residualized_cross.dta", replace

restore


****************************************************************
**# Conduct cross-validation ***
****************************************************************
use "$input_dir/2_intermediate/_residualized_cross.dta" 

* Run cross-validation 
do "$code_dir/2_crossvalidation/1_crossborder/crossval_function_crossmigration.do"


save "$input_dir/2_intermediate/_residualized_cross.dta", replace






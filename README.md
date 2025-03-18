# Global climate migration is a story of who, not just how many
Supporting code for Benveniste, Helene and Huybers, Peter and Proctor, Jonathan, Global Climate Migration is a Story of Who, Not Just How Many (2025). Preprint available at SSRN: https://ssrn.com/abstract=4925994 or http://dx.doi.org/10.2139/ssrn.4925994.

# System requirements:
This code must be run in `Stata`. We used version StataMP 18.

# Installation instructions:
Clone the following repository to a chosen directory (`CODE`):

`cd <CODE>`

`git clone https://github.com/hbenveniste/Climate-migration-demographics.git`

Declare variables locating the folders where your code, input data, and results will be stored on your computer:

`export CODE=<CODE>`

`export INPUT=<INPUT>`

`export RESULTS=<RESULTS>`

Input data will be available on Harvard Dataverse upon publication. Once it is, download and unzip it in a location on your computer that has at least 18 GB of space.

# Code repository structure
`0_datacleaning/` - Code for cleaning and constructing the datasets used to estimate the weather-migration relationships.

`1_description/` - Code for plotting descriptive representations of the migration and weather data (Fig.1, Supplementary Figs.1,2,3,7).

`2_crossvalidation/` - Code for running the cross-validations and plotting results (Figs.2a,3a, Supplementary Figs.4,8,11ab,12ab,13ab,14a,15ab,17,18).

`3_estimation/` - Code for estimating the weather-migration relationships and plotting resulting response curves (Figs.2bc,3bc, Supplementary Figs.5,6,11c-f,12c-f,13c-f,14b-c,15c-d, Supplementary Tables 1,2,3).

`4_projection/` - Code for running future projections of cross-border migration and plotting results (Fig.4, Supplementary Figs.9,10,16).

# Input repository structure
`1_raw` - Subfolder including the raw data files. Before running the code, this is the only subfolder in the Input repository.

`2_intermediate` - Subfolder including the intermediate files constructed while putting together the main two files used in the analysis.

`3_consolidate` - Subfolder including the main two files used in the analysis, one for within-country and one for cross-border migration.

`4_crossvalidation` - Subfolder including the cross-validation results used for the box plots.

`5_estimation` - Subfolder including the estimation results used for the response curves.

# Results repository structure
`1_Description` - Subfolder including data description files and figures.

`2_Crossvalidation_crossmig` - Subfolder including the cross-validation figures for the cross-border migration analysis.

`3_Crossvalidation_withinmig` - Subfolder including the cross-validation figures for the within-country migration analysis.

`4_Estimation_crossmig` - Subfolder including the estimation figures for the cross-border migration analysis.

`5_Estimation_withinmig` - Subfolder including the estimation figures for the within-country migration analysis.

`6_Projection_crossmig` - Subfolder including the projection figures for the cross-border migration analysis.

# Running the code
Start by running the `set.do` file in the `0_datacleaning/0_setup` subfolder.

Then on each step of the analysis, start by running the standalone file in each subfolder. Resulting constructed data files and figures will be stored in the `INPUT` and `RESULTS` folders, respectively.

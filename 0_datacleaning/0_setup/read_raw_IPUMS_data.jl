# This script reads the raw IPUMS data file and creates country-specific files


using CSV, OnlineStats, Plots, DataFrames, StatsPlots, XLSX, Query


###########################################################################################################################
######################################################### Read IPUMS data #################################################
###########################################################################################################################
# Charge raw file
ipums_d = CSV.File(joinpath(@__DIR__,"../ipumsi_00001.csv");limit=20) |> DataFrame

# Obtain variables names
cn = names(ipums_d) ; print(cn)

# Variables of interest
# For cross-border migration
crossmigcol = [
    :YEAR, :COUNTRY,                                                # census country, year
    :PERWT,                                                         # representative weight of each individual surveyed
    :AGE, :SEX, :EDATTAIN,                                          # demographics of individual surveyed
    :BPLCOUNTRY, :YRIMM, :MIGCAUSE,                                 # birth place, year of immigration, reason for migrating (largely missing)
    :URBAN                                                          # rural/urban status of individual surveyed
]
# For within-country migration
withinmigcol = [
    :YEAR, :COUNTRY,                                                # census country, year
    :PERWT,                                                         # representative weight of each individual surveyed
    :AGE, :SEX, :EDATTAIN,                                          # demographics of individual surveyed
    :GEOLEV1, :AREAMOLLWGEO1,                                       # subnational area of residence, surface of subnational area
    :MIGRATE1, :MIGRATE5, :MIGRATE0, :MIGRATEC,                     # migration status 1, 5, 10 years ago, last census
    :GEOMIG1_P, :GEOMIG1_1, :GEOMIG1_5, :GEOMIG1_10, :MIGYRS1,      # area of previous residence, 1, 5, 10 years ago, years residing in current area 
    :MIGCAUSE,                                                      # reason for migrating (largely missing)
    :URBAN                                                          # rural/urban status of individual surveyed
]

allmigcol = union(crossmigcol,withinmigcol)


###########################################################################################################################
######################################################### Create country-specific files ###################################
###########################################################################################################################
# Partition dataset into country-specific sets for easier manipulation

# First, gather indexes of last row for each country in the raw dataset

# Charge first column, which contains country codes 
c1 = CSV.File(joinpath(@__DIR__,"../ipumsi_00001.csv");select=[1]) |> DataFrame        # takes about 15 min to run

# Initialize to first row
j0 = c1[1,1]
j=1

# Create empty DataFrame for storing indexes
indc = DataFrame(country=[],lastind=[])

# Loop over first column only to limit computation time
while j < size(c1,1)
    j = findlast(x->x==j0, c1[:,1])
    push!(indc, [j0,j])
    print(j0," ",j,"  ")
    j0 = c1[j+1,1]
end

# Match with country labels
ctrycode = CSV.File(joinpath(@__DIR__,"../Input_data/1_raw/Coordinates/ipums_ctrycode.csv")) |> DataFrame
indc = innerjoin(rename(indc,:country=>:code),rename(ctrycode,:Value=>:code),on=:code)


# Second, create separate file for each country

# Loop over country row indexes
for i in eachindex(indc[:,1])
    if i == 1
        # initialize with first country
        dfc = CSV.Rows(joinpath(@__DIR__,"../ipumsi_00001.csv"); limit = indc[1,:lastind], select=allmigcol) |> DataFrame        
    else
        dfc = CSV.Rows(joinpath(@__DIR__,"../ipumsi_00001.csv"),reusebuffer=true; select=allmigcol, skipto = indc[i-1,:lastind]+2, limit = indc[i,:lastind] - indc[i-1,:lastind]) |> DataFrame
    end

    CSV.write(joinpath(@__DIR__,string("../Input_data/1_raw/Country_census/ctry_", indc[i,:Label],".csv")), dfc)
    
    print(i, " ",indc[i,:Label], "  ")
end


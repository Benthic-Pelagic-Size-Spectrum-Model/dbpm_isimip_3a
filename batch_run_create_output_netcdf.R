#----------------PUT FISH_MIP MODEL OUTPUTS INTO netcdf 4

rm(list=ls())

#install.packages("RNetCDF")

library('RNetCDF')

# CN work with one earth model at the time: 
# load(file ="/../../rd/gem/private/fishmip_inputs/ISIMIP3b/IPSL-CM6A-LR/IPSL-CM6A-LR_depth.RData") # load depth data
# load(file ="/../../rd/gem/private/fishmip_inputs/ISIMIP3b/GFDL-ESM4/GFDL-ESM4_depth.RData") 

# CN or chose your model here # NOTE HERE YOU DECIDE THE ESM 
esms <- c("spinup","ctrlclim" ,"obsclim")
scenarios <- c("1deg","0.25deg")

# type of outputs to save
agg_out <- F
agg_out_sp <- T

for (iESM in esms[2:3]) {
  
  iScen <- 1
  curr_esm <- iESM
  curr_scen <- scenarios[iScen]
  
  load(list.files(path=paste("/rd/gem/private/fishmip_inputs/ISIMIP3a/processed_forcings/",
                             curr_esm, 
                             '/', 
                             curr_scen, 
                             sep = ""),
                  pattern = "*depth*", full.names = TRUE))
  
  # # locate Noth Sea and dowload for 1 grid sise-spectrum analysis
  # trial<-depth
  # trial$trial<-seq(1:nrow(trial))
  # trial[which(trial$lat == 60.5 & trial$lon == -4.5),] # GFDL 54176 is the gridnum which correspond to the 37014 igrid (following row numbers) - depends on curr_esm above
  # result_set<-readRDS("/../../rd/gem/private/fishmip_outputs/ISIMIP3b/GFDL-ESM4/ssp585/dbpm_output_all_37014_ssp585.rds")
  # input<-readRDS("/../../rd/gem/private/fishmip_inputs/ISIMIP3b/GFDL-ESM4/ssp585/grid_37014_GFDL-ESM4_ssp585.rds")
  # # trial[which(trial$lat == 60.5 & trial$lon == -4),] # IPSL 54177 is the gridnum which correspond to the 34856 igrid (following row numbers)
  # result_set<-readRDS("/../../rd/gem/private/fishmip_outputs/ISIMIP3b/IPSL-CM6A-LR/ssp585/dbpm_output_all_34856_ssp585.rds")
  # input<-readRDS("/../../rd/gem/private/fishmip_inputs/ISIMIP3b/IPSL-CM6A-LR/ssp585/grid_34856_IPSL-CM6A-LR_ssp585.rds")
  
  # locate cells showing super steep slope in DBPM and dowload for 1 grid sise-spectrum analysis: these have been identified in Plot_maps.Rmd
  #    lon  lat     value
  # 1  -72 26.5 -6.561669
  # 2  -71 26.5 -6.567075
  # 3  -70 26.5 -6.567317
  # 4  -69 26.5 -6.567084
  # 5  -68 26.5 -6.566159
  # 6  -67 26.5 -6.564670
  # 7  -66 26.5 -6.565271
  # 8  -73 25.5 -6.466836
  # 9  -72 25.5 -6.566705
  # 10 -71 25.5 -6.567137
  
  # trial<-depth
  # trial$trial<-seq(1:nrow(trial))
  # trial[which(trial$lat == 26.5 & trial$lon == -72),] # IPSL 28980
  # trial[which(trial$lat == 26.5 & trial$lon == -71),] # 28981
  # trial[which(trial$lat == 26.5 & trial$lon == -70),] # 28982
  # trial[which(trial$lat == 26.5 & trial$lon == -69),] # 28983
  # trial[which(trial$lat == 26.5 & trial$lon == -68),] # 28984
  # trial[which(trial$lat == 26.5 & trial$lon == -67),] # 28985
  # trial[which(trial$lat == 26.5 & trial$lon == -66),] # 28986
  # trial[which(trial$lat == 25.5 & trial$lon == -73),] # 28771
  # trial[which(trial$lat == 25.5 & trial$lon == -72),] # 28772
  # trial[which(trial$lat == 25.5 & trial$lon == -71),] # 28773
  
  # location - we are interested in historical runs for this check 
  # /rd/gem/private/fishmip_outputs/ISIMIP3b/IPSL-CM6A-LR/historical/grid_28980_IPSL-CM6A-LR_historical.rds
  # location of inputs - needed too
  # /rd/gem/private/fishmip_inputs/ISIMIP3b/IPSL-CM6A-LR/historical/grid_28980_IPSL-CM6A-LR_historical.rds
  
  # end grid location
  
  # grids to read in are sequential for the depth file
  grids<-1:dim(depth)[1] 
  
  # locations of inputs, outputs from models and where to save netcdf 
  input_loc <- paste0("/rd/gem/private/fishmip_inputs/ISIMIP3a/processed_forcings/",curr_esm,"/",curr_scen,"/gridcell/")
  output_loc <- paste0("/rd/gem/private/fishmip_outputs/ISIMIP3a/",curr_esm,"/",curr_scen,"/")
  save_loc <- paste0("/rd/gem/private/fishmip_outputs/ISIMIP3a/",curr_esm,"/netcdf/")
  
  # CN variables to make 
  # vars2make <- c('U', 'V', 'GGU','GGV') # 'W','dx','x') # if not aggregated   
  vars2make <- c('tcb', 'tpb', 'bp30cm', 'bp30to90cm',"bp90cm",'tdb','bd30cm', 'bd30to90cm',"bd90cm") # if aggregated # NOTE this order is very important!! 
  # if you change it, you need to change dbpm.variables at the beginning of the
  # makenetcdfs_func.R
  # added tcblog10 below, as it needs a size dimension
  prots <- scenarios
  yearRange<- c("1841_1960","1961_2010","1961_2010")
  names(yearRange) <- esms
  
  #### option 3 ----
  
  result_set <- readRDS(paste0("/rd/gem/private/fishmip_outputs/ISIMIP3a/",
                               curr_esm,"/",curr_scen,"/","dbpm_output_all_1_",curr_scen,".rds"))
  isave<-1:dim(result_set$U)[2] 
  
  # isave<- list(isave_p, isave_h, isave_126, isave_585) # picontrol needs to be added instead of historical if picontrol is run 
  
  # other parameters to cut and aggregate outputs 
  # these were originally used (and can still be used) inside the model to aggregate outputs (runmodel_yearly ~ line 316)
  # these can be change according to fishmip requirements
  # ask Julia or investigate the code on the  meaning of these parameters
  x = result_set$x
  dx = result_set$dx
  Nx = length(x)
  x1 = -3 
  x1.det = -3  
  xmin = -12
  ref = ((x1-xmin)/dx)+1
  ref.det = ((x1.det-xmin)/dx)+1 
  
  other_param = list (
    # isave = isave, 
    x = x, 
    dx = dx, 
    Nx = Nx, 
    x1 = x1, 
    x1.det = x1.det, 
    xmin = xmin, 
    ref = ref, 
    ref.det = ref.det)
  
  # CN: dimnames for size (in not aggregated outputs) should be also defined as 'x'
  
  # CN call the function
  source("makenetcdfs_func.R")
  
  # CN: loop through variables and scenarios and create a netcdf file for each combination. 
  
  #### for not aggregated ("partial") outputs ----
  
  # USE TO SAVE THE RAW SIZE_SPECTRUM!? need to adjust according to functions below as you did not update this one I think
  
  # for(i in 1:length(vars2make)){
  # i = 1
  
  # for(j in 1:length(prots)){
  
  # j = 1 # for not aggregated outputs - one variable for one protocol (all grids, yearly outputs) takes 18h to run    
  
  # ptm=proc.time()
  # options(warn=-1)
  # print(paste('Now working on ', vars2make[i], ' for protocol ', prots[j], sep = ''))
  # mknetcdf(vars2make[i], prots[j], input_loc, output_loc, save_loc, grids, isave, yearRange[j])
  # print((proc.time()-ptm)/60.0)
  
  # }
  # }
  
  #### for aggregated outputs ---- 
  
  if(agg_out)
  {
    dbpm.variables<-data.frame(name = vars2make, 
                               description = c("Total Consumer Biomass Density",
                                               "Total Pelagic Biomass Density", 
                                               "Biomass Density of Small Pelagics <30cm",
                                               "Biomass Density of Medium Pelagics >=30cm and <90cm",
                                               "Biomass Density of Large Pelagics >=90cm",
                                               "Total Demersal Biomass Density",
                                               "Biomass Density of Small Demersals <30cm",
                                               "Biomass Density of Medium Demersals >=30cm and <90cm",
                                               "Biomass Density of Large Demersals >=90cm"))
    
    
    vars2make <- c('tcb', 'tpb', 'bp30cm', 'bp30to90cm',"bp90cm",'tdb','bd30cm', 'bd30to90cm',"bd90cm")
    
    # for(i in 1:length(vars2make)){
    
    i = 1 # new runs with min size = -3: tcb done, tbp running now 
    
    # for(j in 1:length(prots)){ 
    
    # j = 3 # ssp126: for aggregated outputs (all grids, monthly outputs) all variables takes 10 h to run  
    # j = 4 # ssp585: for aggregated outputs (all grids, monthly outputs) all variables takes 10 h  
    # j = 2 # historical: for aggregated outputs (all grids, monthly outputs) all variables takes ~2.2 days 
    # j = 1 # picontrol for aggregated outputs (all grids, monthly outputs) all variables takes 17 h
    
    # new round as above but only for histo and spps and given model outputs with no temp effect on senescence 
    # run all together 
    
    # fix this for ssp585 due to 22430 cell where U is saved as character - fixed in runmodel_yearly line ~570 but temp solution (now deleted and moved to line ~330 makenetcdf_fumc.R; see below)
    # Error in result_set$U[other_param$ref:other_param$Nx, isave] * other_param$dx : 
    # non-numeric argument to binary operator
    # tcb OK for the 3 protocols  
    
    # Fix errors as per Matthias 
    # j = 3
    
    # new runs given no temp effect on senescence and detritus otehr mortality 
    # run both IPSL and GFDL
    # the erron on cell 22430 for IPSl did not come up when creating outputs - but it did for another cell for GFDL... how to identify the grid cell? explore which file is bigger than a regular one: cell 38658
    # to fix this error I transform outputs to numeric (if they have been saved as characters) in line ~ 330 makenetcdf_fumc.R
    
    # grids<-36 # for GFDL this grid cell gives an error, it did not like paste(input$depth$lon) so now replaced with input$depth$lon 
    
    # i = 1
    # j = 4
    
    # GFDL files corrupted - see note below on size-spectrum function
    # re-running tcb first as you need to include in CMIP paper - then all the other
    
    # re-run all but tcb 
    
    ptm=proc.time()
    options(warn=-1)
    print(paste('Now working on ', vars2make[i], ' for esm ',iESM," and protocol ", prots[iScen], sep = ''))
    mknetcdf_agg(vars2make[i], prots[iScen], input_loc, output_loc, save_loc, grids, other_param, isave ,yearRange[iESM], curr_esm)
    print((proc.time()-ptm)/60.0)
    
  }
  
  # }
  
  #### for aggregated size-spectrum outputs ----
  if(agg_out_sp)
  {
    # for(j in 1:length(prots)){
    
    #j = 1
    # picontrol error then function stopped  
    # Error in `[<-`(`*tmp*`, inputs$depth$lon, inputs$depth$lat, size[2], ,  : 
    #                  subscript out of bounds
    
    # corrupted file when changed the size bins extremes - try only ssp126 - dowload to desktop and compare with old one 
    # all seemed to work ok when I printed size-spectrum using old size bins
    # j = 3 # still corrupted - 21 h to run 
    # retry - changed matrix indexing to var[pos_lon,pos_lat,1,] where the pos are the position of the lat an dlong withing the matrix 
    ### IF THIS WORKS you need to check the other outpouts (e.g. tcb) as it's quite strange that the old approach worked for these outputs 
    # it worked - only 2 h to run (?) warning message 'R version change [4.0.4 -> 4.0.5] detected when restoring session; search path not restored' 
    # running for the other 2 IpSL scenarios - then check other/previous outputs created with the onld method
    # hist ok but ssp585 not: Error in result_set$U[xcutref[1]:xcutref[2] - 1, isave] : subscript out of bounds
    # that was because you forgot to specify a reduced isave and yearrange... 
    # re-run both with correct values - should take little time
    # OK worked, 1h historical and 0.5h ssp585
    
    # iScen <- 1
    # iESM <- 1
    # curr_esm <- esms[iESM]
    # curr_scen <- scenarios[iScen]
    
    # prots <- scenarios
    # yearRange<- c("1841_1960","1961_2010","1961_2010")
    # names(yearRange) <- esms
    
    # result_set <- readRDS(paste0("/rd/gem/private/fishmip_outputs/ISIMIP3a/",
    # curr_esm,"/",curr_scen,"/","dbpm_output_all_1_",curr_scen,".rds"))
    # isave<-1:dim(result_set$U)[2] 
    
    # check with Cami right isave, iScen and iESM
    
    # install.packages("tidyverse") # long process ... 
    # library("tidyverse") # checking for Julia ... 
    
    # for(j in 1:length(prots)){  
    
    ptm=proc.time()
    options(warn=-1)
    print(paste('Now working on ', "tcblog10", ' for protocol ', prots[iScen], " ", curr_esm, sep = ''))
    mknetcdf_agg_sp("tcblog10", prots[iScen], input_loc, output_loc, save_loc, grids, other_param, isave, yearRange[iESM], curr_esm)
    print((proc.time()-ptm)/60.0)
    
  }
}

#### check ----

library(ncdf4)
# nc <- nc_open("/../../rd/gem/private/fishmip_outputs/ISIMIP3a/IPSL-CM6A-LR/netcdf/historical/dbpm_ipsl-cm6a-lr_nobasd_historical_nat_default_tcblog10_global_monthly_1850_2014.nc")
nc <- nc_open("/../../rd/gem/private/fishmip_outputs/ISIMIP3a/ctrlclim/netcdf/dbpm_ctrlclim_nobasd_1deg_nat_default_tcblog10_global_monthly_1961_2010.nc")
nc <- nc_open("/../../rd/gem/private/fishmip_outputs/ISIMIP3a/ctrlclim/netcdf/dbpm_ctrlclim_nobasd_1deg_nat_default_tcb_global_monthly_1961_2010.nc")

print(nc)
lon <- ncvar_get(nc, "lon")
lat <- ncvar_get(nc, "lat")
time_months <- ncvar_get(nc, "time")
size <- ncvar_get(nc, "bins")
yearmonth = as.yearmon("1601-01") + time_months[1] / 12

tcbh <- ncvar_get(nc, "tcblog10")
dim(tcbh)
tcbh[1:2,1:2,1:2,1:2]
tcbh[1:2,1:2,1:2]


nc <- open.nc("/../../rd/gem/private/fishmip_outputs/ISIMIP3a/IPSL-CM6A-LR/netcdf/ssp126/dbpm_ipsl_cm6a_lr_nobc_ssp126_nat_default_tcb_global_montly_2015_2100.nc4")
tcb126 <- var.get.nc(nc, "tcb")
max(tcb126, na.rm =TRUE)
min(tcb126, na.rm =TRUE)
tcb126[which(tcb126 == max(tcb126, na.rm =TRUE))]<-NA # not sure what the cut off should be here for the different variables 
image(tcb126[,,1031])
dim(tcb126)
# problem with last time step.... need to CHECK why...
tcb126<-tcb126[,,1:dim(tcb126)[3]-1]

nc <- open.nc("/../../rd/gem/private/fishmip_outputs/ISIMIP3a/IPSL-CM6A-LR/netcdf/ssp585/dbpm_ipsl_cm6a_lr_nobc_ssp585_nat_default_tcb_global_montly_2015_2100.nc4")
tcb585 <- var.get.nc(nc, "tcb")
tcb585[which(tcb585 == max(tcb585, na.rm =TRUE))]<-NA # this is 1e20
image(tcb585[,,1031])
# problem with last time step.... need to CHECK why... could be similar to historical runs? 
tcb585<-tcb585[,,1:dim(tcb585)[3]-1]

#### biomass thorugh time ----
bio_h<-rowSums(aperm(tcbh, c(3,1,2)), dims = 1, na.rm = TRUE)
plot(bio_h) # yearly values for now  
bio_126<-rowSums(aperm(tcb126, c(3,1,2)), dims = 1, na.rm = TRUE)
plot(bio_126) # monty - decreases 
bio_585<-rowSums(aperm(tcb585, c(3,1,2)), dims = 1, na.rm = TRUE)
plot(bio_585)

# install.packages("vctrs")
library("tidyr")
library("dplyr")
library("ggplot2")
df<-data.frame(bio_126 = bio_126, bio_585 = bio_585) %>% 
  mutate(time= seq(1:length(bio_585))) %>% # 2015-20100 in months and including last year (12 months) of spinup
  gather(key, value, -time) 

ggplot(df, aes(x=time, y=value, group = key, color = key))+
  geom_point()


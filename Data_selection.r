#Libraries#####################################################################
 library(ncdf4)
 library(reshape)
 library(httpgd)
 library(cowplot)
 library(tidyverse)
 hgd()
#Function######################################################################
 grab_File <- function(path = "", d2variable = "", d1variable = "",
                       timeslice = "") {
            if(d2variable != ""){
                data <- nc_open(path)
                d2 <- ncvar_get(data, varid = d2variable)
                if(is.na(timeslice) == TRUE) {
                    d2 <- d2[, ]
                }else {
                   d2 <- d2[, , timeslice]
                }
                d2 <- as.data.frame(d2)
                output <- d2
            }
            if(d1variable != ""){
                data <- nc_open(path)
                d2 <- ncvar_get(data, varid = d1variable)
                d2 <- d2[]
                d2 <- as.data.frame(d2)
                output <- d2
            }
            return(output)
        }
#Reading in data###############################################################
test <- grab_File(path = "Data\\G10010_sibt1850_v2.0.nc",
                       d2variable = "seaice_conc", timeslice = 1)
 lat <- grab_File(path = "Data\\G10010_sibt1850_v2.0.nc",
                  d1variable = "latitude")
 lon <- grab_File(path = "Data\\G10010_sibt1850_v2.0.nc",
                  d1variable = "longitude")
#77:160, 680:841
data_list <- list()
for(i in seq_along(1:2016)){
    temp_dat <- grab_File(path = "Data\\G10010_sibt1850_v2.0.nc",
                       d2variable = "seaice_conc", timeslice = i)
    temp_dat <- temp_dat[680:841, 77:160]
    timestep <- as.character(i)
    print(timestep)
    data_list[[timestep]] <- temp_dat
}


# 1. Define Dimensions
lon <- lon[680:841,]
lat <- lat[77:160,]
time <- seq_along(data_list)  # Time dimension (e.g., 1, 2, ..., length(data_list))

# Define NetCDF dimensions
lon_dim <- ncdim_def("longitude", "degrees_east", lon)
lat_dim <- ncdim_def("latitude", "degrees_north", lat)
time_dim <- ncdim_def("time", "months since 1850-01-01", time, unlim = TRUE)  # Unlimited time dimension

# 2. Define Variables
# Main variable: sea ice concentration
seaice_var <- ncvar_def(name = "seaice_conc",       # Variable name
                        units = "%",                # Units
                        dim = list(lon_dim, lat_dim, time_dim),  # Dimensions
                        missval = -9999,            # Missing value
                        longname = "Sea Ice Concentration")  # Description

# 3. Create NetCDF File
nc_out <- nc_create("Bering_Strait_Seaice_Concentration.nc",
                    vars = list(seaice_var))

# 4. Write Data to NetCDF
# Loop through each time step and write data
for (i in seq_along(data_list)) {
    temp_data <- data_list[[i]]  # Extract the i-th element

    # Ensure temp_data is a numeric matrix
    temp_data <- as.matrix(temp_data)
    storage.mode(temp_data) <- "double"  # Ensure it is numeric

    # Write data to the NetCDF file
    ncvar_put(nc_out, seaice_var, temp_data, start = c(1, 1, i), count = c(-1, -1, 1))
}


# 5. Close NetCDF File
nc_close(nc_out)

print("NetCDF file created successfully: seaice_concentration.nc")

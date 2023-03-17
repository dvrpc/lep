# LEP
# Indicators of Potential Disadvantage

This project automates parts of DVRPC's Limited english profenency (LEP) analysis, including data download, processing, and export. 

## Getting the Code and Software

1. Clone the repository. 
2. Download and install R from https://www.r-project.org/
3. Download and install R Studio from https://www.rstudio.com/products/rstudio/#Desktop

## Installing Package Dependencies 

The R script has the following dependencies: 

`plyr; here; sf; summarytools; survey; srvyr; sjmisc; tidycensus; tidyverse; tigris; dplyr; descr; sp; rgdal; raster`

If you have not previously installed the dependencies, you will need to do so. If you try to run the script without installing the packages, you will get an error message like 
`Error in library (name_of_package) : there is no package called 'name_of_package'`.

Install each package from R Studio's console (typically at the bottom of the screen in R Studio) with the command  `install.packages('name_of_package')` (include the quotation marks). 

## Updating the Script for a New 5-Year Dataset

If you are running the code against a newly released 5-year ACS dataset, do the following:

1. Make a copy of the latest variables.R file  and rename it for the year you are working on. (This is to ensure that any schema changes for a particular 5-year dataset are kept with the code for that set.)
2. Adjust the value for the `lep_year` variable (to be the end year of the dataset).
3. Verify the field names (listed in the variables.R file).

## Running the Code

1. Open RStudio. 
2. Open the R file (File -> Open File)
3. Start with the variables.R file running it in its entirety then run the dataCollection.R file
4. Run the code by clicking the Source button or Ctrl+A followed by Ctrl+Enter.

## Attempts to automate
Currently parts of this project were done by joining the output tables to tiger line files based on census provided GEOID. This has been refined to export directly using the tigris package. In addtion fields were renamed for ease of use, a compehensive guide to fields used is avaible at data.census.gov .

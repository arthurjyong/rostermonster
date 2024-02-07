# Clear all
cat("\f")
rm(list=ls())

# Set working directory to the directory of the current script
setwd(dirname(sys.frame(1)$ofile))

source('toolkit.R')
source('monster.R')
source('monster_2.R')
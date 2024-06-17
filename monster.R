# Clear all
cat("\f")
rm(list=ls())

# Set working directory to the directory of the current script
setwd(dirname(sys.frame(1)$ofile))
source('toolkit.R')

# Start gathering needed information from input excel
roster <- excel_2_roster("input.xlsx")
mos <- excel_2_mos("input.xlsx")
first_day_postcall <- excel_2_fdpc("input.xlsx")
cumulative_callpoints <- excel_2_callpoints("input.xlsx")

# THIS IS THE MOST IMPORTANT VALUE TO CHANGE IN THIS FILE
# DO NOTE THAT THE num_iteration IS IN MULTIPLE OF each_cycle
# Meaning if you put 100 x 10000, effectively is 1 million iteration
num_iteration = 10
each_cycle = 100

# PARALLEL Loop
start_time <- Sys.time()

for (cycle_no in 1:num_iteration){
  cycle_start_time <- Sys.time()

  # Generate message for consoles
  print(paste0("Generating call roster... cycle #",cycle_no))
    
  # PARALLEL Backend
  no_cores = parallel::detectCores()
  registerDoParallel(no_cores)

  # Progress Bar
  cl <- makeCluster(no_cores)
  registerDoSNOW(cl)
  pb <- txtProgressBar(max = each_cycle, style = 3)
  progress <- function(n){setTxtProgressBar(pb, n)}
  opts <- list(progress = progress)

  # Foreach loop with dopar
  parallel_output_roster_list <- foreach(i = 1:each_cycle, .combine = 'c', .options.snow = opts) %dopar% {

    # Generating roster
    temp_output_roster <- call_monster(roster, mos)
    temp_output_roster_callpoint <- callpoint_calculator(mos, temp_output_roster)
    subtotal_callpoints <- temp_output_roster_callpoint + cumulative_callpoints
    temp_output_roster_sd <- round(sd(unlist(subtotal_callpoints)), 2)

    if (any(is.na(temp_output_roster)) == FALSE) {
      list(temp_output_roster)  # Include in the list
    } else {
      list()  # Return an empty list for this iteration
    }
  }

  # Stop parallel
  stopImplicitCluster()
  close(pb)
  stopCluster(cl)

  # Write out the output to date to cache
  current_timestamp <- format(Sys.time(), "%y%m%d_%H%M%S")
  saveRDS(parallel_output_roster_list, file.path(porl_dir, paste0(current_timestamp,".rds")))

  cycle_end_time <- Sys.time()
  cycle_time_taken <- round(cycle_end_time-cycle_start_time, 2)
  print(cycle_time_taken)
}

end_time <- Sys.time()
time_taken <- round(end_time-start_time, 2)

print("Time taken to generate all rosters:")
print(time_taken)
print(paste("Cumulative output size:",get_directory_size(porl_dir),"MB"))

# Post-processing starts here
start_time <- Sys.time()

# Now read the porl_dir files and combine them into list for downstream shortlisting
porl_list <- dir(porl_dir)
combined_porl <- list()
porl_list_dirs <- file.path(porl_dir, porl_list)
porl_start_time <- Sys.time()
combined_porl <- lapply(porl_list_dirs, readRDS) # I tried mclapply, it's much slower than lapply
porl_end_time <- Sys.time()
porl_time_taken <- round(porl_end_time-porl_start_time, 2)
print("Time taken to collate all call rosters:")
print(porl_time_taken)

combined_porl <- do.call("c", combined_porl)
print(paste("Total number of rosters detected:", length(combined_porl)))

# This utilizes parallel for multicore processing
# Shortlist the generated roster based on SD of callpoints and cumulative callpoints
mclapply_start_time <- Sys.time()
combined_sd <- unlist(mclapply(combined_porl, function(x) round(sd(callpoint_calculator(mos, x)),2), mc.cores = detectCores()))
combined_cumulative_sd <- unlist(mclapply(combined_porl, function(x) round(sd(callpoint_calculator(mos, x)+cumulative_callpoints),2), mc.cores = detectCores()))
mclapply_end_time <- Sys.time()
mclapply_time_taken <- round(mclapply_end_time-mclapply_start_time, 2)
print("Time taken to calculate all roster stats:")
print(mclapply_time_taken)
ordered_combined_stats_indices <- order(combined_cumulative_sd,combined_sd)

if (length(ordered_combined_stats_indices)>5){
  shortlisted_indice <- ordered_combined_stats_indices[1:5]
} else {
  shortlisted_indice <- ordered_combined_stats_indices
}

shortlisted_roster <- combined_porl[shortlisted_indice]
saveRDS(shortlisted_roster, file.path(cache_dir, "part1_shortlisted_roster_list.rds"))

# Print shortlisted roster to excel
wb <- createWorkbook()

subfn_roster_2_worksheet <- function(input_roster,index){
  roster_sd <- sprintf("%.2f", round(sd(callpoint_calculator(mos,input_roster)),2))
  roster_cumulative_sd <- sprintf("%.2f", round(sd(callpoint_calculator(mos,input_roster)+cumulative_callpoints),2))
  sheet_name <- paste(index, "cSD", roster_cumulative_sd, "SD", roster_sd)
  addWorksheet(wb, sheet_name)
  writeData(wb, sheet = sheet_name, input_roster)
}

mapply(subfn_roster_2_worksheet, shortlisted_roster, seq_along(shortlisted_roster), SIMPLIFY = FALSE)

# Writing out callpoints
output_cumulative_callpoint <- lapply(shortlisted_roster, function(df) callpoint_calculator(mos, df)+cumulative_callpoints)
output_cumulative_callpoint <- lapply(output_cumulative_callpoint, function(df) {
  sd_value <- sd(as.numeric(unlist(df)), na.rm = TRUE)
  sd_value_rounded <- round(sd_value, 2)
  df$SD <- sd_value_rounded
  return(df)
})
output_cumulative_callpoint <- do.call(rbind, output_cumulative_callpoint)
addWorksheet(wb, "cumulative_callpoints")
writeData(wb, sheet = "cumulative_callpoints", output_cumulative_callpoint)

output_roster_callpoint <- lapply(shortlisted_roster, function(df) callpoint_calculator(mos, df))
output_roster_callpoint <- lapply(output_roster_callpoint, function(df) {
  sd_value <- sd(as.numeric(unlist(df)), na.rm = TRUE)
  sd_value_rounded <- round(sd_value, 2)
  df$SD <- sd_value_rounded
  return(df)
})
output_roster_callpoint <- do.call(rbind, output_roster_callpoint)
addWorksheet(wb, "callpoints")
writeData(wb, sheet = "callpoints", output_roster_callpoint)

saveWorkbook(wb, file.path(getwd(), new_dir, "call_roster.xlsx"), overwrite = TRUE)

end_time <- Sys.time()
time_taken <- round(end_time-start_time, 2)
print("Time needed for post-processing:")
print(time_taken)
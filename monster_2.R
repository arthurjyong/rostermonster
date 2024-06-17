# Clear all
cat("\f")
rm(list=ls())

# Set working directory to the directory of the current script
setwd(dirname(sys.frame(1)$ofile))
source('toolkit.R')

# Start gathering needed information from input excel
mos_request <- excel_2_mos("input.xlsx")
first_day_postcall <- excel_2_fdpc("input.xlsx")
trainee_list <- excel_2_trainee("input.xlsx")

# Import the roster with call assigned
part_1_output <- as.data.frame(read_excel(file.path(new_dir,'call_roster.xlsx')))

roster_with_call <- part_1_output
mos_list <- unlist(mos_request$name)
roster_with_call <- ampm_monster(roster_with_call, mos_list)
roster_with_call <- sda_pc_monster(roster_with_call, first_day_postcall)
roster_with_call <- al_off_monster(roster_with_call, mos_request)
updated_mos_request <- call_wr_monster(part_1_output, mos_request)

# Start of parallel looping for calculation of output list
# THIS IS THE MOST IMPORTANT VALUE TO CHANGE IN THIS FILE
# DO NOTE THAT THE num_iteration IS IN MULTIPLE OF each_cycle
# Meaning if you put 100 x 10000, effectively is 1 million iteration
num_iteration = 5
each_cycle = 50

# PARALLEL LOOP
start_time <- Sys.time()

for (cycle_no in 1:num_iteration){
  cycle_start_time <- Sys.time()

  # Generate message for consoles
  print(paste0("Generating full roster... cycle #",cycle_no))

  # PARALLEL BACKEND
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

    temp_output_roster <- team_monster(roster_with_call, mos_list, priotitize_free_MO = FALSE)
    temp_output_roster <- weekday_team_monster(temp_output_roster)
    temp_output_roster <- tmx_monster(temp_output_roster)
    temp_output_roster <- run_monster(temp_output_roster)
    temp_output_roster <- trim_non_wr_wknd(temp_output_roster, updated_mos_request, mos_list)
    temp_output_roster <- wknd_trim_dup_team(temp_output_roster)
    temp_output_roster <- assign_wr_monster(temp_output_roster)
    temp_output_roster <- assign_wknd_monster(temp_output_roster,mos_list) # This is a heavy function, taking 50% of computational time here
    temp_output_roster <- assign_wknd_runner(temp_output_roster,mos_list)
    temp_output_roster <- equalize_wknd_duties(temp_output_roster,mos_list)

    if (min(c(temp_output_roster$T1,temp_output_roster$T2,temp_output_roster$T3))>0) {
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
  saveRDS(parallel_output_roster_list, file.path(porl2_dir, paste0(current_timestamp,".rds")))

  cycle_end_time <- Sys.time()
  cycle_time_taken <- round(cycle_end_time-cycle_start_time, 2)
  print(cycle_time_taken)
}

end_time <- Sys.time()
time_taken <- round(end_time-start_time, 2)
print("Time taken to generate all rosters:")
print(time_taken)
print(paste("Cumulative output size:",get_directory_size(porl2_dir),"MB"))

# Post-processing starts here
start_time <- Sys.time()

# Now read the porl2_dir files and combine them into list for downstream shortlisting
porl2_list <- dir(porl2_dir)
combined_porl2 <- list()
porl2_list_dirs <- file.path(porl2_dir, porl2_list)
porl2_start_time <- Sys.time()
combined_porl2 <- lapply(porl2_list_dirs, readRDS)
porl2_end_time <- Sys.time()
porl2_time_taken <- round(porl2_end_time-porl2_start_time, 2)
print("Time taken to collate all full rosters:")
print(porl2_time_taken)

combined_porl2 <- do.call("c", combined_porl2)
print(paste("Total number of rosters detected:", length(combined_porl2)))

# This utilizes parallel for multicore processing
# Shortlist the generated roster based on AMOC and SD
# AMOC stands for average MO count
# It meas the average MO count of all teams across all weeks
mclapply_start_time <- Sys.time()
combined_stats <- mclapply(combined_porl2, function(x) final_roster_stat(x, mos_list), mc.cores = detectCores())
mclapply_end_time <- Sys.time()
mclapply_time_taken <- round(mclapply_end_time-mclapply_start_time, 2)
print("Time taken to calculate all roster stats:")
print(mclapply_time_taken)
ordered_combined_stats_indices <- order(sapply(combined_stats, function(x) x[1]), sapply(combined_stats, function(x) x[2])) #sort based on AMOC, then based on SD

# This part is needed to filter out rosters with enough T3 duties allocated to HC trainees
shortlisted_indice <- list()
for (i in ordered_combined_stats_indices){
  temp_tally <- roster_tally(combined_porl2[[i]][combined_porl2[[i]]["AMPM"]=='AM',], mos_list)
  temp_tally <- temp_tally[temp_tally$MO %in% trainee_list,]
  if (min(temp_tally$T3) >= 10){ # The 10 here indicates that trainee need at least 10 T3 duties on weekdays AM
    shortlisted_indice <- unlist(c(shortlisted_indice, i))
    if (length(shortlisted_indice) >= 5) {break}
  }
}

shortlisted_roster_HC_filter <- combined_porl2[shortlisted_indice]
saveRDS(shortlisted_roster_HC_filter, file.path(cache_dir, "part2_shortlisted_roster_list_HC_filter.rds"))
shortlisted_roster_lowest_AMOC <- combined_porl2[ordered_combined_stats_indices[1:5]]
saveRDS(shortlisted_roster_lowest_AMOC, file.path(cache_dir, "part2_shortlisted_roster_list_lowest_AMOC.rds"))

# Print shortlisted roster to excel

subfn_roster_2_worksheet <- function(input_roster, index){
  roster_stat <- final_roster_stat(input_roster, mos_list)
  roster_amoc <- sprintf("%.2f", roster_stat[1])
  roster_sd <- sprintf("%.2f", roster_stat[2])
  sheet_name <- paste(index, "AMOC", roster_amoc, "SD", roster_sd)
  addWorksheet(wb, sheet_name)
  writeData(wb, sheet = sheet_name, input_roster)

  output_roster_tally <- roster_tally(input_roster,mos_list)
  sheet_name_tally <- paste(index, "roster tally")
  addWorksheet(wb, sheet_name_tally)
  writeData(wb, sheet = sheet_name_tally, output_roster_tally)
}

wb <- createWorkbook()
mapply(subfn_roster_2_worksheet, shortlisted_roster_HC_filter, seq_along(shortlisted_roster_HC_filter), SIMPLIFY = FALSE)
saveWorkbook(wb, file.path(getwd(), new_dir, "full_roster_HC_filter.xlsx"), overwrite = TRUE)

wb <- createWorkbook()
mapply(subfn_roster_2_worksheet, shortlisted_roster_lowest_AMOC, seq_along(shortlisted_roster_lowest_AMOC), SIMPLIFY = FALSE)
saveWorkbook(wb, file.path(getwd(), new_dir, "full_roster_lowest_AMOC.xlsx"), overwrite = TRUE)

end_time <- Sys.time()
time_taken <- round(end_time-start_time, 2)
print("Time needed for post-processing:")
print(time_taken)
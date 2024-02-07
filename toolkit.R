# This file includes all customized functions in monster project so when sourcing is easier to organize the code

# Loading library
library(openxlsx)
library(readxl)
library(dplyr)
library(foreach)
library(parallel)
library(doParallel)
library(progress)
library(doSNOW)

# Create a new directory for output and cache
new_dir <- "monster_output"
if (!dir.exists(new_dir)) {
  dir.create(new_dir)
}
cache_dir <- file.path(new_dir, "cache")
if (!dir.exists(cache_dir)) {
  dir.create(cache_dir)
}

# Generate a folder for parallel looping output
porl_dir <- file.path(cache_dir, "part1_parallel_output_roster_list")
if (!dir.exists(porl_dir)) {
  dir.create(porl_dir)
}

# Generate a folder for parallel looping output
porl2_dir <- file.path(cache_dir, "part2_parallel_output_roster_list")
if (!dir.exists(porl2_dir)) {
  dir.create(porl2_dir)
}

# Create date_monster to generate roster date frame
date_monster <- function(start_date, end_date, public_holidays = NULL) {
  
  # Lengthening end_data by 1 day for calculation of callpoint later
  end_date = end_date + 1
  
  # Generate a sequence of dates from start_date to end_date
  date_sequence <- seq(from = start_date, to = end_date, by = "days")
  day_sequence <- weekdays(date_sequence)
  
  # Determine if each day is a half day (Saturday, Sunday, or public holiday)
  halfday_sequence <- day_sequence %in% c("Saturday", "Sunday") | date_sequence %in% unlist(public_holidays)
  
  # Create a data frame with the date sequence
  roster <- data.frame(date = date_sequence, day = day_sequence, halfday = halfday_sequence)
  
  # Generating list of callpoint and oncall
  roster$callpoint <- rep(NA, nrow(roster))
  roster$oncall <- rep(NA, nrow(roster))
  
  # Assign callpoint
  for (i in 1:nrow(roster)){
    date_data <- roster[i,]
    d2_date_data <- roster[(i+1),]
    # Calculate until last date data of the list
    if (i == nrow(roster)) {
      break
    } else if (date_data$halfday == FALSE && d2_date_data$halfday == FALSE) {
      roster[i, ]$callpoint = 1
    } else if (date_data$halfday == FALSE && d2_date_data$halfday == TRUE) {
      roster[i, ]$callpoint = 1.25
    } else if (date_data$halfday == TRUE && d2_date_data$halfday == FALSE) {
      roster[i, ]$callpoint = 1.5
    } else if (date_data$halfday == TRUE && d2_date_data$halfday == TRUE) {
      roster[i, ]$callpoint = 1.75 # IMPORTANT! The 1.75 is hardcoded inside a patch for call_monster() below, do change that if change of callpoints are needed
    }
  }
  
  # Remove last row again
  roster <- roster[-nrow(roster), ]
  return(roster)
}

# Create leave_to_callblock covert leave to callblock
leave_to_callblock <- function(input_data_frame) {
  output_data_frame <- input_data_frame
  for (i in 1:nrow(output_data_frame)){
    row_data <- output_data_frame[i, ]
    callblock_list <- as.Date(unlist(row_data$callblock))
    leave_list_AM <- as.Date(unlist(row_data$leave_AM))
    leave_list_PM <- as.Date(unlist(row_data$leave_PM))
    leave_eve_list_AM <- as.Date(c(leave_list_AM - 1))
    leave_eve_list_PM <- as.Date(c(leave_list_PM - 1))
    final_callblock_list <- sort(as.Date(unique(na.omit(c(callblock_list,leave_list_PM,leave_eve_list_AM,leave_eve_list_PM)))))
    if (length(final_callblock_list) != 0) {
      output_data_frame[i, ]$callblock[[1]] <- final_callblock_list
    }
  }
  return(output_data_frame)
}

# Create call_monster to assign call
call_monster <- function(input_roster_data, input_mo_data){
  output_roster_data <- input_roster_data
  
  #First loop to assign call per call requests
  for (i in 1:nrow(output_roster_data)){
    output_mo_data <- input_mo_data
    date_data <- output_roster_data[i,]
    target_date <- as.Date(date_data$date)
    
    # Checking if anyone already scheduled oncall
    if (is.na(date_data$oncall)){ #if nobody oncall
      
      # Check for any call request, if yes, assigned by call request
      if (target_date %in% as.Date(unique(sort(na.omit(unlist(output_mo_data$callrequest))))) == TRUE){
        contains_target_date <- lapply(output_mo_data$callrequest, function(dates_list) {
          target_date %in% as.Date(unlist(dates_list))
        })
        call_candidate <- output_mo_data$name[unlist(contains_target_date)]
        if (length(call_candidate)==0){next}
        output_roster_data[i,]$oncall <- sample(call_candidate, 1)
      }
    }
  }
  
  #Second loop to assign call
  for (i in 1:nrow(output_roster_data)){
    output_mo_data <- input_mo_data
    date_data <- output_roster_data[i,]
    target_date <- as.Date(date_data$date)
    
    # Remove postcall MO from consideration
    if (i > 1){
      prev_day_data <- output_roster_data[(i-1),]
      postcall_mo <- prev_day_data$oncall
      if (is.na(postcall_mo) != TRUE){
        output_mo_data <- output_mo_data[-which(output_mo_data$name == postcall_mo),]
      }
    }
    
    # Remove post_postcall MO from consideration
    if (i > 2){
      prev_prev_day_data <- output_roster_data[(i-2),]
      post_postcall_mo <- prev_prev_day_data$oncall
      if (is.na(post_postcall_mo) != TRUE){
        output_mo_data <- output_mo_data[-which(output_mo_data$name == post_postcall_mo),]
      }
    }
    
    # Remove precall MO from consideration
    if (i < nrow(output_roster_data)){
      next_day_data <- output_roster_data[(i+1),]
      precall_mo <- next_day_data$oncall
      if (is.na(precall_mo) != TRUE){
        if (precall_mo %in% output_mo_data$name) {
          output_mo_data <- output_mo_data[-which(output_mo_data$name == precall_mo),]
        }
      }
    }
    
    # Remove pre_precall MO from consideration
    if (i < (nrow(output_roster_data)-1)){
      next_next_day_data <- output_roster_data[(i+2),]
      pre_precall_mo <- next_next_day_data$oncall
      if (is.na(pre_precall_mo) != TRUE){
        if (pre_precall_mo %in% output_mo_data$name) {
          output_mo_data <- output_mo_data[-which(output_mo_data$name == pre_precall_mo),]
        }
      }
    }
    
    # Patch included 19/01/2024
    # Basically if the person already have wknd workrequest >= (min_wknd-1), cannot do call with 1.75pt (eg sat calls)
    # This is because if you already has min_wknd-1, doing 1.75pt call may mean needing to round post call
    # This would cause the need to exceed min_wknd
    if (date_data$callpoint == 1.75){
      temp_wr <- call_wr_monster(output_roster_data, input_mo_data)
      min_wknd <- ceiling((nrow(input_roster_data[input_roster_data$halfday,]) * 4)/length(input_mo_data$name)) # The 4 is minimal manpower for each day: 1 for each team + 1 runner
      ttl_wknd <- nrow(input_roster_data[input_roster_data$halfday,])
      max_off <- (ttl_wknd-min_wknd)
      if (max(unlist(lapply(temp_wr$workrequest, length))) >= (min_wknd-1)) {
        mo_to_exclude <- temp_wr[lapply(temp_wr$workrequest, length)>=(min_wknd-1),]$name
        if (any(output_mo_data$name %in% mo_to_exclude)) {
          output_mo_data <- output_mo_data[-which(output_mo_data$name %in% mo_to_exclude),]
        }
      }
    }
    
    # Checking if anyone already scheduled oncall
    if (is.na(date_data$oncall) == TRUE){ #if nobody oncall
      
      # Check for any call request, if yes, assigned by call request
      if (target_date %in% as.Date(unique(sort(na.omit(unlist(output_mo_data$callrequest))))) == TRUE){
        contains_target_date <- lapply(output_mo_data$callrequest, function(dates_list) {
          target_date %in% as.Date(unlist(dates_list))
        })
        call_candidate <- output_mo_data$name[unlist(contains_target_date)]
        if (length(call_candidate)==0){next}
        output_roster_data[i,]$oncall <- sample(call_candidate, 1)
      } else
        
        # Check anyone blocking call
        if (target_date %in% as.Date(unique(sort(na.omit(unlist(output_mo_data$callblock))))) == TRUE){
          contains_target_date <- lapply(output_mo_data$callblock, function(dates_list) {
            target_date %in% as.Date(unlist(dates_list))
          })
          call_candidate <- output_mo_data$name[!unlist(contains_target_date)]
          if (length(call_candidate)==0){next}
          output_roster_data[i,]$oncall <- sample(call_candidate, 1)
        } else {
          
          # If nobody block or request call, go to non-post-call MO pools
          if (length(output_mo_data$name)==0){next}
          output_roster_data[i,]$oncall <- sample(output_mo_data$name,1)
          
        }
    }
  }
  return(output_roster_data)
}

# Creating a dataframe with mo names as title and callpoint as content
callpoint_calculator <- function (input_mo_data, input_roster_data = NULL){
  # Creating an output points table with NA as content
  mo_namelist <- unlist(input_mo_data$name)
  callpoint_table <- setNames(data.frame(matrix(ncol = length(mo_namelist), nrow = 1)), mo_namelist)
  callpoint_table[,] <- NA
  
  # Check if input_roster_data is not NULL
  if (!is.null(input_roster_data)) {
    # Finding the call points of each MO  
    for (i in mo_namelist){
      callpoint_table[[i]] <- sum(input_roster_data$callpoint[which(input_roster_data$oncall == i)])
    }
  }
  
  return(callpoint_table)
}

# Making request_converter to convert excel data into monster data frame
request_converter <- function (input_mo_extract, input_request_date, input_request_type){
  output_mo_extract <- input_mo_extract
  
  # Defining
  list_leave <- c("OFF","AL","TL","MC")
  list_callblock <- c("NC", "PC")
  list_callrequest <- c("CR")  
  list_workrequest <- c("WR")
  
  # If the request is under leave 
  if (input_request_type %in% list_leave){
    if (is.na(output_mo_extract$leave_AM) == TRUE && is.na(output_mo_extract$leave_PM) == TRUE){
      output_mo_extract$leave_AM <- list(input_request_date)
      output_mo_extract$leave_PM <- list(input_request_date)
    } else if (is.na(output_mo_extract$leave_AM) == TRUE && is.na(output_mo_extract$leave_PM) == FALSE){
      output_mo_extract$leave_AM <- list(input_request_date)
      output_mo_extract$leave_PM[[1]] <- as.Date(unlist(c(output_mo_extract$leave_PM, list(input_request_date))))
    } else if (is.na(output_mo_extract$leave_AM) == FALSE && is.na(output_mo_extract$leave_PM) == TRUE){
      output_mo_extract$leave_AM[[1]] <- as.Date(unlist(c(output_mo_extract$leave_AM, list(input_request_date))))
      output_mo_extract$leave_PM <- list(input_request_date)
    } else if (is.na(output_mo_extract$leave_AM) == FALSE && is.na(output_mo_extract$leave_PM) == FALSE){  
      output_mo_extract$leave_AM[[1]] <- as.Date(unlist(c(output_mo_extract$leave_AM, list(input_request_date))))
      output_mo_extract$leave_PM[[1]] <- as.Date(unlist(c(output_mo_extract$leave_PM, list(input_request_date))))
    }
  } else
    
    # If the request contains (AM)
    if (grepl("\\(AM\\)", input_request_type)){
      if (is.na(output_mo_extract$leave_AM) == TRUE){
        output_mo_extract$leave_AM <- list(input_request_date)
      } else {
        output_mo_extract$leave_AM[[1]] <- as.Date(unlist(c(output_mo_extract$leave_AM, list(input_request_date))))
      }
    } else
      
      # If the request contains (PM)
      if (grepl("\\(PM\\)", input_request_type)){
        if (is.na(output_mo_extract$leave_PM) == TRUE){
          output_mo_extract$leave_PM <- list(input_request_date)
        } else {
          output_mo_extract$leave_PM[[1]] <- as.Date(unlist(c(output_mo_extract$leave_PM, list(input_request_date))))
        }
      } else
        
        # If the request is under callblock
        if (input_request_type %in% list_callblock){
          if (is.na(output_mo_extract$callblock) == TRUE){
            output_mo_extract$callblock <- list(input_request_date)
          } else {
            output_mo_extract$callblock[[1]] <- as.Date(unlist(c(output_mo_extract$callblock, list(input_request_date))))
          }
        } else
          
          # If the request is under callrequest
          if (input_request_type %in% list_callrequest){
            if (is.na(output_mo_extract$callrequest) == TRUE){
              output_mo_extract$callrequest <- list(input_request_date)
            } else {
              output_mo_extract$callrequest[[1]] <- as.Date(unlist(c(output_mo_extract$callrequest, list(input_request_date))))
            }
          } else
            
            # If the request is under workrequest
            if (input_request_type %in% list_workrequest){
              if (is.na(output_mo_extract$workrequest) == TRUE){
                output_mo_extract$workrequest <- list(input_request_date)
              } else {
                output_mo_extract$workrequest[[1]] <- as.Date(unlist(c(output_mo_extract$workrequest, list(input_request_date))))
              }
            } else 
              
            {
              # When the input_request_type cannot be recognize, show warning
              warning(paste(input_request_type,"cannot be understood (i.e., not found in predefined list)"))
            }
  
  return (output_mo_extract)
}

# Convert input from excel to empty roster for subsequent manipulation
excel_2_roster <- function(input_excel_file) {
  imported_raw_data <- suppressMessages(read_excel(input_excel_file, sheet = 1))
  imported_ph_data <- suppressMessages(read_excel(input_excel_file, sheet = 2))
  
  # Extracting start_date, end_date, public_holidays_list
  date_data <- colnames(imported_raw_data)
  date_data <- date_data[-1]
  date_data <- as.Date(as.numeric(date_data), origin = "1899-12-30")
  start_date <- date_data[1]
  end_date <- date_data[length(date_data)]
  
  public_holidays_list <- imported_ph_data[["List of public holidays:"]]
  public_holidays_list <- unlist(as.Date(public_holidays_list))
  
  # Generate roster from extracted dates
  roster <- date_monster(start_date, end_date, public_holidays_list)
  
  return(roster)
}

# Convert input from excel to mos data for subsequent manipulation
excel_2_mos <- function(input_excel_file){
  
  imported_raw_data <- suppressMessages(read_excel(input_excel_file, sheet = 1))
  
  # Getting name list to monster dataframe format
  name_data <- imported_raw_data[1]
  name_list <- list()
  name_data <- for (i in 2:nrow(name_data)){
    name_list <- c(name_list,name_data[[i,1]])
  }
  name_list <- unlist(name_list)
  MO_number <- length(name_list)
  mos <- data.frame(
    name = name_list,
    leave_AM = rep(NA, MO_number),
    leave_PM = rep(NA, MO_number),
    callblock = rep(NA, MO_number),
    callrequest = rep(NA, MO_number),
    workrequest = rep(NA, MO_number)
  )
  
  # Getting data out...
  imported_raw_data <- imported_raw_data %>% slice(-1) # Remove the line of Mon Tue Wed etc
  
  for (i in 1:nrow(imported_raw_data)){
    temp_extract <- imported_raw_data[i,]
    temp_extract <- temp_extract %>% select(where(~ !any(is.na(.))))
    mo_index <- which(temp_extract[[1]] == unlist(mos$name))
    output_mos_extract <- mos[mo_index,]
    
    if (ncol(temp_extract) > 1) { # This filter out MO without making any request at all
      for (j in 2:ncol(temp_extract)){
        request_date <- as.Date(as.numeric(colnames(temp_extract[j])), origin = "1899-12-30")
        request_type <- temp_extract[j][[1]]
        
        if (grepl(", ", request_type) == TRUE) { # This is in case there's more than 1 request on the same day
          request_type_sublist <- unlist(strsplit(request_type, ", "))
          for (i in request_type_sublist){
            output_mos_extract <- request_converter(output_mos_extract,request_date,i)
          }
        } else {
          output_mos_extract <- request_converter(output_mos_extract,request_date,request_type)
        }
      }
    }    
    mos[mo_index,] <- output_mos_extract
  }

  # Patch included on 240117
  # If callrequest / workrequest already exceed than minimal weekends duties, arrange the remaining weekends as leave / OFF  
  temp_roster <- excel_2_roster(input_excel_file)
  wknd_dates <- temp_roster[temp_roster$halfday,]$date
  ttl_wknd <- length(wknd_dates)
  min_wknd <- ceiling((nrow(temp_roster[temp_roster$halfday,]) * 4)/length(name_list))
  
    # Subfunction to go through each line of mo request and check if it fits the criteria
    subfn_exceed_min_weekend <- function(temp_input_line){
      temp_cr <- as.Date(unlist(temp_input_line$callrequest))
      temp_pc <- temp_cr+1 # Exclude post-call as well
      temp_wr <- as.Date(unlist(temp_input_line$workrequest))
    
      wknd_minus_wr <- wknd_dates[!wknd_dates %in% temp_wr]
      wknd_minus_wr_cr <- wknd_minus_wr[!wknd_minus_wr %in% temp_cr]
      wknd_minus_wr_cr_pc <- wknd_minus_wr_cr[!wknd_minus_wr_cr %in% temp_pc]
    
      if (length(wknd_minus_wr_cr_pc) <= (ttl_wknd-min_wknd)){ # if workrequest + callrequest already max out over minimal weekend allocation, assign OFF / leave to the weekend dates
        temp_input_line$leave_AM[[1]] <- as.Date(sort(unique(c(unlist(temp_input_line$leave_AM),unlist(wknd_minus_wr_cr_pc)))))
      }
     
      return(temp_input_line) 
    }
    
    for (i in 1:nrow(mos)){
      mos[i,] <- subfn_exceed_min_weekend(mos[i,])
    }

  # Optimize mo list with prev defined leave_to_callblock
  mos <- leave_to_callblock(mos)
  return(mos)
}

# Convert input from excel to first_day_postcall
excel_2_fdpc <- function(input_excel_file){
  imported_raw_data <- suppressMessages(read_excel(input_excel_file, sheet = 1))
  imported_raw_data <- as.data.frame(imported_raw_data)
  first_day_data <- imported_raw_data[,1:2]
  
  if ("PC" %in% first_day_data[,2]) {
    first_day_postcall <- first_day_data[which(first_day_data[,2]=="PC"),1]
    return(first_day_postcall)
  } else {
    return(NA)
  }
}

# Convert input from excel to cumulative callpoints
# Cumulative callpoints needed to be placed on 3rd sheet of input.xlsx
excel_2_callpoints <- function(input_excel_file){
  imported_raw_data <- suppressMessages(read_excel(input_excel_file, sheet = 3))
  
  if (ncol(imported_raw_data)>1) { #Check if there is any data for cumulative callpoints, if there is none just return NA
    
    # Cleaning up of data format
    imported_raw_data <- as.data.frame(imported_raw_data)
    colnames(imported_raw_data) <- NULL
    imported_raw_data <- as.data.frame(t(imported_raw_data))
    colnames(imported_raw_data) <- NULL
    names(imported_raw_data) <- as.character(unlist(imported_raw_data[1, ]))
    imported_raw_data <- imported_raw_data[2:nrow(imported_raw_data),]
    rownames(imported_raw_data) <- NULL
    
    
    # Adding up cumulative callpoints
    if (nrow(imported_raw_data) >1) {
      cumulative_callpoints <- data.frame(lapply(imported_raw_data, as.numeric)) # Need to convert to numeric if not R will read as character
      colnames(cumulative_callpoints) <- colnames(imported_raw_data)
      column_sums <- colSums(cumulative_callpoints)
      cumulative_callpoints <- as.data.frame(t(column_sums))
    } else if (nrow(imported_raw_data) == 1){
      cumulative_callpoints <- data.frame(lapply(imported_raw_data, as.numeric))
      colnames(cumulative_callpoints) <- colnames(imported_raw_data)
      
    }
    
    if (any(is.na(cumulative_callpoints))){ # In case of incomplete data or absent of data
      cumulative_callpoints <- replace(cumulative_callpoints, is.na(cumulative_callpoints), 0)
      return(cumulative_callpoints)
    } else {
      return(cumulative_callpoints)
    }
    
  } else {
    mos <- excel_2_mos(input_excel_file)
    cumulative_callpoints <- callpoint_calculator(mos)
    cumulative_callpoints[] <- lapply(cumulative_callpoints, function(x) 0)
    return(cumulative_callpoints)
  }
}

# Convert input from excel to HC list
excel_2_trainee <- function(input_excel_file){
  imported_raw_data <- suppressMessages(read_excel(input_excel_file, sheet = 4))
  imported_raw_data <- as.data.frame(imported_raw_data)
  names(imported_raw_data) <- NULL
  trainee <- unlist(imported_raw_data)
  return(trainee)
}

# Function to get directory size in MB
get_directory_size <- function(dir_path) {
  # Check if the provided path is indeed a directory
  if (!dir.exists(dir_path)) {
    stop("The specified path is not a directory or does not exist.")
  }
  
  # List all files in the directory, including files in subdirectories
  file_list <- list.files(path = dir_path, full.names = TRUE, recursive = TRUE)
  
  # Get the size of each file
  file_sizes <- file.info(file_list)$size
  
  # Calculate the total size of the directory
  total_size <- sum(file_sizes)
  total_size <- round((total_size/1048576),2)

# Return the total size
return(total_size)
}

# IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT
# IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT
# IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT
# IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT
# IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT
# IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT
# IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT
# IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT
# IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT

# FUNCTIONS FROM THIS PART ONWARDS WERE CRAFTED FOR PART 2 OF THIS PROJECT
# THIS PART ONWARDS REQUIRE COMPLETION OF CALL ALLOCATION

# Converting the call list to include AM and PM shifts
ampm_monster <- function(input_roster, input_mo_list){
  
  output_roster <- input_roster
  output_roster$AMPM <- rep(NA, nrow(output_roster))
  
  i = 1
  roster_length <- nrow(output_roster)
  
  # Duplicate row 1 to row n-1 with both AM and PM shift (non-half-day)
  while (i < roster_length) {
    if (output_roster[i,]$halfday == FALSE){
      output_roster <- rbind(
        output_roster[1:i, ],         # Take all rows up to the row to duplicate
        output_roster[i, ],           # The row to duplicate
        output_roster[(i+1):nrow(output_roster), ] # Take all the remaining rows
      )
      output_roster[i,]$AMPM <- "AM"
      output_roster[i+1,]$AMPM <- "PM"
      i = i + 2
      roster_length <- nrow(output_roster)
    } else if (output_roster[i,]$halfday == TRUE){
      output_roster[i,]$AMPM <- "AM"
      i = i + 1
      roster_length <- nrow(output_roster)
    }
  }
  
  # Duplicate row n with both AM and PM shift (non-half-day)
  roster_length <- nrow(output_roster)
  
  if (output_roster[roster_length,]$halfday == FALSE) {
    output_roster <- rbind(
      output_roster[1:roster_length, ],         # Take all rows up to the row to duplicate
      output_roster[roster_length, ]           # The row to duplicate
    )
    output_roster[roster_length,]$AMPM <- "AM"
    output_roster[roster_length+1,]$AMPM <- "PM"
  } else if (output_roster[roster_length,]$halfday == TRUE) {
    output_roster[roster_length,]$AMPM <- "AM"
  }
  
  rownames(output_roster) <- NULL
  
  # Adding MOs names to output_roster
  for (i in input_mo_list) {
    output_roster[[i]] <- as.character(NA)
  }
  
  return (output_roster)
}

# Assigning post-call and SDA duties
sda_pc_monster <- function (input_roster, first_day_postcall = NA){
  
  output_roster <- input_roster
  
  for (i in 1:(nrow(output_roster)-1)) {
    # Assigning SDA and PC to first day of the roster with pre-defined first_day_postcall
    if (i == 1 && output_roster[i+1,]$AMPM == "PM" && !is.na(first_day_postcall)) {
      output_roster[i,][first_day_postcall] <- "SDA"
      output_roster[i+1,][first_day_postcall] <- "PC"
    }
    
    # Assigning SDA and PC to other days of the roster
    if (i > 1 && output_roster[i+1,]$AMPM == "PM") {
      postcall_mo <- as.character(output_roster[i-1,]$oncall)
      output_roster[i,][postcall_mo] <- "SDA"
      output_roster[i+1,][postcall_mo] <- "PC"
    }
  }
  return (output_roster)
}

# Assigning AL and OFF to roster
al_off_monster <- function (input_roster,input_mo_data){
  output_roster <- input_roster
  output_mo_data <- input_mo_data
  
  output_roster_index_AM <- which(output_roster$AMPM == "AM")
  output_roster_index_PM <- which(output_roster$AMPM == "PM")
  
  output_roster_AM <- output_roster[output_roster_index_AM,]
  output_roster_PM <- output_roster[output_roster_index_PM,]
  
  for (i in 1:nrow(output_mo_data)){
    mo_name <- unlist(output_mo_data[i,]$name)
    mo_leave_AM <- unlist(output_mo_data[i,]$leave_AM)
    mo_leave_PM <- unlist(output_mo_data[i,]$leave_PM)
    mo_workrequest <- unlist(output_mo_data[i,]$workrequest)
    
    if (length(mo_leave_AM)>1){ for (j in 1:length(mo_leave_AM)){
      leave_day <- mo_leave_AM[j]
      row_index <- which(unlist(as.Date(output_roster_AM$date)) == leave_day)
      row_name <- as.numeric(rownames(output_roster_AM[row_index,]))
      if (output_roster$halfday[row_name]) {
        output_roster[row_name,mo_name] <- "OFF"
      } else {
        output_roster[row_name,mo_name] <- "AL"  
      }
    }}
    
    if (length(mo_leave_PM)>1){ for (k in 1:length(mo_leave_PM)){
      leave_day <- mo_leave_PM[k]
      if (any(unlist(as.Date(output_roster_PM$date)) == leave_day)){
        row_index <- which(unlist(as.Date(output_roster_PM$date)) == leave_day)
        row_name <- as.numeric(rownames(output_roster_PM[row_index,]))
        if (!output_roster$halfday[row_name]) {
          output_roster[row_name,mo_name] <- "AL"
        }
      }
    }}
  }
  return(output_roster)
}

# This function convert precalls and postcalls into work request
call_wr_monster <- function (input_part_1_output, input_mos_request, rounding_precall = TRUE, rounding_postcall = TRUE){
  
  output_roster_with_call <- input_part_1_output
  output_mo_request <- input_mos_request
  
  if (rounding_precall == TRUE) {
    halfday_list <- output_roster_with_call[output_roster_with_call$halfday == TRUE, ]
    
    for (i in 1:nrow(halfday_list)){
      i_line <- halfday_list[i,]
      i_mo <- i_line$oncall
      if (is.na(i_mo)) {next} # Skip if nobody is oncall
      i_date <- as.Date(i_line$date)
      i_mo_index <- which(output_mo_request$name == i_mo)
      output_line <- output_mo_request[i_mo_index, ]
      output_mo_request[i_mo_index, ]$workrequest[[1]] <- as.Date(sort(unique(na.omit(unlist(c(output_line$workrequest, i_date))))))
    }
  }
  
  if (rounding_postcall == TRUE) {
    halfday_list <- output_roster_with_call[output_roster_with_call$halfday == TRUE, ]
    
    for (i in 1:nrow(halfday_list)){
      i_line <- halfday_list[i,]
      i_date <- as.Date(i_line$date)
      prev_day_date <- i_date - 1
      prev_day_line <- output_roster_with_call[as.Date(output_roster_with_call$date) == prev_day_date, ]
      prev_day_oncall <- prev_day_line$oncall # This essentially identify who is post-call
      if (is.na(prev_day_oncall)) {next} # Skip if nobody is postcall
      prev_day_mo_index <- which(output_mo_request$name == prev_day_oncall)
      prev_day_output_line <- output_mo_request[prev_day_mo_index, ]
      output_mo_request[prev_day_mo_index, ]$workrequest[[1]] <- as.Date(sort(unique(na.omit(unlist(c(prev_day_output_line$workrequest, i_date)))))) # Use i_date instead of prev_day_date cause you are looking for postcall date
    }
  }
  
  return(output_mo_request)
}

# Convert roster into weeks indexes, ie to split up the roster into weeks by their indexes
# This function would be incorporated in roster_na_count and team_monster below
week_monster <- function(input_roster){
  # This approach assume Sunday is always halfday, kind of true
  sun_index <- which(input_roster$day == "Sunday")
  output_index_list <- list()
  for (i in 1:(length(sun_index)+1)) {
    if (i == 1){
      output_index <- list(i,sun_index[i])
    } else if (i > 1 && i < (length(sun_index)+1)){
      output_index <- list((sun_index[i-1]+1),sun_index[i])
    } else if (i == (length(sun_index)+1) && sun_index[i-1] == length(input_roster$day)){
      # This is if the roster ending on Sundays
      next
    } else if (i == (length(sun_index)+1)){
      output_index <- list((sun_index[i-1]+1),length(input_roster$day))
    } 
    output_index_list[[i]] <- unlist(output_index)
  }
  return(output_index_list)
}

# Tell TRUE or FALSE, whether input_i is between the particular input week
# The input_week is subset generated from week_monster above
# This function is to complement week_monster usage
is_btw <- function(input_i, input_week) {
  lower_range <- input_week[1]
  upper_range <- input_week[2]
  return(input_i >= lower_range & input_i <= upper_range)
}

# Tell week number of a particular input_i based on week_monster output
# This function is to complement week_monster usage
is_week <- function (input_i, input_week_indexes){
  for (i in 1:length(input_week_indexes)) {
    if (is_btw(input_i, input_week_indexes[[i]])){break}
  }
  return (i)
}

# Calculate number of na (ie not on leave / postcall etc) of each MO during each week
# This tells us they can be assigned to certain team duties
# This function incorporate week_monster above
# This function would be incorporated in team_monster below
roster_na_count <- function (input_roster,input_mos_list){
  week_list <- week_monster(input_roster)
  
  na_count_df <- data.frame(names = character(length(input_mos_list)), stringsAsFactors = FALSE)
  na_count_df$names <- input_mos_list
  
  for (week_no in 1:length(week_list)){
    na_count_list <- list()
    for (mo_no in 1:length(input_mos_list)){
      na_count_list <- unlist(c(na_count_list,sum(is.na(input_roster[[input_mos_list[mo_no]]][week_list[[week_no]][1]:week_list[[week_no]][2]]))))
    }
    na_count_df[paste0("week",week_no)] <- na_count_list
  }
  
  return(na_count_df)
}

# This function attach series of column T1 T2 T3 TMX RUN and calculate how many assigned respective duties
roster_duty_count <- function(input_roster){
  output_roster <- input_roster
  
  output_roster$T1 <- as.numeric(NA)
  output_roster$T2 <- as.numeric(NA)
  output_roster$T3 <- as.numeric(NA)
  output_roster$TMX <- as.numeric(NA)
  output_roster$RUN <- as.numeric(NA)
  
  for (i in 1:nrow(output_roster)){
    output_roster[i,]$T1 <- sum(grepl("T1",output_roster[i,]))
    output_roster[i,]$T2 <- sum(grepl("T2",output_roster[i,]))
    output_roster[i,]$T3 <- sum(grepl("T3",output_roster[i,]))
    output_roster[i,]$TMX <- sum(grepl("TMX",output_roster[i,]))
    output_roster[i,]$RUN <- sum(grepl("RUN",output_roster[i,]))
  }
  output_roster$date <- as.Date(output_roster$date)
  return(output_roster)
}

# This read a line of a roster, and generate the MOs who are currently NA
line_na_mos <- function (input_line){
  na_mos <- unlist(colnames(input_line)[is.na(input_line)])
  return(na_mos)
}

# This function takes in processed roster with AL OFF SDA PC etc assigned
# It randomly allocates MOs into T1 T2 T3 duties
# This function incorporate week_monster and roster_na_count above
team_monster <- function(input_roster, mos_list, priotitize_free_MO = TRUE){
  output_roster <- input_roster
  output_roster_na_count <- roster_na_count(output_roster,mos_list)
  week_indexes_list <- week_monster(output_roster)
  
  for (i in 1:(ncol(output_roster_na_count)-1)){
    
    # Calculate the indexes of mo with most na each week
    output_roster_na_count <- output_roster_na_count[order(-output_roster_na_count[[paste0("week",i)]]), ]
    
    # This prioritize free MO function would prioritize assigning function to 8 MOs with least NAs
    # Meaning 8 MOs there were on least AL PC SDA etc
    # Why 8? Cause I just want to kick out bottom 2 who are clearly clearing leaves / ALs
    if (priotitize_free_MO) {
      weekly_most_na <- unlist(as.numeric(rownames(output_roster_na_count[1:8,])))
    } else {
      weekly_most_na <- unlist(as.numeric(rownames(output_roster_na_count[1:length(mos_list),])))
    }
    
    # Randomize (shuffling) the mo indexes
    weekly_most_na <- sample(weekly_most_na)
    
    for (j in week_indexes_list[[i]][1]:week_indexes_list[[i]][2]){
      if (is.na(output_roster[mos_list[weekly_most_na[1]]][j,])){
        output_roster[mos_list[weekly_most_na[1]]][j,] <- "T1"
      }
      if (is.na(output_roster[mos_list[weekly_most_na[2]]][j,])){
        output_roster[mos_list[weekly_most_na[2]]][j,] <- "T1"
      }
      if (is.na(output_roster[mos_list[weekly_most_na[3]]][j,])){
        output_roster[mos_list[weekly_most_na[3]]][j,] <- "T2"
      }
      if (is.na(output_roster[mos_list[weekly_most_na[4]]][j,])){
        output_roster[mos_list[weekly_most_na[4]]][j,] <- "T2"
      }
      if (is.na(output_roster[mos_list[weekly_most_na[5]]][j,])){
        output_roster[mos_list[weekly_most_na[5]]][j,] <- "T3"
      }
      if (is.na(output_roster[mos_list[weekly_most_na[6]]][j,])){
        output_roster[mos_list[weekly_most_na[6]]][j,] <- "T3"
      }
    }
  }
  output_roster <- roster_duty_count(output_roster)
  return(output_roster)
}

# This function ensure weekday roster to have at least 2 MOs each team
weekday_team_monster <- function (input_roster){
  output_roster <- input_roster
  
  # Subfunction helping to craft the main function
  # Basically it filters na_mo without any adjacent duties
  # If there is totally no mo with adjacent duties, it gives back NA
  df_omit_na <- function(input_df){
    output_df <- Filter(function(x) !any(is.na(x)), input_df)
    if (ncol(output_df) == 0){
      output_df <- NA
    }
    return(output_df)
  }
  
  # This subfunction is supposed to read through each input line
  # It reads how many mo manning input team
  # If the manpower is <2, then it would try to fill the vacancy with mo doing same duties over adjacent slots
  # The problem is, this function may seem to be doing nothing if there's no adjacent MO, which is fine
  # I have included some print function to help with future debugging
  fill_with_adjacent_duty <- function(input_line,input_team, debugging_mode = FALSE){
    output_line <- input_line
    output_team <- input_team
    
    team_count <- output_line[output_team]
    
    if (team_count<2){ # This filters out lines with sufficient manpower
      if (debugging_mode) {print("mo count <2, yeah your function is working well bro, don't worry")}
      na_mo_list <- line_na_mos(output_line)
      
      # This part generate adjacent_mo_duty which is a df that would contain na_mo with their adjacent duties
      if (i == 1){
        next_line <- output_roster[(i+1),]
        next_na_mo_duty <- next_line[na_mo_list]
        adjacent_mo_duty <- next_na_mo_duty
        adjacent_mo_duty <- df_omit_na(adjacent_mo_duty)
      } else if (i>1 && i<nrow(output_roster)) {
        prev_line <- output_roster[(i-1),]
        prev_na_mo_duty <- prev_line[na_mo_list]
        next_line <- output_roster[(i+1),]
        next_na_mo_duty <- next_line[na_mo_list]
        adjacent_mo_duty <- cbind(prev_na_mo_duty,next_na_mo_duty)
        adjacent_mo_duty <- df_omit_na(adjacent_mo_duty)
      } else if (i == nrow(output_roster)) {
        prev_line <- output_roster[(i-1),]
        prev_na_mo_duty <- prev_line[na_mo_list]
        adjacent_mo_duty <- prev_na_mo_duty
        adjacent_mo_duty <- df_omit_na(adjacent_mo_duty)
      }
      
      # This identify na_mo with adjacent duties
      # Essentially prioritizing filling up NA doing similar duties over recent period
      mo_with_adjacent_duties <- colnames(adjacent_mo_duty[grepl(output_team,adjacent_mo_duty)])
      
      # If there is na_mo with adjacent duties, fill them up respective role first
      # If there is none, PURPOSELY DO NOTHING
      # This is because we want to prioritize filling vacancies with MO doing similar duties over adjacent slots
      if (length(mo_with_adjacent_duties)>0){
        output_line[sample(mo_with_adjacent_duties,1)] <- output_team
        if (debugging_mode) {print("wow amazing you detected mo with adjacent duties, good job yeah")}
      } else if (debugging_mode) {print("yeah i know you worried but no adjacent mo detected")}
      output_line <- roster_duty_count(output_line)
    }
    return (output_line)
  }
  
  # This part is not elegant at all
  # I repeated this function for each team 2 times intentionally
  # In ideal scenario, even if the team count is 0, you can potentially fill up to 2 mo with adjacent duties
  # It may not be doing anything, which is fine too, but if there is MO with adjacent duties, it should prioritize pulling them in
  bruteforce_FWAD <- function(input_line, debugging_mode = FALSE){
    output_line <- input_line
    output_line <- fill_with_adjacent_duty(output_line, "T1", debugging_mode)
    output_line <- fill_with_adjacent_duty(output_line, "T2", debugging_mode)
    output_line <- fill_with_adjacent_duty(output_line, "T3", debugging_mode)
    output_line <- fill_with_adjacent_duty(output_line, "T1", debugging_mode)
    output_line <- fill_with_adjacent_duty(output_line, "T2", debugging_mode)
    output_line <- fill_with_adjacent_duty(output_line, "T3", debugging_mode)
    return (output_line)
  }
  
  # This function as the name suggest, fill up the line with team count 0 or 1
  # It simply fills with na mo randomly
  fill_with_na_mo <- function(input_line,input_team){
    
    output_line <- input_line
    output_team <- input_team
    team_count <- output_line[output_team]
    
    if (team_count == 1) { 
      # Essentially, if there is any team count 1, just fill up randomly with na_mo is ok
      # This step is expected to come after bruteforcing the line with mo with adjacent duties
      # Meaning there is no more room for further optimization
      # Just fill up the team count to 2
      na_mo_list <- line_na_mos(output_line)
      output_line[sample(na_mo_list,1)] <- output_team
    } else if (team_count == 0) {
      # However if there is team count 0, it's quite tricky
      # Cause you think about it after filling up randomly once, would it mean that now for the same line, there's a change to adjacent mo list?
      # I think no - cause even after you pull one NA mo to certain team
      # Other NA mo would still be the same for this line - their adjacent duties won't change
      # Therefore I just same 2 MOs from na_mo list and fill them up that particular team
      na_mo_list <- line_na_mos(output_line)
      output_line[sample(na_mo_list,2)] <- output_team
    }
    output_line <- roster_duty_count(output_line)
    return (output_line)
  }
  
  # Going through each line of the entire roster
  for (i in 1:nrow(output_roster)){
    i_line <- output_roster[i,]
    if (i_line$halfday) {next}
    output_roster[i,] <- bruteforce_FWAD(output_roster[i,], debugging_mode = FALSE)
    output_roster[i,] <- fill_with_na_mo(output_roster[i,], "T1")
    output_roster[i,] <- fill_with_na_mo(output_roster[i,], "T2")
    output_roster[i,] <- fill_with_na_mo(output_roster[i,], "T3")
    
  }
  output_roster <- roster_duty_count(output_roster)
  return(output_roster)
}

# Assigning TMX MO
tmx_monster <- function(input_roster){
  output_roster <- input_roster
  for (i in 1:nrow(output_roster)) {
    i_line <- output_roster[i,]
    tmx_count <- sum(grepl("TMX",i_line))
    if (i_line$AMPM == "PM" && tmx_count<1){
      pm_na_mo <- line_na_mos(i_line)
      if (length(pm_na_mo)<1) {
        warning(paste(output_roster[i,]$date,"has not enough MO to run TMX"))
      } else {
        tmx_mo <- sample(pm_na_mo,1)
        output_roster[i,][tmx_mo] <- "TMX"
        output_roster[(i-1),][tmx_mo] <- "RUN"
      }
    }
  }
  output_roster <- roster_duty_count(output_roster)
  return(output_roster)
  }

# Assigning runner to remaining weekday MOs with no duties
run_monster <- function(input_roster){
  output_roster <- input_roster
  
  for (i in 1:nrow(output_roster)){
    i_line <- output_roster[i,]
    if (i_line$halfday) {next}
    na_mo_list <- line_na_mos(i_line)
    if (length(na_mo_list)>0) {
      i_line[na_mo_list] <- "RUN"
    }
    i_line <- roster_duty_count(i_line)
    output_roster[i,] <- i_line
  }
  return (output_roster)
}

# This function trims away weekend excess duties
# It ensures only those with workrequest remained working
# For those who requested OFF, it keeps as OFF
# For those without request, it lists as NA 
trim_non_wr_wknd <- function(input_roster,input_mo_request,input_mos_list){
  
  output_roster <- input_roster
  output_request <- input_mo_request
  output_mos_list <- input_mos_list
  
  for (i in 1:nrow(output_roster)) {
    i_line <- output_roster[i,]
    if (i_line$halfday == FALSE) {next} # Filter out non-weekend
    i_date <- i_line$date
    rows_with_date <- sapply(output_request$workrequest, function(dates) i_date %in% dates)
    mos_with_request <- unlist(output_request$name[rows_with_date])
    mos_wo_request <- setdiff(output_mos_list, mos_with_request)
    for (j in mos_wo_request){
      if (is.na(grepl(i_line[j],"OFF"))) {next} # This filter out MOs without request but already has NA as their duties
      if (any(grepl(i_line[j],"OFF"))) {next} # This filter out MOs without request but reqeusted OFF
      i_line[j] <- NA
    }
    for (k in mos_with_request){
      if (any(is.na(i_line[k]))) { # This selects those with work request but still listed as NA
        i_line[k] <- "WR"
      }
    }
    i_line <- roster_duty_count(i_line)
    output_roster[i,] <- i_line
  }
  
  return(output_roster)
}

#Trim weekend team with 2 manpower, assign 1 of them as RUN
wknd_trim_dup_team <- function(input_roster){
  output_roster <- input_roster
  
  # SUBFUNCTION: Trim weekend team with 2 manpower, assign 1 as MO
  subfn_trim_dup_team <- function(input_line, input_team, debug_mode = FALSE){
    output_line <- input_line
    output_team <- input_team
    team_count <- output_line[output_team]
    if (team_count == 2){
      mo_w_duplicates_duties <- colnames(output_line[grepl(output_team,output_line)]) # identify mo with dup duties
      mo_assigned_as_run <- sample(mo_w_duplicates_duties,1) # select one of the mo as runner
      output_line[mo_assigned_as_run] <- "RUN"
    } else if (debug_mode) {print("no duplicates detected")}
    output_line <- roster_duty_count(output_line)
    return (output_line)
  }
  
  for (i in 1:nrow(output_roster)) {
    i_line <- output_roster[i,]
    if (i_line$halfday == FALSE) {next} # Filter out non-weekend
    output_roster[i,] <- subfn_trim_dup_team(output_roster[i,], "T1")
    output_roster[i,] <- subfn_trim_dup_team(output_roster[i,], "T2")
    output_roster[i,] <- subfn_trim_dup_team(output_roster[i,], "T3")
  }
  
  return(output_roster)
}

# This function takes in roster and assign weekend WR mo to duties they have done before
assign_wr_monster <- function(input_roster){
  output_roster <- input_roster
  week_indexes <- week_monster(output_roster)
  
  for (i in 1:nrow(output_roster)) {
    i_line <- output_roster[i,]
    if (i_line$halfday == FALSE) {next} # Filter out non-weekend
    if (!any(grepl("WR",i_line))) {next} # Filter out line without non-assigned WR

    mo_unassigned_wr <- colnames(i_line[grepl("WR",i_line)])
    mo_unassigned_wr <- sample(mo_unassigned_wr)

    for (j in mo_unassigned_wr){
      week_no <- unlist(week_indexes[is_week(i, week_indexes)])
      subroster <- output_roster[week_no[1]:week_no[2],] # This generates the extracted subroster of the week of interest
      mo_subroster <- subroster[j] # This generates the extracted column of a particular unassigned MO from the extracted subroster
      mo_subtally <- tally_subroster(mo_subroster) # This generates the duty tally of the particular MO for the week (from extracted subroster)

      team_to_fill <- c("MO")
      if (i_line$T1 == 0){team_to_fill <- c(team_to_fill, "T1")}
      if (i_line$T2 == 0){team_to_fill <- c(team_to_fill, "T2")}
      if (i_line$T3 == 0){team_to_fill <- c(team_to_fill, "T3")}
      
      if (length(team_to_fill)>1) { # Basically if all teams already filled up, just assign the person as runner, by allocating max_duty_count as 0
        mo_subtally <- mo_subtally[,(names(mo_subtally) %in% team_to_fill)] # This isolates out subtally with only team to fill
        max_duty_count <- max(mo_subtally[,2:ncol(mo_subtally)]) # This helps to calculate the high duty count within the tally
      } else {
        max_duty_count <- 0
      }
      
      if (max_duty_count>0){ # This filter helps to filter situation where the MO has totally not assigned to the team throughout the week
        team_with_highest_count <- colnames(mo_subtally[(mo_subtally==max_duty_count)[1,]]) # It prioritizes assigning MO with duties they did throughout the week
        i_line[j] <- sample(team_with_highest_count,1)
        i_line <- roster_duty_count(i_line)
        output_roster[i,] <- i_line
      } else {
        i_line[j] <- "RUN" # If the MO must round but hasn't done any duty of the week
        i_line <- roster_duty_count(i_line)
        output_roster[i,] <- i_line
      }
    }
  }
  return(output_roster)
}

# This function calculate the number of each MO duties within a subroster
# The roster need to have only a single column with the MO name
tally_subroster <- function(input_mo_subroster){
  output_mo_subroster <- input_mo_subroster
  MO <- colnames(output_mo_subroster)
  T1 <- sum(grepl("T1",unlist(output_mo_subroster)))
  T2 <- sum(grepl("T2",unlist(output_mo_subroster)))
  T3 <- sum(grepl("T3",unlist(output_mo_subroster)))
  TMX <- sum(grepl("TMX",unlist(output_mo_subroster)))
  RUN <- sum(grepl("RUN",unlist(output_mo_subroster)))
  OFF <- sum(grepl("OFF",unlist(output_mo_subroster)))
  output_tally <- data.frame(MO,T1,T2,T3,TMX,RUN,OFF)
  return(output_tally)
}

# This function calculate the number of duties for input mo list within an input roster
roster_tally <- function(input_roster, input_mo_list){
  output_roster <- input_roster
  output_mo_list <- input_mo_list
  output_tally <- data.frame()
  for (i in 1:length(output_mo_list)){
    mo <- output_mo_list[i]
    i_line <- tally_subroster(output_roster[mo])
    output_tally <- rbind(output_tally,i_line)
  }
  return(output_tally)
}

# This function is used in some other functions below for generation of weekend duties
# It produces the tally of potential MO for their respective duties during the week
# It requires the latest weekend tally and min weekend
# This is because it eliminates MO who have reached max duty allocation
potential_mo_tally <- function(input_i, input_roster, input_mos_list){
  
  output_roster <- input_roster
  wknd_roster <- output_roster[output_roster$halfday,]
  wknd_tally <- roster_tally(wknd_roster,input_mos_list)
  min_wknd <- ceiling((nrow(wknd_roster) * 4)/length(input_mos_list)) # The 4 is minimal manpower for each day: 1 for each team + 1 runner
  
  i_line <- output_roster[input_i,]
  
  week_indexes <- week_monster(output_roster)
  week_no <- is_week(input_i, week_indexes)
  week_no_index <- unlist(week_indexes[week_no])
  subroster <- output_roster[week_no_index[1]:week_no_index[2],] # This generates the extracted subroster of the week of interest
  mo_tally <- data.frame()
  
  potential_mo <- names(i_line)[which(is.na(i_line))] # Basically it reads MOs with NA as potential MO
  
  for (j in potential_mo) {
    # Filter out MO already reaching max allocation for weekends
    j_tally <- wknd_tally[wknd_tally[,1]==j,] # Identifying mo from wknd_tally, extract particular row
    j_total_wknd <- sum(j_tally$T1,j_tally$T2,j_tally$T3,j_tally$RUN) # Calculate totally allocated duties from the tally row
    if (j_total_wknd >= min_wknd) {
      potential_mo <- potential_mo[potential_mo!=j] # Exclude those MO already max out of duty allocation
      next
    }
    
    # For potential MO with room for allocation, see their workload throughout the week
    mo_subroster <- subroster[j] # This generates the extracted column of a particular unassigned MO from the extracted subroster
    mo_subtally <- tally_subroster(mo_subroster) # This generates the duty tally of the particular MO for the week (from extracted subroster)
    mo_tally <- rbind(mo_tally,mo_subtally)
  }
  
  return(mo_tally)
}

# This function produce a tally of weekend potential MO and their respective max duty count
# High max duty count means someone inside that roster someone who covered same team a lot during the week could be assigned
max_pomo_tally <- function(input_roster, input_mos_list){
  output_roster <- input_roster
  output_mos_list <- input_mos_list
  output_tally <- data.frame()

  for (i in 1:nrow(output_roster)) {
    i_line <- output_roster[i,]
    if (i_line$halfday == FALSE) {next} # Filter out non-weekend
    if (i_line$T1 == 1 && i_line$T2 == 1 && i_line$T3 == 1) {next} # Filter out weekend with team 1/2/3 already filled
    if (any(is.na(i_line))==FALSE) {next} # Filter out weekend without MO with NA, technically this is redundant
    
    mo_tally <- potential_mo_tally(i,output_roster,output_mos_list)
    
    suppressWarnings({ # Technical warning can be generated when there is insufficient manpower to allocate for all teams on all weekends for certain iteration
    if (i_line$T1 == 0) {output_tally <- rbind(output_tally,c(i,"T1",max(mo_tally$T1)))}
    if (i_line$T2 == 0) {output_tally <- rbind(output_tally,c(i,"T2",max(mo_tally$T2)))}
    if (i_line$T3 == 0) {output_tally <- rbind(output_tally,c(i,"T3",max(mo_tally$T3)))}
    })
  }
  
  suppressWarnings({ # Technical warning can be generated when there is insufficient manpower to allocate for all teams on all weekends for certain iteration
  colnames(output_tally) <- c("i_no","team","max_duty_count")
  output_tally$i_no <- as.integer(output_tally$i_no)
  output_tally$max_duty_count <- as.integer(output_tally$max_duty_count)
  })
  
  return(output_tally)
}

# This function fills one of the weekend vacancies with a MO with highest duty count that month
wknd_fill_maxdc <- function(input_roster, input_mos_list){
  output_roster <- input_roster
  
  max_dc_tally <- max_pomo_tally(output_roster,input_mos_list) # This tallies max duty count for each weekend vacancy
  
  # Subfunction: To do the processing proper of this function
  # This is needed as the output of max_pomo_tally can at times containing NA
  # The subfunction allow us to easily exclude out the NA row
  subfn_wknd_fill_maxdc <- function(max_dc_tally){
    max_i <- max_dc_tally[(max_dc_tally[,3] == max(max_dc_tally[,3])),] # This extract the weekend vacancies with highest duty count
    max_i <- max_i[sample(1:nrow(max_i),1),] # This sample one of the highest duty count vacancy, in case there's more than 1
    pomo_i <- potential_mo_tally(max_i$i_no,output_roster,input_mos_list) # Generate the tally duties for potential mo
    
    target_i <- max_i$i_no
    target_team <- max_i$team
    target_dc <- max_i$max_duty_count
    target_mo <- sample(pomo_i$MO[pomo_i[target_team]==target_dc],1)
    
    output_roster[target_i,][target_mo] <- target_team # This writes the target team into the roster based on max duty count
    output_roster[target_i,] <- roster_duty_count(output_roster[target_i,])
    return(output_roster)
  }
  
  if (nrow(max_dc_tally)==1 && is.na(max_dc_tally$max_duty_count)){
    # THIS WAS ONCE VERY USEFUL FOR DEBUGGING, KEEP FOR HISTORICAL PURPOSES IN CASE FUTURE NEW BUG APPEAR
    # print("if (nrow(max_dc_tally)==1 && is.na(max_dc_tally$max_duty_count)){")
    # print(max_dc_tally)
    warning_i <- as.integer(max_dc_tally$i_no)
    warning_line <- output_roster[warning_i,]
    warning(paste("Not enough manpower to fill",max_dc_tally$team,"on",warning_line$date,"under current iteration"))
    return(TRUE) # return true for while loop to break
  } else if (nrow(max_dc_tally)>1 && any(is.na(max_dc_tally$max_duty_count))){
    # THIS WAS ONCE VERY USEFUL FOR DEBUGGING, KEEP FOR HISTORICAL PURPOSES IN CASE FUTURE NEW BUG APPEAR
    # print("} else if (nrow(max_dc_tally)>1 && any(is.na(max_dc_tally$max_duty_count))){")
    # print(max_dc_tally)
    na_rows <- max_dc_tally[is.na(max_dc_tally$max_duty_count), ] # Extract the row with NA
    warning_i <- as.integer(na_rows$i_no)
    warning_line <- output_roster[warning_i,]
    warning(paste("Not enough manpower to fill",na_rows$team,"on",warning_line$date,"under current iteration"))
    
    max_dc_tally <- max_dc_tally[!is.na(max_dc_tally$max_duty_count), ] # Remove the line with NA
    if (nrow(max_dc_tally)>0){ # If there is any remaining normal rows without NA
      output_roster <- subfn_wknd_fill_maxdc(max_dc_tally) # Continue on as per usual
      return(output_roster)
    } else { # This is needed in case there's multiple lines of NA but no normal row
      return(TRUE) # return true for while loop to break
    }
  } else {
    output_roster <- subfn_wknd_fill_maxdc(max_dc_tally) # Continue on as per usual
    return(output_roster)
  }
}

# This function would utilize the wknd_fill_maxdc function above
# It uses a while loop to fill up all weekend slots with at least 1 person manning each team
assign_wknd_monster <- function(input_roster,input_mos_list){
  output_roster <- input_roster
  i = 0
  
  # while loop to ensure all team filled up
  while (min(output_roster[output_roster$halfday,]$T1) == 0 || min(output_roster[output_roster$halfday,]$T2) == 0 || min(output_roster[output_roster$halfday,]$T3) == 0){
    temp_roster <- wknd_fill_maxdc(output_roster, input_mos_list)
    if (isTRUE(temp_roster)) {break}
    output_roster <- temp_roster
    
    i = i+1
    if (i == 100){
      warning(paste("assign_wknd_monster unable to break while loop after 100 iteration"))
      break
    }
  }
  return (output_roster)
}

# This function fill up all weekends with 1 runner as much as possible
assign_wknd_runner <- function(input_roster, input_mos_list){
  output_roster <- input_roster
  min_wknd <- ceiling((nrow(output_roster[output_roster$halfday,]) * 4)/length(input_mos_list)) # The 4 is minimal manpower for each day: 1 for each team + 1 runner
  
  for (i in sample(1:nrow(output_roster))) {
    i_line <- output_roster[i,]
    if (i_line$halfday == FALSE) {next} # Filter out non-weekend
    if (i_line$RUN > 0) {next} # Filter out weekend with RUN already filled
    
    wknd_roster <- output_roster[output_roster$halfday,]
    wknd_tally <- roster_tally(wknd_roster,input_mos_list)
    
    potential_mo <- colnames(i_line[,is.na(i_line)]) # Basically it reads MOs with NA as potential MO
    for (j in potential_mo) {
      # Filter out MO already reaching max allocation for weekends
      j_tally <- wknd_tally[wknd_tally[,1]==j,] # Identifying mo from wknd_tally, extract particular row
      j_total_wknd <- sum(j_tally$T1,j_tally$T2,j_tally$T3,j_tally$RUN) # Calculate totally allocated duties from the tally row
      if (j_total_wknd >= min_wknd) {
        potential_mo <- potential_mo[potential_mo!=j] # Exclude those MO already max out of duty allocation
        next
      }
    }
    
    # Mathematically there is a chance that there is not enough mo to be runner
    if (length(potential_mo)<1){
      warning(paste("Not enough manpower for",i_line$date,"to allocate as runner"))
      next
    }
    
    # If there is sufficient potential MO, then allocate one of them as runner
    slcted_mo <- sample(potential_mo,1)
    i_line[slcted_mo] <- "RUN"
    output_roster[i,] <- roster_duty_count(i_line)
    
  }
  return(output_roster)
}

# This function is optional, meaning it aim to equalize weekend distribution
# It calculate the total number of weekends and calculate a minimum for all to be equal
equalize_wknd_duties <- function(input_roster,input_mos_list){
  output_roster <- input_roster
  min_wknd <- ceiling((nrow(output_roster[output_roster$halfday,]) * 4)/length(input_mos_list)) # The 4 is minimal manpower for each day: 1 for each team + 1 runner
  ttl_wknd <- nrow(output_roster[output_roster$halfday,])
  max_off <- (ttl_wknd-min_wknd)
  
  while (any(is.na(output_roster))) { # This ensure filling
    
    # Calculate the latest weekend tally after there's change in output roster
    wknd_roster <- output_roster[output_roster$halfday,]
    na_rows <- apply(wknd_roster, 1, function(x) any(is.na(x))) #Extract out row with NA
    wknd_roster_na <- wknd_roster[na_rows, ] #Extract out row with NA
    wknd_roster_for_i <- wknd_roster_na[sample(nrow(wknd_roster_na)),] #randomize the na roster for now
    wknd_roster_for_i <- wknd_roster_for_i[order(wknd_roster_for_i$RUN),] # now sort it by number of runner, lesser one first
    i_for_loop <- as.integer(rownames(wknd_roster_for_i[1,])) # Now extract the i number with the randomized lowest runner among lines with NA
    i <- i_for_loop
    
    wknd_tally <- roster_tally(wknd_roster,input_mos_list)
    i_line <- output_roster[i,]
    pre_run_count <- as.integer(i_line$RUN) # This helps to tell if later runner needed to be increased
    
    #This part isolate the na_mo
    na_mo <- names(i_line)[which(is.na(i_line))] # Basically it reads MOs with NA from i_line
    
    for (j in na_mo) {
      # Assign MO already reaching max allocation for weekends as OFF
      j_tally <- wknd_tally[wknd_tally[,1]==j,] # Identifying mo from wknd_tally, extract particular row
      j_total_wknd <- sum(j_tally$T1, j_tally$T2, j_tally$T3, j_tally$RUN) # Calculate totally allocated duties from the tally row
      
      if (j_total_wknd >= min_wknd) { # If mo reach max weekend just assign OFF
        i_line[j] <- "OFF"
        na_mo <- na_mo[na_mo!=j] # Exclude those MO already max out of duty allocation
      } else if (j_tally$OFF >= max_off) { # If mo reach max OFF and not assigned anything else, just assign run
        i_line[j] <- "RUN"
        i_line <- roster_duty_count(i_line)
        na_mo <- na_mo[na_mo!=j] # Exclude those MO after done with assigning them as runner
      }
    }
    
    post_run_count <- as.integer(i_line$RUN) # This helps to tell if later runner needed to be increased
    
    if (length(na_mo)>0 && post_run_count == pre_run_count){ #Meaning if there's still at least 1 NA MO, also no runner assigned yet, assign runner
      random_mo <- sample(na_mo,1)
      i_line[random_mo] <- "RUN"
      i_line <- roster_duty_count(i_line)
      output_roster[i,] <- i_line
    } else { #Meaning if there's no more NA, just save and go next line
      i_line <- roster_duty_count(i_line)
      output_roster[i,] <- i_line
    }
  }
  
  return(output_roster)
}

# Calculate week_mo_index of a particular roster
# week_mo_index is something I invented from thin air
# Basically it calculate how many MOs on average manning each team per week
# This is important because you don't want the MO to keep changing over the course of 1 week
# Theoretically, you can have minimal value of 2, lower meaning less changing over of MO
# Maximally you can have up to 12 (however only 10 MOs in our dept so max is 10)
final_roster_stat <- function(input_roster, input_mos_list){
  output_roster <- input_roster
  
  # Calculating week_mo_AMOC
  week_AMOC <- week_monster(output_roster)
  week_mo_count <- list()
  for (i in 1:length(week_AMOC)) {
    week_roster <- output_roster[week_AMOC[[i]][1]:week_AMOC[[i]][2],]
    week_tally <- roster_tally(week_roster,input_mos_list)
    week_mo_count <- unlist(c(week_mo_count, sum(week_tally$T1 != 0),sum(week_tally$T2 != 0),sum(week_tally$T3 != 0)))
  }
  week_mo_AMOC <- mean(week_mo_count)
  week_mo_AMOC <- round(week_mo_AMOC,2)
  
  # Calculating mean SD for each team coverage
  total_tally <- roster_tally(output_roster,input_mos_list)
  sd_list <- c(sd(total_tally$T1), sd(total_tally$T2), sd(total_tally$T3), sd(total_tally$TMX)) # Runner purposely excluded as people with more leave will contribute to difference
  mean_sd <- mean(sd_list)
  mean_sd <- round(mean_sd,2)
  
  output <- c(as.numeric(week_mo_AMOC),as.numeric(mean_sd))
  return(output)
}
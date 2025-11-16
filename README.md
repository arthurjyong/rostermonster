# Project Roster Monster

Roster Monster is an open-source R framework for generating and evaluating junior-doctor rosters under complex, department-specific constraints. It is designed as a clinician-configurable decision-support tool rather than a black-box optimiser.

The framework uses Monte Carlo sampling to generate large numbers of feasible rosters that satisfy local rules for coverage, rest periods, requests and training needs. Each roster is then evaluated using simple, clinically meaningful metrics:

- **Workload fairness:** standard deviation (SD) of call-burden points and duty counts.
- **Continuity of care:** Average MO Count (AMOC), a department-defined metric that reflects how often junior doctors change teams from week to week.

Users can review the distributions of these metrics and select rosters that best balance fairness and continuity of care for their local setting.

---

## Repository contents

- `monster.R`  
  Core script for generating night-call rosters using Monte Carlo sampling, subject to leave, request and post-call rules.

- `monster_2.R`  
  Script for generating complete daytime duty rosters (teams, clinics, weekends) given a selected night-call roster.

- `toolkit.R`  
  Helper functions used by the main scripts, including data loading, tallying duties and calculating metrics.

- `input.xlsx`  
  Example Excel input file. Contains the expected sheet structure for MO names, dates, requests, public holidays, previous call points and trainee flags (with names anonymised).

- `figures/`  
  Example plots and/or scripts used to produce figures for the accompanying manuscript.

---

## Basic usage

1. **Prepare your input file**

   - Open `input.xlsx` and replace the example data with your department’s:
     - MO list and rotation period
     - Leave, call / no-call and weekend preferences
     - Public holidays
     - Optional: previous call points and trainee flags

2. **Generate night-call rosters**

   - In R, source the toolkit and Part I script:

     ```r
     source("toolkit.R")
     source("monster.R")
     ```

   - Run the night-call generation function (see comments inside `monster.R` for arguments and options).
   - The script will generate a large set of feasible night-call rosters and can output summary files, such as shortlisted rosters with low SD of call points.

3. **Generate full day-duty rosters**

   - Choose a shortlisted night-call roster.
   - Source the second script:

     ```r
     source("monster_2.R")
     ```

   - Run the full-roster generation function to create complete day-duty rosters (teams, clinics, weekends) and calculate SD and AMOC for each roster.

4. **Review and select a roster**

   - Use the output tables and histograms to inspect:
     - SD of call points (night calls)
     - SD of duty counts (day duties)
     - AMOC (continuity of care)
   - Select one or more rosters that provide an acceptable balance between fairness, continuity and any other local priorities.

---

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.

## Citation

This repository accompanies a manuscript describing the Roster Monster framework and its application in a tertiary cardiology department. Citation details will be added here once the article is published.

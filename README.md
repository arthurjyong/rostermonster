# Project Roster Monster
An open source R-based algorithm for SKH CVM MO rostering using Monte Carlo simulation. This is an ongoing draft.

## Abstract

## Introduction

Rostering medical officers (MOs) is a crucial yet laborious task within clinical departments at public hospitals. Often, one or two MOs are assigned the unenviable title of "roster monsters," responsible for this duty. These "roster monsters" must orchestrate everyone's on-call schedules and team assignments. Unfortunately, crafting a roster that accommodates all requests is an immensely time-consuming endeavor. Moreover, not all "roster monsters" equitably distribute the workload [[1]](https://web.archive.org/web/20090304002820/https://practicality.wordpress.com/2009/02/28/the-roster-monster/), inevitably impacting the morale and psychological well-being of everyone involved.

The common challenges associated with rostering can be categorized into two main groups: MO requests and departmental requests. MO requests encompass leave requests, on-call requests, block-call preferences, and weekend-duty preferences. Conversely, departments often seek minimal changes in MO teams to ensure continuity of care, distribute the workload evenly among MOs, and prioritize certain duties for trainees over non-trainees. Furthermore, additional implicit requests may emerge from these constraints, such as avoiding on-call duty before scheduled leave, allowing on-call duty after a half-day morning leave, managing staffing for post-call vacancies, assigning weekend duties to MOs before and after on-call shifts on weekends, and achieving a balanced weekend duty allocation. These factors introduce further complexities to the rostering process, diverting the time and energy of "roster monsters" away from clinical work.

At its core, rostering is a mathematical challenge, often offering multiple possible solutions. Monte Carlo methods offer a means to identify the optimal solution from various possibilities simulated by a mathematical model. In the context of roster generation, an algorithm that considers various rostering constraints can be used to randomly generate multiple mathematically valid rosters for consideration before a final roster is determined.

In this project, we have developed an R-based algorithm that leverages Monte Carlo methods to generate and optimize on-call rosters and duty rosters for our department's MOs. We applied this algorithm to MOs' requests for February 2024, generating two million mathematically possible on-call rosters and 200,000 duty rosters based on the selected on-call rosters. Subsequently, we analyzed the generated rosters, identifying those that align with the department's clinical service needs. We have successfully demonstrated the feasibility of this approach for automated roster generation, showcasing its potential to significantly enhance departmental workflow and efficiency.

## Materials and methods

### Algorithm development

The computational algorithm for Project Roster Monster was developed in [R](https://www.r-project.org/), and its source code has been made available on GitHub under an open-source license. For the real-world feasibility evaluation of this approach, we used MO requests for the month of February 2024, which are included as a sample in the 'input.xlsx' file. To maintain confidentiality, the names of MOs have been redacted.

### Manpower distribution

The algorithm was customized to meet the manpower requirements of the Department of Cardiology at Sengkang General Hospital, Singapore. Within the department, ward duties are divided among three teams. Teams 1 and 2 are responsible for patients in general wards, while Team 3 handles patients in high dependency or coronary care units. On weekdays, each team comprises two MOs, while weekends and public holidays have one MO assigned to each team.

Additionally, a runner system is in place, where extra MOs function as 'runners' to provide assistance to the rounding teams. One of the runners is responsible for assisting with the afternoon exercise stress echocardiogram (TTE) clinic on weekdays. During weekends, there is always at least one runner available to assist with rounding duties. To fulfill the manpower needs for weekend rounds, each weekend or public holiday would need at least four MOs on rounding duties. There is no afternoon duties on weekends and public holidays.

Furthermore, there is a designated MO on-call, essentially covering overnight shifts. Post-call, the MO is required to run the same-day admission (SDA) clinic the following morning and take the afternoon off as 'post-call' on weekdays. In general, the department would receive ten MOs during each rotation cycle, with a maximum allowance of two MOs on leave at any given time.

Table 1: Summary of the SKH Department of Cardiology's manpower requirements, detailing the number of MOs assigned to general wards (T1 and T2) , high dependency units / coronary care units (T3), and clinics during weekdays, weekends, and public holidays.

![Table 1](/readme/table1.png)


## Results

### Design of algorithm

![Figure 1](/readme/figure1.png)
Figure 1: The schematic illustrates the two-part algorithm design for roster generation. Part I involves the creation of on-call rosters, and Part II consists of generating full duty rosters based on the shortlisted on-call rosters.

![Figure 2](/readme/figure2.png)
Figure 2: Screenshots of the Excel spreadsheet used for input data. (A) Sheet 1 lists MO names, roster dates, and their requests, (B) Sheet 2 marks public holidays, (C) Sheet 3 details cumulative call points for fairness in on-call duty allocation (optional), and (D) Sheet 4 identifies MOs under the training track (optional), all of which are considered by the algorithm in roster generation.

![Figure 3](/readme/figure3.png)
Figure 3: This schematic outlines the first part of the algorithm process, which randomly generates on-call rosters based on MO names, dates, and requests. The process can be repeated as many time as needed. In this study, we generated two millions different on-call rosters to ensure a broad range of coverage.

![Figure 4](/readme/figure4.png)
Figure 4: The second part of the algorithm design assigns team duties to the shortlisted on-call rosters while considering MO leave and weekend requests. The process can be repeated as many time as needed. In this study, we repeated the process 200,000 times to select the most equitable and practical final roster.


### Analysis of generated call rosters

![Figure 5](/readme/figure5.png)
Figure 5: (Top left) A representative screenshot from the generated on-call rosters. (Top right) A table illustrating the assignment of call points to each call, which can be adjusted based on departmental needs. (Bottom left) Calculation of total call points for each MO is done in every roster, with lower standard deviation (SD) values indicating a fairer distribution of call duties. Previous callpoint can be factored in for analysis as needed. (Bottom right) The histogram of SD values from the two million generated rosters is also presented.


### Analysis of generated full rosters

![Figure 6](/readme/figure6.png)
Figure 6: (A) A representative screenshot from one of the 200,000 full rosters generated by the algorithm. (B) The tally of MO duties from each roster facilitates further analysis, where standard deviation (SD) can be calculated for more equitable distribution of duties. This analysis can also be used to ensure compliance with departmental training requirements, such as mandating a minimum number of Team 3 (HD/ICU) duties for trainees. (C) The histogram of SD values from the 200,000 generated full rosters is presented.

![Figure 7](/readme/figure7.png)
Figure 7: (Left) The concept of Average MO Count (AMOC) is demonstrated, showing the number of MOs covering each team during a typical week. A lower AMOC value indicates reduced turnover, promoting continuity of care. (Right) The histogram of AMOC values from the 200,000 generated full rosters is presented.


## Discussion

Student projects on doctors' rostering

[example 1](https://web.archive.org/web/20240130131935/https://uvents.nus.edu.sg/event/20th-steps/module/IS4250/project/6)

[example 2](https://web.archive.org/web/20240130132101/https://uvents.nus.edu.sg/event/20th-steps/module/IS4250/project/10)

[example 3](https://web.archive.org/web/20240130132756/https://uvents.nus.edu.sg/event/18th-steps/module/IS4250/project/6)

## Conclusion

## References

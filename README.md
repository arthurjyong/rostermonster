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

Furthermore, there is a designated MO on-call, essentially covering overnight shifts. Post-call, the MO is required to run the same-day admission (SDA) clinic the following morning and take the afternoon off as 'post-call' on weekdays. In general, the department would receive ten MOs during each rotation cycle, with a maximum allowance of two MOs on leave at any given time. The manpower requirement is summarized into Table 1.

Table 1: Summary of the SKH Department of Cardiology's manpower requirements, detailing the number of MOs assigned to general wards (T1 and T2) , high dependency units / coronary care units (T3), and clinics during weekdays, weekends, and public holidays.

![Table 1](/readme/table1.png)


## Results

### Design of algorithm

The algorithm used in this study was specifically developed for this project and consists of two major parts. The first part is designed to generate call rosters, while the second part completes the full duty roster (Figure 1). Initially, the algorithm requires an input file in the form of a Microsoft Excel document to generate any specified number of on-call rosters for selection. Once a specific call roster is selected, it is fed into the second part of the algorithm to generate a complete duty roster.

![Figure 1](/readme/figure1.png)
_Figure 1: The schematic illustrates the two-part algorithm design for roster generation. Part I involves the creation of on-call rosters, and Part II consists of generating full duty rosters based on the shortlisted on-call rosters._

### Generation of on-call rosters

Within the input Excel document, users must provide MO names, the duration of rostering, and various requests from the MOs on the first sheet (Figure 2A). To enhance rostering accuracy, a list of public holidays can be added on the second sheet (Figure 2B). For a fairer distribution of call duties among MOs, cumulative call points can be included based on departmental needs (Figure 2C). Additionally, any MO under a specific training track can be noted on the fourth sheet (Figure 2D), as certain duties may be reserved for these trainees.

![Figure 2](/readme/figure2.png)
_Figure 2: Screenshots of the Excel spreadsheet used for input data. (A) Sheet 1 lists MO names, roster dates, and their requests, (B) Sheet 2 marks public holidays, (C) Sheet 3 details cumulative call points for fairness in on-call duty allocation (optional), and (D) Sheet 4 identifies MOs under the training track (optional), all of which are considered by the algorithm in roster generation._

The logical flow of the first part of the roster generation process is detailed in Figure 3. This part handles the MO requests and initial roster setup. Initially, the algorithm generates an empty roster using the MO names and input dates. It also incorporates the list of public holidays to ensure accurate scheduling. Next, the algorithm would go through each day and try to fulfill MO requests as completely as possible. The types of requests considered include various leaves (annual, medical, and training), call and no-call preferences, and preferences for working or not working on specific weekends. After addressing these requests, the algorithm reassesses each date. It randomly assigns MOs who are mathematically eligible, excluding those on leave or who have requested not to work weekends. The assignment process also factors in post-call conditions. MOs who were on call the previous night, and "post-post-call" conditions for MOs who were on call two nights earlier, are also excluded from consideration.

![Figure 3](/readme/figure3.png)
_Figure 3: This schematic outlines the first part of the algorithm process, which randomly generates on-call rosters based on MO names, dates, and requests. The process can be repeated as many time as needed. In this study, we generated two millions different on-call rosters to ensure a broad range of coverage._

In this study, we repeated the generation of call rosters two million times (Figure 4). For each call, we assigned specific call points to manage the distribution of duties. We categorized the calls into four groups: Monday-to-Thursday calls, Friday calls, Saturday calls, and Sunday calls. To accommodate variations such as public holidays, we established the conditions of these calls relative to ordinary working days and holidays/weekends (Figure 4, top right). This approach ensures that the algorithm's outputs can be generalized across different types of days, maintaining fairness and efficiency in duty allocation.

The adaptation of the call point system allowed us to numerically examine the call burden of each MO. By calculating the total call points of everyone, as well as the standard deviation of call points, we can infer the call burden and the fairness of duty distribution. Since our department routinely generates the roster by calendar month, while the total duration of each MO posting usually lasts three to six months, the algorithm can also optionally include cumulative call points (Figure 4, bottom left). This helps in factoring in the total call burden to date, leading to an even fairer distribution of workload across the entire posting duration.

Manually generating even a single on-call roster can be time-consuming. In contrast, the algorithm developed for this study can rapidly generate any mathematically possible roster. For example, running the algorithm on a 2018 entry-spec MacBook Pro takes less than one second to produce a call roster. While this demonstrates significant efficiency, the resulting rosters are often not ideal. For instance, some MOs might end up covering more call duties than others. This limitation, however, can be overcome by employing the Monte Carlo approach, which involves repeating the roster generation multiple times. By doing so, we can select the most suitable roster from a broader range of generated options. With the two million call rosters generated for this study, the standard deviation of call points can be calculated for each roster and plotted on a histogram (Figure 4, bottom right). Generally, we favor rosters on the leftmost tail-end, with a low standard deviation suggesting a fairer distribution of duties. Again, cumulative call points can be optionally included for the selection of the call roster.

![Figure 4](/readme/figure5.png)
_Figure 4: (Top left) A representative screenshot from the generated on-call rosters. (Top right) A table illustrating the assignment of call points to each call, which can be adjusted based on departmental needs. (Bottom left) Calculation of total call points for each MO is done in every roster, with lower standard deviation (SD) values indicating a fairer distribution of call duties. Previous callpoint can be factored in for analysis as needed. (Bottom right) The histogram of SD values from the two million generated rosters is also presented._

### Generation of full rosters

Once an on-call roster is selected from the numerous iterations, it can be fed into the second part of the algorithm for full roster generation. Based on the selected call rosters, we divide all ordinary working days into AM and PM duties, while holidays and weekends are limited to AM duties only. Post-call MOs are entitled to take PM duties off on weekdays and are automatically assigned to manage the same-day-admission (SDA) during post-call AMs on weekdays. These assignments are automatically processed once the on-call roster is integrated into the algorithm.

In our department, the rostering of clinical duties is based on calendar weeks. We initiate the rostering process by dividing the weeks into Monday-to-Sunday cycles (Figure 5). Following this, we randomly assign MOs to clinical teams according to the departmental manpower requirements, as previously detailed in Table 1. For weekend duties, we strive to equalize the duty burden across the manpower pool while aiming to accommodate as many weekend work or off requests from MOs as possible. Meanwhile, we prioritize weekend duties for MOs who are going on-call or post-call. Similar to the generation of the on-call roster, we can repeat the second part of the rostering process as many times as needed.

![Figure 5](/readme/figure4.png)
_Figure 5: The second part of the algorithm design assigns team duties to the shortlisted on-call rosters while considering MO leave and weekend requests. The process can be repeated as many time as needed. In this study, we repeated the process 200,000 times to select the most equitable and practical final roster._

In this study, we repeated the allocation of the full roster 200,000 times to cover a broad range of possibilities (Figure 6A). Each full roster was then tallied according to the duty types assigned to each MO (Figure 6B). This allowed us to calculate the standard deviation among the duty counts, where a lower standard deviation indirectly signifies a fairer distribution of workload types among the MOs. We also plotted the standard deviations calculated from all 200,000 rosters into a histogram; similar to previous analyses, we favored the leftmost tail-end, which signifies a fairer distribution (Figure 6C).

![Figure 6](/readme/figure6.png)
_Figure 6: (A) A representative screenshot from one of the 200,000 full rosters generated by the algorithm. (B) The tally of MO duties from each roster facilitates further analysis, where standard deviation (SD) can be calculated for more equitable distribution of duties. This analysis can also be used to ensure compliance with departmental training requirements, such as mandating a minimum number of Team 3 (HD/ICU) duties for trainees. (C) The histogram of SD values from the 200,000 generated full rosters is presented._

While ensuring a fair distribution of workload among the MOs is crucial, it may not always be the highest priority when planning the clinical roster. In our department, team members including registrars and consultants are rotated to specific teams on a weekly basis. Frequent changes of MOs, who are junior members in charge of execution, could be detrimental to continuity of care. While the calculation of standard deviation (SD) helps ensure a fairer workload, there is a need for another metric to reflect the frequency of manpower changes. We thus introduce a new metric named Average MO Count (AMOC) which accounts for the average number of MOs in a team (Figure 7, left). We calculated the AMOCs for all 200,000 rosters we generated and plotted the values in a histogram (Figure 7, right). We favored the leftmost tail-end, indicating lesser changeover of MO manpower through the weeks on average. We can then select a full roster from the 200,000 generated by choosing one with low AMOC and SD.

![Figure 7](/readme/figure7.png)
_Figure 7: (Left) The concept of Average MO Count (AMOC) is demonstrated, showing the number of MOs covering each team during a typical week. A lower AMOC value indicates reduced turnover, promoting continuity of care. (Right) The histogram of AMOC values from the 200,000 generated full rosters is presented._


## Discussion

Student projects on doctors' rostering

[example 1](https://web.archive.org/web/20240130131935/https://uvents.nus.edu.sg/event/20th-steps/module/IS4250/project/6)

[example 2](https://web.archive.org/web/20240130132101/https://uvents.nus.edu.sg/event/20th-steps/module/IS4250/project/10)

[example 3](https://web.archive.org/web/20240130132756/https://uvents.nus.edu.sg/event/18th-steps/module/IS4250/project/6)

## Conclusion

## References

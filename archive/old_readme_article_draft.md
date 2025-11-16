# Project Roster Monster
Project Roster Monster – Development of a Computational Tool for Efficient Healthcare Rostering 

Arthur Yong<sup>1</sup>, Ruan Xucong<sup>1</sup>, Yeo Si Yong<sup>2</sup>, *Angela S. Koh<sup>1,3</sup>, Daniel Chong<sup>1,3</sup>


<sup>1</sup>Department of Cardiology, National Heart Centre Singapore, 5 Hospital Drive 169609, Singapore

<sup>2</sup>Lee Kong Chian School of Medicine, Nanyang Technological University, 11 Mandalay Road 308232, Singapore

<sup>3</sup>Duke-NUS Medical School, 8 College Road 169857, Singapore

Address for correspondence:
*Angela S. Koh (angela.koh.s.m@singhealth.com.sg)

## Abstract
**Objective**: Effective rostering of junior doctors such as residents or medical officers (MOs) is essential for maintaining operational efficiency and employee satisfaction in healthcare. For decades, hospital departments perform clinical rostering of junior doctors manually, a highly inefficient practice that often leads to inequitable workloads and morale among staff. 


**Materials and Methods**: To address these challenges, we developed "Roster Monster," an open-source, R-based algorithm utilizing Monte Carlo simulations to create night call and daytime duty rosters. This algorithm was designed and modelled against the needs of a tertiary high volume cardiology centre.


**Results**: The algorithm generated two million potential night call and 200,000 daytime duty rosters for a specified month. This algorithm automatically generates multiple roster configurations, customizing factors including staff requests, departmental requirements for training, equitable workload while ensuring continuity of patient care. A machine generated calibrator was developed to allow for selection of the most equitable roster.


**Discussion and Conclusion**: This work underscores the transformative potential of computational tools in healthcare administration, offering substantial benefits for managing workflows optimized for healthcare delivery while balancing staff welfare


## BACKGROUND AND SIGNIFICANCE

Rostering junior doctors including residents in training and medical officers (MOs) is a crucial yet laborious task within clinical departments. Most departments assign chief residents or team leads the unenviable task of being "roster monsters", responsible for this duty of designing rosters every month. Apart from individual doctors’ personal requests which determine level of staff wellness, these "roster monsters" need to coordinate across different team assignments in the day, such that training requirements are also adhered to. Conceivably, crafting a roster that accommodates most, if not all, requests is an immensely difficult and time-consuming endeavour. This contributes to the delayed release of rosters, potentially exacerbating physician burnout<sup>[1]</sup>, which is linked to lower quality patient care, decreased patient satisfaction, and may even compromise patient safety<sup>[2]</sup>.

There are two main challenges associated with rostering: MO requests and departmental requests. MO requests encompass leave requests, night call requests, block-call preferences, and weekend-duty preferences. Conversely, departments often seek minimal changes in MO teams to ensure continuity of care, distribute the workload evenly among MOs, and prioritize certain duties for trainees over non-trainees. Furthermore, additional implicit requests may emerge from these constraints, such as avoiding night call duty before scheduled leave, allowing night call duty after a half-day morning leave, managing staffing for post-call vacancies, assigning weekend duties to MOs before and after night call on weekends, and achieving a balanced weekend duty allocation. These factors introduce further complexities to the rostering process, diverting the time and energy of "roster monsters" away from their own clinical training needs.

At its core, rostering is a mathematical challenge, often offering multiple possible solutions. Monte Carlo methods offer a means to identify the optimal solution from various possibilities simulated by a mathematical model. In the context of roster generation, an algorithm that considers various rostering constraints can be used to randomly generate multiple mathematically valid rosters for consideration before a final roster is determined. 

## OBJECTIVE

In this project, we have developed an R-based algorithm that leverages Monte Carlo methods to generate and optimize night call and daytime duty rosters for our department's MOs. We applied this algorithm to MOs' requests for a sample month of February 2024, generating two million mathematically possible night call rosters and 200,000 daytime duty rosters based on a selected night call roster. Subsequently, we analysed the generated rosters, identifying those that align with the department's clinical service needs, using an automated machine generated calibrating score. We demonstrate the feasibility of this approach for automated roster generation, showcasing its potential to significantly enhance departmental workflow and efficiency.


## Materials and methods

### Algorithm development

The computational algorithm for Project Roster Monster was developed in R, and its source code has been made available on GitHub under an open-source license. For the real-world feasibility evaluation of this approach, we used MO requests for the month of February 2024, which are included as a sample in the 'input.xlsx' file. To maintain confidentiality, the names of MOs have been redacted.

### Manpower distribution

The algorithm was tailored to meet the manpower requirements of a satellite department of the National Heart Centre Singapore – a high volume tertiary cardiology centre that handles 120,000 outpatients, 9,000 procedures, and 10,000 inpatients annually. Within the department, ward duties are divided among three teams. Teams 1 and 2 are responsible for patients in general wards, while Team 3 handles patients in high dependency or coronary care units. On weekdays, each team comprises two MOs, while weekends and public holidays have one MO assigned to each team.

Additionally, a runner system is in place, where extra MOs function as 'runners' to provide assistance to the rounding teams. One of the runners is responsible for assisting with the afternoon exercise stress echocardiogram (TTE) clinic on weekdays. As the designated MO would assist duty consultant in performing the stress TTE, this duty offers an excellent opportunity for MOs to gain more in-depth knowledge about TTE procedures.

During weekends, there is always at least one runner available to assist with rounding duties. To fulfil the manpower needs for weekend rounds, each weekend or public holiday would need at least four MOs on rounding duties. There is no afternoon duties on weekends and public holidays.

Furthermore, there is always a designated MO for night call, essentially covering the overnight shift. Post-call, the MO is required to run the same-day admission (SDA) clinic the following morning and take the afternoon off as 'post-call' on weekdays. In the SDA clinic, MOs review and prepare patients for scheduled elective procedures.

In general, the department would receive ten MOs during each rotation cycle, with a maximum allowance of two MOs on leave at any given time. The manpower requirement is summarized into Table 1.

**Table 1**: Summary of the cardiology department's manpower requirements, detailing the number of MOs assigned to general wards (T1 and T2) , high dependency units / coronary care units (T3), and clinics during weekdays, weekends, and public holidays.
![Table 1](/figures/table_1.png)

## RESULTS

### Design of algorithm

The algorithm consists of two major parts. The first part is designed to generate night call rosters, while the second part completes the full daytime duty roster (Figure 1). Initially, the algorithm requires an input file in the form of a Microsoft Excel document. It can then generate any number of night call rosters for subsequent selection. Once a specific night call roster is selected, it is fed into the second part of the algorithm to generate a complete daytime duty roster.

![Figure 1](/figures/figure_1.png)
**Figure 1**: The schematic illustrates the two-part algorithm design for roster generation. Part I involves the creation of night call rosters, and Part II consists of generating complete daytime duty rosters based on the shortlisted night call roster.

### Generation of night call rosters

Within the input Excel document, users must provide MO names, the duration of rostering, and various requests from the MOs on the first sheet (Figure 2A). To enhance rostering accuracy, a list of public holidays can be added on the second sheet (Figure 2B). For a fairer distribution of call duties among MOs, call points from previous months can be optionally included based on departmental needs (Figure 2C). Additionally, any MO under a specific training track can be specified on the fourth sheet (Figure 2D), as certain duties may be prioritized for these trainees.

![Figure 2](/figures/figure_2.png)
**Figure 2**: Screenshots of the Excel spreadsheet used for input data. (A) Sheet 1 lists MO names, roster dates, and their requests, (B) Sheet 2 marks public holidays, (C) Sheet 3 details call points from previous months for fairness in cumulative night call allocation (optional), and (D) Sheet 4 identifies MOs under any training track (optional), all of which are considered by the algorithm in roster generation. _MO: Medical officer._

The logical flow of the first part of the roster generation process is detailed in Figure 3. This part handles the MO requests and initial roster setup. Initially, the algorithm generates an empty roster using the MO names and input dates. It also incorporates the list of public holidays to ensure accurate scheduling. Next, the algorithm would go through each day and try to fulfil MO requests as completely as possible. The types of requests considered include various leaves (annual, medical, and training), call and no-call preferences, and preferences for working or not working on specific weekends. After addressing these requests, the algorithm reassesses each date. It randomly assigns MOs who are mathematically eligible, excluding those on leave or who have requested not to work on specific weekends. The assignment process also factors in post-call conditions. MOs who were on call the previous night, and "post-post-call" conditions for MOs who were on call two nights earlier, are also excluded from consideration.

![Figure 3](/figures/figure_3.png)
**Figure 3**: This schematic outlines the first part of the algorithm process, which randomly generates night call rosters based on MO names, dates, and requests. The process can be repeated as many time as needed. In this project, we generated two millions different night call rosters to ensure a broad range of coverage. _MO: Medical officer; PH Public holiday._

In this project, we repeated the generation of night call rosters two million times. For each call, we assigned specific call points to manage the distribution of duties (Figure 4A). We categorized the calls into four groups: Monday-to-Thursday calls, Friday calls, Saturday calls, and Sunday calls. To accommodate variations such as public holidays, we established the conditions of these calls relative to ordinary working days and holidays/weekends (Table 2). This approach ensures that the algorithm's outputs can be generalized across different types of days, maintaining fairness and efficiency in duty allocation.

![Figure 4](/figures/figure_4_v2.png)
**Figure 4**: (A) Representative screenshot of a machine-generated night call roster with call points calculated based on conditions in Table 2. (B) In total, five roster contributing to lowest SD of cumulative call points would be shortlisted. Lower SD values suggesting a fairer distribution of call duties. Columns of MO2 to MO9 were minimized for better visualization. (C) SD without factoring in previous call points were also calculated for the shortlisted rosters for user reference. (D) The histogram of SD calculated from cumulative call points, based on the two million generated rosters. (E) The histogram of SD calculated from call points within the rostering period only, without factoring in previous months data. _SD: Standard deviation._

**Table 2**: The assignment of call points to each call, which can be adjusted based on departmental needs.
![Table 2](/figures/table_2.png)

The adaptation of the call point system allowed us to numerically examine the call burden of each MO. By calculating the total call points of everyone, as well as the standard deviation (SD) of call points, we can infer the call burden and the fairness of duty distribution. Among the two million rosters generated, five rosters with lowest SD from cumulative call points were shortlisted (Figure 4B). The distribution of call burden during the rostering period alone can also be analysed without factoring in previous months’ call points (Figure 4C). Overall, this approach allows review of total call burden to date, leading to a fairer distribution of workload across the entire posting duration.

Manually generating even a single night call roster can be time-consuming. In contrast, the algorithm developed for this project can rapidly generate any mathematically possible roster. For example, running the algorithm on a 2018 entry-spec MacBook Pro takes less than one second to produce a call roster. While this demonstrates significant efficiency, the resulting rosters are often not ideal. For instance, some MOs might end up covering more call duties than others. This limitation, however, can be overcome by employing the Monte Carlo approach, which involves repeating the roster generation multiple times. By doing so, we can select the most suitable roster from a broader range of generated options. With the two million call rosters generated for this project, the SD of call points can be calculated for each machine-generated roster and plotted on a histogram (Figure 4D, 4E). Generally, we favour rosters on the leftmost tail-end, with a low SD suggesting a fairer distribution of duties. 

### Generation of full rosters

Once a night call roster is selected from the numerous iterations, it can be fed into the second part of the algorithm for day duty roster generation. Based on the selected call rosters, we divide all ordinary working days into AM and PM duties, while holidays and weekends are limited to AM duties only. Post-call MOs are entitled to take PM duties off on weekdays and are automatically assigned to manage the same-day-admission (SDA) during post-call AMs on weekdays. In the SDA clinic, MOs review and prepare patients for scheduled elective procedures. These assignments are automatically processed once the night call roster is integrated into the algorithm.

In our department, the rostering of clinical duties is based on calendar weeks. We initiate the rostering process by dividing the weeks into Monday-to-Sunday cycles (Figure 5). Following this, we randomly assign MOs to clinical teams according to the departmental manpower requirements, as previously detailed in Table 1. For weekend duties, we strive to equalize the duty burden across the manpower pool while aiming to accommodate as many weekend work or off requests from MOs as possible. Meanwhile, we prioritize weekend duties for MOs who are going for night call or post-call. Similar to the generation of the night call roster, we can repeat the second part of the rostering process as many times as needed.

![Figure 5](/figures/figure_5.png)
**Figure 5**: The second part of the algorithm design assigns team duties to the shortlisted night call rosters while considering MO leave and weekend requests. The process can be repeated as many time as needed. In this project, we repeated the process 200,000 times to select the most equitable and practical final roster.

In this project, we repeated the allocation of the day duty roster 200,000 times to cover a broad range of possibilities (Figure 6A). Each full roster was then tallied according to the duty types assigned to each MO (Figure 6B). This allowed us to calculate the SD among the duty counts, where a lower SD indirectly signifies a fairer distribution of workload types among the MOs. We also plotted the SD calculated from all 200,000 rosters into a histogram; similar to previous analyses, we favoured the leftmost tail-end, which signifies a fairer distribution (Figure 6C).

![Figure 6](/figures/figure_6.png)
**Figure 6**: (A) A representative screenshot from one of the 200,000 full rosters generated by the algorithm. (B) The tally of MO duties from each roster facilitates further analysis, where SD can be calculated for more equitable distribution of duties. This analysis can also be used to ensure compliance with departmental training requirements, such as mandating a minimum number of Team 3 (HD/ICU) duties for trainees. (C) The histogram of SD calculated from the 200,000 generated full rosters is presented. _MO: Medical officer; SD: Standard deviation; HD: High dependency unit; ICU: Intensive care unit._

Ensuring a fair distribution of workload among MOs is crucial, yet it may not always be the top priority when planning the clinical roster. In our department, team members, including registrars and consultants, are rotated to specific teams weekly. Frequent changes of MOs — the junior members responsible for carrying out plans — could harm the continuity of care. Although the SD calculation aids in achieving a fairer workload, an additional metric is necessary to gauge the frequency of manpower changes. Thus, we introduce the Average MO Count (AMOC), which measures the average number of MOs in a team, as depicted in Table 3. Theoretically, it can range from 2 to 12, with a lower value indicating fewer changes in MOs and, consequently, greater continuity of care. We calculated the AMOC for all 200,000 rosters we generated and plotted these values in a histogram (Figure 7A), favouring the leftmost tail-end, which represents less frequent turnover of MO manpower week-over-week.

**Table 3**: The concept of Average MO Count (AMOC) is demonstrated, showing the number of MOs covering each team during a typical week. A lower AMOC value indicates reduced turnover, promoting continuity of care.
![Table 3](/figures/table_3.png)

![Figure 7](/figures/figure_7.png)
**Figure 7**: (A) The histogram of AMOC values derived from the 200,000 generated daytime duty rosters. (B) Scatter plot displaying the relationship between SD and AMOC for a subset of full rosters. This graph represents a random sample of 3,000 rosters out of the 200,000 generated for greater visibility. _AMOC: Average MO Count; SD: Standard deviation._

With both SD and AMOC metrics at our disposal, we can more accurately appraise each automatically generated roster for implementation. Since SD and AMOC values can be derived independently for each full roster, it allows users to decide which metric should carry more weight in their decision-making process. To illustrate the distribution of SD and AMOC across the 200,000 rosters generated, we plotted them on a scatter plot, using a random sample of 3,000 values for better visibility (Figure 7B). Ideally, rosters towards the bottom-left corner are sought after, as they reflect a more equitable workload distribution and better continuity of care.

# DISCUSSION

Rostering duties, while laborious and time-consuming, are essential for the smooth operation of any clinical department. An audit conducted within the UK NHS revealed that only 8% to 17% of junior doctors received their rosters on time, and 19% did not receive their rosters at all prior to the commencement of their posting<sup>[1]</sup>. While the specific reasons for such delays were not investigated, creating a viable roster is complex and time-consuming. 

Poor rostering outcomes have been shown to lead to decreased job satisfaction and an increased risk of burnout among team members<sup>[3]</sup>. Burnout among doctors has been associated with premature attrition, lower quality of patient care, decreased patient satisfaction, and compromised patient safety<sup>[2, 4 ,5]</sup>. Optimal work planning such as advance vacation planning to improve work-life balance has been recommended to combat risks of burnout<sup>[6]</sup>. Other strategies to reduce burnout through work rostering include reducing sleep deprivation resulting from prolonged work shifts<sup>[7-9]</sup>.

In many clinical departments, rostering duty is often delegated to one of the team leaders or chief residents. While this additional duty significantly diverts them from their primary responsibilities, creating a roster that satisfies most leave requests and adheres to departmental constraints is often challenging. Moreover, this task tends to recur monthly, largely due to the impracticality of expecting the entire team to schedule their absences and leaves three to six months in advance. Adjustments made to the call roster to accommodate urgent leaves can further lead to significant shifts in call burden and call point distribution, often necessitating further changes to subsequent rosters to ensure fair workload distribution.

In this project, we custom-built a rostering algorithm aimed at automating the process to the greatest extent possible. Our goal was to craft an algorithm that is user-friendly, which led us to select an Excel document as the sole input file. All subsequent calculations are performed in R without requiring further user input. We tested this algorithm with real-world requests for February 2024 and successfully demonstrated its practical applicability. With this algorithm, we aim to enhance the efficiency of roster creation while ensuring a fair distribution of ward and call duties among all junior doctors.

Admittedly, this approach has its limitations. Primarily, the use of the Monte Carlo method necessitates a large number of repeated iterations, which can be computationally demanding and time-consuming. Even with a multi-core parallel computing algorithm, completing the full set of iterations for this project on an entry-level personal computer took approximately 72 hours. While it may be argued that manual roster creation would not take 72 hours, employing this algorithmic approach liberates time that could be better spent on clinical duties. Moreover, the use of more powerful devices and processors could significantly decrease the computation time. Besides computation time, this approach requires statistical skills, which may not be widely prevalent among junior staff. While the program is designed to be platform-independent, functioning on both Windows and Mac systems, the user must be willing to acquire at least a rudimentary understanding of coding in case of troubleshooting.

The use of the Monte Carlo method was critical in this project, as it allows for the numerical comparison of various rosters, providing a powerful tool to optimize roster planning. Without such computational tools, manual rostering often struggles to satisfy diverse requests while ensuring a fair distribution of workload. Additionally, the implementation of a call points system, although beneficial, is typically limited; systems with high granularity pose a significant challenge for roster planners in balancing the distribution of duties while accommodating various requests and constraints. In this project, we demonstrated the power of the Monte Carlo method to achieve what seems impossible — by considering thousands to millions of mathematically permissible combinations, the ultimate roster we generate is very likely superior to any manually planned roster. This advantage provides a compelling incentive to automate the rostering process, going beyond mere workflow efficiency. 

The use of computational tools in manpower rostering has been studied extensively in computer science and operations research for years. Nonetheless, its actual implementation in clinical scheduling seems to be limited to date. Locally, many hospital departments have engaged with computer science students to address various rostering challenges<sup>[10-12]</sup>. There are also numerous commercial software solutions designed to simplify rostering tasks. However, most of these solutions aim to assist in rostering rather than to fully automate the process, as our project attempts. There are several possible reasons for this. Full automation typically requires detailed customization, which may not be commercially viable for software companies to provide for each department's specific needs. Furthermore, the investment in time and resources required for clinical departments to develop their autonomous rostering tools with external developers would likely exceed the costs of allocating the task to a junior staff. By releasing this open-source algorithm, we aim to support future initiatives toward workflow automation by clinicians with basic coding proficiency. We also hope that the structural design employed in this algorithm could serve as a reference for future automated rostering attempts, including those developed in other languages such as Python.
 
# CONCLUSION

In conclusion, this project introduces a novel approach to rostering for junior doctors. By leveraging Monte Carlo simulations, we have demonstrated significant improvements over traditional manual methods. This method not only enhances operational efficiencies but also ensures a fairer workload distribution and enhances continuity of care. Although there are challenges associated with computational demands and the need for technical proficiency, the potential long-term benefits, such as reduced burnout and increased staff satisfaction, highlight the importance of continuing to develop and adapt these tools in healthcare settings.

# REFERENCES
[1] Pepper T, Hicks G. Six Weeks’ notice of the on-call roster: Fact or fantasy? an audit study. British Journal of Hospital Medicine. 2018 Dec;79(12):708–10. doi:10.12968/hmed.2018.79.12.708

[2] Shanafelt T, Goh J, Sinsky C. The business case for investing in physician well-being. JAMA Internal Medicine. 2017 Dec;177(12):1826. doi:10.1001/jamainternmed.2017.4340

[3] Fletcher CM, Rotstein LL. Optimising rostering patterns for Australian junior doctors. Australian Health Review. 2023 Mar;47(3):344–5. doi:10.1071/ah23030

[4] Shanafelt TD, Mungo M, Schmitgen J, et al. Longitudinal study evaluating the association between physician burnout and changes in professional work effort. Mayo Clinic Proceedings. 2016 Apr;91(4):422–31. doi:10.1016/j.mayocp.2016.02.001

[5] Willard-Grace R, Knox M, Huang B, et al. Burnout and Health Care Workforce turnover. The Annals of Family Medicine. 2019 Jan;17(1):36–41. doi:10.1370/afm.2338

[6] Hobi M, Yegorova-Lee S, Chan CC, et al. Strategies Australian junior doctors use to maintain their mental, physical and social well-being: A qualitative study. BMJ Open. 2022 Sept;12(9). doi:10.1136/bmjopen-2022-062631

[7] Rahman SA, Sullivan JP, Barger LK, et al. Extended work shifts and neurobehavioral performance in resident-physicians. Pediatrics. 2021 Mar;147(3). doi:10.1542/peds.2020-009936

[8] Levine AC, Adusumilli J, Landrigan CP. Effects of reducing or eliminating resident work shifts over 16 hours: A systematic review. Sleep. 2010 Aug;33(8):1043–53. doi:10.1093/sleep/33.8.1043

[9] Brown C, Abdelrahman T, Lewis W, et al. To bed or not to bed: The sleep question? Postgraduate Medical Journal. 2019 Dec;96(1139):520–4. doi:10.1136/postgradmedj-2018-135795

[10] Chan ECS, Foo YQ, et al. Rostermonster.io [Internet]. [Accessed 2024 Jan 30]. Available from: https://web.archive.org/web/20240130131935/https://uvents.nus.edu.sg/event/20th-steps/module/IS4250/project/6

[11] Ang WS, Tan L, Lee RRE, et al. Oral and maxillofacial surgery (OMS) manpower Rostering [Internet]. [Accessed 2024 Jan 30]. Available from: https://web.archive.org/web/20240130132101/https://uvents.nus.edu.sg/event/20th-steps/module/IS4250/project/10

[12] Aw ZK, Koh YLD, Lin Y, et al. Automation of rostering system for doctors [Internet]. [Accessed 2024 Jan 30]. Available from: https://web.archive.org/web/20240130132756/https://uvents.nus.edu.sg/event/18th-steps/module/IS4250/project/6

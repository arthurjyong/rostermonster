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

Rostering junior doctors including residents in training and medical officers (MOs) is a crucial yet laborious task within clinical departments. Most departments assign chief residents or team leads the unenviable task of being "roster monsters", responsible for this duty of designing rosters every month. Apart from individual doctors’ personal requests which determine level of staff wellness, these "roster monsters" need to coordinate across different team assignments in the day, such that training requirements are also adhered to. Conceivably, crafting a roster that accommodates most, if not all, requests is an immensely difficult and time-consuming endeavour. This contributes to the delayed release of rosters, potentially exacerbating physician burnout[1], which is linked to lower quality patient care, decreased patient satisfaction, and may even compromise patient safety[2].

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


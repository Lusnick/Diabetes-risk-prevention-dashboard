# Diabetes Risk Preventive Analysis Dashboard

A comprehensive Data Engineering and Business Intelligence project focused on identifying patient risk profiles, analyzing body mass index (BMI) distributions, and evaluating lifestyle behaviors to support preventive healthcare decisions.

![Dashboard Preview](dashboard_overview.png)

##  Phase 1: Data Engineering (SQL Server)
Instead of loading raw files directly into the BI tool, **Feature Engineering** was applied at the database level to guarantee performance, data integrity, and centralized business rules.

### Database Actions Realized:
1. **Data Cleaning & Typing:** Handled data types specifically for precision numerical values (`DECIMAL`, `INT`).
2. **Clinical Categorization (WHO Rules):** Automated age group segmentation and medical classifications for `BMI`, `Fasting_Blood_Sugar`, and `HbA1c_Level` using structured `CASE WHEN` queries.
3. **Lifestyle Risk Score:** Aggregated multiple behavioral variables (`Smoking_Status`, `Alcohol_Consumption`, `Physical_Activity_Level`) into a unified predictive risk index.
4. **Dimensional Modeling:** Deconstructed the original flat file into a **Star Schema** model, splitting data into a central `Fato_Pacientes` (Fact) and an optimized `Dim_EstiloVida` (Dimension) table to maximize join performance.

> 📂 *All full SQL scripts for table creation and Views are located inside the `011_pipeline_dados.sql` file in this repository.*

---

##  Phase 2: Business Intelligence (Power BI)
The optimized data was imported into Power BI via **SQL Views** using the **Import Mode** (VertiPaq engine) for lightning-fast report interactions.

### Developed Metrics (DAX Formulas):

```dax
Total Pacientes = 
COUNT(Fato_Pacientes[Patient_ID])
```

```dax
Taxa Diabetes = 
DIVIDE(
    CALCULATE(
        [Total Pacientes], 
        Fato_Pacientes[Diagnostico] = 1
    ), 
    [Total Pacientes], 
    0
)
```

```dax
Taxa Risco (%) = 
DIVIDE(
    SUM(Fato_Pacientes[Diagnostico_Risco_Alto]),
    COUNT(Fato_Pacientes[Patient_ID]), 
    0
)
```

```dax
Media IMC = 
AVERAGE(Fato_Pacientes[BMI])
```

### Dashboard Layout & Visuals:
* **KPI Scorecard:** Top cards tracking Total Cohort, Overall Incidence Rate, and Average BMI.
* **Correlation Analysis:** Bar chart analyzing the relationship between weight categories (BMI) and Diabetes diagnosis rates.
* **Behavioral Views:** Donut chart evaluating the direct weight of behavioral profiles on positive diagnoses.
* **Dynamic Filters:** Slicers allowing immediate deep dives by Age Bracket and Glucose Status.

---

##  Key Insights & Business Conclusions
1. **Weight is the Main Trigger:** Patients categorized under "Obesity" present a drastically higher Diabetes incidence rate compared to the general population average.
2. **The Silent Impact of Habits:** Individuals with an "Extreme Risk" behavioral profile (active smokers, high alcohol intake, and sedentary habits) show an exponentially higher probability of pre-diabetes, even within younger groups (18-29 years old).

##  Practical Impact & Target Audience
* **Hospitals & Clinics:** Triage teams can proactively flag high-risk individuals before final lab tests are completed.
* **Health Insurance Providers:** Enables the creation of targeted preventive medicine programs (e.g., specific weight loss tracks for highly vulnerable demographics).
* **Public Health Administrators:** Supports efficient resource allocation and customized educational health campaigns.

---

##  Data Source & Privacy
The historical dataset utilized for this analysis was sourced from **Kaggle**. It features anonymized public healthcare data. All records are strictly sanitized and comply with global data privacy compliance, ensuring no Personally Identifiable Information (PII) is exposed.

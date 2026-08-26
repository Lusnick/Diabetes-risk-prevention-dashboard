-- =========================================================================
-- ETAPA 1: ELIMINAR E CRIAR A TABELA BRUTA 
-- =========================================================================
DROP TABLE IF EXISTS diabetes_risk;
GO

CREATE TABLE diabetes_risk (
    Patient_ID VARCHAR(50),
    Age VARCHAR(50),
    Gender VARCHAR(50),
    City VARCHAR(100),
    BMI VARCHAR(50),
    Family_History VARCHAR(50),
    Physical_Activity VARCHAR(100),
    Diet_Type VARCHAR(100),
    Smoking_Status VARCHAR(100),       
    Alcohol_Consumption VARCHAR(100),  
    Sleep_Hours VARCHAR(50),           
    Pregnancies VARCHAR(50),           
    Fasting_Blood_Sugar VARCHAR(50),   
    HbA1c_Level VARCHAR(50),           
    Systolic_BP VARCHAR(50),           
    Diastolic_BP VARCHAR(50),          
    Pulse_Rate VARCHAR(50),            
    Income_Group VARCHAR(50),          
    Risk_Level VARCHAR(50)             
);
GO

-- =========================================================================
-- ETAPA 2: CARGA DOS DADOS (BULK INSERT)
-- =========================================================================

-- Garanta que limpa a tabela antes de tentar novamente
TRUNCATE TABLE diabetes_risk;
GO

-- 2. Altera o idioma da sessão atual para Inglês (força o ponto como separador decimal)
SET LANGUAGE 'English';
GO


 --ETAPA 2: CARGA DOS DADOS (BULK INSERT)
BULK INSERT diabetes_risk
FROM 'C:\Medical\diabetes_risk.csv' 
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    DATAFILETYPE = 'char',
    CODEPAGE = '65001',
    TABLOCK
);
GO

-- =========================================================================
-- ETAPA 3: A CAMADA DE LIMPEZA E TRATAMENTO DE NULOS/DECIMAIS
-- =========================================================================
CREATE OR ALTER VIEW v_diabetes_risk_limpo AS
WITH CTE_Dedup AS (
    SELECT 
        TRIM(Patient_ID) AS Patient_ID,
        TRY_CAST(TRIM(Age) AS INT) AS Age,
        TRIM(Gender) AS Gender,
        TRIM(City) AS City,
        
        -- Conversão do IMC (BMI) tratando ponto americano
        COALESCE(
            TRY_CAST(REPLACE(TRIM(BMI), '.', ',') AS DECIMAL(10,2)),
            TRY_CAST(TRIM(BMI) AS DECIMAL(10,2))
        ) AS BMI,
        
        TRIM(Family_History) AS Family_History,
        TRIM(Physical_Activity) AS Physical_Activity,
        TRIM(Diet_Type) AS Diet_Type,
        TRIM(Smoking_Status) AS Smoking_Status,
        TRIM(Alcohol_Consumption) AS Alcohol_Consumption,
        TRY_CAST(TRIM(Sleep_Hours) AS DECIMAL(10,2)) AS Sleep_Hours,
        TRY_CAST(TRIM(Pregnancies) AS INT) AS Pregnancies,
        TRY_CAST(TRIM(Fasting_Blood_Sugar) AS INT) AS Fasting_Blood_Sugar,
        
        -- Conversão do HbA1c tratando ponto americano
        COALESCE(
            TRY_CAST(REPLACE(TRIM(HbA1c_Level), '.', ',') AS DECIMAL(10,2)),
            TRY_CAST(TRIM(HbA1c_Level) AS DECIMAL(10,2))
        ) AS HbA1c_Level,
        
        TRY_CAST(TRIM(Systolic_BP) AS INT) AS Systolic_BP,
        TRY_CAST(TRIM(Diastolic_BP) AS INT) AS Diastolic_BP,
        TRIM(Income_Group) AS Income_Group,
        TRIM(Risk_Level) AS Risk_Level,
        
        ROW_NUMBER() OVER(PARTITION BY Patient_ID ORDER BY Patient_ID) AS Row_Num
    FROM diabetes_risk
)
SELECT * FROM CTE_Dedup WHERE Row_Num = 1;
GO


-- =========================================================================
-- ETAPA 4: MODELAÇÃO DIMENSIONAL - TABELA FATO ENRIQUECIDA
-- =========================================================================
-- 1. Atualizar a Tabela Dimensão para ter uma Chave Única Comercial
CREATE OR ALTER VIEW Dim_EstiloVida AS
SELECT 
    -- Cria um ID numérico único para cada combinação exclusiva de hábitos
    DENSE_RANK() OVER(ORDER BY Smoking_Status, Alcohol_Consumption, Physical_Activity) AS Id_Estilo_Vida,
    Smoking_Status,
    Alcohol_Consumption,
    Physical_Activity
FROM v_diabetes_risk_limpo
GROUP BY Smoking_Status, Alcohol_Consumption, Physical_Activity;
GO

-- 2. Atualizar a Tabela Fato para trazer esse mesmo ID de ligação
CREATE OR ALTER VIEW Fato_Pacientes AS
SELECT 
    f.Patient_ID,
    f.City,
    f.Age,
    CASE 
        WHEN f.Age < 30 THEN '18-29 anos'
        WHEN f.Age BETWEEN 30 AND 45 THEN '30-45 anos'
        WHEN f.Age BETWEEN 46 AND 60 THEN '46-60 anos'
        ELSE 'Mais de 60 anos'
    END AS Faixa_Etaria,
    f.Gender,
    f.BMI,
    CASE 
        WHEN f.BMI < 18.5 THEN 'Abaixo do Peso'
        WHEN f.BMI BETWEEN 18.5 AND 24.99 THEN 'Peso Saudável'
        WHEN f.BMI BETWEEN 25.0 AND 29.99 THEN 'Sobrepeso'
        ELSE 'Obesidade'
    END AS Categoria_IMC,
    f.Family_History,
    f.Fasting_Blood_Sugar,
    CASE 
        WHEN f.Fasting_Blood_Sugar < 100 THEN 'Normal'
        WHEN f.Fasting_Blood_Sugar BETWEEN 100 AND 125 THEN 'Pré-Diabetes'
        ELSE 'Diabetes Alerta'
    END AS Status_Glicose,
    f.HbA1c_Level,
    f.Systolic_BP,
    f.Diastolic_BP,
    f.Income_Group,
    CASE WHEN f.Risk_Level = 'High' THEN 1 ELSE 0 END AS Diagnostico_Risco_Alto,
    -- Traz o ID correspondente para a Fato fazer o JOIN 
    d.Id_Estilo_Vida
FROM v_diabetes_risk_limpo f
INNER JOIN Dim_EstiloVida d 
    ON f.Smoking_Status = d.Smoking_Status
    AND f.Alcohol_Consumption = d.Alcohol_Consumption
    AND f.Physical_Activity = d.Physical_Activity;
GO

-- =========================================================================
-- ETAPA 5: MODELAÇÃO DIMENSIONAL - TABELA DIMENSÃO ESTILO VIDA
-- =========================================================================
CREATE OR ALTER VIEW Dim_EstiloVida AS
SELECT DISTINCT
    Smoking_Status,
    Alcohol_Consumption,
    Physical_Activity
FROM v_diabetes_risk_limpo;
GO



--Números de Controlo
SELECT 
    COUNT(Patient_ID) AS Total_Pacientes,
    SUM(Diagnostico_Risco_Alto) AS Total_Risco_Alto,
    ROUND(AVG(BMI), 2) AS Media_Geral_IMC,
    -- Calcula a taxa de risco médio geral
    ROUND((CAST(SUM(Diagnostico_Risco_Alto) AS DECIMAL(10,2)) / COUNT(Patient_ID)) * 100, 2) AS Taxa_Risco_Geral_Percentual
FROM Fato_Pacientes;

 
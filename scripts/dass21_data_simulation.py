import pandas as pd
import numpy as np
import os

# Set random seed for reproducibility
np.random.seed(42)

# Assigning Parameters
n_per_group = 20
timepoints = ["baseline", "3_months", "6_months", "9_months", "12_months"]
groups = ["intervention", "control"]
questions = [f"Q{i}" for i in range(1, 22)]

# Mapping the DASS21 questions to their respective subscales
dass_anxiety = ["Q2", "Q4", "Q7", "Q9", "Q15", "Q19", "Q20"]
dass_depression = ["Q3", "Q5", "Q10", "Q13", "Q16", "Q17", "Q21"]
dass_stress = ["Q1", "Q6", "Q8", "Q11", "Q12", "Q14", "Q18"]

# Creating an effect modifier to apply to the treatment group
def apply_treatment_effect(scores, effect_size=0.2):
    return np.clip(np.round(scores * (1 - effect_size)), 0, 3).astype(int)

# Generate data
data = []

for group in groups:
    for subject_id in range(1, n_per_group + 1):
        full_id = f"{group[:1].upper()}{subject_id:02d}"
        for time in timepoints:
            row = {
                "id": full_id,
                "group": group,
                "timepoint": time
            }
            for q in questions:
                base_score = np.random.choice([0, 1, 2, 3], p=[0.1, 0.2, 0.4, 0.3])
                if group == "intervention" and time != "baseline":
                    row[q] = apply_treatment_effect(np.array([base_score]))[0]
                else:
                    row[q] = base_score

            # Calculate subscale scores
            row["DASS_Anxiety"] = sum([row[q] for q in dass_anxiety])
            row["DASS_Depression"] = sum([row[q] for q in dass_depression])
            row["DASS_Stress"] = sum([row[q] for q in dass_stress])
            data.append(row)

# Create DataFrame
df = pd.DataFrame(data)

# Save to CSV
output_dir = "data"
os.makedirs(output_dir, exist_ok=True)
csv_path = os.path.join(output_dir, "simulated_dass21_full.csv")
df.to_csv(csv_path, index=False)
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

# --- Latent variable model ---
# Each item score is generated from a 3-level latent structure:
#   θ_ij = η_i + ε_it + δ(group, time) + ζ_ijt
#
#   η_i    ~ N(0, σ_between)  — stable subject-level random intercept
#   ε_it   ~ N(0, σ_within)   — timepoint-level fluctuation
#   δ      — deterministic group × time effect (in latent SD units ≈ Cohen's d)
#   ζ_ijt  ~ N(0, σ_item)     — item-level noise
#
# The continuous latent score is mapped to ordinal 0–3 via fixed thresholds.
# Thresholds are calibrated to match the target item distribution p=[0.1, 0.2, 0.4, 0.3]
# using: thresholds = σ_total * norm.ppf([0.1, 0.3, 0.7])
# where σ_total = sqrt(1.0² + 0.5² + 0.3²) ≈ 1.158

SIGMA_BETWEEN = 1.0   # between-person SD
SIGMA_WITHIN  = 0.5   # within-person (timepoint) SD
SIGMA_ITEM    = 0.3   # item-level noise SD

# Pre-computed thresholds: σ_total * norm.ppf([0.1, 0.3, 0.7])
THRESHOLDS = np.array([-1.484, -0.607, 0.607])


def latent_to_ordinal(latent_score: float) -> int:
    """Map a continuous latent score to ordinal 0–3 via fixed thresholds."""
    return int(np.digitize(latent_score, THRESHOLDS))


timepoint_index = {t: i for i, t in enumerate(timepoints)}
N_TIMEPOINTS = len(timepoints)


def group_time_effect(group: str, time: str) -> float:
    """
    Deterministic effect on the latent scale (negative = improvement).

    Control:      small natural remission, reaching -0.2 SD at 12 months.
    Intervention: builds to -0.5 SD at 12 months (medium Cohen's d effect).
    """
    t = timepoint_index[time]
    if group == "control":
        return -0.05 * t
    else:
        return -0.5 * (t / (N_TIMEPOINTS - 1))


# Generate data
data = []

for group in groups:
    for subject_id in range(1, n_per_group + 1):
        full_id = f"{group[:1].upper()}{subject_id:02d}"

        # Subject-level random intercept — stable across all timepoints
        eta_i = np.random.normal(0, SIGMA_BETWEEN)

        for time in timepoints:
            # Person × timepoint latent score
            epsilon_it = np.random.normal(0, SIGMA_WITHIN)
            delta = group_time_effect(group, time)
            theta_it = eta_i + epsilon_it + delta

            row = {"id": full_id, "group": group, "timepoint": time}

            for q in questions:
                item_latent = theta_it + np.random.normal(0, SIGMA_ITEM)
                row[q] = latent_to_ordinal(item_latent)

            row["DASS_Anxiety"]    = sum(row[q] for q in dass_anxiety)
            row["DASS_Depression"] = sum(row[q] for q in dass_depression)
            row["DASS_Stress"]     = sum(row[q] for q in dass_stress)
            data.append(row)

# Create DataFrame
df = pd.DataFrame(data)

# Save to CSV
output_dir = "data"
os.makedirs(output_dir, exist_ok=True)
csv_path = os.path.join(output_dir, "simulated_dass21_full.csv")
df.to_csv(csv_path, index=False)

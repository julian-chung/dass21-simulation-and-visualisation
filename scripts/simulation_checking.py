# A quick script to check the if the data simulation generated two groups with different means

# Import necessary libraries
import pandas as pd

# Load the simulated dataset
df = pd.read_csv("data/simulated_dass21_full.csv")

# Get group-wise means at each timepoint
summary = df.groupby(['group', 'timepoint'])[
    ['DASS_Anxiety', 'DASS_Depression', 'DASS_Stress']
].mean().round(2)

print("Group-wise mean scores over time:\n")
print(summary)

# Show the difference (intervention - control)
diff = summary.unstack(level=0)

# Calculate difference for each subscale
change = pd.DataFrame({
    "Anxiety": diff[('DASS_Anxiety', 'intervention')] - diff[('DASS_Anxiety', 'control')],
    "Depression": diff[('DASS_Depression', 'intervention')] - diff[('DASS_Depression', 'control')],
    "Stress": diff[('DASS_Stress', 'intervention')] - diff[('DASS_Stress', 'control')],
})

print("\nMean difference (intervention - control):\n")
print(change.round(2))

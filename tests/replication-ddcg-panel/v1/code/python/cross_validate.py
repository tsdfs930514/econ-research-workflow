"""
Cross-Validation: DDCG Panel FE — Stata vs Python (pyfixest)
Replicates: xtreg y l(1/4).y dem yy*, fe vce(cluster wbcode2)
"""
import pandas as pd
import pyfixest as pf

df = pd.read_stata("v1/data/raw/DDCGdata_final.dta")

# Create lagged variables (Stata's l(1/4).y)
df = df.sort_values(["wbcode2", "year"])
for lag in range(1, 5):
    df[f"ly{lag}"] = df.groupby("wbcode2")["y"].shift(lag)

# Identify year dummies (yy1-yy50 already in data)
yy_cols = [c for c in df.columns if c.startswith("yy") and c[2:].isdigit()]

# Build formula with year dummies as controls
controls = " + ".join([f"ly{i}" for i in range(1, 5)] + yy_cols)
formula = f"y ~ dem + {controls} | wbcode2"

# Run FE regression with clustered SEs
model = pf.feols(formula, data=df, vcov={"CRV1": "wbcode2"})
print("=== Python FE (pyfixest) ===")
print(model.summary())

# Extract coefficients
py_dem = model.coef()["dem"]
py_ly = model.coef()["ly1"]
py_n = model._N

# Stata values
stata_dem = 0.78655338
stata_se = 0.22631668
stata_ly = 1.238106
stata_n = 6336

# Cross-validation
pct_diff_dem = abs(stata_dem - py_dem) / abs(stata_dem) * 100
pct_diff_ly = abs(stata_ly - py_ly) / abs(stata_ly) * 100

print(f"\n=== CROSS-VALIDATION ===")
print(f"  dem coefficient:")
print(f"    Stata:  {stata_dem:.6f}")
print(f"    Python: {py_dem:.6f}")
print(f"    Diff:   {pct_diff_dem:.4f}%")
print(f"    Status: {'PASS' if pct_diff_dem < 0.1 else 'FAIL'}")
print(f"  L.y coefficient:")
print(f"    Stata:  {stata_ly:.6f}")
print(f"    Python: {py_ly:.6f}")
print(f"    Diff:   {pct_diff_ly:.4f}%")
print(f"    Status: {'PASS' if pct_diff_ly < 0.1 else 'FAIL'}")
print(f"  N: Stata={stata_n}, Python={py_n}")

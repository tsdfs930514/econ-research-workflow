"""
Cross-Validation: DDCG IV — Stata xtivreg2 vs Python pyfixest
Replicates: xtivreg2 y l(1/4).y (dem=l(1/4).instrument) yy*, fe cluster partial
"""
import pandas as pd
import pyfixest as pf

df = pd.read_stata("v1/data/raw/DDCGdata_final.dta")

# Create instrument and lagged variables
df["instrument"] = df["demreg"]
df = df.sort_values(["wbcode2", "year"])
for lag in range(1, 5):
    df[f"ly{lag}"] = df.groupby("wbcode2")["y"].shift(lag)
    df[f"linst{lag}"] = df.groupby("wbcode2")["instrument"].shift(lag)

# Year dummies
yy_cols = [c for c in df.columns if c.startswith("yy") and c[2:].isdigit()]
controls = " + ".join([f"ly{i}" for i in range(1, 5)] + yy_cols)
instruments = " + ".join([f"linst{i}" for i in range(1, 5)])

# pyfixest IV syntax: Y ~ exog | FE | endog ~ instruments
formula = f"y ~ {controls} | wbcode2 | dem ~ {instruments}"

model = pf.feols(formula, data=df, vcov={"CRV1": "wbcode2"})
print("=== Python IV (pyfixest) ===")
print(model.summary())

# Extract
py_dem = model.coef()["dem"]
py_n = model._N

# Stata values
stata_dem = 1.1493847
stata_n = 6309

pct_diff = abs(stata_dem - py_dem) / abs(stata_dem) * 100
print(f"\n=== CROSS-VALIDATION ===")
print(f"  dem coefficient (2SLS):")
print(f"    Stata:  {stata_dem:.6f}")
print(f"    Python: {py_dem:.6f}")
print(f"    Diff:   {pct_diff:.4f}%")
print(f"    Status: {'PASS' if pct_diff < 0.1 else 'CHECK'}")
print(f"  N: Stata={stata_n}, Python={py_n}")

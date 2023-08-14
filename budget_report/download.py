import numpy as np
import pandas as pd

data = pd.read_html("http://127.0.0.1:8000/budget/detail/4220/", na_values=0, keep_default_na=False)


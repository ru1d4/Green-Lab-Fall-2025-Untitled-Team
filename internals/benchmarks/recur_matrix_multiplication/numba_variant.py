from numba import njit
from numba.typed import List as TypedList
import time

# --- Matrices ---
matrix_count_up = [
    [1, 2, 3, 4],
    [5, 6, 7, 8],
    [9, 10, 11, 12],
    [13, 14, 15, 16],
]

matrix_unordered = [
    [5, 8, 1, 2],
    [6, 7, 3, 0],
    [4, 5, 9, 1],
    [2, 6, 10, 14],
]

# --- Helper to build typed matrices once ---
def to_typed_matrix(matrix):
    tmat = TypedList()
    for row in matrix:
        trow = TypedList()
        for item in row:
            trow.append(item)
        tmat.append(trow)
    return tmat

typed_count_up = to_typed_matrix(matrix_count_up)
typed_unordered = to_typed_matrix(matrix_unordered)

# --- Core kernel (non-recursive triple loop) ---
@njit
def multiply_numba(a, b):
    rows_a = len(a)
    cols_a = len(a[0])
    rows_b = len(b)
    cols_b = len(b[0])

    result = TypedList()
    for i in range(rows_a):
        row = TypedList()
        for j in range(cols_b):
            row.append(0)
        result.append(row)

    for i in range(rows_a):
        for j in range(cols_b):
            s = 0
            for k in range(cols_a):
                s += a[i][k] * b[k][j]
            result[i][j] = s

    return result


for _ in range(50000):
    multiply_numba(typed_count_up, typed_unordered)
print(time.time())
for _ in range(50000):
    multiply_numba(typed_count_up, typed_unordered)

# matrix_multiply_recursive_vanilla.py
import time

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


def is_square(matrix):
    len_matrix = len(matrix)
    return all(len(row) == len_matrix for row in matrix)


def matrix_multiply_recursive(matrix_a, matrix_b):
    if not matrix_a or not matrix_b:
        return []
    if not all(
        (len(matrix_a) == len(matrix_b), is_square(matrix_a), is_square(matrix_b))
    ):
        raise ValueError("Invalid matrix dimensions")

    result = [[0] * len(matrix_b[0]) for _ in range(len(matrix_a))]

    def multiply(i_loop, j_loop, k_loop, matrix_a, matrix_b, result):
        if i_loop >= len(matrix_a):
            return
        if j_loop >= len(matrix_b[0]):
            return multiply(i_loop + 1, 0, 0, matrix_a, matrix_b, result)
        if k_loop >= len(matrix_b):
            return multiply(i_loop, j_loop + 1, 0, matrix_a, matrix_b, result)
        result[i_loop][j_loop] += matrix_a[i_loop][k_loop] * matrix_b[k_loop][j_loop]
        return multiply(i_loop, j_loop, k_loop + 1, matrix_a, matrix_b, result)

    multiply(0, 0, 0, matrix_a, matrix_b, result)
    return result


# --- Benchmark ---
for _ in range(50000):
    matrix_multiply_recursive(matrix_count_up, matrix_unordered)
print(time.time())
for _ in range(50000):
    matrix_multiply_recursive(matrix_count_up, matrix_unordered)

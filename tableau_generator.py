import numpy as np
import random

def generate_tableau(num_rows, num_cols, sparsity_factor=0.5):
    # Set the seed
    random.seed(532)
    np.random.seed(532)

    # Define empty tableau
    tableau = np.array([[]])
    
    # Generate OBJ ROW
    obj_row = np.random.rand(num_cols)
    obj_row = obj_row * 2000 - 1000
    obj_row[-1] = 0.0

    # Introduce sparsity into OBJ ROW
    zeroed_indices = random.sample(range(num_cols - 1), int(sparsity_factor*num_cols))
    obj_row[zeroed_indices[:-1]] = 0.0

    if (not (obj_row.any() < 0.0)):     # At least one entry in OBJ ROW must be negative
        obj_row[zeroed_indices[-1]] = obj_row[zeroed_indices[-1]] * -1

    tableau = np.append(tableau, obj_row)

    # Generate remaining rows
    for _ in range(num_rows - 1):
        new_row = np.random.rand(num_cols)
        new_row = new_row * 2000 - 1000
        new_row[-1] = new_row[-1] if (new_row[-1] > 0.0) else (-1 * new_row[-1])

        new_zeroed_indices = random.sample(range(num_cols - 1), int(sparsity_factor*num_cols))
        new_row[new_zeroed_indices] = 0.0

        tableau = np.append(tableau, new_row)

    # Reshape it into actual tableau shape
    tableau = tableau.reshape(num_rows, num_cols)

    return tableau

if __name__ == "__main__":
    generate_tableau(5, 5)

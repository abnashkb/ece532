#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Function defs
float** simplex(float** A, float* c, float* b, int m, int n);
float** create_matrix(int m, int n, float* data);
void free_matrix(float** A, int m);

void print_matrix(float** A, int m, int n);
void print_vector(float* A, int n);
// End of function defs

// VERIFIED
// This simplex implementation is a minimizer, so no need to invert objective function.
float** simplex(float** A, float* c, float* b, int m, int n) {
    // TODO: code assumes:
        // i. problem has feasible optimal solution - would be nice to have optimality checking code
        // ii. problem provided in standard form

    // A is an mxn matrix
    // c is a nx1 matrix - portray as vector in this code
    // b is a mx1 matrix - portray as vector in this code

    // Tableau general format is
    // [[concat(row 0 in A, element 0 in b)],
    //  [concat(row 1 in A, element 1 in b)],
    //  ...
    //  [concat(row m in A, element m in b)]]

    // Z variable general format is: [concat(c, 0)]]

    // Copy inputs to "construct tableau"
    float* z = (float*) malloc((n + 1) * sizeof(float));
    memcpy(z, c, n * sizeof(int));
    z[n] = 0.0;     // Last element is 0, see Z variable general format above

    float** tableau = (float**) malloc(m * sizeof(float*));
    
    for (int i = 0; i < m; i++) {
        tableau[i] = (float*) malloc((n + 1) * sizeof(float));    // Allocate n + 1 to each row in tableau, see tableau format above
        memcpy(tableau[i], A[i], n * sizeof(float));
        
        // Last element is ith element in b
        tableau[i][n] = b[i];
    }

    // Init optimality condition
    int optimal = -1;

    // TODO: compute pivot column_index in same for loop as optimality condition
    // Check for optimality
    while ((optimal != 1)) {
        // Assume optimal, then check if actually optimal
        optimal = 1;
        
        for (int i = 0; i < n; i++) {   // Optimality condition: all elements in z must be <= 0 (i.e. no room to improve)
            if (z[i] > 0.0) {
                optimal = -1;
                break;
            }
        }

        if (optimal == 1) break; // Found the optimal point

        // Get the pivot column: choose the first positive number in current z vector
        int column_index = -1;

        for (int i = 0; i < n; i++) {
            if (z[i] > 0.0) {
                column_index = i;
                break;
            }
        }

        // Calculate the restrictions on each row
        float* restrictions = (float*) malloc(m * sizeof(float));

        for (int i = 0; i < m; i++) {
            if (tableau[i][column_index] <= 0.0) {
                restrictions[i] = (float) 9999999999999.0;     // Basically positive infinity
            } else {
                restrictions[i] = (float) tableau[i][n] / tableau[i][column_index];
            }
        }

        // Get pivot row: choose the lowest value in restrictions vector
        int row_index = -1;
        float current_min = 9999999999999.0;

        for (int i = 0; i < m; i++) {
            if (restrictions[i] < current_min) {
                row_index = i;
                current_min = (float) restrictions[i];
            }
        }

        // Now that we have pivot column and pivot row, do the actual pivot operation
        float pivot_value = tableau[row_index][column_index];

        for (int i = 0; i < (n + 1); i++) {     // Update pivot row in tableau
            tableau[row_index][i] = (float) tableau[row_index][i] / pivot_value;
        }

        // Subtract multiplier value from all rows that are not pivot row
        for (int i = 0; i < m; i++) {
            if (i != row_index) {
                // For each row that isn't the pivot row, the operation is: row <- row - (row[pivot_column] * pivot_row)
                float curr_row_column_pivot_value = tableau[i][column_index];

                for (int j = 0; j < (n + 1); j++) {                
                    // Do the subtraction and update tableau
                    float multiplier = (float) tableau[row_index][j] * curr_row_column_pivot_value;
                    tableau[i][j] = (float) tableau[i][j] - multiplier;
                }
            }
        }

        // Also update z using the same method
        float z_column_pivot_value = z[column_index];

        for (int i = 0; i < (n + 1); i++) {
            float multiplier = (float) tableau[row_index][i] * z_column_pivot_value;
            z[i] = (float) z[i] - multiplier;
        }
    }
    
    // After we're done get solution, first we need to iterate over every column in matrix
    float* solution = (float*) malloc((n + 1) * sizeof(float));
    
    for (int col_iter = 0; col_iter < (n + 1); col_iter++) {
        float* curr_column = (float*) malloc((m + 1) * sizeof(float));
        
        // Curr_column = concat(column i of A, element i of Z)
        for (int row_iter = 0; row_iter < m; row_iter++) {
            curr_column[row_iter] = tableau[row_iter][col_iter];
        }

        curr_column[m] = z[col_iter];

        // Check if column is basic (i.e. column contains one element of value 1 and all other elements are 0)
        // In other words, column sum is 1, and the number of elements that are 0 is equal to the length of the column - 1
        float column_sum = 0.0;
        int column_zero_count = 0;
        int column_one_index = 0;

        for (int basis_iter = 0; basis_iter < (m + 1); basis_iter++) {
            if (curr_column[basis_iter] == 0.0) {
                column_zero_count += 1;
            }

            if (curr_column[basis_iter] == 1.0) {
                column_one_index = basis_iter;
            }

            column_sum += curr_column[basis_iter];
        }

        // Check basis satisfieability
        if ((column_sum == 1.0) && (column_zero_count == m)) {
            // We index the concat(tableau, z), where column_one_index picks out the rows, and we return the last index (i.e. n)
            // Would've been much easier if I just made the tableau table = concat(tableau, z) from the start but oh well
            if (column_one_index == m) solution[col_iter] = z[n];
            else solution[col_iter] = tableau[column_one_index][n];
        } else {
            solution[col_iter] = 0.0;
        }
    }

    printf("Simplex Solution [x_1, x_2, ..., x_n, 0.0]:\n");
    printf("Disregard the last element... artifact from merging tableau with Z variable during calculations and will always be zero if solution is optimal.\n\n");
    print_vector(solution, n + 1);
    printf("\n");
}

// VERIFIED
// Creates matrix of shape A=mxn with values in data where data is a vector of length mxn
float** create_matrix(int m, int n, float* data) {
    // Allocate rows
    float** A = (float**) malloc(m * sizeof(float*));

    // Allocate columns
    for (int i = 0; i < m; i++) {
        A[i] = (float*) malloc(n * sizeof(float));
    }

    // Fill with data
    for (int i = 0; i < m; i++) {
        for (int j = 0; j < n; j++) {
            if (data == NULL) A[i][j] = 0.0;
            else A[i][j] = data[i * n + j];
        }
    }

    return A;
}

/*********** HELPER FUNCS *********/
// Print matrix
void print_matrix(float** A, int m, int n) {
    for (int i = 0; i < m; i++) {
        for (int j = 0; j < n; j++) {
            printf("%f\t", A[i][j]);
        }
        printf("\n");
    }
    printf("\n");
}

// Print vector
void print_vector(float* A, int n) {
    for (int i = 0; i < n; i++) {
        printf("%f\t", A[i]);
    }
    printf("\n");
}

// Free mem
void free_matrix(float** A, int m) {
    for (int i = 0; i < m; i++) {
        free(A[i]);
    }
    free(A);
}

int main() {
    // Simplex Test 1

    // min 3x_1 + 2x_2 - x_3
    // s.t. x_1 - 2x_2 +  x_3 - x_4 = 0
    //      x_1 +  x_2 + 2x_3 - x_4 = 1
    //      x_1,   x_2,  x_3,  x_4 >= 0
    
    float** A_test;
    float* data_A_test = (float *) malloc(8 * sizeof(float));

    data_A_test[0] = 1;
    data_A_test[1] = -2;
    data_A_test[2] = 1;
    data_A_test[3] = -1;
    data_A_test[4] = 1;
    data_A_test[5] = 1;
    data_A_test[6] = 2;
    data_A_test[7] = -1;

    A_test = create_matrix(2, 4, data_A_test);

    float* c_test = (float *) malloc(4 * sizeof(float));
    
    c_test[0] = -3;
    c_test[1] = -2;
    c_test[2] = 1;
    c_test[3] = 0;

    float* b_test = (float *) malloc(2 * sizeof(float));
    
    b_test[0] = 0;
    b_test[1] = 1;

    // Solution should be x1 = 0, x2 = 0, x3 = 1, x4 = 1
    simplex(A_test, c_test, b_test, 2, 4); 

    /*// Simplex Test 2: Martin's problem

    float** A_test;
    float* data_A_test = (float *) malloc(24 * sizeof(float));

    data_A_test[0] = 1;
    data_A_test[1] = 0;
    data_A_test[2] = 0;
    data_A_test[3] = 1;
    data_A_test[4] = 0;
    data_A_test[5] = 0;
    
    data_A_test[6] = 0;
    data_A_test[7] = 1;
    data_A_test[8] = 0;
    data_A_test[9] = 0;
    data_A_test[10] = 1;
    data_A_test[11] = 0;

    data_A_test[12] = 0;
    data_A_test[13] = 0;
    data_A_test[14] = 1;
    data_A_test[15] = 0;
    data_A_test[16] = 0;
    data_A_test[17] = 1;

    data_A_test[18] = 1;
    data_A_test[19] = 1;
    data_A_test[20] = 1;
    data_A_test[21] = 0;
    data_A_test[22] = 0;
    data_A_test[23] = 0;

    A_test = create_matrix(4, 6, data_A_test);

    float* c_test = (float *) malloc(6 * sizeof(float));
    
    c_test[0] = 5;
    c_test[1] = 4;
    c_test[2] = 3;
    c_test[3] = 0;
    c_test[4] = 0;
    c_test[5] = 0;

    float* b_test = (float *) malloc(4 * sizeof(float));
    
    b_test[0] = 30;
    b_test[1] = 50;
    b_test[2] = 100;
    b_test[3] = 140;

    // Solution is x1 = x2 = x3 = 0 which is technically true becaue we cannot model a strict inequality (i.e. < or >)
    // without adding a small error term epsilon in the constraint equation
    simplex(A_test, c_test, b_test, 4, 6);*/

    /*// Simplex Test 3: Abnash Problem on Google Colab

    float** A_test;
    float* data_A_test = (float *) malloc(15 * sizeof(float));

    data_A_test[0] = 1;
    data_A_test[1] = 2;
    data_A_test[2] = 1;
    data_A_test[3] = 0;
    data_A_test[4] = 0;

    data_A_test[5] = 1;
    data_A_test[6] = 1;
    data_A_test[7] = 0;
    data_A_test[8] = 1;
    data_A_test[9] = 0;

    data_A_test[10] = 3;
    data_A_test[11] = 2;
    data_A_test[12] = 0;
    data_A_test[13] = 0;
    data_A_test[14] = 1;

    A_test = create_matrix(3, 5, data_A_test);

    float* c_test = (float *) malloc(5 * sizeof(float));
    
    c_test[0] = 40;
    c_test[1] = 30;
    c_test[2] = 0;
    c_test[3] = 0;
    c_test[4] = 0;

    float* b_test = (float *) malloc(3 * sizeof(float));
    
    b_test[0] = 16;
    b_test[1] = 9;
    b_test[2] = 24;

    // Solution is x1 = 6, x2 = 3, s1 = 4, same as Abnash's
    // without adding a small error term epsilon in the constraint equation
    simplex(A_test, c_test, b_test, 3, 5);*/
}

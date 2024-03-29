#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define debug 1
#define MAX_LINE_LEN 100

void print_matrix(int m, int n, float A[][n]) {
  for (int i = 0; i < m; i++) {
    for (int j = 0; j < n; j++) {
      printf("%f ", A[i][j]);
    }
    printf("\n");
  }
}

void display_soln(int m, int n, float A[][n], char* vars[]) {
  printf("\nfinal solution is:\n");
    for (int j = 0; j < n; j++) { //i in range(0, len(vars)): #iterate thru all vars
      float sum = 0;
      int flag_neg = 0;
      int one_row_idx = -1;
      for (int i = 0; i < m; i++) { //j in range(0, len(A)): #iterate thru all rows in that column
        if (A[i][j] < 0) {
          flag_neg = 1;
        }
        if (A[i][j] == 1) {
          one_row_idx = i;
        }
        sum = sum + A[i][j];
      }
      if ((!flag_neg) && (sum == 1)) {
        printf("%s  = %f\n", vars[j], A[one_row_idx][n-1]);
        //printf(str(vars[j]) + " = " + str(A[one_row_idx][-1]));
      }
    }
}

void simplex(int m, int n, float A[][n], char* vars[]) {
  //m is number of rows in array A
  //n is number of cols in array A
  //print all rows
  if (debug) {
      printf("STARTING SIMPLEX ON: \n");
      print_matrix(m, n, A);
  }

  int flag_soln = 1;
  int go = 0;
  while (1) {
    //look for pivot col
    go++;
    float biggest = 0;
    int pivot_col_idx = -1;
    for (int i = 0; i < n; i++) { //i in range(0, len(A[-1])): #iterate thru all cols
      if (A[m-1][i] < biggest) {
        biggest = A[m-1][i];
        pivot_col_idx = i;
      }
    }
    //check if pivot col found
    if (pivot_col_idx != -1) {
      if (debug) {
        printf("pivot element: %f\n", A[m-1][pivot_col_idx]); // print last row, elem in pivot_col_idx
      }
    } 
    else {
      if (debug) {
        printf("pivot col not found, exiting\n");
      }
      break; //leave while loop bc no pivot col found
    }
    //look for pivot row
    float smallest_non_neg_ratio = 9999999;
    int pivot_row_idx = -1;
    for (int i = 0; i < m-1; i++) { //i in range(0, len(A)-1): #iterate thru all rows but do not include last row bc is eqn to max
      if (A[i][pivot_col_idx] != 0) {  //ensure no div by zero
        float curr_ratio = A[i][n-1] / A[i][pivot_col_idx]; //last elem divided by elem of pivot row
        if ((curr_ratio < smallest_non_neg_ratio) && (curr_ratio >= 0)) {
          smallest_non_neg_ratio = curr_ratio;
          pivot_row_idx = i;
        }
      }
    }
    //check if pivot row found
    if (pivot_row_idx != -1) {
      if (debug) {
        printf("pivot row: " ); //print entire pivot row
        for (int i = 0; i < n; i++) {
            printf("%f ", A[pivot_row_idx][i]);
        }
        printf("\n");
      }
    }
    else {
      if (debug) {
        printf("pivot row not found, exiting\n");
      }
      flag_soln = 0;
      break; //leave while loop bc no pivot row found
    }

    //change pivot row to have 1 in pivot column entry
    float factor = A[pivot_row_idx][pivot_col_idx];
    for (int j = 0; j < n; j++) { //i in range(0, len(A[pivot_row_idx])): #iterate thru all cols
      A[pivot_row_idx][j] = A[pivot_row_idx][j] / factor;
    }
    //transform all other row to clear the entry in the pivot column
    for (int i = 0; i < m; i++) { //i in range(0, len(A)): #iterate thru all rows
      if (i != pivot_row_idx) { //do not apply to pivot row
        factor = A[i][pivot_col_idx] / A[pivot_row_idx][pivot_col_idx];
        for (int j = 0; j < n; j++) { //j in range(0, len(A[i])): #iterate thru all cols
          A[i][j] = A[i][j] - (factor * A[pivot_row_idx][j]);
        }
      }
    }

    if (debug) { //print all rows
      print_matrix(m, n, A);
    }
  }

  //out of loop, display solution
  if (!flag_soln) {
    printf("no solution possible: could not find pivot row with non-negative ratio");
  }
  else if (vars) {
    display_soln(m, n, A, vars); //display solution matrix
  }
}

int main(int argc, char *argv[]) {
  if (argc != 2) {
    printf("Error: must supply file name as input\n");
    return 1; //error return
  }

  char *filename = argv[1];
  FILE *fptr = fopen(filename, "r");
  if (fptr == NULL) {
    printf("Error: could not open file\n");
    return 1; //error return
  }

  //variables to help with reading lines
  char file_line[MAX_LINE_LEN];
  int num_rows = 0;
  int num_cols = 0;
  int file_row_cnt = 0;

  //read first line only
  fgets(file_line, sizeof(file_line), fptr);
  char *token = strtok(file_line, " ");
  num_rows = atoi(token);
  token = strtok(NULL, " ");
  num_cols = atoi(token);
  //create 2d array to store tableau
  float (*matrix)[num_cols] = malloc(sizeof(float[num_rows][num_cols]));
  
  //read other rows now
  while (fgets(file_line, sizeof(file_line), fptr)) {
    char *token = strtok(file_line, " "); //split at space
    int file_col_cnt = 0;
    while (token) {
      matrix[file_row_cnt][file_col_cnt] = atof(token);
      token = strtok(NULL, " ");
      file_col_cnt++;
    }
    printf("%s", file_line);
    file_row_cnt++;
  }
  printf("\n");
  printf("num_rows is: %d\n", num_rows);
  printf("num_cols is: %d\n", num_cols);
  print_matrix(num_rows, num_cols, matrix);


  printf("starting \n");
  //float A_test[][7] = {{1, 2, 1, 0, 0, 0, 16}, {1,1,0,1,0,0,9}, {3,2,0,0,1,0,24}, {-40,-30,0,0,0,1,0}};
  char* vars_test[] = {"x1", "x2", "s1", "s2", "s3", "P", "rhs"};

  //simplex(4, 7, A_test, vars_test);
  simplex(num_rows, num_cols, matrix, vars_test);
  //simplex(num_rows, num_cols, matrix, NULL); //if do not want to pass in char array of variable names

  printf("post algo\n");
  print_matrix(num_rows, num_cols, matrix);

  free(matrix);
  fclose(fptr);
  return 0;
}
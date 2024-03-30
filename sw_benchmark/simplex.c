#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/stat.h>
#include <stdint.h>

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
  //NOTE: only works with binary file input
  if (argc != 2) {
    printf("Error: must supply bin file names as input\n");
    return 1; //error return
  }

  char *binfilename = argv[1];

  //try using mmap to read file
  int fd = open(binfilename, O_RDONLY);
  if (fd == -1)
  {
    printf("Error: could not open file for reading\n");
    return 1;
  }

  //get file size
  struct stat st;
  if (fstat(fd, &st) == -1) {
      printf("Error: cannot get file size\n");
      close(fd);
      return 1;
  }

  //Use mmap to store file contents
  char* arr = mmap(NULL, st.st_size, PROT_READ, MAP_SHARED, fd, 0);
  if (arr == MAP_FAILED) {
    printf("Error: cannot map file to memory\n");
    close(fd);
    return 1;
  }

  //obtain num rows and num cols info
  int num_rows = arr[3];
  if (debug) printf("num_rows: %d\n", num_rows);
  int num_cols = arr[7];
  if (debug) printf("num_cols: %d\n", num_cols);

  close(fd); //can close file now

  //store into float array, going through every 4 bytes
  float (*floatArray)[num_cols] = malloc(sizeof(float[num_rows][num_cols]));
  int idx = 8;
  for (int i = 0; i < num_rows; i++) {
    for (int j = 0; j < num_cols; j++) {
      if (debug) {
        printf("arr[idx+3]: %x ", (uint32_t)arr[idx] & 0x000000ff);
        printf("%x ", (uint32_t)arr[idx+1] & 0x000000ff);
        printf("%x ", (uint32_t)arr[idx+2] & 0x000000ff);
        printf("%x\n", (uint32_t)arr[idx+3] & 0x000000ff);
      }
      uint32_t temp;
      temp  = ((uint32_t)arr[idx+3] & 0x000000ff);
      temp |= ( ((uint32_t)arr[idx+2] & 0x000000ff) << 8);
      temp |= ( ((uint32_t)arr[idx+1] & 0x000000ff) << 16);
      temp |= ( ((uint32_t)arr[idx] & 0x000000ff) << 24);
      memcpy(&floatArray[i][j], &temp, sizeof(float));
      //printf("%f \n", floatArray[i][j]);
      idx+=4;
    }
    //printf("\n");
  }

  if (debug) print_matrix(num_rows, num_cols, floatArray); //to test that input was parsed correctly

  if (munmap(arr, st.st_size) == -1) //done with mmap
  {
    printf("Error: could not unmmap\n");
    return 1;
  }

  printf("starting \n");
  //float A_test[][7] = {{1, 2, 1, 0, 0, 0, 16}, {1,1,0,1,0,0,9}, {3,2,0,0,1,0,24}, {-40,-30,0,0,0,1,0}};
  char* vars_test[] = {"x1", "x2", "s1", "s2", "s3", "P", "rhs"};

  //simplex(4, 7, A_test, vars_test);
  //simplex(num_rows, num_cols, floatArray, vars_test);
  simplex(num_rows, num_cols, floatArray, NULL); //if do not want to pass in char array of variable names

  printf("post algo\n");
  print_matrix(num_rows, num_cols, floatArray);

  free(floatArray);
  return 0;
}
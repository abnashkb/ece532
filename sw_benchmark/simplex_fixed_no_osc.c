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

#define debug 0

//for benchmarking ECE532 project 

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
    for (int j = 0; j < n-1; j++) { //i in range(0, len(vars)): #iterate thru all vars
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

void store_soln (int m, int n, float A[][n], char* outfile) {
  //go through each column in output, each col corresponds to a variable
  //if the col has only one 1 and rest are all zeroes, use the row with the 1 to index into last column
  //if the col does NOT have only one 1 and rest zeroes, then assume 0
  //store values as we go into output txt file as ascii values, separated by spaces

  FILE *file_ptr = fopen(outfile, "w");
  if (file_ptr == NULL) {
    printf("Error: could not open store_soln output file\n");
    exit(1);
  }

  for (int j = 0; j < n-1; j++) { //i in range(0, len(vars)): #iterate thru all vars
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
      //printf("%s  = %f\n", vars[j], A[one_row_idx][n-1]);
      fprintf(file_ptr, "%f ",  A[one_row_idx][n-1]);
    }
    else {
      fprintf(file_ptr, "%f ", 0.0);
    }
  }
  fprintf(file_ptr, "%f ",  A[0][n-1]);

  fclose(file_ptr);
  printf("Successfully stored results into output txt file\n");
}

void simplex(int m, int n, float A[][n], char* vars[]) {
  //m is number of rows in array A
  //n is number of cols in array A
  //print all rows
  if (debug) {
      printf("STARTING SIMPLEX ON: \n");
      print_matrix(m, n, A);
  }

  FILE *file_ptr = fopen("simplex_tab_4_debug", "w");
  if (file_ptr == NULL) {
    printf("Error: could not open simplex debug output file\n");
    exit(1);
  }

  fprintf(file_ptr, "pre-algo objective row: ");
  for (int j = 0; j < n; j++) {
    fprintf(file_ptr, "%f ", A[0][j]);
  }
  fprintf(file_ptr, "\n");

  fprintf(file_ptr, "pre-algo RHS COL: ");
  for (int i = 0; i < m; i++) {
    fprintf(file_ptr, "%f ", A[i][n-1]);
  }
  fprintf(file_ptr, "\n");

  fprintf(file_ptr, "pre-algo last row: ");
  for (int j = 0; j < n; j++) {
    fprintf(file_ptr, "%f ", A[m-1][j]);
  }
  fprintf(file_ptr, "\n");

  /*FILE *file_ptr_spec = fopen("simplex_debug_spec.txt", "w");
  if (file_ptr_spec == NULL) {
    printf("Error: could not open store_soln output file\n");
    exit(1);
  }

  fprintf(file_ptr_spec, "test\n");
  fclose(file_ptr_spec); */

  int flag_soln = 1;
  int go = 0;
  int two_iter_ago_piv_col_idx = -1;
  int two_iter_ago_piv_row_idx = -1;
  int one_iter_ago_piv_col_idx = -1;
  int one_iter_ago_piv_row_idx = -1;
  int prev_fail_pivot_col_idx = -1;
  while (1) {
    //look for pivot col
    float biggest = 0;
    int pivot_col_idx = -1;
    for (int i = 0; i < n; i++) { //i in range(0, len(A[-1])): #iterate thru all cols
      //if ((A[0][i] < biggest) && (two_iter_ago_piv_col_idx != i) && (one_iter_ago_piv_col_idx != i)) {
      if ((A[0][i] < 0) && (prev_fail_pivot_col_idx < i)) {
        biggest = A[0][i];
        pivot_col_idx = i;
        break; //adding for bland's rule
      }
    }
    //check if pivot col found
    if (pivot_col_idx != -1) {
      if (debug) {
        printf("pivot_col_idx: %d\n", pivot_col_idx);
        printf("pivot element: %f\n", A[0][pivot_col_idx]); // print first row, elem in pivot_col_idx
        //if ((go > 300) && (go < 305)) {
          //if ((go > 185) && (go < 200)) {
          // fprintf(file_ptr, "objective row on iteration %d: ", go);
          // //printf("pivot row: " ); //print entire objective row
          // for (int i = 0; i < n; i++) {
          //     fprintf(file_ptr, "%f ", A[0][i]);
          // }
          // fprintf(file_ptr, "\n");
          // //}
      }
    } 
    else {
      //if (debug) {
        printf("pivot col not found, exiting\n");
      //}
      break; //leave while loop bc no pivot col found
    }
    //look for pivot row
    float smallest_non_neg_ratio = 9999999;
    int pivot_row_idx = -1;
    for (int i = 1; i < m; i++) { //i in range(0, len(A)-1): #iterate thru all rows but do not include first row bc is eqn to max
      //if (A[i][pivot_col_idx] != 0) {  //ensure no div by zero
      if (A[i][pivot_col_idx] > 0) {  //ensure no div by zero, and is pos value
        float curr_ratio = A[i][n-1] / A[i][pivot_col_idx]; //last elem divided by elem of pivot row
        //if ((curr_ratio < smallest_non_neg_ratio) && (curr_ratio > 0) && (two_iter_ago_piv_row_idx != i) && (one_iter_ago_piv_row_idx != i)) {
        if ((curr_ratio < smallest_non_neg_ratio)) { //&& (two_iter_ago_piv_row_idx != i) && (one_iter_ago_piv_row_idx != i)) {
          smallest_non_neg_ratio = curr_ratio;
          pivot_row_idx = i;
        }
      }
    }


  //this block is testing alt github repo of open src simplex -- ignore
  /*int skip = 0;
  int pivot_row_idx = -1;
  float min_ratio = 0;
  for (int i = 1; i < m; i++) {
    if ((A[i][pivot_col_idx] != 0) && (A[i][n-1]/A[i][pivot_col_idx] > 0)) {
      skip = i;
      pivot_row_idx = i;
      min_ratio = A[i][n-1]/A[i][pivot_col_idx];
      break;
    }
  }
  if (min_ratio > 0) {
    for (int i = 1; i < m; i++) {
      if ((i > skip) && (A[i][pivot_col_idx])) {
        float ratio = A[i][n-1]/A[i][pivot_col_idx];
        if (min_ratio > ratio) {
          min_ratio = ratio;
          pivot_row_idx = i;
        }
      }
    }
  }*/

    if ((go > 300) && (go < 305)) {
      fprintf(file_ptr, "on iteration %d got obj row @ colidx %d as %f and pivot row @ col_idx %d as %f \n", go, 2227, A[0][2227], 2227, A[pivot_row_idx][2227]);
    }

    if ( ((two_iter_ago_piv_col_idx == pivot_col_idx) && (two_iter_ago_piv_row_idx == pivot_row_idx)) ) { //|| (go > 10) ){
      printf("cycle detected, leaving on iteration %d\n", go);
      break;
    }
    else {
      two_iter_ago_piv_col_idx = one_iter_ago_piv_col_idx;
      two_iter_ago_piv_row_idx = one_iter_ago_piv_row_idx;
      one_iter_ago_piv_col_idx = pivot_col_idx;
      one_iter_ago_piv_row_idx = pivot_row_idx;
    }

    //check if pivot row found
    if (pivot_row_idx != -1) {
      //printf("pivot_row_idx: %d\n", pivot_row_idx);
      prev_fail_pivot_col_idx = -1; //reset this
       //if ((go > 300) && (go < 305)) {
        //if ((go > 185) && (go < 200)) {
      //    fprintf(file_ptr, "pivot row on iteration %d: ", go);
      //     //printf("pivot row: " ); //print entire pivot row
      //     for (int i = 0; i < n; i++) {
      //         fprintf(file_ptr, "%f ", A[pivot_row_idx][i]);
      //     }
      //     fprintf(file_ptr, "\n");
      // //}
    }
    else {
      if (debug) {
        printf("pivot row not found, try again\n"); //exiting\n");
      }
      flag_soln = 0;
      go++;
      prev_fail_pivot_col_idx = pivot_col_idx;
      continue;
      //break; //leave while loop bc no pivot row found
    }

    //pivot row and pivot col found, write raw data for debug

    //change pivot row to have 1 in pivot column entry
    float factor = A[pivot_row_idx][pivot_col_idx];
    //printf("factor: %f\n", factor);
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

    /*if (debug) { //print all rows
      print_matrix(m, n, A);
    }*/

    //printf("Iteration # %d\n", go);
    go++;
  }

  //out of loop, display solution
  if (!flag_soln) {
    //printf("no solution possible: could not find pivot row with non-negative ratio");
  }
  fclose(file_ptr);
  //fclose(file_ptr_spec);
  /*else if (vars) {
    display_soln(m, n, A, vars); //display solution matrix
  }*/
}

int main(int argc, char *argv[]) {
  //NOTE: only works with binary file input
  if (argc != 2) {
    //printf("Error: must supply bin file names as input\n");
    return 1; //error return
  }

  char *binfilename = argv[1];

  //try using mmap to read file
  int fd = open(binfilename, O_RDONLY);
  if (fd == -1)
  {
    //printf("Error: could not open file for reading\n");
    return 1;
  }

  //get file size
  struct stat st;
  if (fstat(fd, &st) == -1) {
      //printf("Error: cannot get file size\n");
      close(fd);
      return 1;
  }

  //Use mmap to store file contents
  char* arr = mmap(NULL, st.st_size, PROT_READ, MAP_SHARED, fd, 0);
  if (arr == MAP_FAILED) {
    //printf("Error: cannot map file to memory\n");
    close(fd);
    return 1;
  }

  //obtain num rows and num cols info
  int num_rows = (((uint32_t)arr[2] & 0x000000ff) << 8) | (((uint32_t)arr[3]) & 0x000000ff); //arr[3];
  // printf("raw 0: %x ", (uint32_t)arr[0]);
  // printf("raw 1: %x ", (uint32_t)arr[1]);
  // printf("raw 2: %x ", (((uint32_t)arr[2] & 0x000000ff) << 8) | ((uint32_t)arr[3]) & 0x000000ff);
  //printf("raw 2: %x ", ((uint32_t)arr[2] & 0x000000ff << 8) | (uint32_t)arr[3]);
  // printf("raw 3: %x ", (uint32_t)arr[3]);
  //printf("num_rows: %d\n", num_rows);
  int num_cols = (((uint32_t)arr[6] & 0x000000ff) << 8) | (((uint32_t)arr[7]) & 0x000000ff); //arr[7];
  //printf("num_cols: %d\n", num_cols);

  close(fd); //can close file now

  //store into float array, going through every 4 bytes
  float (*floatArray)[num_cols] = malloc(sizeof(float[num_rows][num_cols]));
  int idx = 8;
  for (int i = 0; i < num_rows; i++) {
    for (int j = 0; j < num_cols; j++) {
      /*if (debug) {
        printf("arr[idx+3]: %x ", (uint32_t)arr[idx] & 0x000000ff);
        printf("%x ", (uint32_t)arr[idx+1] & 0x000000ff);
        printf("%x ", (uint32_t)arr[idx+2] & 0x000000ff);
        printf("%x\n", (uint32_t)arr[idx+3] & 0x000000ff);
      }*/
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

  //if (debug) print_matrix(num_rows, num_cols, floatArray); //to test that input was parsed correctly

  if (munmap(arr, st.st_size) == -1) //done with mmap
  {
    printf("Error: could not unmmap\n");
    return 1;
  }

  if (debug) printf("starting \n");
  //float A_test[][7] = {{1, 2, 1, 0, 0, 0, 16}, {1,1,0,1,0,0,9}, {3,2,0,0,1,0,24}, {-40,-30,0,0,0,1,0}};
  char* vars_test[] = {"x1", "x2", "s1", "s2", "s3", "P", "rhs"}; //this only works for the specific A_test above
  //float A_test[][9] = {{1, 0, 0, 1, 0, 0, 0, 0, 30}, {0, 1, 0, 0, 1, 0, 0, 0, 50}, {0, 0, 1, 0, 0, 1, 0, 0, 100}, {1, 1, 1, 0, 0, 0, 1, 0, 140}, {-5, -4, -3, 0, 0, 0, 0, 1, 0}};
  // float A_test[][5] = {{-182.25113024, 0, -344.18565274, -642.02206979, 0},
  // {  0, 0, 544.6711869, -500.48610241,491.641967},
  // {492.14078421, 0, 342.29704643, 0,735.17622824},
  // {0, -529.67798793, 0, -347.63074464,486.47907179},
  // {0, 634.52135017, 83.53429165, 0., 334.74151821}};

//   float A_test[][5] = {{-182.25113024, 0., -344.18565274, -642.02206979,    0.        },
//  {   0. ,           0.  ,        772.33559345 , 249.7569488,   745.8209835 },
//  { 746.07039211 ,   0.   ,       671.14852322  ,  0.       ,   132.41188588},
//  {   0.    ,      235.16100604  ,  0.    ,      326.18462768  ,256.76046411},
//  {   0.    ,      817.26067508 , 541.76714583 ,   0.     ,     667.37075911}};


  //ignore: for testing
  //simplex(4, 7, A_test, vars_test);
  //simplex(5, 9, A_test, NULL);
  //simplex(num_rows, num_cols, floatArray, vars_test);
  //simplex(5, 5, A_test, NULL);

  simplex(num_rows, num_cols, floatArray, NULL); //if do not want to pass in char array of variable names

  if (debug) {
    printf("done algo\n");
    //print_matrix(num_rows, num_cols, floatArray);
    //print_matrix(5, 5, A_test);
  }

  /*** START storing output into file ***/
  //remove file extension
  char *ptr_new_end = strrchr(binfilename, '.'); //find the last occurrence of '.'
  if (ptr_new_end != NULL) {
    *ptr_new_end = '\0'; //Null-terminate the string at the position of the last '.'
  }
  char* append_str = "_out.txt";
  char* out_file_name = malloc(strlen(binfilename) + strlen(append_str) + 1);
  if (out_file_name == NULL) {
      printf("Error: malloc failed\n");
      exit(1);
  }
  strcpy(out_file_name, binfilename); //to keep binfilename preserved, copy into new char*
  strcat(out_file_name, append_str); //tack on _out.txt to file name
  store_soln(num_rows, num_cols, floatArray, out_file_name); //generate the output file
  //store_soln(5, 5, A_test, "manual_5x5.txt");

  /*** END storing output into file ***/


  //ignore: for testing //store_soln(5, 9, A_test, out_file_name); //generate the output file

  // //try writing to output bin file
  // const char *filename = "output.bin";

  //   // Open the output file
  //   fd = open(filename, O_RDWR | O_CREAT, S_IRUSR | S_IWUSR);
  //   if (fd == -1) {
  //       printf("Error: could not open file\n");
  //       return 1;
  //   }

  //   // Adjust the file size to accommodate the data
  //   off_t file_size = sizeof(float) * num_rows * num_cols;
  //   if (ftruncate(fd, file_size) == -1) {
  //       printf("Error: could not truncate file\n");
  //       close(fd);
  //       return 1;
  //   }

  //   // Map the file into memory
  //   float *mapped_data = (float *)mmap(NULL, file_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
  //   if (mapped_data == MAP_FAILED) {
  //       printf("Error mapping file");
  //       close(fd);
  //       return 1;
  //   }

  //   // Write the float array into the memory-mapped region
  //   int write_counter = 0;
  //   for (int i = 0; i < num_rows; i++) {
  //     for (int j = 0; j < num_cols; j++) {
  //       mapped_data[write_counter] = floatArray[i][j];
  //       write_counter++;
  //     }
  //   }

  //   // Unmap the memory and close the file
  //   if (munmap(mapped_data, file_size) == -1) {
  //       printf("Error unmapping file");
  //       close(fd);
  //       return 1;
  //   }

  //   close(fd);

  //   printf("Float array has been written to %s\n", filename);

  //cleanup
  free(floatArray);
  free(out_file_name);
  return 0;
}
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
  if (argc != 3) {
    printf("Error: must supply both txt and bin file names as input\n");
    return 1; //error return
  }

  char *filename = argv[1];
  char *binfilename = argv[2];
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

  //try using mmap to read file
  int fd = open(binfilename, O_RDONLY);

  if (fd == -1)
  {
    printf("Error opening file for reading\n");
    return 1;
}

  int pagesize = getpagesize();
  struct stat st;
  printf("pagesize: %d\n", pagesize);

  if (fstat(fd, &st) == -1) {
      printf("Error: cannot get file size\n");
      close(fd);
      return 1;
  }

  int status = stat(binfilename, &st);

  // Map the file into memory
  //float* floatArray = mmap(NULL, st.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
  //float* floatArray = (float *) mmap(NULL, st.st_size, PROT_READ, MAP_SHARED, fd, 0);
  char* arr = mmap(NULL, st.st_size, PROT_READ, MAP_SHARED, fd, 0);
  if (arr == MAP_FAILED) {
    printf("Error: cannot map file to memory\n");
    close(fd);
    return 1;
  }

  size_t numFloats = st.st_size / sizeof(char); //sizeof(float);
  printf("sizeof(float):%d\n", sizeof(float));

  // Print the byte values
  printf("Hex values read from file:\n");
  for (size_t i = 0; i < numFloats; i++) {
      //float val = arr[i];
      //float val = floatArray[i];
      printf("%x ", arr[i]);
  }

  int num_rows_from_bin = arr[3];
  printf("num_rows_from_bin: %d\n", num_rows_from_bin);
  int num_cols_from_bin = arr[7];
  printf("num_cols_from_bin: %d\n", num_cols_from_bin);

  close(fd);

  union IntFloat {  int32_t i;  float f;  }; //Declare combined datatype for HEX to FLOAT conversion
  union IntFloat valUnion; 

  printf("floats each 4 bytes:\n");
  float (*floatArray)[num_cols_from_bin] = malloc(sizeof(float[num_rows_from_bin][num_cols_from_bin]));
  int idx = 8;
  for (int i = 0; i < num_rows_from_bin; i++) {
    for (int j = 0; j < num_cols_from_bin; j++) {
      printf("arr[idx+3]: %x ", (uint32_t)arr[idx] & 0x000000ff);
      printf("%x ", (uint32_t)arr[idx+1] & 0x000000ff);
      printf("%x ", (uint32_t)arr[idx+2] & 0x000000ff);
      printf("%x\n", (uint32_t)arr[idx+3] & 0x000000ff);
      uint32_t temp;
      temp  = ((uint32_t)arr[idx+3] & 0x000000ff);
      temp |= ( ((uint32_t)arr[idx+2] & 0x000000ff) << 8);
      temp |= ( ((uint32_t)arr[idx+1] & 0x000000ff) << 16);
      temp |= ( ((uint32_t)arr[idx] & 0x000000ff) << 24);
      memcpy(&floatArray[i][j], &temp, sizeof(float));
      printf("%f \n", floatArray[i][j]);
      //printf("%f ", 0x40400000);
      float val;
      memcpy(&val, &temp, sizeof(val));
      //rintf("\nsingle fp: %f\n", val);

      valUnion.i = temp; 
      //printf("\nFloat: %f\n", valUnion.f); 


      idx+=4;
    }
    printf("\n");
  }

  print_matrix(num_rows_from_bin, num_cols_from_bin, floatArray);

  /*for (size_t i = 8; i < numFloats; i+=4) {
      float val = arr[i]; //floatArray[i];
      //float val = floatArray[i];
      printf("%f ", val);
      //printf("%f\n", floatArray[i]);
      //printf("%02X ", ((unsigned char *)floatArray)[i]);
      //printf("%02X ", ((float*)floatArray)[i]);
  } */

  // Read the data into an array of floats
  float *data = (float *)floatArray;
  float float_buffer[numFloats];
  for (int i = 0; i < numFloats; i++) {
      float_buffer[i] = data[i];
  }
  // Display the first few floats as an example
  printf("First few floats:\n");
  for (int i = 0; i < 10; i++) {
      printf("%f\n", float_buffer[i]);
  }

  if (munmap(arr, st.st_size) == -1)
  {
    printf("Error: could not unmmap\n");
    return 1;
  }

  //try fread on bin file
  //unsigned char buffer[4];
  int size = 100;
  char buffer[size];
  FILE *ptr;

  ptr = fopen(binfilename,"rb");  // r for read, b for binary

  fread(buffer,sizeof(buffer),1,ptr); // read 10 bytes to our buffer
  printf("try fread on bin file:\n");
  for(int i = 0; i<size-1; i++)
    printf("%x ", buffer[i]); // prints a series of bytes

  //buffer[4] = '\0'; 
  //printf("Buffer: %x\n", buffer[0]);

  //get row and col info from binary stream
  /*int num_rows_from_bin = buffer[3];
  printf("num_rows_from_bin: %d\n", num_rows_from_bin);
  int num_cols_from_bin = buffer[7];
  printf("num_cols_from_bin: %d\n", num_cols_from_bin);*/

  //this works! tested with convert.bin:
  uint32_t temp;
  float val;
  temp  = (uint32_t)buffer[3];
  temp |= (uint32_t)buffer[2] << 8;
  temp |= (uint32_t)buffer[1] << 16;
  temp |= (uint32_t)buffer[0] << 24;
  memcpy(&val, &temp, sizeof(val));
  printf("\nsingle fp: %f\n", val);
  
  idx = 20;
  temp  = ((uint32_t)buffer[idx+3]);
  temp |= ((uint32_t)buffer[idx+2] << 8);
  temp |= (((uint32_t)buffer[idx+1] << 16));
  temp |= (((uint32_t)buffer[idx] << 24));
  memcpy(&val, &temp, sizeof(val));
  printf("\nsingle fp: %f\n", val);


  uint32_t num;
  float f;
  char myString[2];
  strncpy (myString, buffer, 2);
  //myString[2] = '\0';   /* null character manually added */
  //printf("\n%x\n", myString);
  //printf("\n%x\n", buffer);*/
  //char myString[]="0x40400000";
  sscanf(myString, "%x", &num);  // assuming you checked input
  f = *((float*)&num);
  printf("the hexadecimal 0x%08x becomes %.3f as a float\n", num, f); 

  unsigned int hex;
  const char *hex_str = "40490FDB";
  //*buffer = "40490FDB";
  sscanf(buffer,"%X",&hex);
  float hex_to_float;
  *((unsigned int *)&hex_to_float) = hex;
  // Output the result
  printf("Hexadecimal: %s\n", buffer);
  printf("Float: %f\n", hex_to_float);

  printf("%f\n",f);
  printf("%d", buffer[0]);


  //unsigned char* data = mmap((caddr_t)0, pagesize, PROT_READ, MAP_SHARED, fptr, pagesize);

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
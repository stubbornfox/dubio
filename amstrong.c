#include <stdio.h>

void build_possible_worlds(int arr_of_alternatives[], int n)
{
  int indices[n];
  for(int i=0;i<n;i++)
  {
      indices[i]=0;
  }

  while (1) {

    // print current combination
    for (int i = 0; i < n; i++)
      printf("%d", indices[i]);

    printf("\n");

    // find the rightmost array that has more
    // elements left after the current element
    // in that array
    int next = n - 1;
    while (next >= 0 &&
          (indices[next] + 1 >= arr_of_alternatives[next]))
        next--;

    // no such array is found so no more
    // combinations left
    if (next < 0)
        return;

    // if found move to next element in that
    // array
    indices[next]++;

    // for all arrays to the right of this
    // array current index again points to
    // first element
    for (int i = next + 1; i < n; i++)
        indices[i] = 0;
    }
}


int main()
{
  int n = 10;
  int arr_of_alternatives[]= {4,4,4,4,4,4,4,4,4,4};
  build_possible_worlds(arr_of_alternatives, n);
}



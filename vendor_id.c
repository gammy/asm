/* Ugly code to get vendor id string on x86 processors.
 * gcc -m32 -Wa,-32 vendor_id.c */

#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[]) {

  unsigned char vendor_id[13] = "no idea mate";
  unsigned int id[3];
  unsigned int cpuid_missing = 0;

  #ifndef __x86_64
  /* The cpuid instruction exists if we can
     change the value of bit 21(ID) in EFLAGS (486+) */
  asm (
      "pushfl\n"               // push EFLAGS
      "popl %%eax\n"
      "movl %%eax, %%ecx\n"    // copy to ecx
      "xorl $0x200000, %%ecx\n"// flip ID bit in copy
      "pushl %%ecx\n"
      "popfl\n"
      "pushfl\n"               // push new EFLAGS
      "popl %%eax\n"
      "xorl %%ecx, %%eax\n"    // !0 if cpuid is missing
      :"=a" (cpuid_missing)
      : // No input
      : "ecx"
  );

  if(cpuid_missing != 0) {
    fprintf(stderr, "cpuid instruction not available on this machine.\n");
    return(EXIT_FAILURE);
  }
  #endif

  asm(
      "xor %%ebx, %%ebx\n"
      "xor %%ecx, %%ecx\n"
      "xor %%edx, %%edx\n"
      "mov $0, %%eax\n"
      "cpuid"
      :"=b" (id[0]), "=c" (id[1]), "=d" (id[2])
  );

  printf("ebx: %x\necx: %x\nedx: %x\n", id[0], id[1], id[2]);

  int i, j, o;
  int idx[3] = {0, 2, 1};

  o = 0;
  for(i = 0; i < 3; i++)
    for(j = 0; j < 4; j++)
      vendor_id[o++] = id[idx[i]] >> (j * 8);

  printf("Vendor id: \"%s\"\n", vendor_id);

  return(EXIT_SUCCESS);
}


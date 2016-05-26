/* This is a program that takes parameters and encrypts Ascii Uppercase
and lowercase letters to LEET */

  #include <stdio.h>
  char *leet(char *str);

int main(__attribute__((unused))int ac, char **av) {
  printf("%s", leet(av[0]));
  return (0);
}

  char leetchar(char c) {
    switch (c) {
      case 'a':
      case 'A':
        return ('4');
      break;
      case 'b':
      /* case 'B':
        return ('I3');
      break; */
      case 'c':
      case 'C':
        return ('(');
      break;
      case 'd':
      case 'D':
        return ('D');
      break;
      case 'e':
      case 'E':
        return ('E');
      case 'f':
      /* case 'F':
        return ('pH');
      break; */
      case 'g':
      case 'G':
        return ('9');
      break;
      case 'h':
      /* case 'H':
        return ('|-|');
      break; */
      case 'i':
      case 'I':
        return ('1');
      break;
      case 'j':
      case 'J':
        return ('j');
      break;
      case 'k':
      /* case 'K':
        return ('|<');
      break; */
      case 'l':
      case 'L':
        return ('L');
      break;
      case 'm':
      /* case 'M':
        return ('/\/\');
      break; */
      case 'n':
      /* case 'N':
        return ('|\|');
      break; */
      case 'o':
      case 'O':
        return ('0');
      case 'p':
      case 'P':
        return ('p');
        break;
      case 'q':
      case 'Q':
        return ('Q');
        break;
      case 'r':
      case 'R':
        return ('r');
        break;
      case 's':
      case 'S':
        return ('$');
        break;
      case 't':
      case 'T':
        return ('7');
      case 'u':
      case 'U':
        return ('U');
        break;
      case 'v':
      /* case 'V':
        return ('\/');
        break; */
      case 'w':
      /* case 'W':
        return ('\/\/');
        break; */
      case 'x':
      /* case 'X':
        return ('><');
        break; */
      case 'y':
      /* case 'Y':
        return (''/');
        break; */
      case 'z':
      case 'Z':
        return ('Z');
          break;
      default:
        return (c);
    }
  }

  char *leet(char *str) {
    char * ret = str;
    while (*str != 0) {
      *str = leetchar(*str);
      str++;
    }
    return (ret);
  }

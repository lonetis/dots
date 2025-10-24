import { FromKeyParam } from 'karabiner.ts'

function de_key(key: string | number): FromKeyParam {
  switch (key) {
    case '^':
      return 'non_us_backslash' as FromKeyParam
    case 'ß':
      return 'hyphen' as FromKeyParam
    case '´':
      return 'equal_sign' as FromKeyParam
    case 'z':
      return 'y' as FromKeyParam
    case 'ü':
      return 'open_bracket' as FromKeyParam
    case '+':
      return 'close_bracket' as FromKeyParam
    case 'ö':
      return 'semicolon' as FromKeyParam
    case 'ä':
      return 'quote' as FromKeyParam
    case '#':
      return 'backslash' as FromKeyParam
    case '<':
      return 'grave_accent_and_tilde' as FromKeyParam
    case 'y':
      return 'z' as FromKeyParam
    case ',':
      return 'comma' as FromKeyParam
    case '.':
      return 'period' as FromKeyParam
    case '-':
      return 'slash' as FromKeyParam
    default:
      return key as FromKeyParam
  }
}

export default de_key

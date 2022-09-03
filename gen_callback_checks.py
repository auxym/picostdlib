import sys
import re

pat = r"^template (\w+Callback)"
pat_comment = r"^( )+#"

def gencheck(template_name):
    ctvar = template_name
    ctvar = "called" + ctvar[0].upper() + ctvar[1:]
    decl = f"var {ctvar} {{.compileTime.}} = false\n"
    check = f"""\
  static: 
    when {ctvar}:
      {{.error: "called {template_name} twice".}}
    {ctvar} = true
"""
    return (decl, check)

with open(sys.argv[1]) as f:
    check = None
    for line in f:
        if check and not re.match(pat_comment, line):
            sys.stdout.write(check)
            check = None
        m = re.match(pat, line)
        if m:
            tname = m.group(1)
            decl, check = gencheck(tname)
            sys.stdout.write(decl)
        sys.stdout.write(line)

{Jison} = require('jison')

grammar =
    comment: "Zompist Sound Generator"
    author: "Scott Stephens"
    lex:
        rules: [
            ["[^\\n\\S]+",  "/* skip whitespace */"]
            #["[^=\/|\s]+", "return 'SYM';"]
            ["[^=\\s]+",    "return 'SYM';"]
            ["=",           "return '=';"]
            #["/",          "return '/';"]
            #["|",          "return '|';"]
            #["\\n",         "return 'EOL';"]
            #["<<EOF>>",     "return 'EOF';"]
        ]
    tokens: "= SYM"
    startSymbol: 'sound'
    bnf:
        sound:      [["cat", "{$$=$1;}"]]
        cat:        [["SYM = SYM", "{$$ = {name:$1,symbols:$3}}"]]
        #rule:    [["SYM '/' SYM '/' SYM EOL", "{$$ = new Rule($1,$3,$5)}"]]
        #rewrite: [["SYM '|' SYM EOL", "{$$ = new Rewrite($1,$3);}"]]

gen = new Jison.Generator grammar,
  type: 'slr'
  moduleType: 'js'
  moduleName: 'sounds'

parser = gen.createParser()
console.log parser

source = """
V=aeiou
C=ptcqbdgmnlrhs
F=ie
B=ou
S=ptc
Z=bdg
"""

lines = source.split('\n')
for line in lines
    console.log parser.parse(line)

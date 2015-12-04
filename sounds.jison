%lex
%%

[^\n\S]+            /* skip whitespace */
[^=/|\s]+           return 'SYM';
'='                 return '=';
'/'                 return '/';
'|'                 return '|';
\n                  return 'EOL';
<<EOF>>             return 'EOF';

/lex

%start  sounds

%%

sounds : sound* EOF
    {
        var o;
        $$ = {cats: {}, rules: [], rewrites: []};
        for (o in $1) {
            var obj = $1[o];
            if (obj instanceof Cat) {
                $$.cats[obj.name] = obj.symbols;
            }
            else if (obj instanceof Rule) {
                $$.rules.push(obj);
            }
            else if (obj instanceof Rewrite) {
                $$.rewrites.push(obj);
            }
        }
    }
    ;

sound
    :   cat     {$$=$1}
    |   rule    {$$=$1}
    |   rewrite {$$=$1}
    ;

cat     :   SYM '=' SYM EOL             {$$ = new Cat($1,$3)}       ;
rule    :   SYM '/' SYM '/' SYM EOL     {$$ = new Rule($1,$3,$5)}   ;
rewrite :   SYM '|' SYM EOL             {$$ = new Rewrite($1,$3);}  ;

%%
function Cat(name, symbols) {
    this.name = name;
    this.symbols = symbols;
}

function Rule(tgt, repl, pat) {
    this.tgt = tgt;
    this.repl = repl;
    this.pat = pat;
}

function Rewrite(before, after) {
    this.before = before;
    this.after = after;
}

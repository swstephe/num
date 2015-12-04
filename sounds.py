"""
Sound Change Applier

SOUNDS.C

Sound Change Applier

Copyright (C) 2000 by Mark Rosenfelder.
This program may be freely used and modified for non-commercial purposes.

See http://www.zompist.com/sounds.htm for documentation.
"""
#import argparse

PRINT_RULES = True
#MAXRULE = 200
#MAXCAT  = 50

Rule = []
Cat = []

def ReadRules(filestart):
    """
    ReadRules

    Read in the rules file *.sc for a given project.

    There are two types of rules: sound changes and category definitions.
    The former are stored in Rule[], the latter in Cat[].

    The format of these rules is given under Transform().
    """
    global Rule, Cat
    Rule = []
    Cat = []

    # Open the file
    filename = '%s.sc'%filestart
    with open(filename, 'rt') as f:
        for line in f.readlines():
            line = line.rstrip()
            if line[0] != '*':
                if '/' in line:
                    Rule.append(line)
                elif '=' in line:
                    Cat.append(line)

    if Cat:
        print "%d categories found"%len(Cat)

        if PRINT_RULES:
            for cat in Cat:
                print cat
            print
    else:
        print "No rules were found."
        print

    if Rule:
        print "%d rules found"%len(Rule)

        if PRINT_RULES:
            for rule in Rule:
                print rule

            print
    else:
        print "No rules were found.\n"

    return len(Rule)

def Divide(Rule):
    """
    Divide
  
    Divide a rule into source and target phoneme(s) and environment.
    That is, for a rule s1/s2/env
    create the three null-terminated strings s1, s2, and env.
  
    If this cannot be done, return False.
    """
    return Rule.split('/')

def TryCat(env, word):
    """
    TryCat
  
    See if a particular phoneme sequence is part of any category.
    (We try all the categories.)
  
    For instance, if we have 'a' in the source word and 'V' in the
    structural description, and a category V=aeiou, TryCat returns True,
    and sets *n to the number of characters to skip.
  
    If we had 'b' instead, TryCat would return False instead.
  
    If no category with the given identification (env) can be found,
    we return True (continue looking), but set *n to 0.
  
    Warning: For now, we don't have a way to handle digraphs.
  
    We also return True if
    """
    if word == '': return False

    n = 0
    for c in Cat:
        if env == c:
            catdef = Cat[Cat.find('=')+1:]

            if word[0] in catdef:
                n = 1
                catLoc = Cat[c].find(word[0]) - Cat[c];
                break
            else:
                return False
    return n, catLoc

def TryRule(word, i, Rule):
    """
    TryRule

    See if a rule s1->s2/env applies at position i in the given word.

    If it does, we pass back the index where s1 was found in the
    word, as well as s1 and s2, and return True.
  
    Otherwise, we return False, and pass garbage in the output variables.
    """
#    int j, m, cont = 0;
#    int catLoc;
#    char *env;
    optional = False
    varRep = ''

    check = Divide(Rule)
    if not check or '_' in env:
        return False
    s1, s2, env = check

    cont = True
    for j in xrange(len(env)): 0, cont = True; cont && j < strlen(env); j++)
        if env[j] == '(':
            optional = True
        elif env[j] == ')':
            optional = False
        elif env[j] == '#':
            cont = i == len(word) if j else i == 0
        elif env[j] == '_':
            cont = word[i:len(s1)] == s1
            if cont:
                n = i
                i += len(s1)
            else:
                cont, m, catLoc = TryCat(s1, word[i])
                if cont and m:
                    n = i
                    i += m

                    for c in xrange(len(Cat)):
                        if s2[0] == Cat[c][0] and catLoc < len(Cat[c]):
                            varRep = Cat[c][catLoc]
                elif cont:
                    cont = False
        else:
            cont, m, catLoc = TryCat(env[j], word[i])
            if cont and not m:
                # no category applied
                cont = i < len(word) and word[i] == env[j]
                m = 1
                if cont:
                    i += m
                if not cont and optional:
                    cont = True
    if cont and PRINT_RULES:
        print "   %s->%s /%s applies to %s at %i"%(s1, s2, env, word, n)
    return cont

def Transform(inword):
    """
    Transform
  
    Apply the rules to a single word and return the result.
  
    The rules are stated in the form string1/string2/environment, e.g.
        f/h/#_V
    which states that f changes to h at the beginning of a word before a
    vowel.
    """
    # Try to apply each rule in turn
    for rule in Rule:
        # Initialize output of this rule to null
        outword = ''

        # Check each position of the input word in turn
        i = 0
        while i < len(inword):
            check = TryRule(inword, i, rule)
            if not check:
                outword += inword[i]
                i += 1
                continue
            # Rule applies at inword[n]
            n, s1, s2, varRep = check

            if n:
                outword += inword[i:i+n]
            if varRep:
                outword += varRep
            elif s2:
                outword += s2

            i = n + len(s1)
        # Output of one rule is input to next one
        inword = outword
    # Return the output of the last rule
    return outword

def DoWords(lexname, outname):
    """
    DoWords

    Read in each word in turn from the input file,
    transform it according to the rules,
    and output it to the output file.

    This algorithm ensures that word files of any size can be processed.
    """
    n = 0

    filename = '%s.lex'%lexname
    f = open(filename, 'rt')

    filename = '%s.out'%outname
    g = open(filename, 'wt')

    for inword in f.readlines():
        inword = inword.rstrip()
        n += 1
        outword = Transform(inword)
#
#        if not args.printSourc:
#        {
#            if args.toScreen:
#                printf(     "%s\n", outword );
#            fprintf( g, "%s\n", outword );
#        }
#        else if args.bracketOut:
#        {
#            if args.toScreen:
#                printf(     "%s \t[%s]\n", outword, inword );
#            fprintf( g, "%s \t[%s]\n", outword, inword );
#        }
#        else
#        {
#            if args.toScreen:
#                printf(     "%s --> %s\n", inword, outword );
#            fprintf( g, "%s --> %s\n", inword, outword );
#        }
#    }
#
    f.close()
    g.close()
    print "%i word%s processed."%(n, '' if n == 1 else 's')

"""
MAIN ROUTINE

Ask for name of project
Read in rules and input words
Apply transformations
Output words
"""

COPYRIGHT = """
SOUND CHANGE APPLIER
(C) 1992,2000 by Mark Rosenfelder
For more information see www.zompist.com
"""

if __name__ == '__main__':
    ReadRules('port')
    print Rule
    print Cat
    DoWords('latin', 'port')
#    once = False
#    lexicon = ''
#    rules = ''
#
#    parser = argparse.ArgumentParser()
#    parser.add_argument('-p', dest='printRules', action='store_true')
#    parser.add_argument('-b', dest='bracketOut', action='store_true')
#    parser.add_argument('-l', dest='printSourc', action='store_false')
#    parser.add_argument('-f', dest='toScreen', action='store_false')
#    parser.add_argument('lexicon')
#    parser.add_argument('rules')
#    # Read command line arguments */
#    args = parser.parse_args()
#    PRINT_RULES = args.printRules
#
#    once = args.lexicon and args.rules
#
#    print COPYRIGHT
#
#    if once:
#        print "Applying %s.sc to %s.lex\n"%(lexicon, rules)
#
#        if ReadRules(rules):
#            DoWords(lexicon, rules)
#    else:
#        done = False
#        while not done:
#            print
#            print "Enter the name of a LEXICON."
#            print
#            print "For example, enter latin to specify latin.lex."
#            print "Enter q to quit the program."
#            print "-->",
#
#            lexicon = input()
#
#            if lexicon == 'q':
#                done = True
#            else:
#                print "Enter the name of a RULES FILE."
#                print
#                print
#                print "For example, enter french to specify french.sc."
#                print "The output words would be stored in french.out."
#                print "-->",
#
#                rules = input()
#
#                if ReadRules(rules):
#                    DoWords(lexicon, rules)
#
#    print
#    print  "Thank you for using the SOUND CHANGE APPLIER!"

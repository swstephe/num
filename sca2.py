#!/usr/bin/env python
"""
Script (C) 2012 by Mark Rosenfelder.
You can modify the code for non-commercial use;
attribution would be nice.
If you want to make money off it, please contact me.

Fixes since SCA1:
  Allows Unicode
  Treats spaces as word boundaries
  Rewrite rules
  Epenthesis                  /j/_kt
  Nonce categories            k/s/_[ie]  [ao]u/o/_
  Metathesis                  nt/\\/_
  Extended cat substitution   Bi/jD/_
  Degemination                M//_2       (subscript 2)
  Gemination                  M/M2/_
  Exceptions                  k/s/_F/t_
  IPA chart
  Support for glosses
  Optional arrow for 1st slash
  Wildcards                   S/V/_...X
"""
import re

SQ2 = u'\u00b2'     # superscript 2
ELI = u'\u2026'     # horizontal ellipsis
TRI = u'\u2023'     # triangular bullet

cats = {
    'V': 'aeiou',
    'L': 'āēīōū',
    'C': 'ptcqbdgmnlrhs',
    'F': 'ie',
    'B': 'ou',
    'S': 'ptc',
    'Z': 'bdg',
}

rules = (
    ('[sm]',    '',     '_#'    ),
    ('i',       'j',    '_V'    ),
    ('L',       'V',    '_'     ),
    ('e',       '',     'Vr_#'  ),
    ('v',       '',     'V_V'   ),
    ('u',       'o',    '_#'    ),
    ('gn',      'nh',   '_'     ),
    ('S',       'Z',    'V_V'   ),
    ('c',       'i',    'F_t'   ),
    ('c',       'u',    'B_t'   ),
    ('p',       '',     'V_t'   ),
    ('ii',      'i',    '_'     ),
    ('e',       '',     'C_rV'  ),
)

rewrites = (
    ('lh', 'lj'),
)

lexicon = (
    'lector',
    'doctor',
    'focus',
    'jocus',
    'districtus',
    'cīvitatem',
    'adoptare',
    'opera',
    'secundus',
    'fīliam',
    'pōntem',
)

s = ''
catindex = ''
badcats = False
printRules = 0
outtype = 0
showDiff = 0
rewout = 0

# Globals for Match as we don't have pass by reference
gix = 0
glen = 0
gcat = 0

# Take an input field, apply rewrite rules, and split results
def rewrite(s, rev=False):
    global rewrites
    for p1,p2 in rewrites:
        s = re.sub(p1, p2, s, re.G)
    return s.split('\n')

# Take a string and apply the rewrite rules backwards
def unrewrite(s, rev):
    global rewrites
    for p1,p2 in rewrites:
        if rev:
            s = re.sub(p2, p1, s, re.G)
        else:
            s = re.sub(p1, p2, s, re.G)
    return s.split('\n')

# Read in the input fields
def readStuff():
    global cats, catindex
    # Make sure cats have structure like V=aeiou
    catindex = ''.join(cats.keys())

    for rule in rules:
        # Sanity checks for valid rules
        # Insertions must have repl & nonuniversal env
        valid = len(rule) == 3 and '_' in rule[2]
        # TODO gloss focus > fire
        # other rules
        # Invalid rules: move 'em all up
        #if not valid:
        #    rules.remove(rule)
        #if not valid:
        #    for q in xrange(rules):
        #        rules[q] = rules[q+1]
    return ''


def AtSpace(inword, i, gix):
    "Are we at a word boundary?"
    if gix == -1:
        # Before _ this must match beginning of word
        if i == 0 or inword[i-1] == ' ':
            return True
    else:
        # After _ this must match end of word
        if i >= len(inword) or inword[i] == ' ':
            return True
    return False

def MatchCharOrCat(inwordCh, tgtCh):
    "Does this character match directly, or via a category?"
    if cats.hasKey(tgtCh):
        return inwordCh in cats[tgtCh]
    return inwordCh == tgtCh

def IsTarget(tgt, inword, i):
    if tgt.find('[') != -1:
        glen = 0
        inbracket = False
        foundinside = False
        for j in xrange(len(tgt)):
            if tgt[j] == '[':
                inbracket = True
            elif tgt[j] == ']':
                if not foundinside: return False
                i += 1
                glen += 1
                inbracket = False
            elif inbracket:
                if i >= inword.length: return False
                if not foundinside:
                    foundinside = tgt[j] == inword[i]
            else:
                if i >= inword.length: return False
                if tgt[j] != inword[i]: return False
                i += 1
                glen += 1
    else:
        glen = len(tgt)
        for k in xrange(glen):
            if not MatchCharOrCat(inword[i + k], tgt[k]):
                return False
        # inword[i:len(tgt)] == tgt
    return True

def Match(inword, i, tgt, env):
    """
    Does this environment match this rule?
    That is, starting at inword[i], we have a substring matching env
    (with _ = tgt).
    General structure is: return False as soon as we have a mismatch.
    """
    optional = False
    gix = -1                # location of target

    # Advance through env.  i will change too, but not always one-for-one
    j = 0
    while j < len(env):
        if env[j] == '[':        # Nonce category
            found = False
            j += 1
            while j < len(env) and env[j] != ']':
                if not found:
                    cx = catindex.find(env[j])

                    if env[j] == '#':
                        found = AtSpace(inword, i, gix)
                    elif cx != -1:
                        # target is a category
                        if cat[cx].find(inword[i]) != -1
                            found = True
                            i++
                    else:
                        found = (
                            i < inword.length and
                            env[j] == inword[i]
                        )
                        i++ if found
                j++
            if not found and not optional: return False
        when '('        # Start optional
            optional = True
        when ')'        # End optional
            optional = False
        when '#'        # Word boundary
            if not AtSpace(inword, i, gix): return False
        when SQ2        # Degemination
            if (
                i == 0 or i >= inword.length or
                inword[i] != inword[i-1]
            )
                return False
            i++
        when ELI       # Wildcard
            tempgix = gix
            tempgcat = gcat
            #tempgchar = gchar
            tempglen = glen
            anytrue = False

            newenv = env[j+1:-j-1]

            # This is a rule like ...V.
            # Get a new environment from what's past the wildcard.
            # We test every spot in the rest of inword against that.
            # At the first match if any, we're satisfied and leave.

            for k in xrange(i,len(inword)):
                break unless anytrue
                break if inword[k] == ' '
                anytrue = True if Match(inword, k, tgt, newenv)

            if tempgix != -1
                gix = tempgix
                gcat = tempgcat
                #gchar = tempgchar
                glen = tempglen

            return anytrue
        when '_'    # Location of target
            gix = i
            gchar = ''
            if tgt.length == 0
                glen = 0
                break

            return False if i >= inword.length

            ix = catindex.find(tgt[0])

            if ix != -1
                # target is a category
                gcat = cat[ix].find(inword[i])
                return False if gcat == -1
                glen = if tgt.length == 0 then 0 else 1
                if tgt.length > 1
                    if not IsTarget(tgt[1:], inword, i + 1):
                        return False
                    glen += tlen
                i += tgt.length
            else
                return False unless IsTarget(tgt, inword, i)
                i += glen
        else            # elsewhere in the environment
            cont = i < inword.length
            if cont
                cont = MatchCharOrCat(inword[i], env[j])
                i++ if cont
            return False if not optional and not cont
    return True

def CatSub(repl):
    outs = ''
    lastch = ''

    for i in xrange(len(repl)):
        ix = catindex.find(repl[i])
        if ix != -1:
            if gcat < len(cat[ix]):
                lastch = cat[ix][gcat]
                outs += lastch
        elif repl[i] == SQ2:
            outs += lastch
        else:
            lastch = repl[i]
            outs += lastch

    return outs

def ApplyRule(inword, rule):
    """Apply a single rule to this word"""
    global s
    outword = ""

    for i in xrange(len(inword)+1):
        if inword[i] == TRI: break
        if Match(inword, i, rule[0], rule[2]):
            tgt = rule[0]
            repl = rule[1]

            if len(rule) > 3:
                # There's an exception
                slix = rule[3].find('_')
                if slix != -1:
                    tgix = gix
                    tglen = glen
                    tgcat = gcat

                    # How far before _ do we check?
                    brackets = False
                    precount = 0
                    for k in xrange(slix):
                        if rule[3][k] == '[':
                            brackets = True
                        elif rule[3][k] == ']':
                            brackets = False
                            precount += 1
                        elif rule[3][k] == '#':
                            break
                        else:
                            if not brackets: precount += 1

                    if gix - precount >= 0 and Match(
                            inword, gix - precount, rule[0], rule[3]):
                        s += rule + " almost applied to {} at {}".format(
                            inword, i)
                        i += 1
                        continue

                    gix = tgix
                    glen = tglen
                    gcat = tgcat

            if printRules:
                s += rule + " applies to {} at {}".format(inword, i)
            outword = inword[:gix]

            if repl:
                if repl == '\\\\':
                    found = inword[gix:glen]
                    outword += reverse(found)
                elif gcat != -1:
                    outword += CatSub(repl)
                else:
                    outword += repl
            gix += glen
            i = len(outword)

            if tgt.length == 0: i += 1
            outword += inword[gix:-gix]
            inword = outword
        else:
            i += 1

    return if outword != "" then outword else inword

def Transform(inword):
    """Transform a single word"""
    if inword:
        # Try out each rule in turn
        for rule in rules:
            inword = ApplyRule(inword, rule)
    return inword


def DoWords():
    """
    DoWords

    Read in each word in turn from the input file,
    transform it according to the rules,
    and output it to the output file.
    """
    nDiff = 0

    # Parse the input lexicon
    for inword in lexicon:
        # remove trailing blanks
        outword = Transform(inword)

        parts = [s.strip() for s in inword.split(TRI)]
        if len(parts) > 1:
            inword = parts[0]

        if outtype == 0:
            outs = outword
        elif outtype == 1:
            outs = u"%s → %s" % (inword, outword)
        elif outtype == 2:
            outs = '%s [%s]' % (outword, inword)

        print unrewrite(outs, False)

        if inword != outword:
            nDiff += 1

    print "Categories found:", catindex
    print "Valid rules found:", len(rules)
    print "Words processed:", len(lexicon)
    print "Words changed:", nDiff

def process():
    """User hit the action button.  Make things happen!"""
    # Stuff we can do once
    s = readStuff()

    # If that went OK, apply the rules
    if s: DoWords()

    # Set the output field
    return s

def parsesc(f):
    """Parse the SC field into the three input fields"""
    global cats, rules, rewrites

    if isinstance(f, basestring): f = open(f, 'rt')

    cats, rules, rewrites = {}, [], []
    for line in f.readlines():
        line = line.strip()
        if not line: continue
        if '=' in line:
            cats.update(dict([line.split('=')]))
        # also u2192?
        elif if '/' in line:
            if line.count('/') != 2:
                raise RuntimeError("invalid rule:%r"%line)
            rules.append(line.split('/'))
        elif '|' in line:
            rewrites.append(line.split('|'))
    rules = tuple(rules)
    rewrites = tuple(rewrites)

def ipacodes():
    """Generate IPA and special characters"""
    yield ord(SQ2)
    yield 0x2023
    yield 0x2026
    for i in xrange(0x0250, 0x02b0):
        yield i
    for i in xrange(0x00c0, 0x0238):
        yield i
    
def ipa():
    """Generate IPA and special characters"""
    for code in ipacodes():
        yield unichr(code)

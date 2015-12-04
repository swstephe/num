# Script (C) 2012 by Mark Rosenfelder.
# You can modify the code for non-commercial use;
# attribution would be nice.
# If you want to make money off it, please contact me.

# Fixes since SCA1:
#  Allows Unicode
#  Treats spaces as word boundaries
#  Rewrite rules
#  Epenthesis                  /j/_kt
#  Nonce categories            k/s/_[ie]  [ao]u/o/_
#  Metathesis                  nt/\\/_
#  Extended cat substitution   Bi/jD/_
#  Degemination                M//_2       (subscript 2)
#  Gemination                  M/M2/_
#  Exceptions                  k/s/_F/t_
#  IPA chart
#  Support for glosses
#  Optional arrow for 1st slash
#  Wildcards                   S/V/_...X

s = ''
cat = []
ncat = 0
rul = []
nrul = 0
catindex = ''
badcats = false
printRules = 0
outtype = 0
showDiff = 0
rewout = 0

# Globals for Match as we don't have pass by reference
gix = 0
glen = 0
gcat = 0

reverse = (s) -> (s.charAt(i) for i in [s.length..0]).join('')

# Take an input field, apply rewrite rules, and split results
rewrite = (s) ->
    rew = $('#rewrite').val().trim().split('\n')

    for w in [0...rew.length]
        if rew[w].length > 2 and rew[w].indexOf('|') != -1
            parse = rew[w].split('|')
            regex = new RegExp(parse[0], 'g')
            s = s.replace(regex, parse[1])
    s.split('\n')

# Take a string and apply the rewrite rules backwards
unrewrite = (s, rev) ->
    return s unless rewout

    rew = $('#rewrite').val().trim().split('\n')

    p1 = if rev then 0 else 1
    p2 = if rev then 1 else 0

    for w in [0...rew.length]
        if rew[w].length > 2 and rew[w].indexOf('|') != -1
            parse = rew[w].split('|')
            regex = new RegExp(parse[p1], 'g')
            s = s.replace(regex, parse[p2])
    s.split('\n')

# Read in the input fields
readStuff = ->
    # Parse the category list
    cat = rewrite($('#cats').val().trim())
    ncat = cat.length
    badcats = false

    # Make sure cats have structure like V=aeiou
    catindex = ''
    for w in [0...ncat]
        # A final empty cat can be ignored
        thiscat = cat[w] = cat[w].trim()
        if thiscat.length < 3 or thiscat.indexOf('=') == -1
            badcats = true
        else
            catindex += thiscat.charAt(0)

    # Parse the sound changes
    rul = rewrite($('#rules').val().trim())
    nrul = rul.length

    # Remove trailing returns
    for w in [0...nrul]
        t = rul[w] = rul[w].trim()

        # Sanity checks for valid rules
        valid = t.length > 0 and t.indexOf('_') != -1
        if valid
            thisrule = t.split('/')
            valid = thisrule.length > 2 or (thisrule.length == 2 and
                 thisrule[0].indexOf('\u2192') != -1)
            if valid
                # Insertions must have repl & nonuniversal env
                if thisrule[0].length == 0
                    valid = thisrule[1].length > 0 and thisrule[2] != "_"

        # Invalid rules: move 'em all up
        unless valid
            nrul--
            for q in [w...nrul]
                rul[q] = rul[q+1]
            w--

    # Error strings
    if badcats
        "Categories must be of the form V=aeiou<br>" +
        "That is, a single letter, an equal sign, then a list of possible expansions."
    else if nrul == 0
        "There are no valid sound changes, so no output can be generated. Rules must be of the form s1/s2/e1_e2. The strings are optional, but the slashes are not." 
    else
        ""


# Are we at a word boundary?
AtSpace = (inword, i, gix) ->
    if gix == -1
        # Before _ this must match beginning of word
        if i == 0 or inword.charAt(i-1) == ' '
            return true
    else
        # After _ this must match end of word
        if i >= inword.length or inword.charAt(i) == ' '
            return true
    return false

# Does this character match directly, or via a category?
MatchCharOrCat = (inwordCh, tgtCh) ->
    ix = catindex.indexOf(tgtCh)
    if ix != -1 then cat[ix].indexOf(inwordCh) != -1 else inwordCh == tgtCh

IsTarget(tgt, inword, i) ->
    if tgt.indexOf('[') != -1
        glen = 0
        inbracket = false
        foundinside = false
        for j in [0...tgt.length]
            if tgt.charAt(j) == '['
                inbracket = true
            else if tgt.charAt(j) == ']'
                return false unless foundinside
                i++
                glen++
                inbracket = false
            else if inbracket
                return false if i >= inword.length
                if not foundinside
                    foundinside = tgt.charAt(j) == inword.charAt(i)
            else
                return false if i >= inword.length
                if tgt.charAt(j) != inword.charAt(i) then return false
                i++
                glen++
    else
        glen = tgt.length
        for k in [0...glen]
            unless MatchCharOrCat(inword.charAt(i + k), tgt.charAt(k))
                return false
        # inword.substr(i, tgt.length) == tgt
    true

# Does this environment match this rule?
# That is, starting at inword[i], we have a substring matching env (with _ = tgt).
# General structure is: return false as soon as we have a mismatch.
Match = (inword, i, tgt, env ) ->
    optional = false
    gix = -1                # location of target

    # Advance through env.  i will change too, but not always one-for-one
    for j in [0...env.length]
        switch env.charAt(j)
            when '['        # Nonce category
                found = false
                j++
                while j < env.length and env.charAt(j) != ']'
                    if not found
                        cx = catindex.indexOf(env.charAt(j))

                        if env.charAt(j) == '#'
                            found = AtSpace(inword, i, gix)
                        else if cx != -1
                            # target is a category
                            if cat[cx].indexOf(inword.charAt(i)) != -1
                                found = true
                                i++
                        else
                            found = (
                                i < inword.length and
                                env.charAt(j) == inword.charAt(i)
                            )
                            i++ if found
                    j++
                return false unless found or optional
            when '('        # Start optional
                optional = true
            when ')'        # End optional
                optional = false
            when '#'        # Word boundary
                return false unless AtSpace(inword, i, gix)
            when '\u00b2'   # Degemination
                if (
                    i == 0 or i >= inword.length or
                    inword.charAt(i) != inword.charAt(i-1)
                )
                    return false
                i++
            when '\u2026'   # Wildcard
                tempgix = gix
                tempgcat = gcat
                #tempgchar = gchar
                tempglen = glen
                anytrue = false

                newenv = env.substr(j + 1, env.length - j - 1)

                # This is a rule like ...V.
                # Get a new environment from what's past the wildcard.
                # We test every spot in the rest of inword against that.
                # At the first match if any, we're satisfied and leave.

                for k in [i...inword.length]
                    break unless anytrue
                    break if inword[k] == ' '
                    anytrue = true if Match(inword, k, tgt, newenv)

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

                return false if i >= inword.length

                ix = catindex.indexOf(tgt.charAt(0))

                if ix != -1
                    # target is a category
                    gcat = cat[ix].indexOf(inword.charAt(i))
                    return false if gcat == -1
                    glen = if tgt.length == 0 then 0 else 1
                    if tgt.length > 1
                        tlen = tgt.length - 1
                        unless IsTarget(tgt.substr(1, tlen ), inword, i + 1)
                            return false
                        glen += tlen
                    i += tgt.length
                else
                    return false unless IsTarget(tgt, inword, i)
                    i += glen
            else            # elsewhere in the environment
                cont = i < inword.length
                if cont
                    cont = MatchCharOrCat(inword.charAt(i), env.charAt(j))
                    i++ if cont
                return false if not optional and not cont
    true

CatSub = (repl) ->
    outs = ''
    lastch = ''

    for i in [0...repl.length]
        ix = catindex.indexOf(repl.charAt(i))
        if ix != -1
            if gcat < cat[ix].length
                lastch = cat[ix].charAt(gcat)
                outs += lastch
        else if repl.charAt(i) == '\u00b2'
            outs += lastch
        else
            lastch = repl.charAt(i)
            outs += lastch

    return outs

# Apply a single rule to this word
ApplyRule = (inword, r) ->
    outword = ""
    t = rul[r].replace('\u2192', "/")
    thisrule = t.split("/")
    i = 0

    while i <= inword.length and inword.charAt(i) != '\u2023'
        if Match(inword, i, thisrule[0], thisrule[2])
            tgt = thisrule[0]
            repl = thisrule[1]

            if thisrule.length > 3
                # There's an exception
                slix = thisrule[3].indexOf('_')
                if slix != -1
                    tgix = gix
                    tglen = glen
                    tgcat = gcat

                    # How far before _ do we check?
                    brackets = false
                    precount = 0
                    for k in [0...slix]
                        switch thisrule[3].charAt(k)
                            when '['
                                brackets = true
                            when ']'
                                brackets = false
                                precount++
                            when '#'
                                break
                            else
                                precount++ unless brackets

                    if gix - precount >= 0 and Match(inword, gix - precount, thisrule[0], thisrule[3])
                        s += rul[r] + " almost applied to #{inword} at #{i}<br>"
                        i++
                        continue
                    gix = tgix
                    glen = tglen
                    gcat = tgcat

            if printRules
                s += rul[r] + " applies to #{inword} at #{i}<br>"
            outword = inword.substr(0, gix)

            if repl.length > 0
                if repl == "\\\\"
                    found = inword.substr(gix,glen)
                    outword += reverse(found)
                else if gcat != -1
                    outword += CatSub(repl)
                else
                    outword += repl
            gix += glen
            i = outword.length

            if tgt.length == 0 then i++

            outword += inword.substr(gix, inword.length - gix)

            inword = outword
        else
            i++

    if outword != "" then outword else inword

# Transform a single word
Transform = (inword) ->
    if inword.length > 0
        # Try out each rule in turn
        for r in [0...nrul]
            inword = ApplyRule(inword, r)
    inword


# DoWords
#  Read in each word in turn from the input file,
#  transform it according to the rules,
#  and output it to the output file.
DoWords = () ->
    nWord = 0
    nDiff = 0
    olex = ""

    # Parse the input lexicon
    lex = rewrite($('#ilex').val().trim())
    nlex = lex.length

    localshowdiff = showDiff
    if showDiff
        sx = $("#olex").html()
        if sx == ""
            localshowdiff = false
        else
            sx = unrewrite(sx, true)
            sx = sx.replace(new RegExp("<(b|/b)>", "gi"), "")
            oldolex = sx.split("<br>")

    for w in [0...nlex]
        inword = lex[w]

        # remove trailing blanks
        while inword.charAt(inword.length - 1) == ' '
            inword = inword.substr(0, inword.length - 1)

        if inword.length > 0
            if inword.charAt(inword.length - 1) == '\n'
                inword = inword.substr(0, inword.length - 1)

            outword = Transform(inword)

            parts = inword.split(" \u2023")
            if parts.length > 1
                inword = parts[0]

            switch outtype
                when 0 then outs = outword
                when 1 then outs = inword + " → " + outword
                when 2 then outs = outword + " [" + inword + "]"

            if localshowdiff and w < oldolex.length and outs != oldolex[w]
                outs = outs.bold()

            olex += unrewrite(outs, false) + "<br>"

            nWord++
            nDiff++ if inword != outword

    s += """Categories found: #{catindex}
         <br>Valid rules found: #{nrul}
         <br>Words processed: #{nWord}
         <br>Words changed: #{nDiff}"""

    $('#olex').html(olex)

# User hit the action button.  Make things happen!
process = () ->
    #Read parameters
    theform = $('#theform')
    outtypes = theform.find('input[name=outtype]')

    outtype = 0
    if outtypes[1].checked then outtype = 1
    if outtypes[2].checked then outtype = 2

    printRules = theform.find('checkbox[name=report]').checked
    showDiff = theform.find('checkbox[name=showdiff]').checked
    rewout = theform.find('checkbox[name=rewout]').checked

    # Stuff we can do once
    s = readStuff()

    # If that went OK, apply the rules
    if s.length == 0 then DoWords()

    # Set the output field
    $("#mytext").html(s)

helpme = () -> window.open("scahelp.html")

# Parse the SC field into the three input fields
parsesc = () ->
    rul = $('#rules').val().split('\n')
    nrul = rul.length

    orul = ''
    orew = ''
    ocat = ''

    $.each rul, (w, t) ->
        if t.indexOf('|') != -1
            orew += t + '\n'
        else if t.indexOf('=') != -1
            ocat += t + '\n'
        else
            orul += t + '\n'

    if ocat == '' and $('#cats').val() != ''
        alert("""No categories were found in the sound changes area,
        and you have content in the categories area.  You probably don't
        want to do a Parse then.""")
        return
    if orew == '' and $('#rewrite').val() != ''
        alert("""No rewrite rules were found in the sound changes area,
        and you have content in the rewrite rules area.  You probably don't
        want to do a Parse then.""")
        return

    $('#cats').val(ocat)
    $('#rewrite').val(orew)
    $('#rules').val(orul)

# Copy all three input fields back into the SC area
intosc = () ->
    $('#rules').val(
        $('#cats').val() + '\n' +
        $('#rewrite').val() + '\n' +
        $('#rules').val() + '\n'
    )

# Display the IPA
showipa = () ->
    s = "<font face='Gentium'>&#x00b2; &#x2023; &#x2026; "
    s += [String.fromCharCode(i)+' ' for i in [0x0250..0x02af]].join('')
    s += [String.fromCharCode(i)+' ' for i in [0x00c0..0x0237]].join('')
    s += "</font>"
    $('#mytext').html(s)

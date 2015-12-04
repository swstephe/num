// Script (C) 2012 by Mark Rosenfelder.
// You can modify the code for non-commercial use;
// attribution would be nice.
// If you want to make money off it, please contact me.

// Fixes since SCA1:
//  Allows Unicode
//  Treats spaces as word boundaries
//  Rewrite rules
//  Epenthesis                  /j/_kt
//  Nonce categories            k/s/_[ie]  [ao]u/o/_
//  Metathesis                  nt/\\/_
//  Extended cat substitution   Bi/jD/_
//  Degemination                M//_2       (subscript 2)
//  Gemination                  M/M2/_
//  Exceptions                  k/s/_F/t_
//  IPA chart
//  Support for glosses
//  Optional arrow for 1st slash
//  Wildcards                   S/V/_...X

var s;
var cat;
var ncat;
var rul;
var nrul;
var catindex = "";
var badcats;
var printRules;
var outtype;
var showDiff;
var rewout;

function reverse(s)
{
    var outs = '';
    for (var i = s.length - 1; i >= 0; i--) {
        outs += s.charAt(i);
    }
    return outs;
}

// Take an input field, apply rewrite rules, and split results
function rewrite(fld)
{
    var s = fld.val().trim();
    var rew = $('#rewrite').val().trim().split('\n');
    var nrew = rew.length;

    for (var w = 0; w < nrew; w++) {
        if (rew[w].length > 2 && rew[w].indexOf('|') != -1) {
            var parse = rew[w].split('|');
            var regex = new RegExp(parse[0], 'g');
            s = s.replace(regex, parse[1]);
        }
    }
    return s.split('\n');
}

// Take a string and apply the rewrite rules backwards
function unrewrite(s, rev)
{
    if (!rewout) return s;

    var rew = $('#rewrite').val().trim().split('\n');
    var nrew = rew.length;

    var p1 = rev ? 0 : 1;
    var p2 = rev ? 1 : 0;

    for (var w = 0; w < nrew; w++) {
        if (rew[w].length > 2 && rew[w].indexOf('|') != -1) {
            var parse = rew[w].split('|');
            var regex = new RegExp(parse[p1], 'g');
            s = s.replace(regex, parse[p2]);
        }
    }
    return s.split('\n');
}

// Read in the input fields
function readStuff()
{
    // Parse the category list
    cat = rewrite($('#cats'));
    ncat = cat.length;
    var badcats = false;

    // Make sure cats have structure like V=aeiou
    catindex = '';
    var w;
    for (w = 0; w < ncat; w++) {
        // A final empty cat can be ignored
        thiscat = cat[w] = cat[w].trim();
        if (thiscat.length < 3 || thiscat.indexOf('=') == -1) {
            badcats = true;
        } else {
            catindex += thiscat.charAt(0);
        }
    }

    // Parse the sound changes
    rul = rewrite($('#rules'));
    nrul = rul.length;

    // Remove trailing returns
    for (w = 0; w < nrul; w++) {
        var t = rul[w] = rul[w].trim();

        // Sanity checks for valid rules
        var valid = t.length > 0 && t.indexOf('_') != -1;
        if (valid) {
            var thisrule = t.split('/');
            valid = thisrule.length > 2 ||
                (thisrule.length == 2 &&
                 thisrule[0].indexOf('\u2192') != -1);
            if (valid) {
                // Insertions must have repl & nonuniversal env
                if (thisrule[0].length == 0)
                    valid = thisrule[1].length > 0 && thisrule[2] != "_";
            }
        }

        // Invalid rules: move 'em all up
        if (!valid) {
            nrul--;
            for (var q = w; q < nrul; q++) {
                rul[q] = rul[q+1];
            }
            w--;
        }
    }

    // Error strings
    if (badcats) {
        return "Categories must be of the form V=aeiou<br>" +
        "That is, a single letter, an equal sign, then a list of possible expansions.";
    } else if (nrul == 0) {
        return "There are no valid sound changes, so no output can be generated. Rules must be of the form s1/s2/e1_e2. The strings are optional, but the slashes are not." ;
    } else {
        return "";
    }
}

// Globals for Match as we don't have pass by reference
var gix;
var glen = 0;
var gcat;

// Are we at a word boundary?
function AtSpace(inword, i, gix)
{
    if (gix == -1) {
        // Before _ this must match beginning of word
        if (i == 0 || inword.charAt(i-1) == ' ')
            return true;
    } else {
        // After _ this must match end of word
        if (i >= inword.length || inword.charAt(i) == ' ')
            return true;
    }
    return false;
}

// Does this character match directly, or via a category?
function MatchCharOrCat(inwordCh, tgtCh)
{
    var ix = catindex.indexOf(tgtCh);
    if (ix != -1) {
        return (cat[ix].indexOf(inwordCh) != -1);
    } else {
        return inwordCh == tgtCh;
    }
}

function IsTarget(tgt, inword, i)
{
    if (tgt.indexOf('[') != -1) {
        glen = 0;
        var inbracket = false;
        var foundinside = false;
        for (var j = 0; j < tgt.length; j++) {
            if (tgt.charAt(j) == '[') {
                inbracket = true;
            } else if (tgt.charAt(j) == ']') {
                if (!foundinside) return false;
                i++;
                glen++;
                inbracket = false;
            } else if (inbracket) {
                if (i >= inword.length) return false;
                if (!foundinside)
                    foundinside = tgt.charAt(j) == inword.charAt(i);
            } else {
                if (i >= inword.length) return false;
                if (tgt.charAt(j) != inword.charAt(i)) return false;
                i++;
                glen++;
            }
        }
    } else {
        glen = tgt.length;
        for (var k = 0; k < glen; k++) {
            if (MatchCharOrCat(inword.charAt(i + k), tgt.charAt(k)) == false)
                return false;
        }
        return true;
        // return inword.substr(i, tgt.length) == tgt;
    }
    return true;
}

// Does this environment match this rule?
// That is, starting at inword[i], we have a substring matching env (with _ = tgt).
// General structure is: return false as soon as we have a mismatch.
function Match(inword, i, tgt, env )
{
    var optional = false;
    gix = -1; // location of target

    // Advance through env.  i will change too, but not always one-for-one
    for (var j = 0; j < env.length; j++) {
        switch (env.charAt(j)) {
        case '[': // Nonce category
            var found = false;
            for (j++; j < env.length && env.charAt(j) != ']'; j++) {
                if (found) continue;
                var cx = catindex.indexOf(env.charAt(j));

                if (env.charAt(j) == '#') {
                    found = AtSpace(inword, i, gix);
                } else if (cx != -1) {
                    // target is a category
                    if (cat[cx].indexOf(inword.charAt(i)) != -1) {
                        found = true;
                        i++;
                    }
                } else {
                    found = i < inword.length
                        && env.charAt(j) == inword.charAt(i);
                    if (found) i++;
                }
            }
            if (!found && !optional) return false;
            break;
        case '(': // Start optional
            optional = true;
            break;
        case ')': // End optional
            optional = false;
            break;
        case '#': // Word boundary
            if (!AtSpace(inword, i, gix)) return false;
            break;
        case '\u00b2': // Degemination
            if (i == 0 || i >= inword.length
                    || inword.charAt(i) != inword.charAt(i-1))
                return false;
            i++;
            break;
        case '\u2026': // Wildcard
            var tempgix = gix;
            var tempgcat = gcat;
            //var tempgchar = gchar;
            var tempglen = glen;
            var anytrue = false;

            var newenv = env.substr(j + 1, env.length - j - 1);

            // This is a rule like ...V.
            // Get a new environment from what's past the wildcard.
            // We test every spot in the rest of inword against that.
            // At the first match if any, we're satisfied and leave.

            for (var k = i; k < inword.length && anytrue == false; k++) {

                if (inword[k] == ' ') break;

                if (Match(inword, k, tgt, newenv)) {
                    anytrue = true;
                }
            }

            if (tempgix != -1) {
                gix = tempgix;
                gcat = tempgcat;
                //gchar = tempgchar;
                glen = tempglen;
            }

            return anytrue;
        case '_': // Location of target
            gix = i;
            gchar = '';
            if (tgt.length == 0) {
                glen = 0;
                break;
            }

            if (i >= inword.length) return false;

            var ix = catindex.indexOf(tgt.charAt(0));

            if (ix != -1) {
                // target is a category
                gcat = cat[ix].indexOf(inword.charAt(i));
                if (gcat == -1) {
                    return false;
                } else {
                    glen = tgt.length == 0 ? 0 : 1;
                    if (tgt.length > 1) {
                        var tlen = tgt.length - 1;
                        if (!IsTarget(
                            tgt.substr(1, tlen ),
                            inword, i + 1))
                            return false;
                        glen += tlen;
                    }
                }
                i += tgt.length;
            } else {
                if (!IsTarget(tgt, inword, i))
                    return false;
                i += glen;
            }
            break;
        default: // elsewhere in the environment
            var cont = (i < inword.length);
            if (cont) {
                cont = MatchCharOrCat(inword.charAt(i), env.charAt(j));
                if (cont) i++;
            }
            if (!optional && !cont) return false;
        }
    }
    return true;
}

function CatSub(repl)
{
    var outs = '';
    var lastch = '';

    for (var i = 0; i < repl.length; i++) {
        var ix = catindex.indexOf(repl.charAt(i));
        if (ix != -1) {
            if (gcat < cat[ix].length) {
                lastch = cat[ix].charAt(gcat);
                outs += lastch;
            }
        } else if (repl.charAt(i) == '\u00b2') {
            outs += lastch;
        } else {
            lastch = repl.charAt(i);
            outs += lastch;
        }
    }

    return outs;
}

// Apply a single rule to this word
function ApplyRule(inword, r)
{
    var outword = "";
    var t = rul[r].replace('\u2192', "/");
    var thisrule = t.split("/");
    var i = 0;

    while (i <= inword.length && inword.charAt(i) != '\u2023') {
        if (Match(inword, i, thisrule[0], thisrule[2])) {

            var tgt = thisrule[0];
            var repl = thisrule[1];

            if (thisrule.length > 3) {
                // There's an exception
                var slix = thisrule[3].indexOf('_');
                if (slix != -1) {
                    var tgix = gix;
                    var tglen = glen;
                    var tgcat = gcat;

                    // How far before _ do we check?
                    var brackets = false;
                    var precount = 0;
                    for (var k = 0; k < slix; k++) {
                        switch (thisrule[3].charAt(k)) {
                        case '[':
                            brackets = true;
                            break;
                        case ']':
                            brackets = false;
                            precount++;
                            break;
                        case '#':
                            break;
                        default:
                            if (!brackets) precount++;
                        }
                    }

                    if (gix - precount >= 0 &&
                        Match(inword, gix - precount,
                        thisrule[0], thisrule[3])) {
                        s += rul[r] + " almost applied to "
                            + inword + " at " + i + "<br>";
                        i++;
                        continue;
                    }
                    gix = tgix;
                    glen = tglen;
                    gcat = tgcat;
                }
            }

            if (printRules) {
                s += rul[r] + " applies to "
                    + inword + " at " + i + "<br>";
            }
            outword = inword.substr(0, gix);

            if (repl.length > 0) {
                if (repl == "\\\\") {
                    var found = inword.substr(gix,glen);
                    outword += reverse(found);
                } else if (gcat != -1) {
                    outword += CatSub(repl);
                } else {
                    outword += repl;
                }
            }
            gix += glen;
            i = outword.length;

            if (tgt.length == 0) i++;

            outword += inword.substr(gix, inword.length - gix);

            inword = outword;
        } else {
            i++;
        }
    }

    if (outword != "")
        return outword;
    else
        return inword;
}

// Transform a single word
function Transform(inword)
{
    if (inword.length > 0) {
        // Try out each rule in turn
        for (r = 0; r < nrul; r++) {
            inword = ApplyRule(inword, r);
        }
    }

    return inword;
}


// DoWords
//  Read in each word in turn from the input file,
//  transform it according to the rules,
//  and output it to the output file.
function DoWords()
{
    var nWord = 0;
    var nDiff = 0;
    var olex = "";

    // Parse the input lexicon
    lex = rewrite($('#ilex'));
    nlex = lex.length;

    var oldolex;
    var localshowdiff = showDiff;
    if (showDiff) {
        var sx = $("#olex").html;
        if (sx == "")
            localshowdiff = false;
        else {
            sx = unrewrite(sx, true);
            sx = sx.replace(new RegExp("<(b|/b)>", "gi"), "");
            oldolex = sx.split("<br>");
        }
    }

    for (w = 0; w < nlex; w++) {
        var inword = lex[w];

        // remove trailing blanks
        while (inword.charCodeAt(inword.length - 1) == 32) {
            inword = inword.substr(0, inword.length - 1);
        }

        if (inword.length > 0) {
            if (inword.charCodeAt(inword.length - 1) == 13) {
                inword = inword.substr(0, inword.length - 1);
            }

            var outword = Transform(inword);
            var outs;

            var parts = inword.split(" \u2023");
            if (parts.length > 1)
                inword = parts[0];

            switch (outtype) {
            case 0:
                outs = outword;
                break;
            case 1:
                outs = inword + " → " + outword;
                break;
            case 2:
                outs = outword + " [" + inword + "]";
                break;
            }

            if (localshowdiff && w < oldolex.length
                && outs != oldolex[w]) {
                outs = outs.bold();
            }

            olex += unrewrite(outs, false) + "<br>";

            nWord++;
            if (inword != outword) nDiff++;
        }
    }

    s += "Categories found: " + catindex
        + "<br>Valid rules found: " + nrul
        + "<br>Words processed: " + nWord
        + "<br>Words changed: " + nDiff;

    $('#olex').html(olex);
}

// User hit the action button.  Make things happen!
function process()
{
    //Read parameters
    var theform = $('#theform');
    var outtypes = theform.find('input[name=outtype]')

    outtype = 0;
    if (outtypes[1].checked) outtype = 1;
    if (outtypes[2].checked) outtype = 2;

    printRules = theform.find('checkbox[name=report]').checked;
    showDiff = theform.find('checkbox[name=showdiff]').checked;
    rewout = theform.find('checkbox[name=rewout]').checked;

    // Stuff we can do once
    s = readStuff();

    // If that went OK, apply the rules
    if (s.length == 0) {

        DoWords();
    }

    // Set the output field
    $("#mytext").html(s);
}

function helpme()
{
    window.open("scahelp.html");
}

// Parse the SC field into the three input fields
function parsesc()
{
    rul = $('#rules').val().split('\n');
    nrul = rul.length;

    var orul = '';
    var orew = '';
    var ocat = '';

    $.each(rul, function(w, t) {
        if (t.indexOf('|') != -1)
            orew += t + '\n';
        else if (t.indexOf('=') != -1)
            ocat += t + '\n';
        else
            orul += t + '\n';
    });

    if (ocat == '' && $('#cats').val() != '') {
        alert("No categories were found in the sound changes area, and you have content in the categories area.  You probably don't want to do a Parse then.");
        return;
    }
    if (orew == '' && $('#rewrite').val() != '') {
        alert("No rewrite rules were found in the sound changes area, and you have content in the rewrite rules area.  You probably don't want to do a Parse then.");
        return;
    }

    $('#cats').val(ocat);
    $('#rewrite').val(orew);
    $('#rules').val(orul);
}

// Copy all three input fields back into the SC area
function intosc()
{
    $('#rules').val(
        $('#cats').val() + '\n' +
        $('#rewrite').val() + '\n' +
        $('#rules').val() + '\n'
    );
}

// Display the IPA
function showipa()
{
    s = "<font face='Gentium'>&#x00b2; &#x2023; &#x2026; ";
    for (var i = 0x0250; i <= 0x02af; i++) {
        s += String.fromCharCode(i) + " ";
    }
    for (var i = 0x00c0; i <= 0x0237; i++) {
        s += String.fromCharCode(i) + " ";
    }
    s += "</font>";
    $('#mytext').html(s);
}

fs = require('fs')

SQ2 = '\u00b2'             # superscript 2 (gemination/degemination)
ELI = '\u2026'             # horizontal ellipsis
TRI = '\u2023'             # triangular bullet

class Rule
    constructor: (@sounds, @rule) ->
        [@tgt, @rpl, env] = @rule.split('/')
        [@before, @after] = env.split '_'
        console.log 'rule', @rule, @pattern(), @replace()
    pattern: =>
        [@expand(@before), @expand(@tgt), @expand(@after)].join('')
    replace: =>
        return @matcher if @rpl of @sounds.cats
        s = ''
        i = 0
        s += "$#{++i}" if @before and @before != '#'
        i++ if @tgt
        s += @rpl
        s += "$#{++i}" if @after and @after != '#'
        s
    apply: (word) =>
        while true
            oword = word.replace(new RegExp(@pattern(), "gi"), @replace())
            break if oword == word
            #console.log @rule, 'applies to', word
            word = oword
            break unless @tgt
        word
    expand: (s) =>
        return '' unless s
        return '\\b' if s is '#'
        r = ''
        for c in s
            if c of @sounds.cats
                r += "[#{@sounds.cats[c]}]"
            else if c == '#'
                r += '\\b'
            else if c == ELI
                r += '.*'
            else
                r += c.replace /\(([^)]*)\)/, '\\1?'
        "(#{r})"
    matcher: (str) =>
        [r,i] = ['',0]
        r += arguments[++i] if @before
        r += @sounds.cats[@rpl][@sounds.cats[@tgt].indexOf(arguments[++i])]
        r += arguments[++i] if @after
        r
    toString: => "Rule(#{@rule})"

class Sounds
    constructor: (filename) ->
        @cats = {}
        @rules = []
        @rewrites = []
        data = fs.readFileSync filename, 'utf8'
        for line in data.split '\n'
            continue unless line        # skip blank lines
            if '=' in line
                cat = line.split '='
                @cats[cat[0]] = cat[1]
            else if '/' in line
                @rules.push new Rule(@, line)
            else if '|' in line
                @rewrites.push line.split('|')
    run: (filename) =>
        filename = '/dev/stdin' unless filename?
        lexicon = fs.readFileSync filename, 'utf8'
        lexicon = lexicon.replace(/[\n\r., ] */g, ' ')
        for iword in lexicon.split ' '
            continue unless iword
            oword = iword
            for rule in @rules
                oword = rule.apply oword
            for a,b in @rewrites
                oword = oword.replace b, a
            #if iword == oword
            #    console.log iword
            #else
            #    console.log iword, '->', oword
            console.log oword

#sounds = new Sounds 'sca2.sc'
#sounds.run()

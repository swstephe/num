#!/usr/bin/env python
#-*- coding: utf-8 -*-
import re
import sys

SQ2 = u'\u00b2'             # superscript 2 (gemination/degemination)
ELI = u'\u2026'             # horizontal ellipsis
TRI = u'\u2023'             # triangular bullet

class Rule(object):
    def __init__(self, sounds, rule):
        self.sounds = sounds
        self.rule = rule
        rule = rule.split('/')
        self.tgt = rule[0]
        self.repl = rule[1]
        self.before, self.after = rule[2].split('_')
        print 'rule', repr(self.rule), repr(self.pattern), repr(self.replace)
    @property
    def pattern(self):
        return ur''.join((
            self.expand(self.before),
            self.expand(self.tgt),
            self.expand(self.after)
        ))
    @property
    def replace(self):
        if self.repl in self.sounds.cats: return self.matcher
        s = ''
        i = 0
        if self.before and self.before != ur'#':
            i += 1
            s += ur'\%d'%i
        if self.tgt: i += 1
        s += self.repl
        if self.after and self.after != ur'#':
            i += 1
            s += ur'\%d'%i
        return s
    def apply(self, word):
        while True:
            oword = re.sub(self.pattern, self.replace, word, re.I)
            if oword == word: break
            print self.rule, 'applies to', word
            word = oword
            if not self.tgt: break
        return word
    def expand(self, s):
        if not s: return ur''
        if s == ur'#': return ur'\b'
        r = ur''
        for c in s:
            if c in self.sounds.cats:
                r += ur'[%s]'%self.sounds.cats[c]
            elif c == ur'#':
                r += ur'\b'
            elif c == ELI:
                r += ur'.*'
            else:
                r += re.sub('\(([^)]*)\)', '\1?', c)
        return ur'(%s)'%r

    def matcher(self, m):
        r,i = ur'',0
        if self.before:
            i += 1
            r += m.group(i)
        i += 1
        r += self.sounds.cats[self.repl][
            self.sounds.cats[self.tgt].find(m.group(i))
        ]
        if self.after:
            i += 1
            r += m.group(i)
        return r
    def __call__(self, word):
        return self.apply(word)
    def __str__(self):
        return 'Rule(%r)'%self.rule

class Sounds(object):
    def __init__(self, filename):
        self.cats = {}
        self.rules = []
        self.rewrites = []
        with open(filename, 'rt') as f:
            for line in f.readlines():
                line = line.strip().decode('utf-8')
                if not line: continue       # skip blank lines
                if '=' in line:
                    cat = line.split('=')
                    self.cats[cat[0]] = cat[1]
                elif '/' in line:
                    self.rules.append(Rule(self, line))
                elif '|' in line:
                    self.rewrites.append(line.split('|'))
    def run(self, filename=None):
        if filename:
            f = open(filename, 'rt')
        else:
            f = sys.stdin
        lexicon = f.read().decode('utf-8')
        f.close()
        lexicon = (lexicon
            .replace(u'\n', u' ')
            .replace(u'. ', u' ')
            .replace(u', ', u' ')
            .replace(u'.',  u' ')
            .replace(u',',  u' ')
        ).split(' ')
        for iword in lexicon:
            oword = iword
            for rule in self.rules:
                oword = rule(oword)
            for a,b in self.rewrites:
                oword = oword.replace(b,a)
            if iword == oword:
                print iword
            else:
                print iword, '->', oword

sounds = Sounds('sca2.sc')
sounds.run('latin.lex')


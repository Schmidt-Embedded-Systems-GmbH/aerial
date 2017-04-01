/*******************************************************************
 *     This is part of Aerial, it is distributed under the         *
 *  terms of the GNU Lesser General Public License version 3       *
 *           (see file LICENSE for more details)                   *
 *                                                                 *
 *  Copyright 2017:                                                *
 *  Dmitriy Traytel (ETH Zürich)                                   *
 *******************************************************************/

%{
open Util
open Mdl
%}

%token <string> ATOM
%token <int> NUM
%token LOPEN LCLOSED ROPEN RCLOSED LANGLE RANGLE COMMA INFINITY
%token FALSE TRUE EMPTY EPSILON NEG CONJ DISJ PLUS IMP IFF EOF
%token QUESTION STAR
%token SINCE UNTIL WUNTIL RELEASE TRIGGER
%token NEXT PREV ALWAYS EVENTUALLY HISTORICALLY ONCE

%right IFF
%right IMP
%nonassoc PREV NEXT ALWAYS EVENTUALLY ONCE HISTORICALLY
%nonassoc SINCE UNTIL WUNTIL RELEASE TRIGGER
%left DISJ
%left CONJ
%nonassoc NEG

%type <Mdl.formula> formula
%start formula

%%
binterval:
| LOPEN NUM COMMA NUM ROPEN     { lopen_ropen_BI $2 $4 }
| LOPEN NUM COMMA NUM RCLOSED   { lopen_rclosed_BI $2 $4 }
| LCLOSED NUM COMMA NUM ROPEN   { lclosed_ropen_BI $2 $4 }
| LCLOSED NUM COMMA NUM RCLOSED { lclosed_rclosed_BI $2 $4 }

interval:
| binterval                          { B $1 }
| LOPEN NUM COMMA INFINITY ROPEN     { U (lopen_UI $2) }
| LCLOSED NUM COMMA INFINITY ROPEN   { U (lclosed_UI $2) }
| LOPEN NUM COMMA INFINITY RCLOSED   { U (lopen_UI $2) }
| LCLOSED NUM COMMA INFINITY RCLOSED { U (lclosed_UI $2) }

formula:
| e EOF { $1 }

e:
| LOPEN e ROPEN                 { $2 }
| TRUE                          { bool true }
| FALSE                         { bool false }
| e CONJ e                      { conj $1 $3 }
| e DISJ e                      { disj $1 $3 }
| e IMP e                       { imp $1 $3 }
| e IFF e                       { iff $1 $3 }
| NEG e                         { neg $2 }
| ATOM                          { p $1 }
| ATOM LOPEN ROPEN              { p $1 }
| LANGLE re RANGLE interval e   { possiblyF $2 $4 $5 }
| LANGLE re RANGLE e            { possiblyF $2 full $4 }
| LCLOSED re RCLOSED interval e { necessarilyF $2 $4 $5 }
| LCLOSED re RCLOSED e          { necessarilyF $2 full $4 }
| e interval LANGLE re RANGLE   { possiblyP $1 $2 $4 }
| e LANGLE re RANGLE            { possiblyP $1 full $3 }
| e interval LCLOSED re RCLOSED { necessarilyP $1 $2 $4 }
| e LCLOSED re RCLOSED          { necessarilyP $1 full $3 }
| e SINCE interval e            { since $3 $1 $4 }
| e SINCE e                     { since full $1 $3 }
| e TRIGGER interval e          { trigger $3 $1 $4 }
| e TRIGGER e                   { trigger full $1 $3 }
| e UNTIL interval e            { until $3 $1 $4 }
| e UNTIL e                     { until full $1 $3 }
| e WUNTIL interval e           { weak_until $3 $1 $4 }
| e WUNTIL e                    { weak_until full $1 $3 }
| e RELEASE interval e          { release $3 $1 $4 }
| e RELEASE e                   { release full $1 $3 }
| NEXT interval e               { next $2 $3 }
| NEXT e                        { next full $2 }
| PREV interval e               { prev $2 $3 }
| PREV e                        { prev full $2 }
| ONCE interval e               { once $2 $3 }
| ONCE e                        { once full $2 }
| HISTORICALLY interval e       { historically $2 $3 }
| HISTORICALLY e                { historically full $2 }
| ALWAYS interval e             { always $2 $3 }
| ALWAYS e                      { always full $2 }
| EVENTUALLY interval e         { eventually $2 $3 }
| EVENTUALLY e                  { eventually full $2 }

re:
| LOPEN re ROPEN          { $2 }
| EMPTY                   { empty }
| EPSILON                 { epsilon }
| e                       { base $1 }
| e QUESTION              { test $1 }
| re PLUS re              { alt $1 $3 }
| re re                   { seq $1 $2 }
| re STAR                 { star $1 }
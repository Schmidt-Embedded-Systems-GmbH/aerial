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
%token <Util.interval> INTERVAL
%token LOPEN LCLOSED ROPEN RCLOSED LANGLE RANGLE
%token FALSE TRUE EMPTY EPSILON NEG CONJ DISJ PLUS IMP IFF EOF
%token CONCAT
%token WILDCARD QUESTION STAR BASE
%token MODALITY
%token SINCE UNTIL WUNTIL RELEASE TRIGGER
%token NEXT PREV ALWAYS EVENTUALLY HISTORICALLY ONCE

%nonassoc INTERVAL
%nonassoc LOPEN
%nonassoc BASE
%nonassoc LANGLE LCLOSED ROPEN
%nonassoc TRUE FALSE EMPTY EPSILON WILDCARD
%right IFF
%right IMP
%nonassoc MODALITY
%nonassoc PREV NEXT ALWAYS EVENTUALLY ONCE HISTORICALLY
%nonassoc SINCE UNTIL WUNTIL RELEASE TRIGGER
%left DISJ
%left CONJ
%left PLUS
%left CONCAT
%nonassoc NEG
%nonassoc STAR
%nonassoc ATOM

%type <Mdl.formula> formula
%start formula

%%

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
| LANGLE reF RANGLE INTERVAL e   { possiblyF $2 $4 $5 }  %prec MODALITY
| LANGLE reF RANGLE e            { possiblyF $2 full $4 } %prec MODALITY
| LCLOSED reF RCLOSED INTERVAL e { necessarilyF $2 $4 $5 } %prec MODALITY 
| LCLOSED reF RCLOSED e          { necessarilyF $2 full $4 } %prec MODALITY 
| e INTERVAL LANGLE reP RANGLE   { possiblyP $1 $2 $4 }
| e LANGLE reP RANGLE            { possiblyP $1 full $3 }
| e INTERVAL LCLOSED reP RCLOSED { necessarilyP $1 $2 $4 }
| e LCLOSED reP RCLOSED          { necessarilyP $1 full $3 }
| e SINCE INTERVAL e            { since $3 $1 $4 }
| e SINCE e                     { since full $1 $3 }
| e TRIGGER INTERVAL e          { trigger $3 $1 $4 }
| e TRIGGER e                   { trigger full $1 $3 }
| e UNTIL INTERVAL e            { until $3 $1 $4 }
| e UNTIL e                     { until full $1 $3 }
| e WUNTIL INTERVAL e           { weak_until $3 $1 $4 }
| e WUNTIL e                    { weak_until full $1 $3 }
| e RELEASE INTERVAL e          { release $3 $1 $4 }
| e RELEASE e                   { release full $1 $3 }
| NEXT INTERVAL e               { next $2 $3 }
| NEXT e                        { next full $2 }
| PREV INTERVAL e               { prev $2 $3 }
| PREV e                        { prev full $2 }
| ONCE INTERVAL e               { once $2 $3 }
| ONCE e                        { once full $2 }
| HISTORICALLY INTERVAL e       { historically $2 $3 }
| HISTORICALLY e                { historically full $2 }
| ALWAYS INTERVAL e             { always $2 $3 }
| ALWAYS e                      { always full $2 }
| EVENTUALLY INTERVAL e         { eventually $2 $3 }
| EVENTUALLY e                  { eventually full $2 }

reF:
| LOPEN reF ROPEN         { $2 }
| EMPTY                   { empty }
| EPSILON                 { epsilon }
| WILDCARD                { wild }
| e                       { baseF $1 } %prec BASE
| e QUESTION              { test $1 }
| reF PLUS reF            { alt $1 $3 }
| reF reF                 { seq $1 $2 } %prec CONCAT
| reF STAR                { star $1 }

reP:
| LOPEN reP ROPEN         { $2 }
| EMPTY                   { empty }
| EPSILON                 { epsilon }
| WILDCARD                { wild }
| e                       { baseP $1 } %prec BASE
| e QUESTION              { test $1 }
| reP PLUS reP            { alt $1 $3 }
| reP reP                 { seq $1 $2 } %prec CONCAT
| reP STAR                { star $1 }

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
%token LOPEN LCLOSED ROPEN RCLOSED LANGLE RANGLE FORWARD BACKWARD
%token FALSE TRUE EMPTY EPSILON NEG CONJ DISJ PLUS IMP IFF EOF
%token CONCAT
%token WILDCARD QUESTION STAR BASE
%token MODALITY
%token SINCE UNTIL WUNTIL RELEASE TRIGGER
%token NEXT PREV ALWAYS EVENTUALLY HISTORICALLY ONCE

%nonassoc TRUE FALSE EMPTY EPSILON WILDCARD
%right IFF
%right IMP
%nonassoc MODALITY
%nonassoc BACKWARD FORWARD
%nonassoc PREV NEXT ALWAYS EVENTUALLY ONCE HISTORICALLY
%left SINCE UNTIL WUNTIL RELEASE TRIGGER
%left DISJ
%left CONJ
%left PLUS
%left CONCAT
%nonassoc NEG
%nonassoc STAR
%nonassoc LOPEN
%nonassoc BASE QUESTION
%nonassoc INTERVAL
%nonassoc LANGLE LCLOSED ROPEN
%nonassoc ATOM

%type <Mdl.formula> formula
%start formula

%%

formula:
| f=f EOF { f }

f:
| LOPEN f=f ROPEN                       { f }
| TRUE                                  { bool true }
| FALSE                                 { bool false }
| f=f CONJ g=f                          { conj f g }
| f=f DISJ g=f                          { disj f g }
| f=f IMP g=f                           { imp f g }
| f=f IFF g=f                           { iff f g }
| NEG f=f                               { neg f }
| a=ATOM                                { p a }
| LANGLE r=reF RANGLE i=INTERVAL f=f    { possiblyF r i f }  %prec MODALITY
| LANGLE r=reF RANGLE f=f               { possiblyF r full f } %prec MODALITY
| LCLOSED r=reF RCLOSED i=INTERVAL f=f  { necessarilyF r i f } %prec MODALITY
| LCLOSED r=reF RCLOSED f=f             { necessarilyF r full f } %prec MODALITY
| f=f i=INTERVAL LANGLE r=reP RANGLE    { possiblyP f i r }
| f=f LANGLE r=reP RANGLE               { possiblyP f full r }
| f=f i=INTERVAL LCLOSED r=reP RCLOSED  { necessarilyP f i r }
| f=f LCLOSED r=reP RCLOSED             { necessarilyP f full r }
| f=f SINCE i=INTERVAL g=f              { since i f g }
| f=f SINCE g=f                         { since full f g }
| f=f TRIGGER i=INTERVAL g=f            { trigger i f g }
| f=f TRIGGER g=f                       { trigger full f g }
| f=f UNTIL i=INTERVAL g=f              { until i f g }
| f=f UNTIL g=f                         { until full f g }
| f=f WUNTIL i=INTERVAL g=f             { weak_until i f g }
| f=f WUNTIL g=f                        { weak_until full f g }
| f=f RELEASE i=INTERVAL g=f            { release i f g }
| f=f RELEASE g=f                       { release full f g }
| FORWARD i=INTERVAL r=reF              { matchF r i } %prec FORWARD
| FORWARD r=reF                         { matchF r full }
| BACKWARD i=INTERVAL r=reP             { matchP r i } %prec BACKWARD
| BACKWARD r=reP                        { matchP r full }
| NEXT i=INTERVAL f=f                   { next i f }
| NEXT f=f                              { next full f }
| PREV i=INTERVAL f=f                   { prev i f }
| PREV f=f                              { prev full f }
| ONCE i=INTERVAL f=f                   { once i f }
| ONCE f=f                              { once full f }
| HISTORICALLY i=INTERVAL f=f           { historically i f }
| HISTORICALLY f=f                      { historically full f }
| ALWAYS i=INTERVAL f=f                 { always i f }
| ALWAYS f=f                            { always full f }
| EVENTUALLY i=INTERVAL f=f             { eventually i f }
| EVENTUALLY f=f                        { eventually full f }

reF:
| LOPEN r=reF ROPEN     { r }
| EMPTY                 { empty }
| EPSILON               { epsilon }
| WILDCARD              { wild }
| f=f                   { baseF f } %prec BASE
| f=f QUESTION          { test f }
| r=reF PLUS s=reF      { alt r s }
| r=reF s=reF           { seq r s } %prec CONCAT
| r=reF STAR            { star r }

reP:
| LOPEN r=reP ROPEN     { r }
| EMPTY                 { empty }
| EPSILON               { epsilon }
| WILDCARD              { wild }
| f=f                   { baseP f } %prec BASE
| f=f QUESTION          { test f }
| r=reP PLUS s=reP      { alt r s }
| r=reP s=reP           { seq r s } %prec CONCAT
| r=reP STAR            { star r }

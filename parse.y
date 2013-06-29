// at first, read this: http://whitequark.org/blog/2013/04/01/ruby-hacking-guide-ch-11-finite-state-lexer/

%{
#if DEBUG
// #define DEV 1
#define DEV 1
#endif // DEBUG
;(function(){ // whole parser and lexer namespace start

"use strict";

// returns own property or `undefined`
// used at least in Lexer
var hasOwnProperty = Object.prototype.hasOwnProperty;
function ownProperty (obj, prop)
{
  if (hasOwnProperty.call(obj, prop))
    return obj[prop];
  // has no such property
  return undefined;
}

// useful when adding an array elements to the end of array
var Array_push = Array.prototype.push;

// char to code shortcut
function $ (c) { return c.charCodeAt(0) }
function $$ (code) { return String.fromCharCode(code) }

%}

%code lexer {

// here we know all the token numbers as a list of constant variables
// 
//   var END_OF_INPUT = 0;
//   var keyword_class = 258;
//   var keyword_module = 259;
// 
// and so on.

#include "lexer.js"

}

%code actions {

// here goes the code needed in rules only, when generating nodes,
// we still know all the token numbers here too.
#include "builder.js"

var scope = new Scope();
var builder = new Builder(lexer);
builder.scope = scope;

lexer.setScope(scope);

}

%skeleton "./lalr1.js"

%token <id>   keyword_class keyword_module keyword_def keyword_undef keyword_begin keyword_rescue keyword_ensure keyword_end keyword_if keyword_unless keyword_then keyword_elsif keyword_else keyword_case keyword_when keyword_while keyword_until keyword_for keyword_break keyword_next keyword_redo keyword_retry keyword_in keyword_do keyword_do_cond keyword_do_block keyword_do_LAMBDA keyword_return keyword_yield keyword_super keyword_self keyword_nil keyword_true keyword_false keyword_and keyword_or keyword_not modifier_if modifier_unless modifier_while modifier_until modifier_rescue keyword_alias keyword_defined keyword_BEGIN keyword_END keyword__LINE__ keyword__FILE__ keyword__ENCODING__

%token <id>   tIDENTIFIER tFID tGVAR tIVAR tCONSTANT tCVAR tLABEL
%token <node> tINTEGER tFLOAT tSTRING_CONTENT tCHAR
%token <node> tNTH_REF tBACK_REF
%token <num>  tREGEXP_END

%type <node> singleton strings string string1 xstring regexp
%type <node> string_contents xstring_contents regexp_contents string_content
%type <node> words symbols symbol_list qwords qsymbols word_list qword_list qsym_list word
%type <node> literal numeric dsym cpath
%type <node> top_compstmt top_stmts top_stmt
%type <node> bodystmt compstmt stmts stmt_or_begin stmt expr arg primary command command_call method_call
%type <node> expr_value arg_value primary_value fcall
%type <node> if_tail opt_else case_body cases opt_rescue exc_list exc_var opt_ensure
%type <node> args call_args opt_call_args
%type <node> paren_args opt_paren_args args_tail opt_args_tail block_args_tail opt_block_args_tail
%type <node> command_args aref_args opt_block_arg block_arg var_ref var_lhs
%type <node> command_asgn mrhs superclass block_call block_command
%type <node> f_block_optarg f_block_opt
%type <node> f_arglist f_args f_arg f_arg_item f_optarg f_marg f_marg_list f_margs
%type <node> assoc_list assocs assoc undef_list backref string_dvar for_var
%type <node> block_param opt_block_param block_param_def f_opt
%type <node> f_kwarg f_kw f_block_kwarg f_block_kw
%type <node> bv_decls opt_bv_decl bvar
%type <node> lambda f_larglist lambda_body
%type <node> brace_block cmd_brace_block do_block lhs none fitem
%type <node> mlhs mlhs_head mlhs_basic mlhs_item mlhs_node mlhs_post mlhs_inner
%type <id>   fsym keyword_variable user_variable sym symbol operation operation2 operation3
%type <id>   cname fname op f_rest_arg f_block_arg opt_f_block_arg f_norm_arg f_bad_arg
%type <id>   f_kwrest
%type <id>   k_end
/*%%%*/
/*%
%type <val> program reswords then do dot_or_colon
%*/
%type  <id> dot_or_colon
%token <id> END_OF_INPUT 0    "end-of-input"
%token <id> tUPLUS            "unary+"
%token <id> tUMINUS           "unary-"
%token <id> tPOW              "**"
%token <id> tCMP              "<=>"
%token <id> tEQ               "=="
%token <id> tEQQ              "==="
%token <id> tNEQ              "!="
%token <id> tGEQ              ">="
%token <id> tLEQ              "<="
%token <id> tANDOP            "&&"
%token <id> tOROP             "||"
%token <id> tMATCH            "=~"
%token <id> tNMATCH           "!~"
%token <id> tDOT2             ".."
%token <id> tDOT3             "..."
%token <id> tAREF             "[]"
%token <id> tASET             "[]="
%token <id> tLSHFT            "<<"
%token <id> tRSHFT            ">>"
%token <id> tCOLON2           "::"
%token <id >tCOLON3           ":: at EXPR_BEG"
%token <id> tOP_ASGN    /* +=, -=  etc. */
%token <id> tASSOC            "=>"
%token <id> tLPAREN           "("
%token <id> tLPAREN_ARG       "( arg"
%token <id> tRPAREN           ")"
%token <id> tLBRACK           "["
%token <id> tLBRACE           "{"
%token <id> tLBRACE_ARG       "{ arg"
%token <id> tSTAR             "*"
%token <id> tDSTAR            "**arg"
%token <id> tAMPER            "&"
%token <id> tLAMBDA           "->"
%token <id> tSYMBEG tSTRING_BEG tXSTRING_BEG tREGEXP_BEG tWORDS_BEG tQWORDS_BEG tSYMBOLS_BEG tQSYMBOLS_BEG
%token <id> tSTRING_DBEG tSTRING_DEND tSTRING_DVAR tSTRING_END tLAMBEG

/*
 *    precedence table
 */

%nonassoc tLOWEST
%nonassoc tLBRACE_ARG

%nonassoc  modifier_if modifier_unless modifier_while modifier_until
%left  keyword_or keyword_and
%right keyword_not
%nonassoc keyword_defined
%right '=' tOP_ASGN
%left modifier_rescue
%right '?' ':'
%nonassoc tDOT2 tDOT3
%left  tOROP
%left  tANDOP
%nonassoc  tCMP tEQ tEQQ tNEQ tMATCH tNMATCH
%left  '>' tGEQ '<' tLEQ
%left  '|' '^'
%left  '&'
%left  tLSHFT tRSHFT
%left  '+' '-'
%left  '*' '/' '%'
%right tUMINUS_NUM tUMINUS
%right tPOW
%right '!' '~' tUPLUS

%token <id> '?' '>' '<' '|' '^' '&' '+' '-' '*' '/' '%' '{' '}' '[' '.' ',' '~' '`' '(' ')' ']' ';' '\n'


// must be last indeed
%token tLAST_TOKEN

// in rules (and generator) we have access to those things:
//   * all the code from prologue (not much though);
//   * `lexer`: instance of our Lexer class from the lexer code block;
//   * `parser`: instance of our Parser class;
//   * $$ and $N through the `yyval` and `yystack` local variables
//   * all the code and variables from `rules` code block.
// 
// Repeated in generator.js

%%
program:
    {
      lexer.lex_state = EXPR_BEG;
      // creates a new chain link of `lvtbl`es
      scope.push_static();
    }
    top_compstmt
    {
      scope.pop();
      
      parser.resulting_ast = $2;
    };

top_compstmt:
    top_stmts opt_terms
    {
      // was: void_stmts($1);
      // was: fixup_nodes(deferred_nodes);
      $$ = builder.compstmt($1);
    };

top_stmts:
  none
    {
      $$ = []; // statements accumulator
    }

  | top_stmt
    {
      $$ = [$1];
    }
  
  | top_stmts terms top_stmt
    {
      $1.push($3);
      $$ = $1;
    }
  
  | error top_stmt
    {
      $$ = [$2];
    };

top_stmt
  :
    stmt
  |
    keyword_BEGIN
    {
      // RIPPER
    }
    '{' top_compstmt '}'
    {
      $$ = builder.preexe($4);
    }
  ;

bodystmt:
    compstmt opt_rescue opt_else opt_ensure
    {
      var rescue_bodies   = $2;
      var else_           = $3;
      var ensure          = $4;

      if (else_ != null && rescue_bodies.length == 0)
      {
        // TODO
        // diagnostic :warning, :useless_else, else_t
        this.lexer.warn("else without rescue is useless");
      }

      $$ = builder.begin_body($1, rescue_bodies, else_, ensure);
    };

compstmt:
    stmts opt_terms
    {
      // void_stmts($1);
      // fixup_nodes(deferred_nodes);
      // $$ = $1;
    };

stmts:
    none
    {
      $$ = [];
    }

  | stmt_or_begin
    {
      $$ = [$1];
    }

  | stmts terms stmt_or_begin
    {
      var stmts = $1;
      stmts.push($3);
      $$ = stmts;
    }

  | error stmt
    {
      $$ = [ $2 ];
    };

stmt_or_begin:
    stmt
  |
    keyword_BEGIN
    {
      if (lexer.in_def)
      {
        lexer.yyerror("BEGIN is permitted only at toplevel");
      }
    }
    '{' top_compstmt '}'
    {
      $$ = builder.preexe($4);
    };

stmt:
    keyword_alias fitem
    {
      lexer.lex_state = EXPR_FNAME;
    }
    fitem
    {
      $$ = builder.alias($2, $4);
    }
  |
    keyword_alias tGVAR tGVAR
    {
      $$ = builder.alias_gvar_gvar($2, $3);
    }
  |
    keyword_alias tGVAR tBACK_REF
    {
      $$ = builder.alias_gvar_backref($2, $3);
    }
  |
    keyword_alias tGVAR tNTH_REF
    {
      lexer.yyerror("can't make alias for the number variables");
      // $$ = NEW_BEGIN(null);
    }
  |
    keyword_undef undef_list
    {
      $$ = builder.undef_method($2);
    }
  |
    stmt modifier_if expr_value
    {
      // true branch, null, the body
      $$ = builder.condition_mod($1, null, $3);
    }
  |
    stmt modifier_unless expr_value
    {
      // null, false branch, the body
      $$ = builder.condition_mod(null, $1, $3);
    }
  |
    stmt modifier_while expr_value
    {
      $$ = builder.loop_mod('while', $1, $3);
    }
  |
    stmt modifier_until expr_value
    {
      $$ = builder.loop_mod('until', $1, $3);
    }
  |
    stmt modifier_rescue stmt
    {
      // exc_list, exc_var, compound_stmt
      var rescue_body = builder.rescue_body(null, null, $3);
      $$ = builder.begin_body($1, [ rescue_body ]);
    }
  |
    keyword_END '{' compstmt '}'
    {
      if (lexer.in_def || lexer.in_single)
      {
        lexer.warn("END in method; use at_exit");
      }
      
      $$ = builder.postexe($3);
    }
  |
    command_asgn
  |
    mlhs '=' command_call
    {
      $$ = builder.multi_assign($1, $3);
    }
  |
    var_lhs tOP_ASGN command_call
    {
      $$ = builder.op_assign($1, $2, $3);
    }
  |
    primary_value '[' opt_call_args rbracket tOP_ASGN command_call
    {
      $$ = builder.op_assign(builder.index($1, $3), $5, $6);
    }
  |
    primary_value '.' tIDENTIFIER tOP_ASGN command_call
    {
      $$ = builder.op_assign(builder.call_method($1, $2, $3), $4, $5);
    }
  |
    primary_value '.' tCONSTANT tOP_ASGN command_call
    {
      $$ = builder.op_assign(builder.call_method($1, $2, $3), $4, $5);
    }
  |
    primary_value tCOLON2 tCONSTANT tOP_ASGN command_call
    {
      $$ = builder.op_assign(builder.call_method($1, $2, $3), $4, $5);
    }
  |
    primary_value tCOLON2 tIDENTIFIER tOP_ASGN command_call
    {
      $$ = builder.op_assign(builder.call_method($1, $2, $3), $4, $5);
    }
  |
    backref tOP_ASGN command_call
    {
      // expected to return `null` as Ruby doesn't allow backref assignment
      $$ = builder.op_assign($1, $2, $3);
    }
  |
    lhs '=' mrhs
    {
      // mrhs is an array
      $$ = builder.assign($1, builder.array($3));
    }
  |
    mlhs '=' arg_value
    {
      $$ = builder.multi_assign($1, $3);
    }
  |
    mlhs '=' mrhs
    {
      $$ = builder.multi_assign($1, builder.array($3));
    }
  |
    expr
  ;

command_asgn:
    lhs '=' command_call
    {
      $$ = builder.assign($1, $3);
    }
  |
    lhs '=' command_asgn
    {
      $$ = builder.assign($1, $3);
    }
  ;


expr
  :
    command_call
  |
    expr keyword_and expr
    {
      $$ = builder.logical_op('and', $1, $3);
    }
  | expr keyword_or expr
    {
      $$ = builder.logical_op('or', $1, $3);
    }
  |
    keyword_not opt_nl expr
    {
      $$ = builder.not_op($3);
    }
  |
    '!' command_call
    {
      $$ = builder.not_op($2);
    }
  |
    arg
  ;

expr_value:
    expr
  ;

command_call
  :
    command
  |
    block_command
  ;

block_command
  :
    block_call
  |
    block_call dot_or_colon operation2 command_args
    {
      $$ = builder.call_method($1, $2, $3, $4);
    }
  ;

cmd_brace_block:
    tLBRACE_ARG
    {
      scope.push_dynamic();
      // $<num>$ = lexer.ruby_sourceline;
    }
    opt_block_param compstmt '}'
    {
      $$ = { args: $3, body: $4 };
      
      // touching this alters the parse.output
      $<num>2; // nd_set_line($$, $<num>2);
      scope.pop();
    }
  ;

fcall:
    operation
    {
      // nd_set_line($$, tokline); TODO
    }
  ;

command:
    fcall command_args  %prec tLOWEST
    {
      $$ = builder.call_method(null, null, $1, $2);
    }
  |
    fcall command_args cmd_brace_block
    {
      var method_call = builder.call_method(null, null, $1, $2);

      var block = $3;
      $$ = builder.block(method_call, block.args, block.body);
    }
  |
    primary_value '.' operation2 command_args  %prec tLOWEST
    {
      $$ = builder.call_method($1, $2, $3, $4);
    }
  |
    primary_value '.' operation2 command_args cmd_brace_block
    {
      var method_call = builder.call_method($1, $2, $3, $4);

      var block = $5;
      $$ = builder.block(method_call, block.args, block.body);
    }
  |
    primary_value tCOLON2 operation2 command_args    %prec tLOWEST
    {
      $$ = builder.call_method($1, $2, $3, $4);
    }
  |
    primary_value tCOLON2 operation2 command_args cmd_brace_block
    {
      var method_call = builder.call_method($1, $2, $3, $4);

      var block = $5;
      $$ = builder.block(method_call, block.args, block.body);
    }
  |
    keyword_super command_args
    {
      $$ = builder.keyword_cmd('super', $2);
    }
  |
    keyword_yield command_args
    {
      $$ = builder.keyword_cmd('yield', $2);
    }
  |
    keyword_return call_args
    {
      $$ = builder.keyword_cmd('return', $2);
    }
  |
    keyword_break call_args
    {
      $$ = builder.keyword_cmd('break', $2);
    }
  |
    keyword_next call_args
    {
      $$ = builder.keyword_cmd('next', $2);
    }
  ;

mlhs
  :
    mlhs_basic
    {
      $$ = builder.multi_lhs($1);
    }
  |
    tLPAREN mlhs_inner rparen
    {
      $$ = builder.begin($2);
    }
  ;

mlhs_inner:
    mlhs_basic
    {
      $$ = builder.multi_lhs($1);
    }
  |
    tLPAREN mlhs_inner rparen
    {
      $$ = builder.multi_lhs($2);
    }
  ;

mlhs_basic:
    mlhs_head
  |
    mlhs_head mlhs_item
    {
      var mlhs_head = $1;
      mlhs_head.push($2);
      $$ = mlhs_head;
    }
  |
    mlhs_head tSTAR mlhs_node
    {
      var mlhs_head = $1;
      mlhs_head.push(builder.splat($3));
      $$ = mlhs_head;
    }
  |
    mlhs_head tSTAR mlhs_node ',' mlhs_post
    {
      var mlhs_head = $1;
      mlhs_head.push(builder.splat($3));
      Array_push.apply(mlhs_head, $5);
      $$ = mlhs_head;
    }
  |
    mlhs_head tSTAR
    {
      var mlhs_head = $1;
      mlhs_head.push(builder.splat_empty());
      $$ = mlhs_head;
    }
  |
    mlhs_head tSTAR ',' mlhs_post
    {
      var mlhs_head = $1;
      mlhs_head.push(builder.splat_empty());
      Array_push.apply(mlhs_head, $4);
      $$ = mlhs_head;
    }
  |
    tSTAR mlhs_node
    {
      $$ = [ builder.splat($2) ];
    }
  |
    tSTAR mlhs_node ',' mlhs_post
    {
      var ary = [ builder.splat($2) ];
      Array_push.apply(mlhs_head, $4);
      $$ = ary;
    }
  |
    tSTAR
    {
      $$ = [ builder.splat_empty() ];
    }
  | tSTAR ',' mlhs_post
    {
      var ary = [ builder.splat_empty() ];
      Array_push.apply(mlhs_head, $3);
      $$ = ary;
    }
  ;

mlhs_item
  :
    mlhs_node
  |
    tLPAREN mlhs_inner rparen
    {
      $$ = builder.begin($2);
    }
  ;

mlhs_head
  :
    mlhs_item ','
    {
      $$ = [ $1 ];
    }
  |
    mlhs_head mlhs_item ','
    {
      var mlhs_head = $1;
      mlhs_head.push($2);
      $$ = mlhs_head;
    }
  ;

mlhs_post
  :
    mlhs_item
    {
      $$ = [ $1 ];
    }
  |
    mlhs_post ',' mlhs_item
    {
      var mlhs_post = $1;
      mlhs_post.push($3);
      $$ = mlhs_post;
    }
  ;

mlhs_node
  :
    user_variable
    {
      $$ = builder.assignable($1);
    }
  |
    keyword_variable
    {
      $$ = builder.assignable($1);
    }
  |
    primary_value '[' opt_call_args rbracket
    {
      $$ = builder.index_asgn($1, $3);
    }
  |
    primary_value '.' tIDENTIFIER
    {
      $$ = builder.attr_asgn($1, $2, $3);
    }
  |
    primary_value tCOLON2 tIDENTIFIER
    {
      $$ = builder.attr_asgn($1, $2, $3);
    }
  |
    primary_value '.' tCONSTANT
    {
      $$ = builder.attr_asgn($1, $2, $3);
    }
  |
    primary_value tCOLON2 tCONSTANT
    {
      if (lexer.in_def || lexer.in_single)
        lexer.yyerror("dynamic constant assignment");
      
      $$ = builder.assignable(builder.const_fetch(val[0], val[1], val[2]))
    }
  |
    tCOLON3 tCONSTANT
    {
      if (lexer.in_def || lexer.in_single)
        lexer.yyerror("dynamic constant assignment");
      
      $$ = builder.assignable(builder.const_global($2));
    }
  |
    backref
    {
      $$ = builder.assignable($1);
    }
  ;

lhs:
    user_variable
    {
      $$ = builder.assignable($1);
    }
  |
    keyword_variable
    {
      $$ = builder.assignable($1);
    }
  |
    primary_value '[' opt_call_args rbracket
    {
      $$ = builder.index_asgn($1, $3);
    }
  |
    primary_value '.' tIDENTIFIER
    {
      $$ = builder.attr_asgn($1, $2, $3);
    }
  |
    primary_value tCOLON2 tIDENTIFIER
    {
      $$ = builder.attr_asgn($1, $2, $3);
    }
  |
    primary_value '.' tCONSTANT
    {
      $$ = builder.attr_asgn($1, $2, $3);
    }
  |
    primary_value tCOLON2 tCONSTANT
    {
      if (lexer.in_def || lexer.in_single)
        lexer.yyerror("dynamic constant assignment");
      
      $$ = builder.assignable(builder.const_fetch($1, $2, $3));
    }
  |
    tCOLON3 tCONSTANT
    {
      if (lexer.in_def || lexer.in_single)
        lexer.yyerror("dynamic constant assignment");
      
      $$ = builder.assignable(builder.const_global($2));
    }
  |
    backref
    {
      $$ = builder.assignable($1);
    }
  ;

cname
  :
    tIDENTIFIER
    {
      lexer.yyerror("class/module name must be CONSTANT");
    }
  |
    tCONSTANT
  ;

cpath
  :
    tCOLON3 cname
    {
      $$ = builder.const_global($2);
    }
  |
    cname
    {
      $$ = builder.const_($1);
    }
  |
    primary_value tCOLON2 cname
    {
      $$ = builder.const_fetch($1, $2, $3);
    }
  ;

fname:
    tIDENTIFIER
  |
    tCONSTANT
  |
    tFID
  |
    op
    {
      lexer.lex_state = EXPR_ENDFN;
    }
  |
    reswords
    {
      lexer.lex_state = EXPR_ENDFN;
    }
  ;

fsym:
    fname
    {
      $$ = builder.symbol($1);
    }
  |
    symbol
  ;

fitem
  :
    fsym
    {}
  |
    dsym
  ;

undef_list
  :
    fitem
    {
      $$ = [ $1 ];
    }
  |
    undef_list ','
    {
      lexer.lex_state = EXPR_FNAME;
    }
    fitem
    {
      var undef_list = $1;
      undef_list.push($4);
      $$ = undef_list;
    }
  ;

op
  : '|'
  | '^'
  | '&'
  | tCMP
  | tEQ
  | tEQQ
  | tMATCH
  | tNMATCH
  | '>'
  | tGEQ
  | '<'
  | tLEQ
  | tNEQ
  | tLSHFT
  | tRSHFT
  | '+'
  | '-'
  | '*'
  | tSTAR
  | '/'
  | '%'
  | tPOW
  | tDSTAR
  | '!'
  | '~'
  | tUPLUS
  | tUMINUS
  | tAREF
  | tASET
  | '`'
  ;

reswords
  : keyword__LINE__ | keyword__FILE__ | keyword__ENCODING__
  | keyword_BEGIN | keyword_END
  | keyword_alias | keyword_and | keyword_begin
  | keyword_break | keyword_case | keyword_class | keyword_def
  | keyword_defined | keyword_do | keyword_else | keyword_elsif
  | keyword_end | keyword_ensure | keyword_false
  | keyword_for | keyword_in | keyword_module | keyword_next
  | keyword_nil | keyword_not | keyword_or | keyword_redo
  | keyword_rescue | keyword_retry | keyword_return | keyword_self
  | keyword_super | keyword_then | keyword_true | keyword_undef
  | keyword_when | keyword_yield | keyword_if | keyword_unless
  | keyword_while | keyword_until
  ;

arg:
    lhs '=' arg
    {
      $$ = builder.assign($1, $3);
    }
  |
    lhs '=' arg modifier_rescue arg
    {
      var rescue_body = builder.rescue_body(null, null, $5);
      var rescue = builder.begin_body($3, [ rescue_body ]);
      $$ = builder.assign($1, rescue);
    }
  |
    var_lhs tOP_ASGN arg
    {
      $$ = builder.op_assign($1, $2, $3);
    }
  |
    var_lhs tOP_ASGN arg modifier_rescue arg
    {
      var rescue_body = builder.rescue_body(null, null, $5);
      var rescue = builder.begin_body($3, [ rescue_body ]);
      $$ = builder.op_assign($1, $2, rescue);
    }
  |
    primary_value '[' opt_call_args rbracket tOP_ASGN arg
    {
      var index = builder.index($1, $3);
      $$ = builder.op_assign(index, $5, $6);
    }
  |
    primary_value '.' tIDENTIFIER tOP_ASGN arg
    {
      var call_method = builder.call_method($1, $2, $3);
      $$ = builder.op_assign(call_method, $4, $5);
    }
  |
    primary_value '.' tCONSTANT tOP_ASGN arg
    {
      var call_method = builder.call_method($1, $2, $3);
      $$ = builder.op_assign(call_method, $4, $5);
    }
  |
    primary_value tCOLON2 tIDENTIFIER tOP_ASGN arg
    {
      var call_method = builder.call_method($1, $2, $3);
      $$ = builder.op_assign(call_method, $4, $5);
    }
  |
    primary_value tCOLON2 tCONSTANT tOP_ASGN arg
    {
      // TODO
      // if in_def?
      //   diagnostic(:error, :dynamic_const, val[2], [ val[3] ])
      // end
      
      var const_ = builder.assignable(builder.const_fetch($1, $2, $3));
      $$ = builder.op_assign(const_, $4, $5);
    }
  |
    tCOLON3 tCONSTANT tOP_ASGN arg
    {
      // TODO
      // if in_def?
      //   diagnostic(:error, :dynamic_const, val[1], [ val[2] ])
      // end
      
      var const_  = builder.assignable(builder.const_global($2));
      $$ = builder.op_assign(const_, $3, $4);
    }
  |
    backref tOP_ASGN arg
    {
      // expected to return `null` as Ruby doesn't allow backref assignment
      $$ = builder.op_assign($1, $2, $3);
    }
  |
    arg tDOT2 arg
    {
      $$ = builder.range_inclusive($1, $3);
    }
  |
    arg tDOT3 arg
    {
      $$ = builder.range_exclusive($1, $3);
    }
  |
    arg '+' arg
    {
      $$ = builder.binary_op($1, $2, $3);
    }
  |
    arg '-' arg
    {
      $$ = builder.binary_op($1, $2, $3);
    }
  |
    arg '*' arg
    {
      $$ = builder.binary_op($1, $2, $3);
    }
  |
    arg '/' arg
    {
      $$ = builder.binary_op($1, $2, $3);
    }
  |
    arg '%' arg
    {
      $$ = builder.binary_op($1, $2, $3);
    }
  |
    arg tPOW arg
    {
      $$ = builder.binary_op($1, $2, $3);
    }
  |
    tUMINUS_NUM tINTEGER tPOW arg
    {
      // TODO: convert tINTEGER to NEW_LIT()
    }
  |
    tUMINUS_NUM tFLOAT tPOW arg
    {
      // TODO: convert tFLOAT to NEW_LIT()
    }
  |
    tUPLUS arg
    {}
  |
    tUMINUS arg
    {}
  |
    arg '|' arg
    {
      $$ = builder.binary_op($1, $2, $3);
    }
  |
    arg '^' arg
    {
      $$ = builder.binary_op($1, $2, $3);
    }
  |
    arg '&' arg
    {
      $$ = builder.binary_op($1, $2, $3);
    }
  |
    arg tCMP arg
    {
      $$ = builder.binary_op($1, $2, $3);
    }
  |
    arg '>' arg
    {
      $$ = builder.binary_op($1, $2, $3);
    }
  |
    arg tGEQ arg
    {
      $$ = builder.binary_op($1, $2, $3);
    }
  |
    arg '<' arg
    {
      $$ = builder.binary_op($1, $2, $3);
    }
  |
    arg tLEQ arg
    {
      $$ = builder.binary_op($1, $2, $3);
    }
  |
    arg tEQ arg
    {
      $$ = builder.binary_op($1, $2, $3);
    }
  |
    arg tEQQ arg
    {
      $$ = builder.binary_op($1, $2, $3);
    }
  |
    arg tNEQ arg
    {
      $$ = builder.binary_op($1, $2, $3);
    }
  |
    arg tMATCH arg
    {}
  |
    arg tNMATCH arg
    {
      $$ = builder.binary_op($1, $2, $3);
    }
  |
    '!' arg
    {
      $$ = builder.not_op($2);
    }
  |
    '~' arg
    {}
  |
    arg tLSHFT arg
    {
      $$ = builder.binary_op($1, $2, $3);
    }
  |
    arg tRSHFT arg
    {
      $$ = builder.binary_op($1, $2, $3);
    }
  |
    arg tANDOP arg
    {}
  |
    arg tOROP arg
    {}
  |
    keyword_defined opt_nl { lexer.in_defined = true;} arg
    {
      lexer.in_defined = false;
    }
  |
    arg '?' arg opt_nl ':' arg
    {}
  |
    primary
  ;

arg_value:
    arg
  ;

aref_args    : none
        | args trailer
            {}
        | args ',' assocs trailer
            {}
        | assocs trailer
            {}
        ;

paren_args:
    '(' opt_call_args rparen
    {
      $$ = $2;
    }
  ;

opt_paren_args:
    none
    {
      $$ = []; // args collector
    }
  |
    paren_args
  ;

opt_call_args:
    none
    {
      $$ = []; // args collector
    }
  | call_args
  | args ','
    {}
  | args ',' assocs ','
    {
      var args = $1;
      args.push(builder.associate($3));
      $$ = args;
    }
  | assocs ','
    {
      $$ = [ builder.associate($1) ];
    }
  ;

call_args    : command
            {}
        | args opt_block_arg
            {}
        | assocs opt_block_arg
            {}
        | args ',' assocs opt_block_arg
            {}
        | block_arg
        ;

command_args
  :
    {
      $<val>$ = lexer.cmdarg_stack;
      lexer.CMDARG_PUSH(1);
    }
    call_args
    {
      // CMDARG_POP()
      lexer.cmdarg_stack = $<val>1;
    }
  ;

block_arg    : tAMPER arg_value
            {}
        ;

opt_block_arg    : ',' block_arg
            {}
        | none
            {}
        ;

args:
    arg_value
    {
      $$ = [ $1 ];
    }
  |
    tSTAR arg_value
    {
      $$ = [ builder.splat($2) ];
    }
  | args ',' arg_value
    {
      var args = $1;
      args.push($3);
      $$ = args;
    }
  | args ',' tSTAR arg_value
    {
      var args = $1;
      args.push(builder.splat($4));
      $$ = args;
    }
  ;

mrhs        : args ',' arg_value
            {}
        | args ',' tSTAR arg_value
            {}
        | tSTAR arg_value
            {}
        ;

primary:  literal
        | strings
        | xstring
        | regexp
        | words
        | qwords
        | symbols
        | qsymbols
        | var_ref
        | backref
        | tFID
            {}
        | k_begin
          {
            $<val>1 = lexer.cmdarg_stack;
            lexer.cmdarg_stack = 0;
          }
          bodystmt
          k_end
          {
            lexer.cmdarg_stack = $<val>1;
            
            // touching this alters the parse.output
            $<num>2;
            
            $$ = builder.begin_keyword($3);
          }
        | tLPAREN_ARG
        {
          lexer.lex_state = EXPR_ENDARG;
        }
        rparen
            {}
        | tLPAREN_ARG expr
        {
          lexer.lex_state = EXPR_ENDARG;
        }
        rparen
            {}
        | tLPAREN compstmt ')'
            {}
        | primary_value tCOLON2 tCONSTANT
            {}
        | tCOLON3 tCONSTANT
            {}
        | tLBRACK aref_args ']'
            {}
        |
          tLBRACE assoc_list '}'
          {
            $$ = builder.associate($2);
          }
        | keyword_return
            {}
        | keyword_yield '(' call_args rparen
            {}
        | keyword_yield '(' rparen
            {}
        | keyword_yield
            {}
        | keyword_defined opt_nl '(' { lexer.in_defined = true;} expr rparen
            {
              lexer.in_defined = false;
            }
        | keyword_not '(' expr rparen
          {
            $$ = builder.not_op($3);
          }
        | keyword_not '(' rparen
          {
            // not ()
            $$ = builder.not_op(null);
          }
        | fcall brace_block
          {
            var method_call = builder.call_method(null, null, $1);

            var block = $2;
            $$ = builder.block(method_call, block.args, block.body);
          }
        | method_call
        | method_call brace_block
          {
            var block = $2;
            $$ = builder.block($1, block.args, block.body);
          }
        | tLAMBDA lambda
            {}
        | k_if expr_value then
          compstmt
          if_tail
          k_end
            {}
        | k_unless expr_value then
          compstmt
          opt_else
          k_end
            {}
        | k_while
          {
            lexer.COND_PUSH(1);
          }
          expr_value do
          {
            lexer.COND_POP();
          }
          compstmt
          k_end
            {}
        | k_until
        {
          lexer.COND_PUSH(1);
        }
        expr_value do
        {
          lexer.COND_POP();
        }
          compstmt
          k_end
            {}
        | k_case expr_value opt_terms
          case_body
          k_end
            {}
        | k_case opt_terms case_body k_end
            {}
        | k_for for_var keyword_in
          {
            lexer.COND_PUSH(1);
          }
          expr_value do
          {
            lexer.COND_POP();
          }
          compstmt
          k_end
            {}
        | k_class cpath superclass
            {
          if (lexer.in_def || lexer.in_single)
            lexer.yyerror("class definition in method body");
                scope.push_static();
            }
          bodystmt
          k_end
            {
              // touching this alters the parse.output
                $<num>4;
                scope.pop();
            }
        | k_class tLSHFT expr
            {
          $<num>$ = lexer.in_def;
          lexer.in_def = 0;
            }
          term
            {
              $<num>$ = lexer.in_single;
              lexer.in_single = 0;
              scope.push_static();
            }
          bodystmt
          k_end
            {
              scope.pop();
          lexer.in_def = $<num>4;
          lexer.in_single = $<num>6;
            }
        | k_module cpath
            {
          if (lexer.in_def || lexer.in_single)
            lexer.yyerror("module definition in method body");
                scope.push_static();
            }
          bodystmt
          k_end
            {
              // touching this alters the parse.output
                $<num>3;
                scope.pop();
            }
        | k_def fname
            {
              $<id>$ = lexer.cur_mid; // TODO
                lexer.cur_mid = $2;
                
              lexer.in_def++;
              scope.push_static();
            }
          f_arglist
          bodystmt
          k_end
            {
              // touching this alters the parse.output
                $<num>1;
                scope.pop();
                lexer.in_def--;
                lexer.cur_mid = $<id>3;
            }
  |
    k_def singleton dot_or_colon
    {
      lexer.lex_state = EXPR_FNAME;
    }
    fname
    {
      lexer.in_single++;
      lexer.lex_state = EXPR_ENDFN; /* force for args */
      scope.push_static();
    }
    f_arglist
    bodystmt
    k_end
    {
      scope.pop();
      lexer.in_single--;
    }
        | keyword_break
            {}
        | keyword_next
            {}
        | keyword_redo
            {}
        | keyword_retry
            {}
        ;

primary_value    : primary
            {}
        ;

k_begin:
    keyword_begin
    {
      // TODO: store line/col to $$
    }
  ;

k_if        : keyword_if
            {}
        ;

k_unless    : keyword_unless
            {}
        ;

k_while        : keyword_while
            {}
        ;

k_until        : keyword_until
            {}
        ;

k_case        : keyword_case
            {}
        ;

k_for        : keyword_for
            {}
        ;

k_class        : keyword_class
            {}
        ;

k_module    : keyword_module
            {}
        ;

k_def        : keyword_def
            {}
        ;

k_end:
    keyword_end
  ;

then        : term
        | keyword_then
        | term keyword_then
        ;

do        : term
        | keyword_do_cond
        ;

if_tail        : opt_else
        | keyword_elsif expr_value then
          compstmt
          if_tail
            {}
        ;

opt_else    : none
        | keyword_else compstmt
            {}
        ;

for_var        : lhs
        | mlhs
        ;

f_marg        : f_norm_arg
            {}
        | tLPAREN f_margs rparen
            {}
        ;

f_marg_list    : f_marg
            {}
        | f_marg_list ',' f_marg
            {}
        ;

f_margs        : f_marg_list
            {}
        | f_marg_list ',' tSTAR f_norm_arg
            {}
        | f_marg_list ',' tSTAR f_norm_arg ',' f_marg_list
            {}
        | f_marg_list ',' tSTAR
            {}
        | f_marg_list ',' tSTAR ',' f_marg_list
            {}
        | tSTAR f_norm_arg
            {}
        | tSTAR f_norm_arg ',' f_marg_list
            {}
        | tSTAR
            {}
        | tSTAR ',' f_marg_list
            {}
        ;


block_args_tail    : f_block_kwarg ',' f_kwrest opt_f_block_arg
            {}
        | f_block_kwarg opt_f_block_arg
            {}
        | f_kwrest opt_f_block_arg
            {}
        | f_block_arg
            {}
        ;

opt_block_args_tail:
    ',' block_args_tail
    {
      $$ = $2;
    }
  | /* none */
    {
      $$ = [];
    }
  ;

block_param    : f_arg ',' f_block_optarg ',' f_rest_arg opt_block_args_tail
            {}
        | f_arg ',' f_block_optarg ',' f_rest_arg ',' f_arg opt_block_args_tail
            {}
        | f_arg ',' f_block_optarg opt_block_args_tail
            {}
        | f_arg ',' f_block_optarg ',' f_arg opt_block_args_tail
            {}
                | f_arg ',' f_rest_arg opt_block_args_tail
            {}
        | f_arg ','
            {}
        | f_arg ',' f_rest_arg ',' f_arg opt_block_args_tail
            {}
        | f_arg opt_block_args_tail
          {
            $$ = $1.concat($2);
          }
        | f_block_optarg ',' f_rest_arg opt_block_args_tail
            {}
        | f_block_optarg ',' f_rest_arg ',' f_arg opt_block_args_tail
            {}
        | f_block_optarg opt_block_args_tail
            {}
        | f_block_optarg ',' f_arg opt_block_args_tail
            {}
        | f_rest_arg opt_block_args_tail
            {}
        | f_rest_arg ',' f_arg opt_block_args_tail
            {}
        | block_args_tail
            {}
        ;

opt_block_param:
    none
    {
      $$ = builder.args([]);
    }
  |
    block_param_def
    {
      lexer.command_start = true;
    }
  ;

block_param_def:
    '|' opt_bv_decl '|'
    {
      $$ = builder.args($2);
    }
  |
    tOROP
    {
      $$ = builder.args([]);
    }
  | '|' block_param opt_bv_decl '|'
    {
      $$ = builder.args($2.concat($3));
    }
  ;


opt_bv_decl:
    opt_nl
    {
      $$ = [];
    }
  | opt_nl ';' bv_decls opt_nl
    {
      $$ = $3;
    }
  ;

bv_decls:
    bvar
    {
      $$ = [ $1 ];
    }
  |
    bv_decls ',' bvar
    {
      var bv_decls = $1;
      bv_decls.push($3);
      $$ = bv_decls;
    }
  ;

bvar:
    tIDENTIFIER
    {
      $$ = builder.shadowarg($1);
    }
  |
    f_bad_arg
    {
      $$ = null;
    }
  ;

lambda        :   {}
            {
              $<num>$ = lexer.lpar_beg;
              lexer.lpar_beg = ++lexer.paren_nest;
            }
          f_larglist
          lambda_body
            {
          lexer.lpar_beg = $<num>2;
          // touching this alters the parse.output
          $<vars>1;
            }
        ;

f_larglist    : '(' f_args opt_bv_decl ')'
            {}
        | f_args
            {}
        ;

lambda_body    : tLAMBEG compstmt '}'
            {}
        | keyword_do_LAMBDA compstmt keyword_end
            {}
        ;

do_block    : keyword_do_block
            {}
          opt_block_param
          compstmt
          keyword_end
            {
          // touching this alters the parse.output
        $<num>2;
              $<vars>1;
            }
        ;

block_call    : command do_block
            {}
        | block_call dot_or_colon operation2 opt_paren_args
            {}
        | block_call dot_or_colon operation2 opt_paren_args brace_block
            {}
        | block_call dot_or_colon operation2 command_args do_block
            {}
        ;

method_call:
    fcall paren_args
    {
      $$ = builder.call_method(null, null, $1, $2);
    }
  |
    primary_value '.' operation2 {/*TODO*/} opt_paren_args
    {
      $$ = builder.call_method($1, $2, $3, $5);
      
      // touching this alters the parse.output
        $<num>4;
    }
  |
    primary_value tCOLON2 operation2 {/*TODO*/} paren_args
    {
      $$ = builder.call_method($1, $2, $3, $5);
      
      // touching this alters the parse.output
        $<num>4
    }
  |
    primary_value tCOLON2 operation3
    {
      $$ = builder.call_method($1, $2, $3); // empty args
    }
  |
    primary_value '.' {/*TODO*/} paren_args
    {
      // null for empty method name
      // as in `primary_value.(paren_args)`
      $$ = builder.call_method($1, '.', null, $4);
      
      // touching this alters the parse.output
      $<num>3;
    }
  |
    primary_value tCOLON2 {/*TODO*/} paren_args
    {
      $$ = builder.call_method($1, $2, null, $4);

      // TODO: touching this alters the parse.output
      $<num>3;
    }
  |
    keyword_super paren_args
    {
      $$ = builder.keyword_cmd('super', $2);
    }
  |
    keyword_super
    {
      $$ = builder.keyword_cmd('zsuper');
    }
  |
    primary_value '[' opt_call_args rbracket
    {
      $$ = builder.index($1, $3);
    }
  ;

brace_block:
    '{'
    {
      scope.push_dynamic();
    }
    opt_block_param compstmt '}'
    {
      $$ = { args: $3, body: $4 };
      
      // touching this alters the parse.output
      $<num>2;
      
      scope.pop();
    }
  |
    keyword_do
    {
      scope.push_dynamic();
    }
    opt_block_param compstmt keyword_end
    {
      $$ = { args: $3, body: $4 };
      
      // touching this alters the parse.output
      $<num>2;
      
      scope.pop();
    }
  ;

case_body    : keyword_when args then
          compstmt
          cases
            {}
        ;

cases        : opt_else
        | case_body
        ;

opt_rescue:
    keyword_rescue exc_list exc_var then compstmt opt_rescue
    {
      var exc_list = $2;
      if (exc_list)
      {
        exc_list = builder.array(exc_list)
      }

      var rescue_ary = [builder.rescue_body(exc_list, $3, $5)];
      var opt_rescue = $6;
      if (opt_rescue)
      {
        Array_push.apply(rescue_ary, opt_rescue);
      }
      $$ = rescue_ary;
    }
  |
    none
    {
      $$ = [];
    }
  ;

exc_list:
    arg_value
    {
      $$ = [ $1 ];
    }
  |
    mrhs
    {
      
    }
  |
    none
  ;

exc_var:
    tASSOC lhs
    {
      $$ = $2;
    }
  |
    none
  ;

opt_ensure    : keyword_ensure compstmt
            {}
        | none
        ;

literal        : numeric
        | symbol
            {}
        | dsym
        ;

strings        : string
            {}
        ;

string        : tCHAR
        | string1
        | string string1
            {}
        ;

string1        : tSTRING_BEG string_contents tSTRING_END
            {}
        ;

xstring        : tXSTRING_BEG xstring_contents tSTRING_END
            {}
        ;

regexp        : tREGEXP_BEG regexp_contents tREGEXP_END
            {}
        ;

words        : tWORDS_BEG ' ' tSTRING_END
            {}
        | tWORDS_BEG word_list tSTRING_END
            {}
        ;

word_list    : /* none */
            {}
        | word_list word ' '
            {}
        ;

word        : string_content
        | word string_content
            {}
        ;

symbols            : tSYMBOLS_BEG ' ' tSTRING_END
            {}
        | tSYMBOLS_BEG symbol_list tSTRING_END
            {}
        ;

symbol_list    : /* none */
            {}
        | symbol_list word ' '
            {}
        ;

qwords        : tQWORDS_BEG ' ' tSTRING_END
            {}
        | tQWORDS_BEG qword_list tSTRING_END
            {}
        ;

qsymbols    : tQSYMBOLS_BEG ' ' tSTRING_END
            {}
        | tQSYMBOLS_BEG qsym_list tSTRING_END
            {}
        ;

qword_list    : /* none */
            {}
        | qword_list tSTRING_CONTENT ' '
            {}
        ;

qsym_list    : /* none */
            {}
        | qsym_list tSTRING_CONTENT ' '
            {}
        ;

string_contents : /* none */
            {}
        | string_contents string_content
            {}
        ;

xstring_contents: /* none */
            {}
        | xstring_contents string_content
            {}
        ;

regexp_contents: /* none */
            {}
        | regexp_contents string_content
            {}
        ;

string_content    : tSTRING_CONTENT
        | tSTRING_DVAR
            {
            $<node>$ = lexer.lex_strterm;
            lexer.lex_strterm = null;
            lexer.lex_state = EXPR_BEG;
            }
          string_dvar
            {
            /*%%%*/
            lexer.lex_strterm = $<node>2;
            }
        | tSTRING_DBEG
            {
          $<val>1 = lexer.cond_stack;
          $<val>$ = lexer.cmdarg_stack;
          lexer.cond_stack = 0;
          lexer.cmdarg_stack = 0;
            }
            {
            $<node>$ = lexer.lex_strterm;
            lexer.lex_strterm = null;
            lexer.lex_state = EXPR_BEG;
            }
            {
            $<num>$ = lexer.brace_nest;
            lexer.brace_nest = 0;
            }
          compstmt tSTRING_DEND
            {
          lexer.cond_stack = $<val>1;
          lexer.cmdarg_stack = $<val>2;
          lexer.lex_strterm = $<node>3;
          lexer.brace_nest = $<num>4;
            }
        ;

string_dvar:
    tGVAR
    {
      $$ = builder.gvar($1);
    }
  |
    tIVAR
    {
      $$ = builder.ivar($1);
    }
  |
    tCVAR
    {
      $$ = builder.cvar($1);
    }
  |
    backref
  ;

symbol:
    tSYMBEG sym
    {
      lexer.lex_state = EXPR_END;
      $$ = builder.symbol($2);
    }
  ;

sym        : fname
        | tIVAR
        | tGVAR
        | tCVAR
        ;

dsym        : tSYMBEG xstring_contents tSTRING_END
            {
            lexer.lex_state = EXPR_END;
            }
        ;

numeric     : tINTEGER
            {
              $$ = builder.integer($1, /*negate=*/false);
            }
        | tFLOAT
            {
              // TODO: convert tFLOAT to NEW_LIT()
            }
        | tUMINUS_NUM tINTEGER           %prec tLOWEST
            {
              // TODO: convert tINTEGER to NEW_LIT()
            }
        | tUMINUS_NUM tFLOAT           %prec tLOWEST
            {
              // TODO: convert tFLOAT to NEW_LIT()
            }
        ;

user_variable:
    tIDENTIFIER
    {
      $$ = builder.ident($1);
    }
  |
    tIVAR
    {
      $$ = builder.ivar($1);
    }
  |
    tGVAR
    {
      $$ = builder.gvar($1);
    }
  |
    tCONSTANT
    {
      $$ = builder.const_($1);
    }
  |
    tCVAR
  ;

keyword_variable:
    keyword_nil
    {
      $$ = builder.nil();
    }
  |
    keyword_self
    {
      $$ = builder.self();
    }
        | keyword_true {$$ = keyword_true;}
        | keyword_false {$$ = keyword_false;}
        | keyword__FILE__ { $$ = lexer.filename; }
  |
    keyword__LINE__
    {
      $$ = builder._LINE_(lexer.ruby_sourceline)
    }
        | keyword__ENCODING__ {$$ = keyword__ENCODING__;}
        ;

var_ref:
    user_variable
    {
      $$ = builder.accessible($1);
    }
  |
    keyword_variable
    {
      $$ = builder.accessible($1);
    }
  ;

var_lhs:
    user_variable
    {
      $$ = builder.assignable($1);
    }
  |
    keyword_variable
    {
      $$ = builder.assignable($1);
    }
  ;

backref:
    tNTH_REF
    {
      $$ = builder.nth_ref($1);
    }
  |
    tBACK_REF
    {
      $$ = builder.back_ref($1);
    }
  ;

superclass    : term
            {}
        | '<'
            {
            lexer.lex_state = EXPR_BEG;
            lexer.command_start = true;
            }
          expr_value term
            {}
        | error term
            {
              parser.yyerrok();
            }
        ;

f_arglist    : '(' f_args rparen
            {
            lexer.lex_state = EXPR_BEG;
            lexer.command_start = true;
            }
        | f_args term
            {
            lexer.lex_state = EXPR_BEG;
            lexer.command_start = true;
            }
        ;

args_tail    : f_kwarg ',' f_kwrest opt_f_block_arg
            {}
        | f_kwarg opt_f_block_arg
            {}
        | f_kwrest opt_f_block_arg
            {}
        | f_block_arg
            {}
        ;

opt_args_tail    : ',' args_tail
            {}
        | /* none */
            {}
        ;

f_args        : f_arg ',' f_optarg ',' f_rest_arg opt_args_tail
            {}
        | f_arg ',' f_optarg ',' f_rest_arg ',' f_arg opt_args_tail
            {}
        | f_arg ',' f_optarg opt_args_tail
            {}
        | f_arg ',' f_optarg ',' f_arg opt_args_tail
            {}
        | f_arg ',' f_rest_arg opt_args_tail
            {}
        | f_arg ',' f_rest_arg ',' f_arg opt_args_tail
            {}
        | f_arg opt_args_tail
            {}
        | f_optarg ',' f_rest_arg opt_args_tail
            {}
        | f_optarg ',' f_rest_arg ',' f_arg opt_args_tail
            {}
        | f_optarg opt_args_tail
            {}
        | f_optarg ',' f_arg opt_args_tail
            {}
        | f_rest_arg opt_args_tail
            {}
        | f_rest_arg ',' f_arg opt_args_tail
            {}
        | args_tail
            {}
        | /* none */
            {}
        ;

f_bad_arg    : tCONSTANT
            {
              lexer.yyerror("formal argument cannot be a constant");
            }
        | tIVAR
            {
              lexer.yyerror("formal argument cannot be an instance variable");
            }
        | tGVAR
            {
              lexer.yyerror("formal argument cannot be a global variable");
            }
        | tCVAR
            {
              lexer.yyerror("formal argument cannot be a class variable");
            }
        ;

f_norm_arg:
    f_bad_arg
  |
    tIDENTIFIER
    {
      // formal_argument(get_id($1)) // TODO
      $$ = $1;
    }
  ;

f_arg_item:
    f_norm_arg
    {
      var f_norm_arg = $1;
      scope.declare(f_norm_arg[0]);
      
      $$ = builder.arg(f_norm_arg);
    }
  | tLPAREN f_margs rparen
    {
      $$ = builder.multi_lhs($2);
    }
  ;

f_arg:
    f_arg_item
    {
      $$ = [ $1 ];
    }
  |
    f_arg ',' f_arg_item
    {
      var f_arg = $1;
      f_arg.push($3);
      $$ = f_arg;
    }
  ;

f_kw        : tLABEL arg_value
            {}
        ;

f_block_kw    : tLABEL primary_value
            {}
        ;

f_block_kwarg    : f_block_kw
            {}
        | f_block_kwarg ',' f_block_kw
            {}
        ;


f_kwarg        : f_kw
            {}
        | f_kwarg ',' f_kw
            {}
        ;

kwrest_mark    : tPOW
        | tDSTAR
        ;

f_kwrest    : kwrest_mark tIDENTIFIER
            {}
        | kwrest_mark
            {}
        ;

f_opt        : tIDENTIFIER '=' arg_value
            {}
        ;

f_block_opt    : tIDENTIFIER '=' primary_value
            {}
        ;

f_block_optarg    : f_block_opt
            {}
        | f_block_optarg ',' f_block_opt
            {}
        ;

f_optarg    : f_opt
            {}
        | f_optarg ',' f_opt
            {}
        ;

restarg_mark    : '*'
        | tSTAR
        ;

f_rest_arg    : restarg_mark tIDENTIFIER
            {
          if (!is_local_id($2)) // TODO
            lexer.yyerror("rest argument must be local variable");
                
            }
        | restarg_mark
            {}
        ;

blkarg_mark    : '&'
        | tAMPER
        ;

f_block_arg    : blkarg_mark tIDENTIFIER
            {
              if (!is_local_id($2))
            lexer.yyerror("block argument must be local variable");
                else if (!dyna_in_block() && local_id($2))
            lexer.yyerror("duplicated block argument name");
                
            }
        ;

opt_f_block_arg    : ',' f_block_arg
            {}
        | none
            {}
        ;

singleton    : var_ref
            {}
        | '('
        {
          lexer.lex_state = EXPR_BEG;
        }
        expr rparen
            {
          if ($3 == null) {
            lexer.yyerror("can't define singleton method for ().");
          }
          else {
            switch ($3.type) { // TODO
              case 'STR':
              case 'DSTR':
              case 'XSTR':
              case 'DXSTR':
              case 'DREGX':
              case 'LIT':
              case 'ARRAY':
              case 'ZARRAY':
                lexer.yyerror("can't define singleton method for literals");
              default:
                value_expr($3); // TODO
                break;
            }
          }
            }
        ;

assoc_list:
    none
    {
      $$ = [];
    }
  |
    assocs trailer
  ;

assocs:
    assoc
    {
      $$ = [$1];
    }
  |
    assocs ',' assoc
    {
      var assocs = $1;
      assocs.push($3);
      $$ = assocs;
    }
  ;

assoc:
    arg_value tASSOC arg_value
    {
      $$ = builder.pair($1, $2);
    }
  | tLABEL arg_value
    {
      $$ = builder.pair_keyword($1, $2);
    }
  | tDSTAR arg_value
    {
      $$ = builder.kwsplat($2);
    }
  ;

operation:
    tIDENTIFIER
  |
    tCONSTANT
  |
    tFID
  ;

operation2    : tIDENTIFIER
        | tCONSTANT
        | tFID
        | op
        ;

operation3    : tIDENTIFIER
        | tFID
        | op
        ;

dot_or_colon    : '.'
        | tCOLON2
        ;

opt_terms    : /* none */
        | terms
        ;

opt_nl        : /* none */
        | '\n'
        ;

rparen        : opt_nl ')'
        ;

rbracket    : opt_nl ']'
        ;

trailer        : /* none */
        | '\n'
        | ','
        ;

term
  :
    ';'
    { parser.yyerrok(); }
  |
    '\n'
  ;

terms
  :
    term
  |
    terms ';'
    { parser.yyerrok(); }
  ;

none: /* none */
    {
      // empty ensure or else block for example
      $$ = null;
    };

%%


// Exports part.
// Here we have to expose our YY* classes to outer world somehow.
// And yes, all the two YYParser and YYLexer are visible here

global.YYLexer = YYLexer;
global.YYParser = YYParser;

})(); // whole parser and lexer namespace start

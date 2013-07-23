// XLang
// -- A parser framework for language modeling
// Copyright (C) 2011 Jerry Chen <mailto:onlyuser@gmail.com>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.

//%output="XLang.tab.c"
%name-prefix="_XLANG_"

%{

#include "XLang.h"
#include "node/XLangNodeIFace.h" // node::NodeIdentIFace
#include "XLang.tab.h" // ID_XXX (yacc generated)
#include "XLangAlloc.h" // Allocator
#include "mvc/XLangMVCView.h" // mvc::MVCView
#include "mvc/XLangMVCModel.h" // mvc::MVCModel
#include "XLangTreeContext.h" // TreeContext
#include "XLangType.h" // uint32_t
#include <stdio.h> // size_t
#include <stdarg.h> // va_start
#include <string> // std::string
#include <sstream> // std::stringstream
#include <iostream> // std::cout
#include <stdlib.h> // EXIT_SUCCESS
#include <getopt.h> // getopt_long

#define MAKE_TERM(lexer_id, ...)   xl::mvc::MVCModel::make_term(tree_context(), lexer_id, ##__VA_ARGS__)
#define MAKE_SYMBOL(...)           xl::mvc::MVCModel::make_symbol(tree_context(), ##__VA_ARGS__)
#define ERROR_LEXER_ID_NOT_FOUND   "missing lexer id handler, most likely you forgot to register one"
#define ERROR_LEXER_NAME_NOT_FOUND "missing lexer name handler, most likely you forgot to register one"
#define EOL                        xl::node::SymbolNode::eol();

// report error
void _xl(error)(const char* s)
{
    error_messages() << s;
}

// get resource
std::stringstream &error_messages()
{
    static std::stringstream _error_messages;
    return _error_messages;
}
std::string id_to_name(uint32_t lexer_id)
{
    static const char* _id_to_name[] = {
        "int",
        "float",
        "ident"
        };
    int index = static_cast<int>(lexer_id)-ID_BASE-1;
    if(index >= 0 && index < static_cast<int>(sizeof(_id_to_name)/sizeof(*_id_to_name)))
        return _id_to_name[index];
    switch(lexer_id)
    {
        case ID_S:   return "S";
        case ID_NP:  return "NP";
        case ID_VP:  return "VP";
        case ID_AP:  return "AP";
        case ID_PP:  return "PP";
        case ID_N:   return "N";
        case ID_V:   return "V";
        case ID_A:   return "A";
        case ID_ADV: return "Adv";
        case ID_P:   return "P";
        case ID_AUX: return "Aux";
        case ID_D:   return "D";
        case ID_C:   return "C";
    }
    throw ERROR_LEXER_ID_NOT_FOUND;
    return "";
}
uint32_t name_to_id(std::string name)
{
    if(name == "int")   return ID_INT;
    if(name == "float") return ID_FLOAT;
    if(name == "ident") return ID_IDENT;
    if(name == "S")     return ID_S;
    if(name == "NP")    return ID_NP;
    if(name == "VP")    return ID_VP;
    if(name == "AP")    return ID_AP;
    if(name == "PP")    return ID_PP;
    if(name == "N")     return ID_N;
    if(name == "V")     return ID_V;
    if(name == "A")     return ID_A;
    if(name == "Adv")   return ID_ADV;
    if(name == "P")     return ID_P;
    if(name == "Aux")   return ID_AUX;
    if(name == "D")     return ID_D;
    if(name == "C")     return ID_C;
    throw ERROR_LEXER_NAME_NOT_FOUND;
    return 0;
}
xl::TreeContext* &tree_context()
{
    static xl::TreeContext* tc = NULL;
    return tc;
}

%}

// type of yylval to be set by scanner actions
// implemented as %union in non-reentrant mode
%union
{
    xl::node::TermInternalType<xl::node::NodeIdentIFace::INT>::type    int_value;    // int value
    xl::node::TermInternalType<xl::node::NodeIdentIFace::FLOAT>::type  float_value;  // float value
    xl::node::TermInternalType<xl::node::NodeIdentIFace::IDENT>::type  ident_value;  // symbol table index
    xl::node::TermInternalType<xl::node::NodeIdentIFace::SYMBOL>::type symbol_value; // node pointer
}

// show detailed parse errors
%error-verbose

%nonassoc ID_BASE

%token<int_value>   ID_INT
%token<float_value> ID_FLOAT
%token<ident_value> ID_IDENT ID_N ID_V ID_A ID_ADV ID_P ID_AUX ID_D ID_C
%type<symbol_value> S NP VP AP PP N V A Adv P Aux D C

%nonassoc ID_S ID_NP ID_VP ID_AP ID_PP

%nonassoc ID_COUNT

%%

root:
      S     { tree_context()->root() = $1; YYACCEPT; }
    | error { yyclearin; /* yyerrok; YYABORT; */ }
    ;

S:
      NP VP { $$ = MAKE_SYMBOL(ID_S, 2, $1, $2); }
    ;

NP:
      D N     { $$ = MAKE_SYMBOL(ID_NP, 2, $1, $2); }
    | N       { $$ = MAKE_SYMBOL(ID_NP, 1, $1); }
    | D A N   { $$ = MAKE_SYMBOL(ID_NP, 3, $1, $2, $3); }
    | NP C NP { $$ = MAKE_SYMBOL(ID_NP, 3, $1, $2, $3); }
    ;

VP:
      V       { $$ = MAKE_SYMBOL(ID_VP, 1, $1); }
    | V NP    { $$ = MAKE_SYMBOL(ID_VP, 2, $1, $2); }
    | V AP    { $$ = MAKE_SYMBOL(ID_VP, 2, $1, $2); }
    | VP C VP { $$ = MAKE_SYMBOL(ID_VP, 3, $1, $2, $3); }
    ;

AP:
      A PP { $$ = MAKE_SYMBOL(ID_AP, 2, $1, $2); }
    | PP   { $$ = MAKE_SYMBOL(ID_AP, 1, $1); }
    ;

PP:
      P NP { $$ = MAKE_SYMBOL(ID_PP, 2, $1, $2); }
    | P PP { $$ = MAKE_SYMBOL(ID_PP, 2, $1, $2); }
    ;

N:
      ID_N { $$ = MAKE_SYMBOL(ID_N, 1, MAKE_TERM(ID_IDENT, $1)); }
    ;

V:
      ID_V { $$ = MAKE_SYMBOL(ID_V, 1, MAKE_TERM(ID_IDENT, $1)); }
    ;

A:
      ID_A { $$ = MAKE_SYMBOL(ID_A, 1, MAKE_TERM(ID_IDENT, $1)); }
    | A A  { $$ = MAKE_SYMBOL(ID_A, 2, $1, $2); }
    ;

Adv:
      ID_ADV { $$ = MAKE_SYMBOL(ID_ADV, 1, MAKE_TERM(ID_IDENT, $1)); }
    ;

P:
      ID_P { $$ = MAKE_SYMBOL(ID_P, 1, MAKE_TERM(ID_IDENT, $1)); }
    ;

Aux:
      ID_AUX { $$ = MAKE_SYMBOL(ID_AUX, 1, MAKE_TERM(ID_IDENT, $1)); }
    ;

D:
      ID_D { $$ = MAKE_SYMBOL(ID_D, 1, MAKE_TERM(ID_IDENT, $1)); }
    ;

C:
      ID_C { $$ = MAKE_SYMBOL(ID_C, 1, MAKE_TERM(ID_IDENT, $1)); }
    ;

%%

xl::node::NodeIdentIFace* make_ast(xl::Allocator &alloc)
{
    tree_context() = new (PNEW(alloc, xl::, TreeContext)) xl::TreeContext(alloc);
    int error_code = _xl(parse)(); // parser entry point
    _xl(lex_destroy)();
    return (!error_code && error_messages().str().empty()) ? tree_context()->root() : NULL;
}

void display_usage(bool verbose)
{
    std::cout << "Usage: XLang [-i] OPTION [-m]" << std::endl;
    if(verbose)
    {
        std::cout << "Parses input and prints a syntax tree to standard out" << std::endl
                << std::endl
                << "Input control:" << std::endl
                << "  -i, --in-xml=FILE (de-serialize from xml)" << std::endl
                << std::endl
                << "Output control:" << std::endl
                << "  -e, --eval" << std::endl
                << "  -l, --lisp" << std::endl
                << "  -x, --xml" << std::endl
                << "  -g, --graph" << std::endl
                << "  -d, --dot" << std::endl
                << "  -m, --memory" << std::endl
                << "  -h, --help" << std::endl;
    }
    else
        std::cout << "Try `XLang --help\' for more information." << std::endl;
}

struct args_t
{
    typedef enum
    {
        MODE_NONE,
        MODE_EVAL,
        MODE_LISP,
        MODE_XML,
        MODE_GRAPH,
        MODE_DOT,
        MODE_HELP
    } mode_e;

    mode_e mode;
    std::string in_xml;
    bool dump_memory;

    args_t()
        : mode(MODE_NONE), dump_memory(false)
    {}
};

bool parse_args(int argc, char** argv, args_t &args)
{
    int opt = 0;
    int longIndex = 0;
    static const char *optString = "i:lxgdmh?";
    static const struct option longOpts[] = {
                { "in-xml", required_argument, NULL, 'i' },
                { "lisp",   no_argument,       NULL, 'l' },
                { "xml",    no_argument,       NULL, 'x' },
                { "graph",  no_argument,       NULL, 'g' },
                { "dot",    no_argument,       NULL, 'd' },
                { "memory", no_argument,       NULL, 'm' },
                { "help",   no_argument,       NULL, 'h' },
                { NULL,     no_argument,       NULL, 0 }
            };
    opt = getopt_long(argc, argv, optString, longOpts, &longIndex);
    while(opt != -1)
    {
        switch(opt)
        {
            case 'i': args.in_xml = optarg; break;
            case 'l': args.mode = args_t::MODE_LISP; break;
            case 'x': args.mode = args_t::MODE_XML; break;
            case 'g': args.mode = args_t::MODE_GRAPH; break;
            case 'd': args.mode = args_t::MODE_DOT; break;
            case 'm': args.dump_memory = true; break;
            case 'h':
            case '?': args.mode = args_t::MODE_HELP; break;
            case 0: // reserved
            default:
                break;
        }
        opt = getopt_long(argc, argv, optString, longOpts, &longIndex);
    }
    if(args_t::MODE_NONE == args.mode && !args.dump_memory)
    {
        display_usage(false);
        return false;
    }
    return true;
}

bool import_ast(args_t &args, xl::Allocator &alloc, xl::node::NodeIdentIFace* &ast)
{
    if(args.in_xml != "")
    {
        ast = xl::mvc::MVCModel::make_ast(
                new (PNEW(alloc, xl::, TreeContext)) xl::TreeContext(alloc),
                args.in_xml);
        if(!ast)
        {
            std::cout << "de-serialize from xml fail!" << std::endl;
            return false;
        }
    }
    else
    {
        ast = make_ast(alloc);
        if(!ast)
        {
            std::cout << error_messages().str().c_str() << std::endl;
            return false;
        }
    }
    return true;
}

void export_ast(args_t &args, const xl::node::NodeIdentIFace* ast)
{
    switch(args.mode)
    {
        case args_t::MODE_LISP:  xl::mvc::MVCView::print_lisp(ast); break;
        case args_t::MODE_XML:   xl::mvc::MVCView::print_xml(ast); break;
        case args_t::MODE_GRAPH: xl::mvc::MVCView::print_graph(ast); break;
        case args_t::MODE_DOT:   xl::mvc::MVCView::print_dot(ast); break;
        default:
            break;
    }
}

bool do_work(args_t &args)
{
    try
    {
        if(args.mode == args_t::MODE_HELP)
        {
            display_usage(true);
            return true;
        }
        xl::Allocator alloc(__FILE__);
        xl::node::NodeIdentIFace* ast = NULL;
        if(!import_ast(args, alloc, ast))
            return false;
        export_ast(args, ast);
        if(args.dump_memory)
            alloc.dump(std::string(1, '\t'));
    }
    catch(const char* s)
    {
        std::cout << "ERROR: " << s << std::endl;
        return false;
    }
    return true;
}

int main(int argc, char** argv)
{
    args_t args;
    if(!parse_args(argc, argv, args))
        return EXIT_FAILURE;
    if(!do_work(args))
        return EXIT_FAILURE;
    return EXIT_SUCCESS;
}

// XLang
// -- A parser framework for language modeling
// Copyright (C) 2011 onlyuser <mailto:onlyuser@gmail.com>
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

%{

#include "XLang.h"
#include "node/XLangNodeIFace.h" // node::NodeIdentIFace
#include "XLangLexerIDWrapper.h" // ID_XXX (yacc generated)
#include "XLangAlloc.h" // Allocator
#include "mvc/XLangMVCView.h" // mvc::MVCView
#include "mvc/XLangMVCModel.h" // mvc::MVCModel
#include "XLangTreeContext.h" // TreeContext
#include "XLangType.h" // uint32_t
#include <stdio.h> // fread
#include <stdarg.h> // va_start
#include <string.h> // memset
#include <ctype.h> // isalpha
#include <stdlib.h> // atoi
#include <string> // std::string
#include <sstream> // std::stringstream
#include <iostream> // std::cout
#include <algorithm> // std::min
#include <stdlib.h> // EXIT_SUCCESS
#include <getopt.h> // getopt_long

#define SIZE_BUF_SMALL 160

#define MAKE_TERM(lexer_id, ...)   xl::mvc::MVCModel::make_term(&parser_context()->tree_context(), lexer_id, ##__VA_ARGS__)
#define MAKE_SYMBOL(...)           xl::mvc::MVCModel::make_symbol(&parser_context()->tree_context(), ##__VA_ARGS__)
#define ERROR_LEXER_ID_NOT_FOUND   "missing lexer id handler, most likely you forgot to register one"
#define ERROR_LEXER_NAME_NOT_FOUND "missing lexer name handler, most likely you forgot to register one"

// report error
void yyerror(const char* s)
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
        case ID_UMINUS: return "uminus";
        case '+':       return "+";
        case '-':       return "-";
        case '*':       return "*";
        case '/':       return "/";
        case '=':       return "=";
        case ',':       return ",";
    }
    throw ERROR_LEXER_ID_NOT_FOUND;
    return "";
}
uint32_t name_to_id(std::string name)
{
    if(name == "int")    return ID_INT;
    if(name == "float")  return ID_FLOAT;
    if(name == "ident")  return ID_IDENT;
    if(name == "uminus") return ID_UMINUS;
    if(name == "+")      return '+';
    if(name == "-")      return '-';
    if(name == "*")      return '*';
    if(name == "/")      return '/';
    if(name == "=")      return '=';
    if(name == ",")      return ',';
    throw ERROR_LEXER_NAME_NOT_FOUND;
    return 0;
}
ParserContext* &parser_context()
{
    static ParserContext* pc = NULL;
    return pc;
}

// When in the lexer you have to access parm through the extra data.
#define PARM parser_context()->scanner_context()

// We want to read from a the buffer in parm so we have to redefine the
// YY_INPUT macro (see section 10 of the flex manual 'The generated scanner')
#define YY_INPUT(buf, result, max_size) \
    do { \
        if(PARM.m_pos >= PARM.m_length) \
            (result) = 0; \
        else { \
            (result) = std::min(PARM.m_length - PARM.m_pos, static_cast<int>(max_size)); \
            fread((buf), sizeof(char), (result), PARM.m_file); \
            PARM.m_pos += (result); \
        } \
    } while(0)

#define YY_REWIND(n_less) \
    do { \
        if(PARM.m_pos - (n_less) >= 0) { \
            fseek(PARM.m_file, sizeof(char) * -(n_less), SEEK_CUR); \
            PARM.m_pos -= (n_less); \
        } \
    } while(0)

int yylex()
{
    char yytext[SIZE_BUF_SMALL];
    memset(yytext, 0, sizeof(yytext));
    int start_pos = PARM.m_pos;
    char* cur_ptr = &yytext[PARM.m_pos - start_pos];
    int bytes_read = 0;
    YY_INPUT(cur_ptr, bytes_read, 1);
    if(!bytes_read)
        return -1;
    if(isalpha(*cur_ptr) || *cur_ptr == '_')
    {
        do
        {
            cur_ptr = &yytext[PARM.m_pos - start_pos];
            YY_INPUT(cur_ptr, bytes_read, 1);
        } while(bytes_read != 0 && (isdigit(*cur_ptr) || isalpha(*cur_ptr) || *cur_ptr == '_'));
        if(bytes_read != 0)
        {
            YY_REWIND(1);
            yytext[PARM.m_pos - start_pos] = '\0';
        }
        yylval.ident_value = parser_context()->tree_context().alloc_unique_string(yytext);
        return ID_IDENT;
    }
    else if(isdigit(*cur_ptr))
    {
        bool find_decimal_point = false;
        do
        {
            cur_ptr = &yytext[PARM.m_pos - start_pos];
            YY_INPUT(cur_ptr, bytes_read, 1);
            if(*cur_ptr == '.')
                find_decimal_point = true;
        } while(bytes_read != 0 && (isdigit(*cur_ptr) || *cur_ptr == '.'));
        if(bytes_read != 0)
        {
            YY_REWIND(1);
            yytext[PARM.m_pos - start_pos] = '\0';
        }
        if(find_decimal_point)
        {
            yylval.float_value = atof(yytext);
            return ID_FLOAT;
        }
        yylval.int_value = atoi(yytext);
        return ID_INT;
    }
    else if(*cur_ptr == ' ' || *cur_ptr == '\t' || *cur_ptr == '\n')
    {
        do
        {
            cur_ptr = &yytext[PARM.m_pos - start_pos];
            YY_INPUT(cur_ptr, bytes_read, 1);
        } while(bytes_read != 0 && (*cur_ptr == ' ' || *cur_ptr == '\t' || *cur_ptr == '\n'));
        if(bytes_read != 0)
        {
            YY_REWIND(1);
            return yylex();
        }
    }
    else
        switch(*cur_ptr)
        {
            case ',':
            case '(': case ')':
            case '+': case '-':
            case '*': case '/':
            case '=':
                return *cur_ptr;
            default:
                yyerror("unknown character");
        }
    return -1;
}

%}

// type of yylval to be set by scanner actions
// implemented as %union in non-reentrant mode
//
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
%token<ident_value> ID_IDENT
%type<symbol_value> program stmt expr

%left '+' '-'
%left '*' '/'
%nonassoc ID_UMINUS

%%

root:
      program { parser_context()->tree_context().root() = $1; YYACCEPT; }
    | error   { yyclearin; /* yyerrok; YYABORT; */ }
    ;

program:
      stmt             { $$ = $1; }
    | program ',' stmt { $$ = MAKE_SYMBOL(',', 2, $1, $3); }
    ;

stmt:
      expr              { $$ = $1; }
    | ID_IDENT '=' expr { $$ = MAKE_SYMBOL('=', 2, MAKE_TERM(ID_IDENT, $1), $3); }
    ;

expr:
      ID_INT                   { $$ = MAKE_TERM(ID_INT, $1); }
    | ID_FLOAT                 { $$ = MAKE_TERM(ID_FLOAT, $1); }
    | ID_IDENT                 { $$ = MAKE_TERM(ID_IDENT, $1); }
    | '-' expr %prec ID_UMINUS { $$ = MAKE_SYMBOL(ID_UMINUS, 1, $2); }
    | expr '+' expr            { $$ = MAKE_SYMBOL('+', 2, $1, $3); }
    | expr '-' expr            { $$ = MAKE_SYMBOL('-', 2, $1, $3); }
    | expr '*' expr            { $$ = MAKE_SYMBOL('*', 2, $1, $3); }
    | expr '/' expr            { $$ = MAKE_SYMBOL('/', 2, $1, $3); }
    | '(' expr ')'             { $$ = $2; }
    ;

%%

ScannerContext::ScannerContext(FILE* file)
    : m_file(file), m_pos(0)
{
    fseek(file, 0, SEEK_END);
    m_length = ftell(file);
    rewind(file);
}

xl::node::NodeIdentIFace* make_ast(xl::Allocator &alloc, FILE* file)
{
    parser_context() = new (PNEW(alloc, , ParserContext)) ParserContext(alloc, file);
    int error_code = yyparse(); // parser entry point
    return (!error_code && error_messages().str().empty()) ? parser_context()->tree_context().root() : NULL;
}

void display_usage(bool verbose)
{
    std::cout << "Usage: XLang [-i|-f] OPTION [-m]" << std::endl;
    if(verbose)
    {
        std::cout << "Parses input and prints a syntax tree to standard out" << std::endl
                << std::endl
                << "Input control:" << std::endl
                << "  -i, --in-xml FILENAME (de-serialize from xml)" << std::endl
                << "  -f, --in-file FILENAME" << std::endl
                << std::endl
                << "Output control:" << std::endl
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

struct options_t
{
    typedef enum
    {
        MODE_NONE,
        MODE_LISP,
        MODE_XML,
        MODE_GRAPH,
        MODE_DOT,
        MODE_HELP
    } mode_e;

    mode_e      mode;
    std::string in_xml;
    std::string in_file;
    bool        dump_memory;

    options_t()
        : mode(MODE_NONE), dump_memory(false)
    {}
};

bool extract_options_from_args(options_t* options, int argc, char** argv)
{
    if(!options)
        return false;
    int opt = 0;
    int longIndex = 0;
    static const char *optString = "i:f:lxgdmh?";
    static const struct option longOpts[] = {
                { "in-xml",  required_argument, NULL, 'i' },
                { "in-file", required_argument, NULL, 'f' },
                { "lisp",    no_argument,       NULL, 'l' },
                { "xml",     no_argument,       NULL, 'x' },
                { "graph",   no_argument,       NULL, 'g' },
                { "dot",     no_argument,       NULL, 'd' },
                { "memory",  no_argument,       NULL, 'm' },
                { "help",    no_argument,       NULL, 'h' },
                { NULL,      no_argument,       NULL, 0 }
            };
    opt = getopt_long(argc, argv, optString, longOpts, &longIndex);
    while(opt != -1)
    {
        switch(opt)
        {
            case 'i': options->in_xml = optarg; break;
            case 'f': options->in_file = optarg; break;
            case 'l': options->mode = options_t::MODE_LISP; break;
            case 'x': options->mode = options_t::MODE_XML; break;
            case 'g': options->mode = options_t::MODE_GRAPH; break;
            case 'd': options->mode = options_t::MODE_DOT; break;
            case 'm': options->dump_memory = true; break;
            case 'h':
            case '?': options->mode = options_t::MODE_HELP; break;
            case 0: // reserved
            default:
                break;
        }
        opt = getopt_long(argc, argv, optString, longOpts, &longIndex);
    }
    return options->mode != options_t::MODE_NONE || options->dump_memory;
}

bool import_ast(options_t &options, xl::Allocator &alloc, xl::node::NodeIdentIFace* &ast)
{
    if(options.in_xml.size())
    {
        ast = xl::mvc::MVCModel::make_ast(
                new (PNEW(alloc, xl::, TreeContext)) xl::TreeContext(alloc),
                options.in_xml);
        if(!ast)
        {
            std::cerr << "ERROR: de-serialize from xml fail!" << std::endl;
            return false;
        }
    }
    else
    {
        FILE* file = fopen(options.in_file.c_str(), "rb");
        if(!file)
        {
            std::cerr << "ERROR: cannot open file" << std::endl;
            return false;
        }
        ast = make_ast(alloc, file);
        fclose(file);
        if(!ast)
        {
            std::cerr << "ERROR: " << error_messages().str().c_str() << std::endl;
            return false;
        }
    }
    return true;
}

void export_ast(options_t &options, const xl::node::NodeIdentIFace* ast)
{
    switch(options.mode)
    {
        case options_t::MODE_LISP:  xl::mvc::MVCView::print_lisp(ast); break;
        case options_t::MODE_XML:   xl::mvc::MVCView::print_xml(ast); break;
        case options_t::MODE_GRAPH: xl::mvc::MVCView::print_graph(ast); break;
        case options_t::MODE_DOT:   xl::mvc::MVCView::print_dot(ast); break;
        default:
            break;
    }
}

bool apply_options(options_t &options)
{
    try
    {
        if(options.mode == options_t::MODE_HELP)
        {
            display_usage(true);
            return true;
        }
        xl::Allocator alloc(__FILE__);
        xl::node::NodeIdentIFace* ast = NULL;
        if(!import_ast(options, alloc, ast))
            return false;
        export_ast(options, ast);
        if(options.dump_memory)
            alloc.dump(std::string(1, '\t'));
    }
    catch(const char* s)
    {
        std::cerr << "ERROR: " << s << std::endl;
        return false;
    }
    return true;
}

int main(int argc, char** argv)
{
    options_t options;
    if(!extract_options_from_args(&options, argc, argv))
    {
        display_usage(false);
        return EXIT_FAILURE;
    }
    if(!apply_options(options))
        return EXIT_FAILURE;
    return EXIT_SUCCESS;
}

// Variations of a Flex-Bison parser
// -- based on "A COMPACT GUIDE TO LEX & YACC" by Tom Niemann
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

#include "mvc/XLangMVCView.h" // mvc (owner)
#include "node/XLangNodeBase.h" // node::NodeBase
#include "XLangType.h" // uint32
#include <string> // std::string
#include <iostream>

/* source code courtesy of Frank Thomas Braun */
/* minimally altered by Jerry Chen <mailto:onlyuser@gmail.com> */

/* calc3d.c: Generation of the graph of the syntax tree */

#include <stdio.h> // printf
#include <string.h> // strcpy

//#include "calc3.h"
//#include "calc3.tab.h"

#define typeId node::NodeBase::IDENT
#define typeOpr node::NodeBase::INNER

namespace mvc {

void MVCView::print_lisp(const node::NodeBase* _node)
{
    if(NULL == _node)
        return;
    switch(_node->type())
    {
        case node::NodeBase::INT:
            std::cout << dynamic_cast<const node::LeafNodeBase<node::NodeBase::INT>*>(_node)->value();
            break;
        case node::NodeBase::FLOAT:
            std::cout << dynamic_cast<const node::LeafNodeBase<node::NodeBase::FLOAT>*>(_node)->value();
            break;
        case node::NodeBase::STRING:
            std::cout << '\"' << dynamic_cast<const node::LeafNodeBase<node::NodeBase::STRING>*>(_node)->value() << '\"';
            break;
        case node::NodeBase::CHAR:
            std::cout << '\'' << dynamic_cast<const node::LeafNodeBase<node::NodeBase::CHAR>*>(_node)->value() << '\'';
            break;
        case node::NodeBase::IDENT:
            std::cout << *dynamic_cast<const node::LeafNodeBase<node::NodeBase::IDENT>*>(_node)->value();
            break;
        case node::NodeBase::INNER:
            {
                std::cout << '(' << dynamic_cast<const node::InnerNodeBase*>(_node)->name() << ' ';
                size_t i;
                for(i = 0; i < dynamic_cast<const node::InnerNodeBase*>(_node)->child_count()-1; i++)
                {
                    print_lisp(dynamic_cast<const node::InnerNodeBase*>(_node)->child(i));
                    std::cout << ' ';
                }
                print_lisp(dynamic_cast<const node::InnerNodeBase*>(_node)->child(i));
                std::cout << ')';
            }
    }
}

typedef const node::NodeBase nodeType;
int ex (nodeType *p);
void MVCView::print_graph(nodeType* p)
{
    ex (p);
}

int del = 1; /* distance of graph columns */
int eps = 3; /* distance of graph lines */

/* interface for drawing (can be replaced by "real" graphic using GD or other) */
void graphInit (void);
void graphFinish();
void graphBox (char *s, int *w, int *h);
void graphDrawBox (char *s, int c, int l);
void graphDrawArrow (int c1, int l1, int c2, int l2);

/* recursive drawing of the syntax tree */
void exNode (nodeType *p, int c, int l, int *ce, int *cm);

/*****************************************************************************/

/* main entry point of the manipulation of the syntax tree */
int ex (nodeType *p) {
    int rte, rtm;

    graphInit ();
    exNode (p, 0, 0, &rte, &rtm);
    graphFinish();
    return 0;
}

/*c----cm---ce---->                       drawing of leaf-nodes
 l leaf-info
 */

/*c---------------cm--------------ce----> drawing of non-leaf-nodes
 l            node-info
 *                |
 *    -------------     ...----
 *    |       |               |
 *    v       v               v
 * child1  child2  ...     child-n
 *        che     che             che
 *cs      cs      cs              cs
 *
 */

void exNode
    (   nodeType *p,
        int c, int l,        /* start column and line of node */
        int *ce, int *cm     /* resulting end column and mid of node */
    )
{
    int w, h;           /* node width and height */
    char *s;            /* node text */
    int cbar;           /* "real" start column of node (centred above subnodes) */
    uint32 k;           /* child number */
    int che, chm;       /* end column and mid of children */
    int cs;             /* start column of children */
    char word[20];      /* extended node text */

    if (!p) return;

    strcpy (word, "???"); /* should never appear */
    s = word;
    std::string temp;
    switch (p->type()) {
        case node::NodeBase::INT:
            sprintf(word, "%ld", dynamic_cast<const node::LeafNodeBase<node::NodeBase::INT>*>(p)->value());
            break;
        case node::NodeBase::FLOAT:
            sprintf(word, "%f", dynamic_cast<const node::LeafNodeBase<node::NodeBase::FLOAT>*>(p)->value());
            break;
        case typeId:
            sprintf(word, "%s", dynamic_cast<const node::LeafNodeBase<node::NodeBase::IDENT>*>(p)->value()->c_str());
            break;
        case typeOpr:
            temp = dynamic_cast<const node::InnerNodeBase*>(p)->name();
            s = const_cast<char*>(temp.c_str());
            break;
        default:
            break;
    }

    /* construct node text box */
    graphBox (s, &w, &h);
    cbar = c;
    *ce = c + w;
    *cm = c + w / 2;

    /* node is leaf */
    if (p->type() != typeOpr ||
            dynamic_cast<const node::InnerNodeBase*>(p)->child_count() == 0) {
        graphDrawBox (s, cbar, l);
        return;
    }

    /* node has children */
    cs = c;
    for (k = 0; k < dynamic_cast<const node::InnerNodeBase*>(p)->child_count(); k++) {
        exNode (dynamic_cast<const node::InnerNodeBase*>(p)->child(k), cs, l+h+eps, &che, &chm);
        cs = che;
    }

    /* total node width */
    if (w < che - c) {
        cbar += (che - c - w) / 2;
        *ce = che;
        *cm = (c + che) / 2;
    }

    /* draw node */
    graphDrawBox (s, cbar, l);

    /* draw arrows (not optimal: children are drawn a second time) */
    cs = c;
    for (k = 0; k < dynamic_cast<const node::InnerNodeBase*>(p)->child_count(); k++) {
        exNode (dynamic_cast<const node::InnerNodeBase*>(p)->child(k), cs, l+h+eps, &che, &chm);
        graphDrawArrow (*cm, l+h, chm, l+h+eps-1);
        cs = che;
    }
}

/* interface for drawing */

#define lmax 200
#define cmax 200

char graph[lmax][cmax]; /* array for ASCII-Graphic */
int graphNumber = 0;

void graphTest (int l, int c)
{   int ok;
    ok = 1;
    if (l < 0) ok = 0;
    if (l >= lmax) ok = 0;
    if (c < 0) ok = 0;
    if (c >= cmax) ok = 0;
    if (ok) return;
    printf ("\n+++error: l=%d, c=%d not in drawing rectangle 0, 0 ... %d, %d",
        l, c, lmax, cmax);
    //exit (1);
}

void graphInit (void) {
    int i, j;
    for (i = 0; i < lmax; i++) {
        for (j = 0; j < cmax; j++) {
            graph[i][j] = ' ';
        }
    }
}

void graphFinish() {
    int i, j;
    for (i = 0; i < lmax; i++) {
        for (j = cmax-1; j > 0 && graph[i][j] == ' '; j--);
        graph[i][cmax-1] = 0;
        if (j < cmax-1) graph[i][j+1] = 0;
        if (graph[i][j] == ' ') graph[i][j] = 0;
    }
    for (i = lmax-1; i > 0 && graph[i][0] == 0; i--);
    printf ("\n\nGraph %d:\n", graphNumber++);
    for (j = 0; j <= i; j++) printf ("\n%s", graph[j]);
    printf("\n");
}

void graphBox (char *s, int *w, int *h) {
    *w = strlen (s) + del;
    *h = 1;
}

void graphDrawBox (char *s, int c, int l) {
    uint32 i;
    graphTest (l, c+strlen(s)-1+del);
    for (i = 0; i < strlen (s); i++) {
        graph[l][c+i+del] = s[i];
    }
}

void graphDrawArrow (int c1, int l1, int c2, int l2) {
    int m;
    graphTest (l1, c1);
    graphTest (l2, c2);
    m = (l1 + l2) / 2;
    while (l1 != m) { graph[l1][c1] = '|'; if (l1 < l2) l1++; else l1--; }
    while (c1 != c2) { graph[l1][c1] = '-'; if (c1 < c2) c1++; else c1--; }
    while (l1 != l2) { graph[l1][c1] = '|'; if (l1 < l2) l1++; else l1--; }
    graph[l1][c1] = '|';
}

}
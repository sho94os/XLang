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

#ifndef XLANG_MVC_MODEL_H_
#define XLANG_MVC_MODEL_H_

#include "XLangAlloc.h"
#include "node/XLangNodeIFace.h" // node::NodeIdentIFace
#include "node/XLangNode.h" // node::TermNode
#include "XLangTreeContext.h" // TreeContext
#include "XLangType.h" // uint32_t
#include <string> // std::string

namespace xl { namespace mvc {

struct MVCModel
{
    template<class T>
    static node::NodeIdentIFace* make_term(TreeContext* tc, uint32_t sym_id, T value)
    {
        return new (tc->alloc(), __FILE__, __LINE__) node::TermNode<
                static_cast<node::NodeIdentIFace::type_t>(node::TermType<T>::type)
                >(sym_id, value); // default case assumes no non-trivial dtor
    }
    static node::SymbolNode* make_symbol(TreeContext* tc, uint32_t sym_id, size_t size, ...);
    static node::NodeIdentIFace* make_ast(TreeContext* tc, std::string filename);
};

} }

#endif
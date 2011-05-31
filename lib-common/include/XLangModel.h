// Variations of a Flex-Bison parser -- based on
// "A COMPACT GUIDE TO LEX & YACC" by Tom Niemann
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
#include "XLangNodeBase.h" // node::NodeBase
#include "XLangNode.h" // node::Node
#include "XLangParseContextBase.h" // ParseContextBase
#include "XLangType.h" // uint32
#include <string> // std::string

namespace mvc {

class Model
{
public:
    template<class T>
    static node::NodeBase* make_leaf(ParseContextBase* pc, uint32 sym_id, T value)
    {
        return new (pc->alloc(), __FILE__, __LINE__) node::LeafNode<T>(sym_id, value);
    }
    static node::NodeBase* make_inner(ParseContextBase* pc, uint32 sym_id, size_t child_count, ...);
};

}

#endif

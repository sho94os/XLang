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

#include "mvc/XLangMVCModel.h" // mvc::MVCModel
#include "XLangParseContextBase.h" // ParseContextBase
#include "node/XLangNode.h" // node::Node
#include "XLangType.h" // uint32
#include <stdarg.h> // va_list
#include <string> // std::string

namespace mvc {

node::NodeBase* MVCModel::make_inner(ParseContextBase* pc, uint32 sym_id, size_t child_count, ...)
{
    va_list ap;
    va_start(ap, child_count);
    node::NodeBase* node = new (pc->alloc(), __FILE__, __LINE__) node::InnerNode(sym_id, child_count, ap);
    va_end(ap);
    return node;
}

}
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

#ifndef XLANG_NODE_VISITOR_BASE_H_
#define XLANG_NODE_VISITOR_BASE_H_

#include "XLangNodeBase.h" // Node

namespace node {

class NodeVisitorBase
{
public:
    virtual void visit(const node::LeafNodeBase<node::NodeBase::INT>* node) = 0;
    virtual void visit(const node::LeafNodeBase<node::NodeBase::FLOAT>* node) = 0;
    virtual void visit(const node::LeafNodeBase<node::NodeBase::STRING>* node) = 0;
    virtual void visit(const node::LeafNodeBase<node::NodeBase::CHAR>* node) = 0;
    virtual void visit(const node::LeafNodeBase<node::NodeBase::IDENT>* node) = 0;
    virtual void visit(const node::InnerNodeBase* node) = 0;
};

class NodeVisitable
{
public:
    virtual void accept(NodeVisitorBase* visitor) const = 0;
};

}

#endif
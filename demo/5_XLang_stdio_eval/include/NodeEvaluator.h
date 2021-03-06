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

#ifndef NODE_EVALUATOR_H_
#define NODE_EVALUATOR_H_

#include "node/XLangNodeIFace.h" // node::NodeIdentIFace
#include "visitor/XLangVisitor.h" // visitor::VisitorDFS

struct NodeEvaluator : public xl::visitor::VisitorDFS
{
public:
    NodeEvaluator()
    {}
    void visit(const xl::node::TermNodeIFace<xl::node::NodeIdentIFace::INT>* _node);
    void visit(const xl::node::TermNodeIFace<xl::node::NodeIdentIFace::FLOAT>* _node);
    void visit(const xl::node::TermNodeIFace<xl::node::NodeIdentIFace::STRING>* _node);
    void visit(const xl::node::TermNodeIFace<xl::node::NodeIdentIFace::CHAR>* _node);
    void visit(const xl::node::TermNodeIFace<xl::node::NodeIdentIFace::IDENT>* _node);
    void visit(const xl::node::SymbolNodeIFace* _node);
    bool is_printer() const
    {
        return false;
    }
    float32_t get_value() const
    {
        return m_value;
    }

private:
    float32_t m_value;
};

#endif

#include <assert.h>
#include <stdio.h>
#include <vector>
#include "emit.h"
#include "cool-tree.h"
#include "symtab.h"

enum Basicness     {Basic, NotBasic};
#define TRUE 1
#define FALSE 0

class CgenClassTable;
typedef CgenClassTable *CgenClassTableP;

class CgenNode;
typedef CgenNode *CgenNodeP;

class Environment {
private:
    std::vector<Symbol> vars;
    std::vector<int> scope_lengths; // To track scopes for ExitScope
    CgenNodeP cur_class;
    
    // We might need to store method formals here or in CgenNode
    // But formals are specific to the method being generated.
    // So maybe we initialize Environment with formals.
    std::vector<Symbol> formals;

public:
    Environment(CgenNodeP cls, std::vector<Symbol> f) : cur_class(cls), formals(f) {}
    Environment(CgenNodeP cls) : cur_class(cls) {}

    int LookUpVar(Symbol sym);
    int LookUpParam(Symbol sym);
    int LookUpAttrib(Symbol sym);
    void EnterScope();
    void ExitScope();
    void AddVar(Symbol sym);
    void AddParam(Symbol sym); // Used during init?
    void AddObstacle(); // For GC?
    
    CgenNodeP get_class() { return cur_class; }
    std::vector<Symbol> get_formals() { return formals; }
};

class CgenClassTable : public SymbolTable<Symbol,CgenNode> {

private:
   List<CgenNode> *nds;
   ostream& str;
   int stringclasstag;
   int intclasstag;
   int boolclasstag;


// The following methods emit code for
// constants and global declarations.

   void code_global_data();
   void code_global_text();
   void code_bools(int);
   void code_select_gc();
   void code_constants();
   
   void code_class_nameTab();
   void code_class_objTab();
   void code_dispatchTabs();
   void code_protObjs();
   void code_class_inits();
   void code_class_methods();

// The following creates an inheritance graph from
// a list of classes.  The graph is implemented as
// a tree of `CgenNode', and class names are placed
// in the base class symbol table.

   void install_basic_classes();
   void install_class(CgenNodeP nd);
   void install_classes(Classes cs);
   void build_inheritance_tree();
   void set_relations(CgenNodeP nd);
public:
   CgenClassTable(Classes, ostream& str);
   void code();
   CgenNodeP root();
};


class CgenNode : public class__class {
private: 
   CgenNodeP parentnd;                        // Parent of class
   List<CgenNode> *children;                  // Children of class
   Basicness basic_status;                    // `Basic' if class is basic
                                              // `NotBasic' otherwise

public:
   CgenNode(Class_ c,
            Basicness bstatus,
            CgenClassTableP class_table);

   void add_child(CgenNodeP child);
   List<CgenNode> *get_children() { return children; }
   void set_parentnd(CgenNodeP p);
   CgenNodeP get_parentnd() { return parentnd; }
   int basic() { return (basic_status == Basic); }

   std::vector<CgenNodeP> inheritance_path;
   std::vector<std::pair<Symbol,Symbol>> methods; // name, class_defined_in
   std::vector<std::pair<Symbol,Symbol>> attribs; // name, type

   int class_tag;
   int max_child_tag;

   void setup(int tag, int& next_tag);
   int get_tag() const { return class_tag; }
   
   int get_method_offset(Symbol name);
   int get_attrib_offset(Symbol name);
   
   void code_protobj(ostream& s);
   void code_init(ostream& s);
   void code_methods(ostream& s);
};

class BoolConst 
{
 private: 
  int val;
 public:
  BoolConst(int);
  void code_def(ostream&, int boolclasstag);
  void code_ref(ostream&) const;
};


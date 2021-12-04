
// a lexer so that i can grab the input and parse it correctly turn it to
// toknens whatever etc

// (define a 20)
// it would assign "a" in the current scope in the hashtable to the
// primitive 20

// (define a (lambda (x) (+ 10 x)))

// lambda values or whatever (a 20)
// scope = {}
// for a, v in zip(lambargs, params):
//   scope[a] = v
// + -> 10 -> x -> None
// "+" function pointer that does the sum of nodes
// scope has a parent
// scope -> parent -> primitives it will give an error that the identifier is missing
//
// (+) -> 10 -> x
// (+ 10 x)

// (* 20 (+ 10 x))

#define NODE_EXPRESSION 1
#define NODE_PRIMITIVE 2

// (define (a hello))
// [EXPRESSION] -> (define) -> [EXPRESSION] ->
// (define a b)
// []->([]->(()() []()()))
// an expression body is a list of sub-nodes, but they're
// unconventional in comparison to nodes which only have one
// (define a b) (define a b)
// (x y) ((x y) x y (x))
// [] new scope
//   ()
//   ()
// [] all of these are scope nodes !
//   []
//     () lambdas grab future primitives? it might ignore the rest
//     ()
//   ()
//   ()
//   []
//     ()
// define is a lambda that takes two arguments
// () -> () -> () ... if there is not enough arguments, everything will be nil,
//                    if there is too many,they will be ignored
//                    once it's executed, the scope will be exited
//                    of course, the lambda will only be executed if
//                    it's the first item in the expression, otherwise,
//                    it will be passed to other items.
// there's two kinds of Nodes
// * IDENTIFIER
// identifies are symbols that represent something internal in the
// system or are literals, it doesn't make a difference to the system
// and that should be decided at parse time
// 
// * BLOCK
// surrounded in parentheses and with list notation, the sub-items are
// linked together. the first item of the block must /always/ be a lambda.
// there will be a special "block" keyword that will allow the user to be
// able to have a list of statements much like how the root node will
// behave. the block will internally be a lambda but it will execute the
// special behaviour that only the root node does where it will execute
// each statement after one another and then return the results. the lambda
// keyword will also trigger a special block where the first list in the
// lambda is used to interanlly register the parameters for the lambda while
// the rest is contained in a block.
//
// is this macros? macros will be easy to implement probably since it
// just generates a syntax tree... i think.
//
// ----
//
// there will also be ONEmore type of Node that's used for a special
// use-case that's just for the parser's usage
//
// *PLACEHOLDER
// placeholders will always be the first item of a BLOCK Node,
// this node has the special purpose of being recognized that it's
// being used to contain the items inside of a block
//
//
// ----
//
// well now I've decided one more Node type that can exist
//
// *LAMBDA
// this will mostly be used internally so it can be identified
// when it is stored as a LispValue 


#define NODET_IDENTIFIER 0
#define NODET_BLOCK 1
#define NODET_PLACEHOLDER 2
#define NODET_LAMBDA 3

class Node {
  // used for a NODE_PRIMITIVE so it can be used to reference
  // an assigned variable
  U8 *name;
  // used for a NODE_BLOCK in order to contain the sub-items
  Node *node;
  // used to determine the link of the next node
  Node *link;
  U32 type;
} n;

class Pair {
  U8 *key;
  U0 *value;
} p;

class Range {
  U32 s;
  U32 e;
} r;

U8* GetStringFromRange(U8 *str, Range range) {
  U32 len = range.e - range.s + 1;
  U8* ret = CAlloc(len + 1);
  MemCpy(ret, &str[range.s], len);
  ret[len] = '\0';
  return ret;
}

U0* FindValueByKey(Pair *pairs, U8 *key, U32 size) {
  U32 i;
  for (i = 0; i < size; i++) {
    "The key is %s\n", pairs[i].key;
    if (!StrCmp(pairs[i].key, key)) {
      
      return pairs[i].value;
    }
  }
  return NULL;
}

Node* NewIdentifier(U8 *symbol) {
  Node* n = CAlloc(sizeof(Node));
  n->name = symbol;
  n->type = NODET_IDENTIFIER;
  return n;
}

Node* NewBlock() {
  Node* n = CAlloc(sizeof(Node));
  n->type = NODET_BLOCK;
  Node* p = CAlloc(sizeof(Node));
  p->type = NODET_PLACEHOLDER;
  n->node = p;
  return n;
}

// look for the next symbol, currently scanning through
// whitespace
#define PARSER_SEEK 0
// currently scanning through the symbol, this basically changes
// how the range is being changed
#define PARSER_SCANNING 1

// TODO:we need to actually make this detect
// alphanumeric numbers properly lol
Bool IsAlphanumeric(U8 char) {
  return (char >= 'a' && char <= 'z') || 
         (char >= 'A' && char <= 'Z') ||
         (char >= '0' && char <= '9');
}

Bool IsWhitespace(U8 char) {
  return char == '\n' ||
         char == '\t' ||
         char == ' ';
}

#define EXPRESSION_START'('
#define EXPRESSION_END')'

Bool IsIdentifier(U8char) {
  return !IsWhitespace(char) &&
         char != EXPRESSION_START &&
         char != EXPRESSION_END;  
}

#define STACK_SIZE 32

Node* LexText(U8 *input) {
  Node *root = NewBlock();
  
  Node *new = NULL;
  // this contains blocks in scope
  Node **scopes = CAlloc(sizeof(Node) * STACK_SIZE);
  scopes[0] = root;
  Node *current = root->node;  

  I32 scope = 0;
  U32 length = StrLen(input);
  U32 i; 
  Range range;
  U32 lstate = PARSER_SEEK;
  "Reached parser\n";
  for (i = 0; i < length; i++) {
    "%c ", input[i];\
    switch_state:
    switch (lstate) {
      case (PARSER_SEEK): {
        "Seeking...\n";
        if (input[i] == EXPRESSION_START) {
          "ENTERINGNEWSCOPE(EXPRESSION)\n";
          new = NewBlock();
          if ((scope++) >= STACK_SIZE) {
            throw('Overflow');
          }
          scopes[scope] = new;
          current->link = new;
          current = new->node;
        } else if (input[i] == EXPRESSION_END) {
          "EXITINGSCOPE(EXPRESSION)\n";
          if ((scope--) < 0) {
            throw('Undrflow');
          }
          current = scopes[scope]->node;
          while (current->link != NULL) {
            current = current->link;
          }
        } else if (IsIdentifier(input[i])) {
          "SHOULDSWAPTOSCANINGNOW\n";
          range.s = i;
          lstate = PARSER_SCANNING;
          goto switch_state;
        }
        break;
      }
      // The parser is scanning the symbol in this state and building
      // the node.
      case (PARSER_SCANNING): {
        "Scanning...\n";
        Bool last = i == (length-1);
        Bool invalid = !IsIdentifier(input[i]);
        if (last || invalid) {
          if (!invalid) {
            range.e = i;
          } else {
            range.e = i-1;
          }
          U8 *symbolName = GetStringFromRange(input, range);
          new = NewIdentifier(symbolName);
          current->link = new;
          current = new; 
          if (invalid) {
            "SHOULDSWAPTOSEEKINGNOW\n";
            lstate = PARSER_SEEK;
            goto switch_state;
          }
        }
        break;
      }
    }
    continue_parse:
  }
  return root; 
}

U0 PrintTree(Node* node, U32 scope) {
  U32 i;
  if (node != NULL) {
    for (i = 0; i < scope; i++)
      "  ";
    switch (node->type) {
      case (NODET_IDENTIFIER):
        "- %s\n", node->name;
        PrintTree(node->link, scope);
        break;
      case (NODET_BLOCK):
        "[BLOCK]\n";
        PrintTree(node->node->link, scope+1);
        PrintTree(node->link, scope);
        break;   
      default:
        "[UNKNOWN]\n";
    }
  }
}

#define LispStr U8*
#define LISP_STR 0
#define LispInt I32
#define LISP_INT 1
#define LISP_DOUBLE 2
#define LISP_LIST 3
#define LISP_VECTOR 4
// lambdas are just like nodes
#define LISP_LAMBDA 5
// FUNCTIONS are a special kind of lambda where they
// will point to a function pointer. the parameter
// that will be passed to the function will be a LISP_LIST.
// it will be expected to return a value
#define LISP_FUNCTION 5
#define LISP_NIL 6

class LispValue {
  U0 *value;
  U32 type;
} lv;

#define LISP_TABLE_SIZE 32
#define LISP_SCOPE_SIZE 32

class LispTablePair {
  U8 *key;
  LispValue *value;
} ltp;

#define LispTable LispTablePair**

LispTable NewLispTable() {
  LispTable table = CAlloc(sizeof(LispTablePair) *
                           LISP_TABLE_SIZE *
                           LISP_SCOPE_SIZE);
  return table;
}

LispValue* GetValueByKey(LispTablePair* pairs, U8 *key) {
  U32 i;
  for (i = 0; i < LISP_SCOPE_SIZE; i++) {
    if (!StrCmp(pairs[i].key, key)) {
      return pairs[i].value;
    }
  }
  return NULL;
}

LispValue* SearchScopes(LispTable table, U8 *key, I32 scope) {
  LispValue *value = NULL;
  for (;(scope >= 0) || value == NULL; scope--) {
    value = GetValueByKey(table[scope], key);
  }
  return value;
}

Bool IsInt(U8* str) {
  return FALSE;
}

Bool IsDouble(U8*str) {
  return FALSE;
}

LispTable lispValues;
// this will keep track of the parent 
Node lispScopes[LISP_SCOPE_SIZE];

// this does the actual processing of a node tree
// it will go through the tree recursively
U0*ParseNode(Node* node, I32 scope) {
  
}

U0 ParseTree(Node* tree) {
  lispValues = NewLispTable();
  ParseNode(tree, 0);
  Free(lispValues);
}

U8 *example = "(define (lambda (x) (+ 10 20))) define a 20";

// this is an input without parentheses
U8 *exampleInput2 = "define a 20";

U8 Main() {
  Node* tree = LexText(example);
  "\ninput: %s\n\n", example;
  PrintTree(tree, 0);
  Free(tree);
  return 0;
}
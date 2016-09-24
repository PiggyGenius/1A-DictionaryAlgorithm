with Ada.Strings.Unbounded;
use Ada.Strings.Unbounded;

PACKAGE Tree IS
    MAX: array(Character range 'a'..'z') of Natural := (others=>0);
    type Tree IS private;type CellAccess IS private;
    FUNCTION New_Tree RETURN Tree;
    PROCEDURE Insertion(T:IN OUT Tree;Word:IN String);
    PROCEDURE Search_And_Display(T:IN Tree;Letters:IN String);
    PROCEDURE Add(head:IN OUT CellAccess;Word:IN String);
    PROCEDURE AddWord(T:IN OUT Tree;Word:IN String;pos:IN String);
    PROCEDURE Search(T:IN Tree;pos:IN String);
    PROCEDURE Display(L:IN CellAccess);
    PROCEDURE FreeData(T:IN OUT Tree;C:IN Character);
    PROCEDURE FreeTree(T:IN OUT Tree);
    PROCEDURE CheckTree(T:IN Tree);
    PROCEDURE SetMax;
    PROCEDURE SearchMax;
private
    subtype Digit IS Character range '0'..'9';
    type Node;type Cell;
    type CellAccess IS access Cell;
    type Tree IS access Node;
    type Cell IS record
        word: Unbounded_String;
        next: CellAccess;
    end record;
    type Arrnode IS array(Natural range <>) of tree;
    type AccessArray IS access Arrnode;
    type Node(is_Cell: Boolean) IS record
        CASE is_Cell IS
            WHEN false =>
                nodes: AccessArray := NULL;
            WHEN true =>
                head: CellAccess := NULL;
        END CASE;
    end record;
END Tree;

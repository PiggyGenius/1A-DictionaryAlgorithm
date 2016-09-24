WITH Ada.Text_IO,Ada.Integer_Text_IO,Ada.Integer_Text_IO,Ada.Unchecked_Deallocation,tree;
WITH Ada.Strings.Fixed,Interfaces.C,Ada.Directories;
USE Ada.Text_IO,Ada.Integer_Text_IO,Ada.Integer_Text_IO,Ada.Strings.Fixed,Interfaces.C,Ada.Directories;

PACKAGE BODY Tree IS
    PROCEDURE FreeNode IS NEW Ada.Unchecked_Deallocation(Node,Tree);

    PROCEDURE FreeCell IS NEW Ada.Unchecked_Deallocation(Cell,CellAccess);

    PROCEDURE FreeArrnode IS NEW Ada.Unchecked_Deallocation(Arrnode,AccessArray);

    -- Exception may be created if the file is deleted or the structure changed.
    PROCEDURE SearchMax IS 
        date: File_Type;
    BEGIN
        Open(File=>date,Mode=>In_File,Name=>"american-english");
        WHILE NOT End_Of_File(date) LOOP
            DECLARE
                str: String := Get_Line(date);
                tab: array(Character range 'a'..'z') of Natural := (others=>0);
            BEGIN
                FOR i IN str'Range LOOP
                    tab(str(i)):=tab(str(i))+1;
                END LOOP;
                FOR i IN str'Range LOOP
                    IF MAX(str(i)) < tab(str(i)) THEN
                        MAX(str(i)) := tab(str(i));
                    END IF;
                END LOOP;
            END;
        END LOOP;
        Close(date);
    END;

    -- We want to know the max number of occurance of letter x in 'a'..'z' to create array of max.
    -- The MAX will only be actualized if the dictionnary was modified.
    PROCEDURE SetMax IS
        FUNCTION Sys (Arg : Char_Array) RETURN Integer;
        pragma Import(C, Sys, "system");
        date: File_Type;
        tmp: File_Type;
        val: Integer;
    BEGIN
        val := Sys(To_C("echo $(stat -c %y american-english | awk '{print $1$2}')> .dictionnaryTmp"));
        IF val = 0 THEN
            Open(File=>date,Mode=>In_File,Name=>".dictionnaryDate");
            Open(File=>tmp,Mode=>In_File,Name=>".dictionnaryTmp");
            IF Get_Line(date) /= Get_Line(tmp) THEN
                Close(date);
                val := Sys(To_C("echo $(stat -c %y american-english | awk '{print $1$2}')> .dictionnaryDate"));
                SearchMax;
                Open(File=>date,Mode=>Append_File,Name=>".dictionnaryDate");
                FOR i IN MAX'Range LOOP
                    Put(date,MAX(i),width=>0);New_Line(date);
                END LOOP;
            ELSE
                FOR i IN MAX'Range LOOP
                    MAX(i) := Natural'Value(Get_Line(date));
                END LOOP;
            END IF;
            Close(tmp);
            Close(date);
            Delete_File(".dictionnaryTmp");
        END IF;
    END;

    -- The free works well with a argument but user isn't supposed to know this.
    PROCEDURE FreeTree(T:IN OUT Tree) IS
    BEGIN
        FreeData(T,'a');
    END;

    -- Recursive free of entire tree and all the lists.
    PROCEDURE FreeData(T:IN OUT Tree;C:IN Character) IS
    BEGIN
        IF T /= NULL THEN
            IF C = Character'Val(Character'Pos('z')+1) THEN
                IF T.ALL.head /= NULL THEN
                    DECLARE
                        tmp: CellAccess := NULL;
                    BEGIN
                        WHILE T.ALL.head /= NULL LOOP
                            tmp := T.ALL.head.ALL.next;
                            FreeCell(T.ALL.head);
                            T.ALL.head := tmp;
                        END LOOP;
                    END;
                END IF;
            ELSE
                IF T.ALL.nodes /= NULL THEN
                    FOR i IN 0..MAX(C) LOOP
                        IF T.ALL.nodes.ALL(i) /= NULL THEN
                            FreeData(T.ALL.nodes.ALL(i),Character'Val(Character'Pos(C)+1));
                            FreeNode(T.ALL.nodes.ALL(i));
                        END IF;
                    END LOOP;
                    FreeArrnode(T.ALL.nodes);
                END IF;
                FreeNode(T);
            END IF;
        END IF;
    END;

    FUNCTION New_Tree RETURN Tree IS
    BEGIN
        SetMax;
        RETURN NEW Node(false);
    END;

    -- Add word to list.
    PROCEDURE Add(head:IN OUT CellAccess;Word:IN String) IS
    BEGIN
        head := NEW Cell'(To_Unbounded_String(Word),head);
    END;

    -- We want to know the number of x entered by user, with x in 'a'..'z'
    FUNCTION GetValue(str: String) RETURN Natural IS
        tmp: Unbounded_String := To_Unbounded_String("");
        i: Positive := Str'First;
    BEGIN
        WHILE i IN str'First..str'Last AND THEN str(i) IN Digit LOOP
            tmp:=tmp&str(i);
            i:=i+1;
        END LOOP;
        RETURN Natural'Value(To_String(tmp));
    END;


    -- Just a small debug check if tree was freed, valgrind is better of course.
    PROCEDURE CheckTree(T:IN Tree) IS
        top: Natural := 0;
    BEGIN
        FOR i IN MAX'Range LOOP
            IF top < MAX(i) THEN
                top:=MAX(i);
            END IF;
        END LOOP;
        IF T /= NULL THEN
            IF T.ALL.nodes /= NULL THEN
                FOR i IN 0..top LOOP
                    IF T.ALL.nodes(i) /= NULL THEN
                        Put_Line("WTF");
                    END IF;
                END LOOP;
            ELSE
                Put_Line("OK");
            END IF;
        END IF;
    END;

    -- We need to find the correct node to input a word, recursive search for this node
    PROCEDURE AddWord(T:IN OUT Tree;Word:IN String;pos:IN String) IS
        i: Natural := GetValue(pos(pos'First+1..pos'Last));
    BEGIN
        IF T.ALL.nodes = NULL THEN
            T.ALL.nodes := NEW Arrnode(0..MAX(pos(pos'First)));
        END IF;
        IF pos(pos'First..pos'First) = "z" THEN
            IF T.ALL.nodes(i) = NULL THEN
                T.ALL.nodes(i) := NEW Node(true);
            END IF;
            Add(T.ALL.nodes(i).head,Word);
        ELSE
            IF T.ALL.nodes(i) = NULL THEN
                T.ALL.nodes(i) := NEW Node(false);
            END IF;
            AddWord(T.ALL.nodes(i),Word,pos(pos'First+Integer'Image(i)'Length..pos'Last));
        END IF;
    END;

    -- We create a string to search and add words. cab will be: a1b1c1d0...z0.
    FUNCTION GetPos(Word:IN String) RETURN String IS
        tab: array(Character Range 'a'..'z') of Natural := (others=>0);
        str: Unbounded_String := To_Unbounded_String("");
    BEGIN
        FOR i IN 1..Word'Length LOOP
            tab(Word(i)):=tab(Word(i))+1;
        END LOOP;
        FOR i IN Word'Range LOOP
            IF tab(Word(i)) > MAX(Word(i)) THEN
                tab(Word(i)) := MAX(Word(i));
            END IF;
        END LOOP;
        FOR c IN tab'Range LOOP
            str := str & c & Trim(Natural'Image(tab(c)),Ada.Strings.Left);
        END LOOP;
        RETURN To_String(str);
    END;

    PROCEDURE Insertion(T:IN OUT Tree;Word:IN String) IS
    BEGIN
        AddWord(T,Word,GetPos(Word));
    END;

    PROCEDURE Search_And_Display(T:IN Tree;Letters:IN String) IS
    BEGIN
        Put_Line("Anagrams of: " & Letters);
        Search(T,GetPos(Letters));
        New_Line;
    END;

    PROCEDURE Display(L:IN CellAccess) IS
        tmp: CellAccess := L;
    BEGIN
        WHILE tmp /= NULL LOOP
            Put_Line(To_String(tmp.ALL.word));
            tmp:=tmp.ALL.next;
        END LOOP;
    END;

    PROCEDURE Search(T:IN Tree;pos:IN String) IS
        i: Natural := GetValue(pos(pos'First+1..pos'Last));
    BEGIN
        IF T /= NULL THEN
            IF T.ALL.nodes = NULL THEN
                NULL;
            ELSIF pos(pos'First..pos'First) = "z" THEN
                FOR j IN 0..i LOOP
                    IF T.ALL.nodes(j) = NULL THEN
                        NULL;
                    ELSIF T.ALL.nodes(j).head = NULL THEN
                        NULL;
                    ELSE
                        Display(T.ALL.nodes(j).head);
                    END IF;
                END LOOP;
            ELSE
                FOR j IN 0..i LOOP
                    IF T.ALL.nodes(j) = NULL THEN
                        NULL;
                    ELSE
                        IF T.ALL.nodes(j) /= NULL THEN
                            Search(T.ALL.nodes(j),pos(pos'First+Integer'Image(i)'Length..pos'Last));
                        END IF;
                    END IF;
                END LOOP;
            END IF;
        END IF;
    END;
END Tree;

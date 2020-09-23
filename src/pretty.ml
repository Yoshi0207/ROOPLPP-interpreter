open Syntax
   
let pretty_dataType = function
  | IntegerType -> "int"
  | ObjectType typeId -> typeId
  | CopyType typeId -> typeId
  | ObjectArrayType typeId -> typeId ^ "[]"
  | IntegerArrayType -> "int[]"
  | ArrayType -> ""
  | ArrayElementType -> ""
  | NilType -> ""

let pretty_binOp = function
  | Add -> "+"
  | Sub -> "-"
  | Xor -> "^"
  | Mul -> "*"
  | Div -> "/"
  | Mod -> "%"
  | Band -> "&"
  | Bor -> "|"
  | And -> "&&"
  | Or -> "||"
  | Lt -> "<"
  | Gt -> ">"
  | Eq -> "="
  | Ne -> "!="
  | Le -> "<="
  | Ge -> ">="

let pretty_modOp = function
  | ModAdd -> "+="
  | ModSub -> "-="
  | ModXor -> "^="
            
let rec pretty_exp = function
  | Const n -> string_of_int n
  | Var id -> id
  | ArrayElement(id, exp) -> id ^ "[" ^ (pretty_exp exp) ^ "]"
  | Nil -> "nil"
  | Binary(binOp, exp1, exp2) -> (pretty_exp exp1) ^ " " ^ (pretty_binOp binOp) ^ " " ^ (pretty_exp exp2)
  | Dot(exp1, exp2) -> (pretty_exp exp1) ^ "." ^ (pretty_exp exp2)
                     
let rec pretty_obj = function
  | VarArray(id, None) -> id
  | VarArray(id, Some exp) -> id ^ "[" ^ (pretty_exp exp) ^ "]"
  | InstVar(obj1, obj2) -> (pretty_obj obj1) ^ "." ^ (pretty_obj obj2)
                         
let rec pretty_actArgs =
  let pretty_actArg = function
    | Id(id) -> id
    | Exp(e) -> pretty_exp e
  in
  function
  | [] -> ""
  | [arg] -> pretty_actArg arg
  | hd :: tl -> (pretty_actArg hd) ^ ", " ^ (pretty_actArgs tl)
              
let rec pretty_stms stms =
  let pretty_stm str stm =
    let s =
    match stm with
    | Assign(obj, modOp, exp) -> (pretty_obj obj) ^ " " ^ (pretty_modOp modOp) ^ " " ^ (pretty_exp exp)
    | Swap(obj1, obj2) -> (pretty_obj obj1) ^ " <=> " ^ (pretty_obj obj2)
    | Conditional(exp1, stm1, stm2, exp2) -> "if " ^ (pretty_exp exp1) ^ " then\n" ^ (pretty_stms stm1) ^ "else\n" ^ (pretty_stms stm2) ^ "fi " ^ (pretty_exp exp2)
    | Loop(exp1, stm1, stm2, exp2) -> "from " ^ (pretty_exp exp1) ^ " do\n" ^ (pretty_stms stm1) ^ "loop\n" ^ (pretty_stms stm2) ^ "until " ^(pretty_exp exp2)
    | ObjectBlock(typeId, id, stm) -> "construct " ^ typeId ^ " " ^ id ^ "\n" ^ (pretty_stms stm) ^ "\n" ^ "destruct " ^ id
    | LocalBlock(dataType, id, exp1, stm, exp2) -> "local " ^ (pretty_dataType dataType) ^ " " ^ id ^ " = " ^ (pretty_exp exp1) ^ "\n" ^ (pretty_stms stm) ^ "\n" ^ "delocal " ^ (pretty_dataType dataType) ^ " " ^ id ^ " = " ^ (pretty_exp exp2)
    | LocalCall(methodId, ids) -> "call " ^ methodId ^ "(" ^ (pretty_actArgs ids) ^ ")"
    | LocalUncall(methodId, ids) -> "uncall " ^ methodId ^ "(" ^ (pretty_actArgs ids) ^ ")"
    | ObjectCall(obj, methodId, ids) -> "call " ^ (pretty_obj obj) ^ "::" ^ methodId ^ "(" ^ (pretty_actArgs ids) ^ ")"
    | ObjectUncall(obj, methodId, ids) -> "uncall " ^ (pretty_obj obj) ^ "::" ^ methodId ^ "(" ^ (pretty_actArgs ids) ^ ")"
    | ObjectConstruction(typeId, obj) -> "new " ^ typeId ^ " " ^ (pretty_obj obj)
    | ObjectDestruction(typeId, obj) -> "delete " ^ typeId ^ " " ^ (pretty_obj obj)
    | CopyReference(dataType, obj1, obj2) -> "copy " ^ (pretty_dataType dataType) ^ " " ^ (pretty_obj obj1) ^ " " ^ (pretty_obj obj2)
    | UncopyReference(dataType, obj1, obj2) -> "uncopy " ^ (pretty_dataType dataType) ^ " " ^ (pretty_obj obj1) ^ " " ^ (pretty_obj obj2)
    | ArrayConstruction((typeId, exp), obj) -> "new " ^ typeId ^ "[" ^ (pretty_exp exp) ^ "] " ^ (pretty_obj obj)
    | ArrayDestruction((typeId, exp), obj) -> "delete " ^ typeId ^ "[" ^ (pretty_exp exp) ^ "] " ^ (pretty_obj obj)
    | Skip -> "skip"
    | Show(exp) -> "show" ^ "(" ^ (pretty_exp exp) ^ ")"
    | Print(str) -> "print" ^ "(\"" ^ str ^ "\")"
    in
    str ^ s ^ "\n"
  in
  List.fold_left pretty_stm "" stms
  
let pretty_decl (Decl(dataType, id)) = (pretty_dataType dataType) ^ " " ^ id
                                     
let rec pretty_fields = function
  | [] -> ""
  | hd :: tl -> (pretty_decl hd) ^ "\n" ^ (pretty_fields tl)
              
let rec pretty_args = function
  | [] -> ""
  | [arg] -> pretty_decl arg
  | hd :: tl -> (pretty_decl hd) ^ ", " ^ (pretty_args tl)
              
let pretty_method (MDecl(id, args, stms)) =
  "method " ^ id ^ "(" ^ pretty_args args ^ ")\n" ^ (pretty_stms stms)
  
let rec pretty_methods = function
  | [m] -> (pretty_method m)
  | hd :: tl -> (pretty_method hd) ^ "\n" ^ (pretty_methods tl)
              
let pretty_c (CDecl(c, inherits, fields, methods)) =
  let inher = 
  match inherits with
  | None -> ""
  | Some(id) -> " inherits " ^ id
  in
  "class " ^ c ^ inher  ^ "\n" ^ (pretty_fields fields) ^ (pretty_methods methods)
  
let rec pretty_cl = function
  | [cl] -> pretty_c cl
  | hd :: tl ->(pretty_c hd) ^ "\n" ^ (pretty_cl tl)
             
let pretty_prog (Prog(cl)) = pretty_cl cl

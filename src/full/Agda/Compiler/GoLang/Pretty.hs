module Agda.Compiler.GoLang.Pretty where

import qualified Agda.Utils.Haskell.Syntax as HS
import Data.List ( intercalate )
import qualified Agda.Compiler.GoLang.Syntax as Go
import Text.PrettyPrint (empty)
import qualified Text.PrettyPrint as T
import Agda.Utils.Hash
import Agda.Utils.Impossible
import Agda.Syntax.Common ( Nat )
import Agda.Compiler.MAlonzo.Encode
import Agda.Utils.Pretty
import Data.Char ( chr, ord )


prettyPrintGo :: Pretty a => a -> String
prettyPrintGo = show . pretty

instance Pretty Go.Module where
  pretty (Go.Module m imports imps) =
    vcat [ "package" <+> pretty m
         , ""
         , vcat $ map pretty imps
         , ""]

instance Pretty Go.Exp where
  prettyPrec pr e =
    case e of
      Go.Const s -> text s
      Go.GoVar i -> getVarNamet i
      Go.GoInterface id -> "type" <+> pretty id <+> " = interface{}"
      Go.GoStruct id elems -> "type" <+> pretty id <+> "struct " <+> (T.braces (vcat $ map pretty elems))
      Go.GoStructElement localId typeId -> "_" <+> pretty localId <+> pretty typeId <+> T.semi
      Go.GoFunction signatures (Go.GoSwitch a b) -> (vcat $ map pretty signatures) <+> (pretty (Go.GoSwitch a b)) <+> (text $ concat $ replicate (length signatures) "}\n")
      Go.GoFunction signatures body -> (vcat $ map pretty signatures) <+> (pretty body) <+> (text $ concat $ replicate (length signatures) "}\n")
      Go.GoSwitch v cases -> "switch type_" <> (pretty v) <> (text "  := ") <> (pretty v) <> (text ".(type) {\n") <> (vcat $ map pretty cases) <> "\ndefault:\n_ = type_"<> (pretty v) <> ";\n panic(\"Unreachable\");\n}"
      Go.GoCase name switchVar paramsStart paramCount exps -> "\ncase " <> (pretty name) <> spaceWrap (T.colon) <> (hsep $ map (createCaseParam paramsStart switchVar) (createCaseList paramCount)) <> (vcat $ map pretty exps)
      Go.GoCreateStruct name params -> (pretty name) <+> T.lbrace <+> (joinStructParams (map pretty params)) <+> "}"
      Go.GoMethodCall name params -> (pretty name) <> (hsep $ map T.parens $ map pretty params)
      Go.GoIf a b c -> "if (" <+> (pretty a) <+> ") {\n" <+> (pretty b) <+> "\n} else {\n" <+> pretty c <+> "\n}\n"
      Go.BinOp a b c -> (T.parens (pretty a)) <+> (pretty b) <+> (T.parens (pretty c))
      Go.GoLet name val exp -> (text name) <+> ":=" <+> (pretty val) <+> "\n" <+> (pretty exp)
      Go.Integer n -> text $ show n
      Go.ReturnExpression exp -> "return" <+> (pretty exp)
      _ -> text ""

spaceWrap :: Doc -> Doc
spaceWrap d = T.space <> d <> T.space

joinStructParams :: [Doc] -> Doc
joinStructParams [] = T.empty
joinStructParams [x] = x <+> (joinStructParams [])
joinStructParams (x:xs) = x <+> "," <+> (joinStructParams xs)

createCaseParam :: Nat -> Nat -> Nat -> Doc
createCaseParam paramStart switchVar paramId = "\n" <> (getVarNamet (paramStart + paramId)) <> " := type_" <> (getVarNamet switchVar) <> "." <> (getVarNamet (paramId - 1)) <> ";\n _ = " <> (getVarNamet (paramStart + paramId))<> ";\n"

instance Pretty Go.MemberId where
  pretty (Go.MemberId  s) = text s
  pretty (Go.MemberIndex i c) = text ""

createCaseList :: Nat -> [Nat]
createCaseList 0 = []
createCaseList n = [1..n]

getVarName :: Nat -> String
getVarName n = [chr ((ord 'a') + n)]

getVarNamet :: Nat -> Doc
getVarNamet n = text $ getVarName n

instance Pretty Go.GlobalId where
  pretty (Go.GlobalId m) = text $ show $ intercalate "_" m


instance Pretty Go.LocalId where
  pretty (Go.LocalId n) = text $ show n

instance Pretty Go.TypeId where
  pretty (Go.TypeId m) = text m
  pretty (Go.ConstructorType m n) = text m <+> text n <+> T.semi
  pretty (Go.FunctionType m n) = "(" <+> text m <+> text n <+> ")"
  pretty (Go.FunctionReturnElement m) = " func(" <+> text m <+> ")"
  pretty (Go.EmptyFunctionParameter) = "()"
  pretty (Go.EmptyType) = text ""
  pretty (Go.PiType (Go.ConstructorType m1 n1) (Go.ConstructorType m2 n2)) = "( " <> text m1 <> " func(" <> (text n1) <> ") " <> (text n2) <> ")"
  pretty _ = (text "utype")

instance Pretty Go.GoFunctionSignature where
  pretty (Go.OuterSignature name param returnElems returnType) = "func " <> (pretty name) <> (pretty param) <> (vcat $ map pretty returnElems) <> T.space <> (pretty returnType) <> " {\n"
  pretty (Go.InnerSignature param returnElems returnType) = "return func" <> (pretty param) <> (vcat $ map pretty returnElems) <> T.space <> (pretty returnType) <> " {\n"



